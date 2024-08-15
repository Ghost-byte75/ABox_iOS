import Foundation
import SafariServices
import Async
import RxAlamofire
import Alamofire

extension ViewController {
    
    func openIPA(url: URL, unzipHandler: ((Bool, URL) -> Void)? = nil) {
        UIImpactFeedbackGenerator.init(style: .medium).impactOccurred()
        var tipMessage = "未越狱设备请签名后再安装。"
        if UIDevice().isJailbroken {
            tipMessage = tipMessage + "已越狱设备请先安装【AppSync Unified】插件关闭签名验证再安装。"
        }
        tipMessage = tipMessage + "安装期间请不要退出对话框，否则可能会导致安装失败。"
        
        let alertController = QMUIAlertController.init(title: url.lastPathComponent, message: tipMessage, preferredStyle: .actionSheet)
        
        alertController.addAction(QMUIAlertAction.init(title: "导入应用库", style: .default, handler: { _, _ in
            let hud = QMUITips.showProgressView(self.view, status: "正在解压IPA")
            Async.main(after: 0.1, {
                let appSigner = AppSigner()
                let key = UUID().uuidString
                let toDirectoryURL = FileManager.default.appLibraryDirectory.appendingPathComponent(key, isDirectory: true)
                appSigner.unzipAppBundle(at: url,
                                         outputDirectoryURL: toDirectoryURL,
                                         progressHandler: { entry, zipInfo, entryNumber, total in
                    hud.setProgress(CGFloat(entryNumber)/CGFloat(total), animated: true)
                },
                                         completionHandler: { (success, application, error) in
                    hud.removeFromSuperview()
                    if let application = application {
                        AppLibraryModel.importApplication(application, key: key, ipaURL: url, toDirectoryURL: toDirectoryURL)
                    } else {
                        kAlert("无法读取应用信息，不受支持的格式。")
                    }
                })
            })
        }))
        
        if let unzipHandler = unzipHandler {
            alertController.addAction(QMUIAlertAction.init(title: "解压", style: .default, handler: { _, _ in
                
                let hud = QMUITips.showProgressView(self.view, status: "正在解压IPA...")
                let outputDirectoryURL = url.deletingPathExtension()
                Async.main(after: 0.1, {
                    let appSigner = AppSigner()
                    appSigner.unzipAppBundle(at: url,
                                             outputDirectoryURL: outputDirectoryURL,
                                             progressHandler: { entry, zipInfo, entryNumber, total in
                        Async.main {
                            hud.setProgress(CGFloat(entryNumber)/CGFloat(total), animated: true)
                        }
                    },
                                             completionHandler: { (success, application, error) in
                        Async.main {
                            unzipHandler(success, outputDirectoryURL)
                            hud.removeFromSuperview()
                        }
                    })
                })
            }))
        }
        
        alertController.addAction(QMUIAlertAction.init(title: "安装", style: .destructive, handler: { _, _ in
            let hud = QMUITips.showProgressView(self.view, status: "正在读取IPA信息...")
            Async.main(after: 0.1, {
                let appSigner = AppSigner()
                appSigner.unzipAppBundle(at: url,
                                         outputDirectoryURL: FileManager.default.unzipIPADirectory.appendingPathComponent(UUID().uuidString, isDirectory: true),
                                         progressHandler: { entry, zipInfo, entryNumber, total in
                    hud.setProgress(CGFloat(entryNumber)/CGFloat(total), animated: true)
                },
                                         completionHandler: { (success, application, error) in
                    hud.removeFromSuperview()
                    if let application = application {
                        AppManager.default.installApp(ipaURL: url, icon: application.icon,  ipaInfo: "\(application.name)/\(application.bundleIdentifier)/\(application.version)")
                    } else {
                        kAlert("无法读取应用信息，不受支持的格式。")
                    }
                })
            })
        }))
        
        alertController.addAction(QMUIAlertAction.init(title: "取消", style: .cancel, handler: nil))
        alertController.showWith(animated: true)
    }
    
    func openURLWithSafari(_ url: URL) {
        let safariVC = SFSafariViewController(url: url)
        safariVC.configuration.entersReaderIfAvailable = false
        safariVC.configuration.barCollapsingEnabled = false
        safariVC.dismissButtonStyle = .close
        self.present(safariVC, animated: true, completion: nil)
        
    }
    
//    func getUDIDWithSafari() {
//        let safariVC = SFSafariViewController(url: AppManager.default.getUDIDURL)
//        safariVC.configuration.entersReaderIfAvailable = false
//        safariVC.configuration.barCollapsingEnabled = false
//        safariVC.dismissButtonStyle = .done
//        self.present(safariVC, animated: true, completion: nil)
//    }
    
    func openURLWithWebView(_ url: URL) {
        let safariVC = SFSafariViewController(url: url)
        safariVC.configuration.entersReaderIfAvailable = false
        safariVC.configuration.barCollapsingEnabled = false
        safariVC.dismissButtonStyle = .close
        self.present(safariVC, animated: true, completion: nil)
    }
            
}


