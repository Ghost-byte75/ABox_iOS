import UIKit
import Material
import RxSwift
import RxCocoa
import SafariServices
import Async

class SettingsViewController: ViewController {
    
    let backgroundTaskSwitch = UISwitch()
    var tableView = QMUITableView.init(frame: CGRect.zero, style: .grouped)
    let cellIdentifier = "settingsCell"
    var cacheSize: Int = 0
    var webUploaderTipStr = ""
    let webUploaderSwitch = UISwitch()
    let trollStoreSwitch = UISwitch()
    var webUploader: GCDWebUploader?
    
    let privateURL = URL(string: "https://www.julyedu.com/agreement/priv")!//隐私协议
    let tutorialURL = URL(string: "https://www.baidu.com")! //签名站点

    //  ("关于我们", "ic_aboutus")
    var cellData = [[("证书管理", "ic_contract"),
                     ("设备UDID", "ic_udid")],
                    [("IPA安装服务器", "cloud-download"),
                     ("使用TrollStore安装", "trollstore")],
                    [("WiFi文件传输", "ob_icon_wifi")],
                    [("后台运行", "background"),
                     ("清理缓存", "ic_helper"),
                     ("使用教程", "ic_aboutus"),
                     ("服务及隐私协议", "ic_unlock"),]]
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.cacheSize = AppDefaults.shared.cacheFileSize!
        self.tableView.reloadData()
        Async.background {
            self.cacheSize = self.fileSizeOfCache()
            AppDefaults.shared.cacheFileSize = self.cacheSize
            Async.main {
                self.tableView.reloadData()
            }
        }
    }
    
    override func setupNavigationItems() {
        super.setupNavigationItems()
        if Client.shared.isMaster {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem.init(image: UIImage(named: "nav_trend"), style: .done, target: self, action: #selector(statistics))
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func initSubviews() {
        super.initSubviews()
        backgroundTaskSwitch.tag = 0
        backgroundTaskSwitch.isOn = AppDefaults.shared.backgroundTaskEnable!
        backgroundTaskSwitch.addTarget(self, action: #selector(switchValueChanged(sender:)), for: .valueChanged)
        
        webUploaderSwitch.tag = 1
        webUploaderSwitch.addTarget(self, action: #selector(switchValueChanged(sender:)), for: .valueChanged)
        
        trollStoreSwitch.tag = 2
        trollStoreSwitch.isOn = AppDefaults.shared.trollStoreEnable!
        trollStoreSwitch.addTarget(self, action: #selector(switchValueChanged(sender:)), for: .valueChanged)

        if #available(iOS 13.0, *) {
            self.tableView = QMUITableView.init(frame: .zero, style: .insetGrouped)
        }
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.showsVerticalScrollIndicator = false
        self.tableView.showsHorizontalScrollIndicator = false
        self.tableView.register(QMUITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.left.top.right.equalTo(0)
            maker.bottom.equalTo(0)
        }
    }
    
    @objc
    func statistics() {
        let controller = StatisticsViewController.init(style: .grouped)
        controller.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    @objc
    func switchValueChanged(sender: UISwitch) {
        if sender.tag == 0 {
            print(message: CLLocationManager.authorizationStatus())
            if sender.isOn {
                if CLLocationManager.authorizationStatus() == .denied  {
                    kAlert("请开启定位权限以便App在后台运行时可以安装应用和传输文件")
                    backgroundTaskSwitch.isOn = false
                    return
                }
                if CLLocationManager.authorizationStatus() != .authorizedAlways {
                    LocationManager.shared.requestAuthority()
                }
            }
            AppDefaults.shared.backgroundTaskEnable = sender.isOn
        } else if sender.tag == 1 {
            if sender.isOn {
                startWebUploader()
            } else {
                stopWebUploader()
            }
        } else if sender.tag == 2 {
            
            if sender.isOn {
                if UIApplication.shared.canOpenURL(URL(string:"apple-magnifier://")!) {
                    print(message: "可以打开TrollStore!")
                    AppDefaults.shared.trollStoreEnable = true
                } else {
                    kAlert("打开 TrollStore 时发生了错误", message: "请确保已成功安装 TrollStore 并开启了 URL Scheme！否则请在设置中关闭使用 TrollStore 安装。")
                    print(message: "打不开TrollStore!")
                    AppDefaults.shared.trollStoreEnable = false
                    sender.isOn = false
                }
            } else {
                AppDefaults.shared.trollStoreEnable = false
            }
        }
    }
  
}


extension SettingsViewController: QMUITableViewDelegate, QMUITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.cellData[section].count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return cellData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "cell"
        var cell = tableView.dequeueReusableCell(withIdentifier: identifier)
        if cell == nil {
            cell = QMUITableViewCell(for: tableView, with: .value1, reuseIdentifier: identifier)
            cell?.selectionStyle = .none
            cell?.textLabel?.font = UIFont.medium(aSize: 14)
            cell?.textLabel?.textColor = kTextColor
            cell?.detailTextLabel?.font = UIFont.regular(aSize: 13)
            cell?.detailTextLabel?.textColor = kTextColor
        }
        
        cell?.accessoryType = .disclosureIndicator
        let item = self.cellData[indexPath.section][indexPath.row]
        cell?.textLabel?.text = item.0
        cell?.imageView?.image = UIImage(named: item.1)?.qmui_image(withTintColor: kTextColor)
        cell?.detailTextLabel?.text = nil

        if item.0 == "证书管理" {
            if let signingCertificateName = AppDefaults.shared.signingCertificateName {
                cell?.detailTextLabel?.text = signingCertificateName
            } else {
                cell?.detailTextLabel?.text = "选择签名证书"
            }
           
        } else if item.0 == "设备UDID" {
            if let udid = AppDefaults.shared.deviceUDID {
                cell?.detailTextLabel?.text = udid
            } else {
                cell?.detailTextLabel?.text = "点击获取"
            }
        } else if item.0 == "清理缓存" {
            cell?.detailTextLabel?.text = String.fileSizeDesc(self.cacheSize)
        } else if item.0 == "后台运行" {
            backgroundTaskSwitch.isOn = AppDefaults.shared.backgroundTaskEnable!
            cell?.accessoryView = backgroundTaskSwitch
        } else if item.0 == "IPA安装服务器" {
            let installIPAService: Int = AppDefaults.shared.installIPAService!
            switch installIPAService {
            case 0:
                cell?.detailTextLabel?.text = "gbox.pub"
            default:
                cell?.detailTextLabel?.text = "gbox.run"
            }
        } else if item.0 == "WiFi文件传输" {
            cell?.accessoryView = webUploaderSwitch
        } else if item.0 == "使用TrollStore安装" {
            cell?.accessoryView = trollStoreSwitch
        }
        return cell!
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 2 {
            return 30
        }
        return 10
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 2 {
            return webUploaderTipStr
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 1 {
            return 45
        } else if section == 2 {
            return 45
        } else if section == 3 {
            return 45
        } else {
            return 0.01
        }
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 1 {
            return "请确保已成功安装 TrollStore 并在其设置中开启了 URL Scheme！否则请关闭使用 TrollStore 安装。"
        } else if section == 2 {
            return "电脑与该设备必须在同一局域网下\n在文件传输过程中请勿锁屏"
        } else if section == 3 {
            return "\(kAppDisPlayName!)：\(kAppVersion!)(\(kAppBuildVersion!))\nAppID：\(kAppBundleIdentifier!)"
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        UIImpactFeedbackGenerator.init(style: .medium).impactOccurred()
        let item = self.cellData[indexPath.section][indexPath.row]
        if item.0 == "证书管理" {
            let controller = CertificateListViewController()
            controller.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(controller, animated: true)
        } else if item.0 == "清理缓存" {
            QMUITips.showLoading("清理中...", in: self.view).whiteStyle()
            Async.background {
                self.clearCache()
            } .main {
                UIImpactFeedbackGenerator.init(style: .medium).impactOccurred()
                self.cacheSize = 0
                AppDefaults.shared.cacheFileSize = 0
                self.tableView.reloadData()
                QMUITips.hideAllTips(in: self.view)
                QMUITips.showSucceed("已清除全部缓存", in: self.view).whiteStyle()
            }
        } else if item.0 == "设备UDID" {
            let alertController = QMUIAlertController.init(title: "获取UDID", message: "下载配置描述文件后请在【设置】应用中安装。", preferredStyle: .actionSheet)
            if let udid = AppDefaults.shared.deviceUDID {
                alertController.addAction(QMUIAlertAction.init(title: "复制", style: .default, handler: { _, _ in
                    UIPasteboard.general.string = udid
                    QMUITips.showSucceed("已复制UDID\n\(udid)", in: self.view).whiteStyle()
                }))
                alertController.addAction(QMUIAlertAction.init(title: "重新获取", style: .destructive, handler: { _, _ in
                    self.getUDID()
                }))
            } else {
                alertController.addAction(QMUIAlertAction.init(title: "获取", style: .destructive, handler: { _, _ in
                    self.getUDID()
                }))
            }
            alertController.addAction(QMUIAlertAction.init(title: "取消", style: .cancel, handler: nil))
            alertController.showWith(animated: true)
        } else if item.0 == "IPA安装服务器" {
            let controller = IPAInstallServiceViewController()
            controller.hidesBottomBarWhenPushed = true
            controller.completionHandler = { [unowned self] in
                self.tableView.reloadData()
            }
            self.navigationController?.pushViewController(controller, animated: true)
        } else if item.0 == "使用教程" {
            let webVC = WebViewController(url: tutorialURL)
            webVC.hidesBottomBarWhenPushed = true
            webVC.title = "使用教程"
            self.navigationController?.pushViewController(webVC, animated: true)
        } else if item.0 == "服务及隐私协议" {
            let webVC = UserAgreementViewController()
            webVC.hidesBottomBarWhenPushed = true
            webVC.title = "隐私协议"
            webVC.hideNext = true
            self.navigationController?.pushViewController(webVC, animated: true)
        }
    }

}

extension SettingsViewController {
    
    func getUDID() {
        //AppManager.default.getUDID()
        self.getUDIDWithSafari()

    }
    
    func fileSizeOfCache()-> Int {
        // 取出cache文件夹目录 缓存文件都在这个目录下
        let fileURLs: [URL] = [FileManager.default.recycleBinDirectory]

        var size = 0
        for url in fileURLs {
            if let fileArr = FileManager.default.subpaths(atPath: url.path) {
                for file in fileArr {
                    let path = url.appendingPathComponent(file).path
                    do {
                        let floder = try FileManager.default.attributesOfItem(atPath: path)
                        for (abc, bcd) in floder {
                            if abc == FileAttributeKey.size {
                                size += (bcd as AnyObject).integerValue
                            }
                        }
                    } catch let error {
                        print(message: error.localizedDescription)
                    }
                }
            }
        }
        return size
    }
    
    func clearCache() {
//        URLCache.shared.removeAllCachedResponses()
//        
//        let tmpDir = NSTemporaryDirectory()
//        do {
//            try FileManager.default.removeItem(atPath: tmpDir)
//        } catch let error {
//            print(message: "清理\(tmpDir)失败，\(error.localizedDescription)")
//        }
 
        let fileURLs: [URL] = [FileManager.default.recycleBinDirectory]
        
        for fileURL in fileURLs {
            if let fileArr = FileManager.default.subpaths(atPath: fileURL.path) {
                for file in fileArr {
                    let path = fileURL.appendingPathComponent(file).path
                    print(message: "清理\(path)")
                    do {
                        try FileManager.default.removeItem(atPath: path)
                    } catch let error {
                        print(message: "清理\(fileURL.absoluteString)失败，\(error.localizedDescription)")
                    }
                }
            }
        }
        
        FileManager.default.createDefaultDirectory()
    }
    
    func startWebUploader() {
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].path
        if self.webUploader == nil {
            self.webUploader = GCDWebUploader(uploadDirectory: path)
            if let wb = self.webUploader {
                wb.start(withPort: 80, bonjourName: "\(kAppDisPlayName!)")
                if let url = wb.serverURL {
                    print(message: "浏览器访问：\(url.absoluteString)")
                    webUploaderTipStr = "在浏览器访问：\(url.absoluteString)"
                    webUploaderSwitch.isOn = true
                } else {
                    webUploaderTipStr = "无法建立文件传输服务器，请在Wi-Fi环境下使用"
                    webUploaderSwitch.isOn = false
                }
            }
        }
        tableView.reloadData()
    }
    
    func stopWebUploader() {
        if let wp = webUploader {
            if wp.isRunning {
                wp.stop()
            }
            webUploader = nil
        }
        webUploaderTipStr = ""
        tableView.reloadData()
    }
}

struct SettingsCellData {
    var title = ""
    var icon = ""
}
