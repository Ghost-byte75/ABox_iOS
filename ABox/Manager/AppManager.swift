import UIKit
import Async

class AppManager: NSObject {
    //获取udid描述文件
    static let `default` = AppManager()
    let getUDIDURL = URL(string: "https://baidu.com/test.mobileconfig")!

    private var webServer: GCDWebServer?
    private var installApp = false

    func installApp(ipaURL: URL, icon: UIImage? = nil, ipaInfo: String? = nil) {
        if AppDefaults.shared.trollStoreEnable! {
            AppManager.default.trollStoreInstallApp(ipaURL: ipaURL)
        } else {
            do {
                let appData = try Data.init(contentsOf: ipaURL, options: .mappedIfSafe)
                self.initWebServer()
                self.startAppInstallWebServer(appData: appData, icon: icon, ipaInfo: ipaInfo)
            } catch let error {
                kAlert("安装应用时发生错误",message: "Code:482\n\(error.localizedDescription)")
            }
//            if let appData = self.loadDataFromURL(ipaURL) {
//                self.initWebServer()
//                self.startAppInstallWebServer(appData: appData, icon: icon, ipaInfo: ipaInfo)
//            } else {
//                do {
//                    let appData = try Data.init(contentsOf: ipaURL, options: .mappedIfSafe)
//                    self.initWebServer()
//                    self.startAppInstallWebServer(appData: appData, icon: icon, ipaInfo: ipaInfo)
//                } catch let error {
//                    kAlert("安装应用时发生错误",message: "Code:482\n\(error.localizedDescription)")
//                }
//            }
        }
    }
    
    func loadDataFromURL(_ url: URL) -> Data? {
        guard let inputStream = InputStream(url: url) else {
            return nil
        }
        inputStream.open()

        defer {
            inputStream.close()
        }

        var data = Data()
        let bufferSize = 4096
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)

        defer {
            buffer.deallocate()
        }

        while inputStream.hasBytesAvailable {
            let bytesRead = inputStream.read(buffer, maxLength: bufferSize)

            if bytesRead < 0 {
                // 读取错误，处理错误逻辑
                return nil
            } else if bytesRead == 0 {
                // 读取完成
                break
            } else {
                // 将读取的数据追加到 Data 中
                data.append(buffer, count: bytesRead)
            }
        }

        return data
    }
    
    
    func getUDID() {
        UIApplication.shared.open(getUDIDURL, options: [:], completionHandler: nil)
    }
    
    fileprivate func initWebServer() {
        if let webServer = self.webServer {
            if webServer.isRunning {
                print(message: "webServer isRunning... STOP")
                webServer.stop()
            }
            self.webServer = nil
        }
        self.webServer = GCDWebServer()
        self.webServer?.delegate = self
    }
    
    fileprivate func startAppInstallWebServer(appData: Data, icon: UIImage?, ipaInfo: String? = nil) {

        var port: UInt = 8881
        var installURL: URL!
        var iconPath = "/applogo.png"

        let installIPAService: Int = AppDefaults.shared.installIPAService!
        
        if let ipaInfo = ipaInfo {
            Client.shared.updateLog("安装应用：\(ipaInfo)")
            let data = ipaInfo.data(using: String.Encoding.utf8)
            if let base64String = data?.base64EncodedString() {
                print(message: base64String)
                var params = base64String
                params = params.replacingOccurrences(of: "=", with: "")
                print(message: params)
                if installIPAService == 0 {
                    let gboxURL = "https://test.gbox.pub/"
                    installURL = URL(string: "itms-services://?action=download-manifest&url=\(gboxURL)\(params).plist")!
                    port = 9800
                    iconPath = "/icon.png"
                    if let iconData = icon?.pngData() {
                        webServer?.addHandler(forMethod: "GET", path: "/iconx.png", request: GCDWebServerRequest.self, processBlock: { request -> GCDWebServerResponse? in
                            print(message: request)
                            return GCDWebServerDataResponse.init(data: iconData, contentType: "image/png")
                        })
                    }
                } else if installIPAService == 1 {
                    let gboxURL = "https://test.gbox.run/"
                    installURL = URL(string: "itms-services://?action=download-manifest&url=\(gboxURL)\(params).plist")!
                    port = 9800
                    iconPath = "/icon.png"
                    if let iconData = icon?.pngData() {
                        webServer?.addHandler(forMethod: "GET", path: "/iconx.png", request: GCDWebServerRequest.self, processBlock: { request -> GCDWebServerResponse? in
                            print(message: request)
                            return GCDWebServerDataResponse.init(data: iconData, contentType: "image/png")
                        })
                    }
                }
                
            }
        }
        
        if let iconData = icon?.pngData() {
            webServer?.addHandler(forMethod: "GET", path: iconPath, request: GCDWebServerRequest.self, processBlock: { request -> GCDWebServerResponse? in
                print(message: request)
                return GCDWebServerDataResponse.init(data: iconData, contentType: "image/png")
            })
        }
         
        webServer?.addHandler(forMethod: "GET", path: "/app.ipa", request: GCDWebServerRequest.self, processBlock: { request -> GCDWebServerResponse? in
            print(message: request)
            return GCDWebServerDataResponse.init(data: appData, contentType: "application/octet-stream")
        })
        
        print(message: "installURL:\(installURL.absoluteString)")
        self.installApp = true
        do {
            try webServer?.start(options: ["Port": port, "BonjourName": "GCD Web Server"])
            print("Visit \(String(describing: webServer!.serverURL)) in your web browser")
            Async.main(after: 0.55, {
                UIApplication.shared.open(installURL, options: [:]) { result in
                    print(message: result)
                }
            })
        } catch let error {
            Async.main(after: 0.55, {
                kAlert("暂时无法安装，请稍后再试\n\(error.localizedDescription)")
            })
        }
    }

    func importProfile(url: URL, completionHandler:(() -> ())? = nil) {
        if let profile = ALTProvisioningProfile.init(url: url) {
            let fileName = "\(profile.uuid).mobileprovision"
            let savePath = FileManager.default.profilesDirectory.appendingPathComponent(fileName).path
            FileManager.default.createFile(atPath: savePath, contents: profile.data, attributes: nil)
            if AppDefaults.shared.signingProvisioningProfile == nil {
                if let signingCertificateSerialNumber = AppDefaults.shared.signingCertificateSerialNumber {
                    for profileCertificate in profile.certificates {
                        if profileCertificate.serialNumber == signingCertificateSerialNumber {
                            AppDefaults.shared.signingProvisioningProfile = profile.data
                            break
                        }
                    }
                }
            }
            kAlert("描述文件导入成功！")
            completionHandler?()
        } else {
            kAlert("描述文件无效！")
        }
    }
    
    func importCertificate(url: URL, completionHandler: (() -> ())? = nil) {
        let dialogViewController = QMUIDialogTextFieldViewController()
        dialogViewController.title = "导入证书"
        dialogViewController.enablesSubmitButtonAutomatically = false
        dialogViewController.addTextField(withTitle: nil) { (titleLabel, textField, separatorLayer) in
            textField.placeholder = "请输入证书密码"
            textField.maximumTextLength = 100
            textField.keyboardType = .asciiCapable
        }
        dialogViewController.shouldManageTextFieldsReturnEventAutomatically = true
        dialogViewController.addCancelButton(withText: "取消") { d in
            // Add fade out animation
            UIView.animate(withDuration: 0.3, animations: {
                dialogViewController.view.alpha = 0.0
            }) { _ in
                d.hide()
            }
        }
        dialogViewController.addSubmitButton(withText: "确定") { d in
            // Add fade out animation
            UIView.animate(withDuration: 0.3, animations: {
                dialogViewController.view.alpha = 0.0
            }) { _ in
                d.hide()
                let password = dialogViewController.textFields![0].text!
                if let data: Data = NSData.init(contentsOf: url) as Data? {
                    if let certificate = ALTCertificate.init(p12Data: data, password: password) {
                        print(message: certificate.description)
                        let fileName = "\(certificate.name).p12"
                        let savePath = FileManager.default.certificatesDirectory.appendingPathComponent(fileName).path
                        FileManager.default.createFile(atPath: savePath, contents: certificate.p12Data(), attributes: nil)
                        if AppDefaults.shared.signingCertificateName == nil {
                            AppDefaults.shared.signingCertificate = certificate.p12Data()
                            AppDefaults.shared.signingCertificateName = certificate.name
                            AppDefaults.shared.signingCertificateSerialNumber = certificate.serialNumber
                            AppDefaults.shared.signingCertificatePassword = nil
                        }
                        kAlert("证书（\(certificate.name)）导入成功！")
                        completionHandler?()
                    } else {
                        kAlert("证书密码错误！")
                    }
                } else {
                    kAlert("证书已损坏或无效！")
                }
            }
        }
        
        // Configure the dialog view controller appearance
        dialogViewController.show()
        
        // Customizing dialog appearance
        dialogViewController.view.backgroundColor = UIColor.white
        dialogViewController.view.layer.cornerRadius = 8
        dialogViewController.view.layer.masksToBounds = true
        
        // Add fade in animation
        dialogViewController.view.alpha = 0.0
        UIView.animate(withDuration: 0.3) {
            dialogViewController.view.alpha = 1.0
        }
    }

    
    func trollStoreInstallApp(ipaURL: URL) {
        do {
            let appData = try Data.init(contentsOf: ipaURL, options: .mappedIfSafe)
            self.initWebServer()
            self.webServer?.addHandler(forMethod: "GET", path: "/app.ipa", request: GCDWebServerRequest.self, processBlock: { request -> GCDWebServerResponse? in
                print(message: request)
                return GCDWebServerDataResponse.init(data: appData, contentType: "application/octet-stream")
            })
            do {
                try webServer?.start(options: ["Port": 8881, "BonjourName": "GCD Web Server"])
                print("Visit \(String(describing: webServer!.serverURL)) in your web browser")
                Async.main(after: 0.55, {
                    if let trollURL = URL.init(string: "apple-magnifier://install?url=http://127.0.0.1:8881/app.ipa") {
                        print(message: trollURL)
                        UIApplication.shared.open(trollURL, options: [:]) { success in
                            if !success {
                                kAlert("打开 TrollStore 时发生了错误", message: "请确保已成功安装 TrollStore 并开启了 URL Scheme！否则请在设置中关闭使用 TrollStore 安装。")
                            }
                        }
                    }
                })
            } catch let error {
                Async.main(after: 0.55, {
                    kAlert("无法安装应用\n\(error.localizedDescription)")
                })
            }
        } catch let error {
            Async.main(after: 0.55, {
                kAlert("无法安装应用\n\(error.localizedDescription)")
            })
            
        }
    }
}

extension AppManager: GCDWebServerDelegate {

    func webServerDidStart(_ server: GCDWebServer) {
        print(message: "webServerDidStart")
    }
    
    func webServerDidConnect(_ server: GCDWebServer) {
        print(message: "webServerDidConnect")
        if self.installApp && !showingAlert {
            QMUITips.showLoading("正在安装应用，请勿关闭对话框或退到后台，以免安装失败！", in: kAPPKeyWindow!).whiteStyle()
        }
    }
    
    func webServerDidDisconnect(_ server: GCDWebServer) {
        print(message: "webServerDidDisconnect")
        if self.installApp {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                QMUITips.hideAllTips()
                kAlert("App已载入完成，请返回桌面查看安装进度", showCancel: true, preferredStyle: .actionSheet, callBack: {
                    UIApplication.shared.perform(#selector(URLSessionTask.suspend))
                })
            }
        }
    }
    
    func webServerDidStop(_ server: GCDWebServer) {
        print(message: "webServerDidStop")
    }
}
