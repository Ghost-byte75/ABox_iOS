import UIKit

class TabBarViewController: QMUITabBarViewController {
    
    let appController = AppsViewController()
    let signedAppController = SignedAppsViewController()
    let folderController = FolderViewController()
    let downloadController = DownloadViewController()
    let settingViewController = SettingsViewController()

    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        appController.title = "Apps"
        let appsNav = QMUINavigationController(rootViewController: appController)
        appsNav.tabBarItem = UITabBarItem.init(title: "Apps", image: UIImage.init(named: "tabbar_source"), tag: 0)
        
        signedAppController.title = "应用"
        let signedAppNav = QMUINavigationController(rootViewController: signedAppController)
        signedAppNav.tabBarItem = UITabBarItem.init(title: "应用", image: UIImage.init(named: "tabbar_app"), tag: 1)
        
        folderController.title = "文件"
        folderController.isRootViewController = true
        let folderNav = QMUINavigationController(rootViewController: folderController)
        folderNav.tabBarItem = UITabBarItem.init(title: "文件", image: UIImage.init(named: "tabbar_file"), tag: 2)
                
        downloadController.title = "下载"
        let downloadNav = QMUINavigationController(rootViewController: downloadController)
        downloadNav.tabBarItem = UITabBarItem.init(title: "下载", image: UIImage.init(named: "tabbar_download"), tag: 3)
        
        settingViewController.title = "设置"
        let settingsNav = QMUINavigationController(rootViewController: settingViewController)
        settingsNav.tabBarItem = UITabBarItem.init(title: "设置", image: UIImage.init(named: "tabbar_setting"), tag: 4)
        
//        if QMUIHelper.isNotchedScreen && kiOS13Later {
//            let viewControllers = [signedAppNav, folderNav, downloadNav, settingsNav]
//            for controller in viewControllers {
//                controller.navigationBar.prefersLargeTitles = true
//                controller.navigationItem.largeTitleDisplayMode = .automatic
//            }
//        }
        self.viewControllers = [appsNav, signedAppNav, folderNav, downloadNav, settingsNav]
    }

}

extension UITabBar {
    //让图片和文字在iOS11下仍然保持上下排列
    override open var traitCollection: UITraitCollection {
        if UIDevice.current.userInterfaceIdiom == .pad {
//            if #available(iOS 17.0, *) {
//                self.traitOverrides.horizontalSizeClass = .compact
//            } else {
                return UITraitCollection(horizontalSizeClass: .compact)
//            }
        }
        return super.traitCollection
    }
}

