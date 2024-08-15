import UIKit
import Alamofire
import HandyJSON
import Async

enum DownloadTaskState: Int, HandyJSONEnum {
    case downloading = 0
    case finished = 1
    case error = 2
    case paused = 3
    case cancelled = 4
    case deleted = 5
}

class DownloadTask: NSObject {
    
    var httpClinet = DownloadManager()
    var downloadRequest: DownloadRequest?
    var info = DownloadTaskInfo()
    var downloadProgress = Progress()
    var downloadProgressHandle: ((Progress) -> ())?
    var downloadStateHandle: ((DownloadTaskState) -> ())?
    var downloadFinishHandle: ((DownloadTaskInfo) -> ())?

    func startDownload() {
        self.saveTaskInfo()
        if let url = URL(string: info.downloadURL) {
            self.downloadRequest = self.httpClinet.download(urlStr: url.absoluteString, filename: self.info.filename) { progress in
                //debugPrint(progress.fractionCompleted, progress.completedUnitCount / 1024, progress.totalUnitCount / 1024)
                self.downloadProgress = progress
                self.downloadProgressHandle?(progress)
            } success: { fileURL in
                print(message: fileURL)
                // 下载完成，读取真实文件名
                self.info.filename = fileURL.lastPathComponent
                self.info.filetype = fileURL.pathExtension.lowercased()
                do {
                    let fileAttributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
                    if let fileSize:NSNumber = fileAttributes[FileAttributeKey.size] as! NSNumber? {
                        self.info.filesize = String.fileSizeDesc(fileSize.intValue)
                    }
                } catch let error as NSError {
                    print("Get attributes errer: \(error)")
                }
                self.info.state = .finished
                self.downloadStateHandle?(self.info.state)
                self.downloadFinishHandle?(self.info)
                self.saveTaskInfo()
                if self.info.filetype == "ipa" {
                    self.importToAppLibrary(info: self.info)
                }
            } failure: { error in
                self.info.state = .error
                self.downloadStateHandle?(self.info.state)
                self.saveTaskInfo()
            }
        } else {
        }
    }
    
    func importToAppLibrary(info: DownloadTaskInfo) {
        if let filename = info.filename {
            let fileURL = FileManager.default.downloadDirectory.appendingPathComponent(filename)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                let hud = QMUITips.showProgressView(kAPPKeyWindow!, status: "正在解压IPA")
                Async.main(after: 0.1, {
                    let appSigner = AppSigner()
                    let key = UUID().uuidString
                    let toDirectoryURL = FileManager.default.appLibraryDirectory.appendingPathComponent(key, isDirectory: true)
                    appSigner.unzipAppBundle(at: fileURL,
                                             outputDirectoryURL: toDirectoryURL,
                                             progressHandler: { entry, zipInfo, entryNumber, total in
                        hud.setProgress(CGFloat(entryNumber)/CGFloat(total), animated: true)
                    },
                                             completionHandler: { (success, application, error) in
                        hud.removeFromSuperview()
                        if let application = application {
                            AppLibraryModel.importApplication(application, key: key, ipaURL: fileURL, toDirectoryURL: toDirectoryURL)
                        } else {
                            kAlert("无法读取应用信息，不受支持的格式。")
                        }
                    })
                })
            }
        }
    }
    
    func suspendTask() {
        print(message: "下载 suspendTask")
        self.info.state = .paused
        self.downloadStateHandle?(self.info.state)
        if let request = self.downloadRequest {
            request.suspend()
        } else {
            self.restartTask()
        }
        self.saveTaskInfo()
    }
    
    func resumeTask() {
        print(message: "下载 resumeTask")
        self.info.state = .downloading
        self.downloadStateHandle?(self.info.state)
        if let request = self.downloadRequest {
            request.resume()
        } else {
            self.restartTask()
        }
        self.saveTaskInfo()
    }
    
    func cancelTask() {
        print(message: "下载 cancelTask")
        self.info.state = .cancelled
        self.downloadStateHandle?(self.info.state)
        if let request = self.downloadRequest {
            request.cancel()
        } else {
            self.restartTask()
        }
        self.saveTaskInfo()
    }
    
    func restartTask() {
        self.info.state = .downloading
        self.downloadStateHandle?(self.info.state)
        self.startDownload()
    }

    func saveTaskInfo() {
        Client.shared.store?.createTable(withName: kDownloadTableName)
        self.info.createDate = Date().toString(.custom("yyyy-MM-dd HH:mm"))
        if let jsonString = self.info.toJSONString() {
            print(message: jsonString)
            Client.shared.store?.put(jsonString, withId: self.info.id, intoTable: kDownloadTableName)
        }
        if let filename = self.info.filename {
            UserDefaults.standard.setValue(filename, forKey: self.info.downloadURL)
            UserDefaults.standard.synchronize()
        }
    }
}

class DownloadTaskInfo: HandyJSON {
    var state = DownloadTaskState.finished
    var appSource: String? = nil
    var downloadURL = ""
    var filesize = "0.0 Bytes"
    var filename: String?
    var filetype = ""
    var createDate = ""
    var id = NSUUID().uuidString
    required init() {}
}
