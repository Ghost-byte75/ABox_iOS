import UIKit
import UserNotifications
import SwiftDate
import Alamofire
import Async
import QMUIKit
import IOSSecuritySuite

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
     
    var window: UIWindow?
    let release = false
    let umengAppkey = "000000000000000000000000"
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        configureApp()
        configureAppearance()
        application.isIdleTimerDisabled = true
        window = UIWindow.init(frame: UIScreen.main.bounds)
        window?.backgroundColor = .white
        window?.rootViewController = rootViewController()
        window?.makeKeyAndVisible()
        return true
    }
    
    func rootViewController() -> UIViewController {
        if AppDefaults.shared.aggreUserAgreement! == true {
            //if let udid = AppDefaults.shared.deviceUDID {
            //    print(message: udid)
                return TabBarViewController()
            //} else {
            //    return GetUDIDViewController()
            //}
        } else {
            return UINavigationController(rootViewController: UserAgreementViewController())
        }
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        print(message: "open url:\(url.absoluteString)")
        UIImpactFeedbackGenerator.init(style: .medium).impactOccurred()
        
        if url.absoluteString.hasPrefix("xzsign") {
            if let urlComponents = NSURLComponents.init(url: url, resolvingAgainstBaseURL: false) {
                var udid = ""
                if let queryItems = urlComponents.queryItems {
                    for item in queryItems {
                        if item.name == "deviceUDID" {
                            if let value = item.value {
                                udid = NSString.decryptAES(value, key: AESNormalKey)
                                print(message: "udid:\(udid)")
                                AppDefaults.shared.deviceUDID = udid
                                Client.shared.updateDeviceInfo()
                                window?.rootViewController = TabBarViewController()
                                break
                            }
                        }
                    }
                }
            }
        }
        
        if url.absoluteString.hasPrefix("file://") {
            do {
                let moveToURL = FileManager.default.documentDirectory.appendingPathComponent(url.lastPathComponent)
                if FileManager.default.fileExists(atPath: moveToURL.path) {
                    try FileManager.default.removeItem(at: moveToURL)
                }
                
                try FileManager.default.moveItem(at: url, to: moveToURL)
                let alertController = QMUIAlertController.init(title: url.lastPathComponent, message: "该文件存储在「文件」中，是否查看?", preferredStyle: .alert)
                alertController.addCancelAction()
                alertController.addAction(QMUIAlertAction.init(title: "查看", style: .destructive, handler: { _, _ in
                    let controller = FolderViewController()
                    controller.indexFileURL = moveToURL.deletingLastPathComponent()
                    controller.title = FileManager.default.documentDirectory.lastPathComponent
                    controller.navigationItem.leftBarButtonItem = UIBarButtonItem.init(title: "关闭", style: .plain, target: controller, action: #selector(controller.dismissController))
                    let nav = QMUINavigationController.init(rootViewController: controller)
                    nav.modalPresentationStyle = .fullScreen
                    kAppRootViewController?.present(nav, animated: true, completion: nil)
                }))
                alertController.showWith(animated: true)
                return true
            } catch let error {
                print(message: error.localizedDescription)
                kAlert(error.localizedDescription)
                return true
            }
        }
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        if AppDefaults.shared.backgroundTaskEnable! && Client.shared.requestBackgroundTask {
            LocationManager.shared.startLocation()
        }
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        LocationManager.shared.stopLocation()
    }
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        // Alamofire 5 does not support background sessions.
        // SessionManager.default.backgroundCompletionHandler = completionHandler
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        print(message: "清理缓存垃圾")
        // 取出cache文件夹目录 缓存文件都在这个目录下
        let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        // 取出文件夹下所有文件数组
        if let fileArr = FileManager.default.subpaths(atPath: cacheURL.path) {
            // 遍历删除
            for file in fileArr {
                let path = cacheURL.appendingPathComponent(file).path
                do {
                    try FileManager.default.removeItem(atPath: path)
                    print(message: "清理\(path)")
                } catch let error {
                    print(message: "清理\(path)失败，\(error.localizedDescription)")
                }
            }
        }
    }
}

extension AppDelegate {

    func configureApp() {
        
        let calendar = Calendar.init(identifier: .iso8601)
        let zone = TimeZone(identifier: "Asia/Shanghai") == nil ? TimeZone.current : TimeZone(identifier: "Asia/Shanghai")!
        let locale = Locale.init(identifier: "zh_Hans_CN")
        let region = Region.init(calendar: calendar, zone: zone, locale: locale)
        SwiftDate.defaultRegion = region
                
        Client.shared.recoverDeviceInfo()
        Client.shared.updateDeviceInfo()
        
        if CLLocationManager.authorizationStatus() == .denied {
            AppDefaults.shared.backgroundTaskEnable = false
        }
        
        Async.background {
            FileManager.default.createDefaultDirectory()
            FileManager.default.clearSignedAppData()
        }
#if DEBUG
        // debug
        print(message: "debug 环境")
        AppDefaults.shared.deviceUDID = "00000000-0000000000000000"
//        UMConfigure.initWithAppkey(umengAppkey, channel: "Release")
//        UMConfigure.setLogEnabled(true)


#else
        // release
        AppDefaults.shared.deviceUDID = "00000000-0000000000000000"
//        UMConfigure.initWithAppkey(umengAppkey, channel: "Release")
//        UMConfigure.setLogEnabled(false)
#endif
                  
        
        /*
        let jailbreakStatus = IOSSecuritySuite.amIJailbrokenWithFailMessage()
        if jailbreakStatus.jailbroken {
            print(message:"This device is jailbroken")
            print(message:"Because: \(jailbreakStatus.failMessage)")
        } else {
            print(message:"This device is not jailbroken")
        }

        /// 调试器检测
        let amIDebugged: Bool = IOSSecuritySuite.amIDebugged()
        print(message: "amIDebugged:\(amIDebugged)")
        //        IOSSecuritySuite.denyDebugger()

        /// 模拟器检测
        let runInEmulator: Bool = IOSSecuritySuite.amIRunInEmulator()
        print(message: "runInEmulator:\(runInEmulator)")

        /// 逆向工程工具检测
        let amIReverseEngineered: Bool = IOSSecuritySuite.amIReverseEngineered()
        print(message: "amIReverseEngineered:\(amIReverseEngineered)")

        /// 系统代理检测
        let amIProxied: Bool = IOSSecuritySuite.amIProxied()
        print(message: "amIProxied:\(amIProxied)")
        
       
        if (amIDebugged || runInEmulator || amIReverseEngineered) && release {
            exit(0)
        }
         */
    }
    
    func configureAppearance() {
        if #available(iOS 13.0, *) {
            let barAppearance =  UINavigationBarAppearance()
            barAppearance.configureWithDefaultBackground()
            barAppearance.backgroundImage = UIImage.qmui_image(with: UIColor.white)
            UINavigationBar.appearance().scrollEdgeAppearance = barAppearance
        }
        if #available(iOS 15.0, *) {
            let tabbarAppearance = UITabBarAppearance()
            tabbarAppearance.configureWithDefaultBackground()
            UITabBar.appearance().scrollEdgeAppearance = tabbarAppearance
        }
        UITabBar.appearance().tintColor = .black
    }
}


