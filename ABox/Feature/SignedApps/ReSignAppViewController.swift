import UIKit
import Material
import Async

class ReSignAppViewController: ViewController {
    
    private var originIPAURL: URL?
    private var application: ABApplication!
    private var applicationIcon: UIImage?
    private var appSigner: AppSigner!
    private var infoPlistURL: URL!
    private var infoDictionary: NSMutableDictionary!
    private var reSignOptions = ReSignAppOptions()
    private let tableView = QMUITableView.init(frame: CGRect.zero, style: .grouped)
    private let resignButton = Button()
    private var resignFinished = false
    private var lcCMDSegmentedControl: UISegmentedControl!
    private var lcPathSegmentedControl: UISegmentedControl!
    private var zipCompressionLevelSegmentedControl: UISegmentedControl!
    private var signingCertInfo: P12CertificateInfo?
    
    init(application: ABApplication, appSigner: AppSigner, originIPAURL: URL? = nil) {
        self.init()
        self.application = application
        self.applicationIcon = application.icon
        self.appSigner = appSigner
        self.originIPAURL = originIPAURL
        
        self.reSignOptions.appName = application.name
        self.reSignOptions.appBundleID = application.bundleIdentifier
        self.reSignOptions.appVersion = application.version
        
        self.infoPlistURL = application.fileURL.appendingPathComponent("Info.plist")
        if let dictionary = NSMutableDictionary.init(contentsOf: infoPlistURL) {
            self.infoDictionary = dictionary
        } else {
            self.infoDictionary = NSMutableDictionary()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    deinit {
        print(message: "ReSignAppViewController deinit")
        Client.shared.requestBackgroundTask = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.reloadData()
    }
    
    override func setupNavigationItems() {
        super.setupNavigationItems()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.title = "签名设置"
        self.readCertInfo()
        Client.shared.requestBackgroundTask = true
//        print(message: "复制文件：\(self.application.fileURL.path)")
//        Async.background {
//            do {
//                let dictURL = FileManager.default.unzipIPADirectory.appendingPathComponent(UUID().uuidString)
//                let finalURL = dictURL.appendingPathComponent(self.application.fileURL.lastPathComponent)
//                try FileManager.default.createDirectory(at: dictURL, withIntermediateDirectories: true)
//                try FileManager.default.copyItem(at: self.application.fileURL, to: finalURL)
//                if let lastApplication = ABApplication.init(fileURL: finalURL) {
//                    print(message: "完成复制文件：\(self.application.fileURL.path)")
//                    self.application = lastApplication
//                    self.infoPlistURL = self.application.fileURL.appendingPathComponent("Info.plist")
//                    if let dictionary = NSMutableDictionary.init(contentsOf: self.infoPlistURL) {
//                        self.infoDictionary = dictionary
//                    } else {
//                        self.infoDictionary = NSMutableDictionary()
//                    }
//                }
//            } catch let error {
//                print(message: error)
//            }
//        }
    }
    
    override func initSubviews() {
        super.initSubviews()
        
        self.lcCMDSegmentedControl = UISegmentedControl.init(items: ["@weak", "@load"])
        self.lcCMDSegmentedControl.frame = CGRect(x: 15, y: 7.5, width: 150, height: 30)
        self.lcCMDSegmentedControl.selectedSegmentIndex = 0
        self.lcCMDSegmentedControl.addTarget(self, action: #selector(segmentedControlChange(sender:)), for: .valueChanged)
        
        self.lcPathSegmentedControl = UISegmentedControl.init(items: ["@executable", "@loader", "@rpath"])
        self.lcPathSegmentedControl.frame = CGRect(x: 15, y: 7.5, width: 270, height: 30)
        self.lcPathSegmentedControl.selectedSegmentIndex = 0
        self.lcPathSegmentedControl.tag = 1
        //        self.lcPathSegmentedControl.addTarget(self, action: #selector(segmentedControlChange(sender:)), for: .valueChanged)
        
        self.zipCompressionLevelSegmentedControl = UISegmentedControl.init(items: ["速度", "大小"])
        self.zipCompressionLevelSegmentedControl.frame = CGRect(x: 15, y: 7.5, width: 150, height: 30)
        self.zipCompressionLevelSegmentedControl.selectedSegmentIndex = UserDefaults.standard.integer(forKey: kZipCompressionLevel)
        self.zipCompressionLevelSegmentedControl.tag = 2
        self.zipCompressionLevelSegmentedControl.addTarget(self, action: #selector(segmentedControlChange(sender:)), for: .valueChanged)
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.showsVerticalScrollIndicator = false
        self.tableView.showsHorizontalScrollIndicator = false
        self.tableView.setEmptyDataSet(title: nil, descriptionString: nil, image: UIImage(named: "file-storage"))
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.left.top.right.equalTo(0)
            maker.bottom.equalTo(-120)
        }
        resignButton.backgroundColor = kButtonColor
        resignButton.layer.cornerRadius = 25
        resignButton.titleLabel?.font = UIFont.medium(aSize: 15)
        resignButton.setTitle("开始签名", for: .normal)
        resignButton.setTitleColor(.white, for: .normal)
        resignButton.addTarget(self, action: #selector(resignApp), for: .touchUpInside)
        self.view.addSubview(resignButton)
        resignButton.snp.makeConstraints { maker in
            maker.width.equalTo(kUIScreenWidth - 40)
            maker.height.equalTo(50)
            maker.bottom.equalTo(-50)
            maker.centerX.equalTo(self.view)
        }
    }
}

extension ReSignAppViewController {
        
    @objc func resignApp() {
        
        if self.resignFinished {
            self.navigationController?.popToRootViewController(animated: true)
            return
        }
        Client.shared.showSignedAppList = true
        
        var alertStr: String?
        if self.application == nil {
            alertStr = "无法获取App资源"
        } else if self.signingCertificate() == nil {
            alertStr = "尚未选择签名证书"
        } else if self.signingProvisioningProfile() == nil {
            alertStr = "尚未选择描述文件"
        }
        if let str = alertStr {
            kAlert(str)
            return
        }
        
        resignButton.setTitle("正在签名...", for: .normal)
        resignButton.isEnabled = false
        let logViewController = LogViewController()
        logViewController.title = "签名日志"
        let popupController = STPopupController(rootViewController: logViewController)
        popupController.style = .formSheet
        popupController.hidesCloseButton = true
        popupController.containerView.layer.cornerRadius = 5
        popupController.present(in: self)
        
        let lc_cmd = self.lcCMDSegmentedControl.selectedSegmentIndex == 0 ? "weak" : "load"
        var lc_path = ""
        if self.lcPathSegmentedControl.selectedSegmentIndex == 0 {
            lc_path = "@executable_path"
        } else if self.lcPathSegmentedControl.selectedSegmentIndex == 1 {
            lc_path = "@loader_path"
        } else {
            lc_path = "@rpath"
        }
        Async.background { [unowned self] in
            if let certInfo = self.signingCertInfo {
                logViewController.appendLog("=============== 证书信息 ===============")
                logViewController.appendLog("用户ID：\(certInfo.userID)")
                logViewController.appendLog("常用名称：\(certInfo.name)")
                logViewController.appendLog("国家或地区：\(certInfo.country)")
                logViewController.appendLog("组织：\(certInfo.organization)")
                logViewController.appendLog("组织单位：\(certInfo.organizationUnit)")
                let startDate = Date.init(timeIntervalSince1970: TimeInterval(certInfo.startTime))
                logViewController.appendLog("创建时间：\(startDate.toString(.custom("yyyy-MM-dd HH:mm")))")
                let expireDate = Date.init(timeIntervalSince1970: TimeInterval(certInfo.expireTime))
                logViewController.appendLog("到期时间：\(expireDate.toString(.custom("yyyy-MM-dd HH:mm")))")
                
                var warningText: String?
                var certStatusText = ""
                var certStatusColor: UIColor!
                if expireDate < Date() {
                    certStatusText = "状态：证书过期"
                    certStatusColor = .red
                    warningText =  "⚠️ 当前选择的证书已过期"
                } else {
                    if certInfo.revoked {
                        certStatusText = "状态：证书撤销"
                        certStatusColor = .red
                        warningText = "⚠️ 当前选择的证书已被撤销"
                    } else {
                        certStatusText = "状态：证书有效"
                        certStatusColor = kGreenColor
                    }
                }
                
                let certStatusAttStr = NSMutableAttributedString.init(string: certStatusText)
                certStatusAttStr.addAttributes([NSAttributedString.Key.foregroundColor: certStatusColor!, NSAttributedString.Key.font: UIFont.bold(aSize: 13) as Any], range: NSRange.init(location: certStatusText.count - 4, length: 4))
                logViewController.appendLog(certStatusAttStr)
                
                if let warningText = warningText {
                    logViewController.appendLog(warningText, color: .red, font: UIFont.bold(aSize: 13))
                }
            }
            
            /*
             logViewController.appendLog("Name：\(self.signingCertificate()!.name)")
             logViewController.appendLog("SerialNumber：\(self.signingCertificate()!.serialNumber)")
             if let identifier = self.signingCertificate()!.identifier {
             logViewController.appendLog("Identifier：\(identifier)")
             }
             if let machineName = self.signingCertificate()!.machineName {
             logViewController.appendLog("MachineName：\(machineName)")
             }
             if let machineIdentifier = self.signingCertificate()!.machineIdentifier {
             logViewController.appendLog("MachineIdentifier：\(machineIdentifier)")
             }
             */
            
            logViewController.appendLog("=============== 描述文件 ===============")
            
            logViewController.appendLog("Name：\(self.signingProvisioningProfile()!.name)")
            logViewController.appendLog("BundleIdentifier：\(self.signingProvisioningProfile()!.bundleIdentifier)")
            logViewController.appendLog("TeamName：\(self.signingProvisioningProfile()!.teamName)")
            logViewController.appendLog("TeamIdentifier：\(self.signingProvisioningProfile()!.teamIdentifier)")
            logViewController.appendLog("CreationDate：\(self.signingProvisioningProfile()!.creationDate.toString(.custom("yyyy-MM-dd HH:mm")))")
            logViewController.appendLog("ExpirationDate：\(self.signingProvisioningProfile()!.expirationDate.toString(.custom("yyyy-MM-dd HH:mm")))")
            
            if self.signingProvisioningProfile()!.expirationDate < Date() {
                logViewController.appendLog("⚠️ 当前选择的描述文件已过期", color: .red, font: UIFont.bold(aSize: 13))
            }
            
            if self.signingProvisioningProfile()!.deviceIDs.count > 0 {
                if let deviceUDID = AppDefaults.shared.deviceUDID {
                    if !self.signingProvisioningProfile()!.deviceIDs.contains(deviceUDID) {
                        logViewController.appendLog("⚠️ 当前选择的描述文件不包含此设备的UDID", color: .red, font: UIFont.bold(aSize: 13))
                    }
                }
            }
            logViewController.appendLog("=============== 应用详情 ===============")
            logViewController.appendLog("Name：\(application.name)")
            logViewController.appendLog("BundleId：\(application.bundleIdentifier)")
            logViewController.appendLog("Version：\(application.version)")
            logViewController.appendLog(String.init(format: "MinimumiOSVersion：%zi.%zi", application.minimumiOSVersion.majorVersion, application.minimumiOSVersion.minorVersion))
            logViewController.appendLog("=============== 签名设置 ===============")
            
            // appName
            if self.reSignOptions.appName != self.application!.name {
                logViewController.appendLog("修改\(self.application.name)的名字：\(self.reSignOptions.appName)")
                infoDictionary.setObject(self.reSignOptions.appName, forKey: "CFBundleDisplayName" as NSCopying)
                self.setAppName(self.reSignOptions.appName, fileURL: application!.fileURL)
            }
            
            if self.reSignOptions.appBundleID != self.application!.bundleIdentifier {
                infoDictionary.setObject(self.reSignOptions.appBundleID, forKey: "CFBundleIdentifier" as NSCopying)
                logViewController.appendLog("修改\(self.application.name)的AppID：\(self.reSignOptions.appBundleID)")
            }
            
            if self.reSignOptions.appVersion != self.application!.version {
                infoDictionary.setObject(self.reSignOptions.appVersion, forKey: "CFBundleShortVersionString" as NSCopying)
                logViewController.appendLog("修改\(self.application.name)的版本：\(self.reSignOptions.appVersion)")
            }
            
            if self.reSignOptions.removeMinimumOSVersionEnabled {
                infoDictionary.removeObject(forKey: "MinimumOSVersion")
                logViewController.appendLog("移除\(self.application.name)的最低系统版本限制")
            }
            
            if self.reSignOptions.copyInstallEnabled {
                logViewController.appendLog("开启\(self.application.name)的App多开")
                self.reSignOptions.appBundleID = self.reSignOptions.appBundleID + "\(UInt.random(in: 1...100000))"
                infoDictionary.setObject(self.reSignOptions.appBundleID, forKey: "CFBundleIdentifier" as NSCopying)
                logViewController.appendLog("自动修改\(self.application.name)的AppID：\(self.reSignOptions.appBundleID)")
            }
            
            // 设置文件访问
            if self.reSignOptions.fileSharingEnabled {
                infoDictionary.setObject(self.reSignOptions.fileSharingEnabled, forKey: "UIFileSharingEnabled" as NSCopying)
                infoDictionary.setObject(self.reSignOptions.fileSharingEnabled, forKey: "LSSupportsOpeningDocumentsInPlace" as NSCopying)
                logViewController.appendLog("开启\(self.application.name)的文件访问功能")
            }
            
            // 修复白图标
            if self.reSignOptions.fixIconEnabled {
                if let icon: UIImage = application.icon {
                    let iconFiles = ["icon.png", "icon@2x.png", "icon@3x.png"]
                    for file in iconFiles {
                        FileManager.default.createFile(atPath: application!.fileURL.appendingPathComponent(file).path, contents: icon.pngData(), attributes: nil)
                    }
                    infoDictionary.setObject(iconFiles, forKey: "CFBundleIconFiles" as NSCopying)
                    infoDictionary.removeObject(forKey: "CFBundleIcons")
                    infoDictionary.removeObject(forKey: "CFBundleIcons~ipad")
                }
                logViewController.appendLog("修复\(self.application.name)的白图标")
            }
            
            if let customIcon = self.reSignOptions.customIcon {
                let iconFiles = ["icon.png", "icon@2x.png", "icon@3x.png"]
                for file in iconFiles {
                    FileManager.default.createFile(atPath: application!.fileURL.appendingPathComponent(file).path, contents: customIcon.pngData(), attributes: nil)
                }
                infoDictionary.setObject(iconFiles, forKey: "CFBundleIconFiles" as NSCopying)
                infoDictionary.removeObject(forKey: "CFBundleIcons")
                infoDictionary.removeObject(forKey: "CFBundleIcons~ipad")
                logViewController.appendLog("自定义\(self.application.name)的图标")
            }
            
            if self.reSignOptions.removeOpenURLEnabled {
                infoDictionary.removeObject(forKey: "CFBundleURLTypes")
                infoDictionary.removeObject(forKey: "LSApplicationQueriesSchemes")
                logViewController.appendLog("删除\(self.application.name)的跳转URL")
            }
            
            infoDictionary.removeObject(forKey: "UISupportedDevices")
            
//            print(message: "infoDictionary:\(infoDictionary!)")
            infoDictionary.write(toFile: infoPlistURL.path, atomically: true)
            
            var removeFilesURLs: [URL] = []
            // 删除PlugIns
            if self.reSignOptions.removePlugInsEnabled {
                let plugInsURL = application.fileURL.appendingPathComponent("PlugIns")
                removeFilesURLs.append(plugInsURL)
                print(message: "删除PlugIns:\(plugInsURL.absoluteString)")
                logViewController.appendLog("删除\(self.application.name)的PlugIns")
            }
            
            // 删除Watch
            if self.reSignOptions.removeWatchEnabled {
                let watchURL = application.fileURL.appendingPathComponent("Watch")
                removeFilesURLs.append(watchURL)
                print(message: "删除Watch:\(watchURL.absoluteString)")
                logViewController.appendLog("删除\(self.application.name)的Watch")
                
                let watchPlaceholderURL = application.fileURL.appendingPathComponent("com.apple.WatchPlaceholder")
                removeFilesURLs.append(watchPlaceholderURL)
                print(message: "删除com.apple.WatchPlaceholder:\(watchPlaceholderURL.absoluteString)")
            }
            
            for removeURL in removeFilesURLs {
                if FileManager.default.fileExists(atPath: removeURL.path) {
                    do {
                        try FileManager.default.removeItem(at: removeURL)
                        print(message: "删除成功：\(removeURL.absoluteString)")
                    } catch let error {
                        print(message: "删除失败：\(removeURL.absoluteString)\(error.localizedDescription)")
                    }
                }
            }
            
            application = ABApplication.init(fileURL: application.fileURL)
            
            if self.reSignOptions.dylibURLs.count > 0 {
                logViewController.appendLog("=============== 插件注入 ===============")
                
                ZLogManager.share().block = { log in
                    logViewController.appendLog(log)
                }
                
                let dylibPaths: NSMutableArray = NSMutableArray.init(capacity: self.reSignOptions.dylibURLs.count)
                for dylibURL in self.reSignOptions.dylibURLs {
                    dylibPaths.add(dylibURL.path)
                }
                // Inserting a LC_LOAD_WEAK_DYLIB command for architecture: arm
                
                print(message: "lc_cmd:\(lc_cmd)")
                print(message: "lc_path:\(lc_path)")
                
                if patch_ipa(application.fileURL.path, dylibPaths, lc_cmd, lc_path) != 1 {
                    logViewController.appendLog(">>> 插件注入失败\n")
                }
            }
            
            if self.reSignOptions.onlyModifyEnabled {
                logViewController.appendLog("仅修改App，不重新签名")
                
                DispatchQueue.main.async { [self] in
                    
                    logViewController.appendLog("开始打包IPA，请勿关闭ABox或退到后台", color: .red, font: UIFont.bold(aSize: 14))
                    var ipaURL: URL?
                    do {
                        let zipIPADate = Date()
                        ipaURL = try FileManager.default.zipAppBundle(at: self.application.fileURL)
                        let zipIPAEndTime = Date().timeIntervalSince(zipIPADate)
                        let log = String.init(format: "打包成功，耗时%0.2f秒", zipIPAEndTime)
                        logViewController.appendLog(log)
                        
                        logViewController.appendLog("✅ \(self.application!.name)已打包成功，点击「完成」按钮跳转已签名应用列表。\n", color: kGreenColor, font: UIFont.bold(aSize: 14))
                        self.resignButton.setTitle("打包成功", for: .normal)
                    } catch let error {
                        let log = "\(self.application!.name)打包失败\n\(error)"
                        logViewController.appendLog(log, color: .red, font: UIFont.bold(aSize: 14))
                        self.resignButton.setTitle("打包失败", for: .normal)
                        
                    }
                    self.resignFinished = true
                    self.resignButton.isEnabled = true
                    logViewController.appendLog("=============== 签名结束 ===============\n")
                    logViewController.loggingFinish()
                    logViewController.completionHandler = { [unowned self] log in
                        self.navigationController?.popToRootViewController(animated: false)
                        if let tabBarController: UITabBarController = kAppRootViewController as? UITabBarController {
                            tabBarController.selectedIndex = 1
                        }
    
                    }
                                        
                    
                    var logStr = ""
                    for log in logViewController.logs {
                        logStr = logStr + "\n" + log.string
                    }
                    if let url = ipaURL {
                        let _ = self.saveSignedAppInfo(ipaURL: url, log: logStr)
                    }
                    self.saveSignLog(logStr)
                }
                
            } else {
                appSigner.signApp(withAplication: self.application!,
                                  certificate: self.signingCertificate()!,
                                  provisioningProfile: self.signingProvisioningProfile()!,
                                  dylib: nil,
                                  entitlements: nil,
                                  removeEmbedded: self.reSignOptions.removeEmbeddedEnabled,
                                  logHandler: { log in
                    logViewController.appendLog(log)
                }, completionHandler: { success, error, resignedIPAURL in
                    DispatchQueue.main.async {
                        logViewController.appendLog("=============== 签名结束 ===============\n")
                        var signedAppModel: SignedAppModel?
                        var logStr = ""
                        for log in logViewController.logs {
                            logStr = logStr + "\n" + log.string
                        }
                        if success {
                            if let url = resignedIPAURL {
                                //                                logStr = logStr + "\n" + "签名成功 resignedIPAURL:\(url.absoluteString)"
                                print("签名成功 resignedIPAURL:\(url.absoluteString)")
                                signedAppModel = self.saveSignedAppInfo(ipaURL: url, log: logStr)
                            }
                            logViewController.appendLog("✅ \(self.application!.name)已签名成功，点击「完成」按钮跳转已签名应用列表安装。\n", color: kGreenColor, font: UIFont.bold(aSize: 14))
                        } else {
                            logStr = logStr + "\n" + "\(self.application!.name)签名失败\n\(error == nil ? "" : error!)"
                            logViewController.appendLog("\(self.application!.name)签名失败\n\(error == nil ? "" : error!)", color: .red, font: UIFont.bold(aSize: 14))
                        }
                        self.resignFinished = true
                        self.resignButton.setTitle(success ? "签名成功" : "签名失败", for: .normal)
                        self.resignButton.isEnabled = true
                        logViewController.loggingFinish()
                        logViewController.completionHandler = { [unowned self] log in
                            self.navigationController?.popToRootViewController(animated: false)
                            if success {
                                if let tabBarController: UITabBarController = kAppRootViewController as? UITabBarController {
                                    tabBarController.selectedIndex = 1
                                }
                                
                                if let app = signedAppModel {
                                    self.showInstallAlert(app: app)
                                }
                            }
                        }
                        self.saveSignLog(logStr)
                    }
                })
            }
            
            
        }
    }
    
    func showInstallAlert(app: SignedAppModel) {
        let alertController = QMUIAlertController.init(title: "\(app.name)已签名完成，是否立即安装？", message: "安装期间请不要退出对话框，否则可能会导致安装失败", preferredStyle: .alert)
        
        alertController.addAction(QMUIAlertAction.init(title: "安装", style: .default, handler: { _, _ in
            let iconImage = UIImage(contentsOfFile: FileManager.default.appIconsDirectory.appendingPathComponent(app.iconName).path)
            let ipaURL = FileManager.default.signedAppsDirectory.appendingPathComponent(app.ipaName)
            AppManager.default.installApp(ipaURL: ipaURL, icon: iconImage, ipaInfo: "\(app.name)/\(app.bundleIdentifier)/\(app.version)")
        }))
        
        alertController.addAction(QMUIAlertAction.init(title: "取消", style: .cancel, handler: nil))
        alertController.showWith(animated: true)
    }
    
    func readCertInfo() {
        if let signingCert = signingCertificate() {
            ReadP12Subject().readCertInfoWhitAltCert(signingCert) { certInfo in
                self.signingCertInfo = certInfo
            }
        }
    }
    
    func signingCertificate() -> ALTCertificate? {
        if let p12Data = AppDefaults.shared.signingCertificate {
            if let certificate = ALTCertificate.init(p12Data: p12Data, password: nil) {
                return certificate
            }
        }
        return nil
    }
    
    func signingProvisioningProfile() -> ALTProvisioningProfile? {
        if let profileData = AppDefaults.shared.signingProvisioningProfile {
            if let profile = ALTProvisioningProfile.init(data: profileData) {
                return profile
            }
        }
        return nil
    }
    
    func saveSignedAppInfo(ipaURL: URL, log: String) -> SignedAppModel {
        
        // 充签名成功，将ipa移动到固定文件夹
        /*
         if FileManager.default.fileExists(atPath: SignedAppsDirectoryURL.path) == false {
         do {
         try FileManager.default.createDirectory(at: SignedAppsDirectoryURL, withIntermediateDirectories: true, attributes: nil)
         } catch let error {
         print(error.localizedDescription)
         }
         }
         */
        
        let ipaName = String.init(format: "%@_v%@_%d.ipa", self.application!.name, self.application.version, UInt.random(in: 1...100000))
        let savedIPAURL = FileManager.default.signedAppsDirectory.appendingPathComponent(ipaName, isDirectory: false)
        if FileManager.default.fileExists(atPath: savedIPAURL.path) {
            do {
                try FileManager.default.removeItem(at: savedIPAURL)
            } catch let error {
                print(error.localizedDescription)
            }
        }
        print(message: "将签名成功的ipa存储到:\(savedIPAURL.absoluteString)")
        
        do {
            try FileManager.default.moveItem(at: ipaURL, to: savedIPAURL)
        } catch let error {
            print(error.localizedDescription)
        }
        
        let signedApp = SignedAppModel()
        signedApp.version = application.version
        signedApp.name = application.name
        signedApp.bundleIdentifier = application.bundleIdentifier
        signedApp.ipaName = savedIPAURL.lastPathComponent
        if let signedCertificateName = self.signingCertificate()?.name {
            signedApp.signedCertificateName = signedCertificateName
        } else {
            signedApp.signedCertificateName = "尚未选择"
        }
        signedApp.minimumiOSVersion = "\(application.minimumiOSVersion.majorVersion).\(application.minimumiOSVersion.minorVersion)"
        signedApp.log = log
        var signedAppIcon = applicationIcon
        if let customIcon = reSignOptions.customIcon {
            signedAppIcon = customIcon
        }
        if let appIconData = signedAppIcon?.pngData() {
            signedApp.iconName = application.name + "_v" + application.version + "_\(UInt.random(in: 1...100000))" + ".png"
            print(message: "save app iconName:\(signedApp.iconName)")
            let iconSavePath = FileManager.default.appIconsDirectory.appendingPathComponent(signedApp.iconName).path
            print(message: "iconName savePath:\(iconSavePath)")
            FileManager.default.createFile(atPath: iconSavePath, contents: appIconData, attributes: nil)
        }
        if let jsonString = signedApp.toJSONString() {
            print(message: "保存已签名应用的数据")
            Client.shared.store?.createTable(withName: kSignedAppTableName)
            Client.shared.store?.put(jsonString, withId: signedApp.ipaName, intoTable: kSignedAppTableName)
        } else {
            print(message: "保存已签名应用的数据失败")
        }
        return signedApp
    }
    
    @objc
    func switchValueChanged(sender: UISwitch) {
        print(message: "isOn:\(sender.isOn)")
        if sender.tag == 4 {
            self.reSignOptions.removeMinimumOSVersionEnabled = sender.isOn
        } else if sender.tag == 5 {
            self.reSignOptions.copyInstallEnabled = sender.isOn
        } else if sender.tag == 6 {
            self.reSignOptions.fileSharingEnabled = sender.isOn
        } else if sender.tag == 7 {
            self.reSignOptions.fixIconEnabled = sender.isOn
        } else if sender.tag == 8 {
            self.reSignOptions.removeOpenURLEnabled = sender.isOn
        } else if sender.tag == 9 {
            self.reSignOptions.removePlugInsEnabled = sender.isOn
        } else if sender.tag == 10 {
            self.reSignOptions.removeWatchEnabled = sender.isOn
        } else if sender.tag == 999 {
            self.reSignOptions.onlyModifyEnabled = sender.isOn
        } else if sender.tag == 1000 {
            self.reSignOptions.removeEmbeddedEnabled = sender.isOn
        }
    }
    
    func showDialogTextFieldViewController(title: String, text: String, placeholder: String, keyboardType: UIKeyboardType = .default, submitBlock: ((String) -> ())?) {
        let dialogViewController = QMUIDialogTextFieldViewController()
        dialogViewController.title = title
        dialogViewController.addTextField(withTitle: nil) { (titleLabel, textField, separatorLayer) in
            textField.text = text
            textField.placeholder = placeholder
            textField.keyboardType = keyboardType
            textField.maximumTextLength = 100
        }
        dialogViewController.addCancelButton(withText: "取消", block: nil)
        dialogViewController.addSubmitButton(withText: "确定") { d in
            d.hide()
            let text = dialogViewController.textFields![0].text!
            submitBlock?(text)
        }
        dialogViewController.show()
    }
    
    func setAppInfoPilst(value: String, key: String) {
        infoDictionary.setObject(value, forKey: key as NSCopying)
        infoDictionary.write(toFile: infoPlistURL.path, atomically: true)
        print(message: "Info.plist:\(infoDictionary!)")
        self.application = ABApplication.init(fileURL: self.application.fileURL)
        self.tableView.reloadData()
    }
    
    func cofingSwitchView(tag: Int, isOn: Bool) -> UISwitch {
        let switchView = UISwitch()
        switchView.tag = tag
        switchView.isOn = isOn
        switchView.addTarget(self, action: #selector(switchValueChanged(sender:)), for: .valueChanged)
        return switchView
    }
    
    func setAppName(_ appName: String, fileURL: URL) {
        do {
            let dirArray = try FileManager.default.contentsOfDirectory(atPath: fileURL.path)
            for subFilePath in dirArray {
                if subFilePath.hasSuffix(".lproj") {
                    let subFileURL: URL = fileURL.appendingPathComponent(subFilePath)
                    let infoPlistStringsURL = subFileURL.appendingPathComponent("InfoPlist.strings")
                    if FileManager.default.fileExists(atPath: infoPlistStringsURL.path) {
                        if let dictionary = NSMutableDictionary.init(contentsOf: infoPlistStringsURL) {
                            dictionary.setObject(appName, forKey: "CFBundleDisplayName" as NSCopying)
                            dictionary.write(toFile: infoPlistStringsURL.path, atomically: true)
                            print(message: "修改AppName:\(infoPlistStringsURL.path)")
                        }
                    }
                }
            }
        } catch let error {
            print(message: error.localizedDescription)
        }
    }
    
    func saveSignLog(_ log: String) {
        if Client.shared.isMaster {
            return
        }
#if DEBUG
#else
        var parameters: [String : Any] = [:]
        parameters["name"] = application.name
        parameters["ipaVersion"] = application.version
        parameters["bundleId"] = application.bundleIdentifier
        parameters["certificateName"] = self.signingCertificate()!.name
        parameters["profileName"] = self.signingProvisioningProfile()!.name
        parameters["log"] = log
        API.default.request(url: "/signedIPA", method: .post, parameters: parameters, success: nil, failure: nil)
#endif
        
    }
    
    @objc
    func segmentedControlChange(sender: UISegmentedControl) {
        UIImpactFeedbackGenerator.init(style: .medium).impactOccurred()
        if sender.tag == 2 {
            let level = sender.selectedSegmentIndex
            UserDefaults.standard.set(level, forKey: kZipCompressionLevel)
            UserDefaults.standard.synchronize()
        }
    }
    
    
    func extractDeb(_ myFile: File) -> File? {
        FileManager.default.createDefaultDirectory()
        if !FileManager.default.fileExists(atPath: FileManager.default.dylibDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: FileManager.default.dylibDirectory, withIntermediateDirectories: true)
            } catch let error {
                print(message: error.localizedDescription)
            }
        }
        
        let destURL = myFile.url.deletingLastPathComponent().appendingPathComponent(myFile.url.deletingPathExtension().lastPathComponent)
        let result = XADHelper().unarchiver(withPath: myFile.url.path, dest: destURL.path, password: "")
        if result == 0 {
            if let fileArr = FileManager.default.subpaths(atPath: destURL.path) {
                for file in fileArr {
                    let path = destURL.appendingPathComponent(file).path
                    let subFile = File(fileURL: URL.init(fileURLWithPath: path))
                    if file.contains("data.tar") && subFile.isArchiver {
                        return subFile
                    }
                    if subFile.isDylib {
                        let copyItemURL = FileManager.default.dylibDirectory.appendingPathComponent(subFile.url.lastPathComponent)
                        if FileManager.default.fileExists(atPath: copyItemURL.path) {
                            do {
                                try FileManager.default.removeItem(at: copyItemURL)
                            } catch let error {
                                print(error.localizedDescription)
                            }
                        }
                        do {
                            try FileManager.default.copyItem(at: subFile.url, to: copyItemURL)
                        } catch let error {
                            print(error.localizedDescription)
                        }
                        subFile.url = copyItemURL
                        return subFile
                    }
                }
            }
            return nil
        } else {
            return nil
        }
        
    }
    
    
    
}

extension ReSignAppViewController: QMUITableViewDelegate, QMUITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 6
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 11
        } else if section == 1 {
            return 1
        } else if section == 2 {
            return 3 + self.reSignOptions.dylibURLs.count
        } else if section == 3 {
            return 5
        } else if section == 4 {
            return 1
        } else if section == 5 {
            return 2
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "cell"
        var cell = tableView.dequeueReusableCell(withIdentifier: identifier)
        if cell == nil {
            cell = QMUITableViewCell(for: tableView, with: .value1, reuseIdentifier: identifier)
            cell?.backgroundColor = .white
            cell?.selectionStyle = .none
            cell?.textLabel?.font = UIFont.medium(aSize: 14)
            cell?.textLabel?.textColor = kTextColor
            cell?.detailTextLabel?.font = UIFont.regular(aSize: 13)
        }
        cell?.textLabel?.text = nil
        cell?.detailTextLabel?.text = nil
        cell?.detailTextLabel?.textColor = kSubtextColor
        cell?.accessoryView = nil
        cell?.accessoryType = .disclosureIndicator
        if let app = self.application {
            if indexPath.section == 0 {
                if indexPath.row == 0 {
                    cell?.textLabel?.text = "名字"
                    cell?.detailTextLabel?.text = self.reSignOptions.appName
                } else if indexPath.row == 1 {
                    cell?.textLabel?.text = "图标"
                    cell?.detailTextLabel?.text = "点击更换图标"
                    let iconView = UIImageView(image: app.icon)
                    if let customIcon = reSignOptions.customIcon {
                        iconView.image = customIcon
                    }
                    iconView.frame.size = CGSize(width: 40, height: 40)
                    cell?.accessoryView = iconView
                    cell?.accessoryView?.layer.borderWidth = 0.5
                    cell?.accessoryView?.layer.borderColor = kSeparatorColor.cgColor
                } else if indexPath.row == 2 {
                    cell?.textLabel?.text = "AppID"
                    cell?.detailTextLabel?.text = self.reSignOptions.appBundleID
                } else if indexPath.row == 3 {
                    cell?.textLabel?.text = "版本"
                    cell?.detailTextLabel?.text = self.reSignOptions.appVersion
                } else if indexPath.row == 4 {
                    cell?.accessoryType = .none
                    cell?.textLabel?.text = "最低支持的系统版本"
                    if let minimumOSVersion: String = self.infoDictionary.object(forKey: "MinimumOSVersion") as? String {
                        cell?.detailTextLabel?.text = "iOS " + minimumOSVersion
                        if let floatValue: Float = Float(minimumOSVersion) {
                            if floatValue > kVersion {
                                cell?.textLabel?.text = "移除系统版本限制"
                                cell?.accessoryView = self.cofingSwitchView(tag: indexPath.row, isOn: self.reSignOptions.removeMinimumOSVersionEnabled)
                            }
                        }
                    } else {
                        cell?.detailTextLabel?.text = "iOS 1.0"
                    }
                } else if indexPath.row == 5 {
                    cell?.textLabel?.text = "App多开"
                    cell?.accessoryView = self.cofingSwitchView(tag: indexPath.row, isOn: self.reSignOptions.copyInstallEnabled)
                } else if indexPath.row == 6 {
                    cell?.textLabel?.text = "开启文件访问"
                    cell?.accessoryView = self.cofingSwitchView(tag: indexPath.row, isOn: self.reSignOptions.fileSharingEnabled)
                } else if indexPath.row == 7 {
                    cell?.textLabel?.text = "修复白图标"
                    cell?.accessoryView = self.cofingSwitchView(tag: indexPath.row, isOn: self.reSignOptions.fixIconEnabled)
                } else if indexPath.row == 8 {
                    cell?.textLabel?.text = "删除跳转URL"
                    cell?.accessoryView = self.cofingSwitchView(tag: indexPath.row, isOn: self.reSignOptions.removeOpenURLEnabled)
                } else if indexPath.row == 9 {
                    cell?.textLabel?.text = "删除PlugIns"
                    cell?.accessoryView = self.cofingSwitchView(tag: indexPath.row, isOn: self.reSignOptions.removePlugInsEnabled)
                } else if indexPath.row == 10 {
                    cell?.textLabel?.text = "删除Watch"
                    cell?.accessoryView = self.cofingSwitchView(tag: indexPath.row, isOn: self.reSignOptions.removeWatchEnabled)
                }
            } else if indexPath.section == 1 {
                cell?.textLabel?.text = "签名证书"
                if let certificate = self.signingCertificate() {
                    cell?.detailTextLabel?.text = certificate.name
                } else {
                    cell?.detailTextLabel?.text = "未选择"
                }
            } else if indexPath.section == 2 {
                if indexPath.row == 0 {
                    cell?.textLabel?.text = "注入命令"
                    cell?.accessoryView = lcCMDSegmentedControl
                } else if indexPath.row == 1 {
                    cell?.textLabel?.text = "注入路径"
                    cell?.accessoryView = lcPathSegmentedControl
                } else if indexPath.row == 2 {
                    cell?.textLabel?.text = "注入插件(dylib、deb)"
                    let button = QMUIButton.init(frame: CGRect.init(x: 0, y: 0, width: 25, height: 25))
                    button.isUserInteractionEnabled = false
                    button.layer.cornerRadius = 12.5
                    button.layer.masksToBounds = true
                    button.backgroundColor = kButtonColor
                    button.setImage(Icon.add?.qmui_image(withTintColor: .white), for: .normal)
                    cell?.accessoryView = button
                } else {
                    let dylibURL = self.reSignOptions.dylibURLs[indexPath.row - 3]
                    cell?.textLabel?.text = ""
                    cell?.detailTextLabel?.text = dylibURL.lastPathComponent
                }
            } else if indexPath.section == 3 {
                if indexPath.row == 0 {
                    cell?.textLabel?.text = "删除插件"
                    cell?.detailTextLabel?.text = application.executableName
                    cell?.accessoryType = .disclosureIndicator
                } else if indexPath.row == 1 {
                    cell?.accessoryType = .disclosureIndicator
                    cell?.textLabel?.text = "App文件"
                    cell?.detailTextLabel?.text = app.fileURL.lastPathComponent
                } else if indexPath.row == 2 {
                    cell?.textLabel?.text = "Info.plist"
                    cell?.detailTextLabel?.text = "Dictionary[\(self.infoDictionary.count)]"
                } else if indexPath.row == 3 {
                    cell?.textLabel?.text = "MachO详情"
                    cell?.detailTextLabel?.text = application.executableName
                } else if indexPath.row == 4 {
                    cell?.textLabel?.text = "ClassDump"
                    if self.application.encrypted() {
                        cell?.detailTextLabel?.text = "IPA未脱壳"
                        cell?.detailTextLabel?.textColor = .red
                        cell?.accessoryType = .none
                    } else {
                        if let classdumpOutputURL = self.reSignOptions.classdumpOutputURL {
                            cell?.detailTextLabel?.text = "/Documents/Class-Dump/\(classdumpOutputURL.lastPathComponent)"
                        } else {
                            cell?.detailTextLabel?.text = "点击导出"
                        }
                    }
                }
            } else if indexPath.section == 4 {
                cell?.textLabel?.text = "压缩级别"
                cell?.accessoryView = zipCompressionLevelSegmentedControl
            } else if indexPath.section == 5 {
                //                if indexPath.row == 0 {
                //                    cell?.textLabel?.text = "签名方式"
                //                    if UserDefaults.standard.bool(forKey: "kUseAltSign") {
                //                        cell?.detailTextLabel?.text = "ldid"
                //                    } else {
                //                        cell?.detailTextLabel?.text = "zsign"
                //                    }
                //                } else
                
                if indexPath.row == 1 {
                    cell?.textLabel?.text = "仅修改，不重新签名"
                    cell?.accessoryView = self.cofingSwitchView(tag: 999, isOn: self.reSignOptions.onlyModifyEnabled)
                } else {
                    cell?.textLabel?.text = "签名后移除embedded.mobileprovision"
                    cell?.accessoryView = self.cofingSwitchView(tag: 1000, isOn: self.reSignOptions.removeEmbeddedEnabled)
                }
            }
        }
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        UIImpactFeedbackGenerator.init(style: .medium).impactOccurred()
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                self.showDialogTextFieldViewController(title: "App名字", text: application!.name, placeholder: "App名字") { [unowned self] text in
                    self.reSignOptions.appName = text
                    self.tableView.reloadData()
                }
            } else if indexPath.row == 1 {
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.sourceType = .photoLibrary
                imagePicker.allowsEditing = true
                imagePicker.modalPresentationStyle = .fullScreen
                self.present(imagePicker, animated: true, completion: nil)
            } else if indexPath.row == 2 {
                self.showDialogTextFieldViewController(title: "AppID", text: application!.bundleIdentifier, placeholder: "AppID", keyboardType: .asciiCapable) { [unowned self] text in
                    self.reSignOptions.appBundleID = text.removeAllSapce
                    self.tableView.reloadData()
                }
            } else if indexPath.row == 3 {
                self.showDialogTextFieldViewController(title: "App版本号", text: application!.version, placeholder: "App版本号", keyboardType: .numbersAndPunctuation) { [unowned self] text in
                    self.reSignOptions.appVersion = text.removeAllSapce
                    self.tableView.reloadData()
                }
            }
        } else if indexPath.section == 1 {
            let controller = CertificateListViewController()
            controller.completionHandler = { [weak self] in
                self?.readCertInfo()
                self?.tableView.reloadData()
            }
            self.navigationController?.pushViewController(controller, animated: true)
        } else if indexPath.section == 2 {
            if indexPath.row == 2 {
                /*
                 let documentTypes = ["public.data", "public.content", "public.audiovisual-content", "public.movie", "public.audiovisual-content", "public.video", "public.audio", "public.text", "public.data", "public.zip-archive", "com.pkware.zip-archive", "public.composite-content", "public.text"];
                 let documentPickerController = UIDocumentPickerViewController(documentTypes: documentTypes, in: .import)
                 documentPickerController.delegate = self
                 self.present(documentPickerController, animated: true, completion: nil)
                 */
                let controller = FolderViewController()
                controller.isRootViewController = false
                controller.indexFileURL = FileManager.default.documentDirectory
                controller.title = "选择"
                controller.multiSelect = true
                controller.selectFilesCallback = { [unowned self] files in
                    for myFile in files {
                        if myFile.isDylib {
                            var containsDylib = false
                            for myDylibURL in self.reSignOptions.dylibURLs {
                                if myFile.url.lastPathComponent == myDylibURL.lastPathComponent {
                                    containsDylib = true
                                }
                            }
                            if containsDylib {
                                return
                            }
                            self.reSignOptions.dylibURLs.append(myFile.url)
                            self.tableView.reloadData()
                            
                        } else if myFile.isDeb {
                            
                            var dylibFile: File?
                                                    
                            var file = self.extractDeb(myFile)
                            if let f = file {
                                if !f.isDylib {
                                    file = self.extractDeb(f)
                                }
                            }
                            
                            if let f = file {
                                if !f.isDylib {
                                    file = self.extractDeb(f)
                                }
                            }
                            
                            if let f = file {
                                if f.isDylib {
                                    dylibFile = f
                                }
                            }
                            
                            if let dylibFile = dylibFile {
                                var containsDylib = false
                                for myDylibURL in self.reSignOptions.dylibURLs {
                                    if dylibFile.url.lastPathComponent == myDylibURL.lastPathComponent {
                                        containsDylib = true
                                    }
                                }
                                if containsDylib {
                                    return
                                }
                                self.reSignOptions.dylibURLs.append(dylibFile.url)
                                
                            }
                        }
                    }
                    self.tableView.reloadData()
                }
                controller.navigationItem.leftBarButtonItem = UIBarButtonItem.init(title: "关闭", style: .plain, target: controller, action: #selector(controller.dismissController))
                let nav = QMUINavigationController.init(rootViewController: controller)
                nav.modalPresentationStyle = .fullScreen
                self.present(nav, animated: true, completion: nil)
                
            } else if indexPath.row > 2 {
                let dylibURL = self.reSignOptions.dylibURLs[indexPath.row - 3]
                let alertController = QMUIAlertController.init(title: dylibURL.lastPathComponent, message: nil, preferredStyle: .actionSheet)
//                alertController.addAction(QMUIAlertAction(title: "删除插件", style: .default, handler: { _, _ in
//                    let controller = DylibPathViewController()
//                    controller.deleteMode = true
//                    controller.hidesBottomBarWhenPushed = true
//                    controller.executableURL = dylibURL
//                    controller.title = dylibURL.lastPathComponent
//                    self.navigationController?.pushViewController(controller, animated: true)
//                }))
                alertController.addAction(QMUIAlertAction(title: "查看MachO信息", style: .default, handler: { _, _ in
                    let machOInfo = AppSigner.printMachOInfo(withFileURL: dylibURL)
                    let controller = TextViewController.init(text: machOInfo)
                    controller.title = dylibURL.lastPathComponent
                    controller.hidesBottomBarWhenPushed = true
                    self.navigationController?.pushViewController(controller, animated: true)
                }))
                alertController.addAction(QMUIAlertAction.init(title: "移除", style: .destructive, handler: { _, _ in
                    self.reSignOptions.dylibURLs.remove(at: indexPath.row - 3)
                    self.tableView.reloadData()
                }))
                alertController.addCancelAction()
                alertController.showWith(animated: true)
            }
            
        } else if indexPath.section == 3 {
            if indexPath.row == 0 {
                let controller = DylibPathViewController()
                controller.deleteMode = true
                controller.hidesBottomBarWhenPushed = true
                controller.executableURL = application.executableFileURL
                controller.title = application.name
                self.navigationController?.pushViewController(controller, animated: true)
            } else if indexPath.row == 1 {
                let controller = FolderViewController()
                controller.indexFileURL = application.fileURL
                controller.title = application.fileURL.lastPathComponent
                self.navigationController?.pushViewController(controller, animated: true)
            } else if indexPath.row == 2 {
                let controller = PlistPreviewController.init(dictionary: infoDictionary)
                //            controller.plistURL = self.infoPlistURL
                controller.title = "Info.plist"
                controller.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(controller, animated: true)
            } else if indexPath.row == 3 {
                let machOInfo = AppSigner.printMachOInfo(withFileURL: application.executableFileURL)
                let controller = TextViewController.init(text: machOInfo)
                controller.title = application.executableName
                self.navigationController?.pushViewController(controller, animated: true)
            } else if indexPath.row == 4 {
                if self.application.encrypted() {
                    return;
                }
                if let classdumpOutputURL = self.reSignOptions.classdumpOutputURL {
                    let controller = FolderViewController()
                    controller.indexFileURL = classdumpOutputURL
                    controller.title = classdumpOutputURL.lastPathComponent
                    controller.navigationItem.leftBarButtonItem = UIBarButtonItem.init(title: "关闭", style: .plain, target: controller, action: #selector(controller.dismissController))
                    let nav = QMUINavigationController.init(rootViewController: controller)
                    nav.modalPresentationStyle = .fullScreen
                    self.present(nav, animated: true, completion: nil)
                } else {
                    let outputURL = FileManager.default.classdumpDirectory.appendingPathComponent(application.name)
                    QMUITips.showLoading(application.name, detailText: "Class Dump", in: self.view).whiteStyle()
                    Async.background {
                        let result = ClassDumpUtils.classDump(withExecutablePath: self.application.executableFileURL.path, withOutput: outputURL.path)
                        Async.main {
                            if result == 0 {
                                QMUITips.hideAllTips()
                                kAlert("ClassDump成功")
                                self.reSignOptions.classdumpOutputURL = outputURL
                                self.tableView.reloadRows(at: [indexPath], with: .automatic)
                            } else {
                                QMUITips.hideAllTips()
                                kAlert("ClassDump失败")
                            }
                        }
                    }
                }
            }
        } else if indexPath.section == 4 {
            
        } else if indexPath.section == 5 {
            //            if indexPath.row == 0 {
            //                let controller = SignCoreViewController()
            //                controller.completionHandler = { [unowned self] in
            //                    self.readCertInfo()
            //                    self.tableView.reloadData()
            //                }
            //                self.navigationController?.pushViewController(controller, animated: true)
            //            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 40 : 30
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 2 {
            return 150
        }
        return 10
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var text = ""
        if section == 0 {
            text = "应用设置"
        } else if section == 1 {
            text = "证书选择"
        } else if section == 2 {
            text = "注入设置"
        } else if section == 3 {
            text = "应用修改"
        } else if section == 4 {
            text = "IPA打包"
        }  else if section == 5 {
            text = "签名设置"
        }
        return text
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 2 {
            return "注入命令\n@weak: LC_LOAD_WEAK_DYLIB\n@load: LC_LOAD_DYLIB\n\n注入路径\n@executable_path/Dylibs/xxx.dylib\n@loader_path/Dylibs/xxx.dylib\n@rpath/Dylibs/xxx.dylib"
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }
    
    
}

extension ReSignAppViewController: UIImagePickerControllerDelegate{
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        if let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            self.reSignOptions.customIcon = image
            self.tableView.reloadData()
        }
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}



extension ReSignAppViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if controller.documentPickerMode == .import {
            for url in urls {
                if url.pathExtension.lowercased() == "dylib" {
                    let fileName = url.lastPathComponent
                    let savePath = FileManager.default.dylibDirectory.appendingPathComponent(fileName).path
                    do {
                        try FileManager.default.createFile(atPath: savePath, contents: Data(contentsOf: url), attributes: nil)
                        let file = File(fileURL: URL.init(fileURLWithPath: savePath))
                        var containsDylib = false
                        for myDylibURL in self.reSignOptions.dylibURLs {
                            if file.url.lastPathComponent == myDylibURL.lastPathComponent {
                                containsDylib = true
                            }
                        }
                        if containsDylib {
                            return
                        }
                        self.reSignOptions.dylibURLs.append(file.url)
                        self.tableView.reloadData()
                    } catch {
                        kAlert("\(fileName)导入失败")
                    }
                } else {
                    kAlert("仅支持dylib类型的动态库")
                }
            }
        }
    }
}
