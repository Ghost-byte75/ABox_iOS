import UIKit
import RxAlamofire
import Alamofire
import RxSwift

class DownloadManager {
    
    public static let shared = DownloadManager()
    let disposeBag = DisposeBag()
    
    func download(urlStr: String,
                  filename: String? = nil,
                  downloadDirectoryURL: URL = FileManager.default.downloadDirectory,
                  downloadProgress: ((Progress) -> ())? = nil,
                  success: ((URL)->())?,
                  failure: ((String)->())?) -> DownloadRequest {
        
        if !FileManager.default.fileExists(atPath: downloadDirectoryURL.path) {
            do {
                try FileManager.default.createDirectory(at: downloadDirectoryURL, withIntermediateDirectories: true)
            } catch let error {
                print(message: error.localizedDescription)
            }
        }

        return AF.download(urlStr)
            .downloadProgress { progress in
                downloadProgress?(progress)
            }
            .responseData { response in
                var myFilename: String!
                if let name = filename {
                    // 自定义文件名
                    myFilename = name
                } else {
                    if let originFilename = response.response?.suggestedFilename?.removingPercentEncoding {
                        myFilename = originFilename
                    } else {
                        // 从url获取文件名
                        if urlStr.contains("?") {
                            let u1 = urlStr.split(separator: "?")[0]
                            myFilename = URL(string: String(u1))!.pathExtension
                        } else {
                            myFilename = URL(string: urlStr)!.pathExtension
                        }
                    }
                }
                
                
                // 下载路径
                let fileURL: URL = downloadDirectoryURL.appendingPathComponent(myFilename)
                if let data = response.value {
                    FileManager.default.createFile(atPath:fileURL.path, contents: data)
                    success?(fileURL)
                }
                if let error = response.error {
                    failure?(error.localizedDescription)
                }
            }
    }
    
    func downloadIPA(urlStr: String,
                     filename: String? = nil,
                     downloadDirectoryURL: URL = FileManager.default.appsDirectory,
                     completionHandler:((URL?, String?)->())?) -> DownloadRequest {
        let hud = QMUITips.showProgressView(kAPPKeyWindow!, status: "请勿关闭对话框或退到后台，以免下载失败！")
        return self.download(urlStr: urlStr, filename: filename, downloadDirectoryURL: downloadDirectoryURL) { downloadProgress in
            // 下载进度
            debugPrint(downloadProgress.fractionCompleted, downloadProgress.completedUnitCount/1024, downloadProgress.totalUnitCount/1024)
            hud.setProgress(CGFloat(downloadProgress.fractionCompleted), animated: true)
        } success: { fileURL in
            var valid = true
            if let data = NSData(contentsOf: fileURL) {
                let fileType = AppSigner.fileType(with: data as Data)
                print(message: "fileType:\(fileType)")
                print(message: "data.count:\(data.count)")
                valid = fileType == 8075;
            } else {
                valid = false
            }
            if valid {
                hud.status = "下载完成"
                hud.removeFromSuperview()
                completionHandler?(fileURL, nil)
            } else {
                hud.status = "下载失败"
                hud.removeFromSuperview()
                completionHandler?(nil, "下载链接已失效！")
                do {
                    try FileManager.default.removeItem(at: fileURL)
                } catch let error {
                    print(message: "删除下载失败的ipa文件时发生错误：\(error.localizedDescription)")
                }
            }
        } failure: { error in
            hud.status = "下载失败"
            hud.removeFromSuperview()
            completionHandler?(nil, error)
        }
    }
}
