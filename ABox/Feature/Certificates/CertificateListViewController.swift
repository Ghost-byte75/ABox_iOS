import UIKit
import Async
import HandyJSON

typealias CertItem = (certificate: ALTCertificate, certInfo: P12CertificateInfo, profile: ALTProvisioningProfile?)

class CertificateListViewController: ViewController {
    
    var completionHandler:(() -> ())?
    
    fileprivate let tableView = QMUITableView.init(frame: CGRect.zero, style: .grouped)
    fileprivate var localCertList: [CertItem] = []
    fileprivate var cloudCertList: [CertItem] = []
    fileprivate var originCloudCertList: [CloudCert] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.loadDataSources()
        //self.getAllCloudCerts(flag: false)
    }
    
    override func initSubviews() {
        super.initSubviews()

        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.showsVerticalScrollIndicator = false
        self.tableView.showsHorizontalScrollIndicator = false
        self.tableView.register(CertificateInfoCell.self, forCellReuseIdentifier: CertificateInfoCell.cellIdentifier())
        self.tableView.setEmptyDataSet(title: nil, descriptionString: nil, image: UIImage(named: "file-storage"))
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.left.top.right.equalTo(0)
            maker.bottom.equalTo(0)
        }
    }
    
    override func setupNavigationItems() {
        super.setupNavigationItems()
        self.title = "证书管理"
        let importButton = UIBarButtonItem(title: "导入", style: .done, target: self, action:  #selector(barButtonItemTapped(sender: )))
        let regainButton = UIBarButtonItem(title: "恢复", style: .done, target: self, action:  #selector(barButtonItemTapped(sender: )))
        regainButton.tag = 1
        self.navigationItem.rightBarButtonItems = [importButton, regainButton]
    }

    func getAllCloudCerts(flag: Bool) {
        self.cloudCertList.removeAll()
        
        if let udid = AppDefaults.shared.deviceUDID {
            XZAPI.default.request(url: "/api/external/api/cert.htm", parameters: ["udid": udid]) { (result: [CloudCert]?) in
                if let list = result {
                    self.originCloudCertList = list
                    for cloudCert in list {
                        if let certData = Data.init(base64Encoded: cloudCert.p12Data), let profileData = Data(base64Encoded: cloudCert.profileData) {
                        
                            if let altCert = ALTCertificate(p12Data: certData, password: cloudCert.certPwd) {                              
                                if let altProfile = ALTProvisioningProfile(data: profileData) {
                                    print(message: altCert)
                                    print(message: altProfile)
                                    var item: (certificate: ALTCertificate, certInfo: P12CertificateInfo, profile: ALTProvisioningProfile?)
                                    item.certificate = altCert
                                    item.profile = altProfile
                                    item.certInfo = ReadP12Subject().readCertInfoWhitAltCert(altCert)
                                    print(message: item.certInfo)
                                    self.cloudCertList.append(item)
                                    
                                    let p12Name = "\(altCert.name).p12"
                                    let p12SavePath = FileManager.default.certificatesDirectory.appendingPathComponent(p12Name).path
                                    FileManager.default.createFile(atPath: p12SavePath, contents: altCert.p12Data(), attributes: nil)
                                    
                                    let profileName = "\(altProfile.uuid).mobileprovision"
                                    let profileSavePath = FileManager.default.profilesDirectory.appendingPathComponent(profileName).path
                                    FileManager.default.createFile(atPath: profileSavePath, contents: profileData, attributes: nil)
                                }
                           
                                
                            } else {
                                kAlert("证书(\(cloudCert.name) - \(cloudCert.serialNumber))的密码错误：\(cloudCert.certPwd)")
                            }
                        }
                    }
                }
                self.loadDataSources()
                QMUITips.hideAllTips()
                if flag {
                    kAlert(self.cloudCertList.count <= 0 ? "暂无更多证书":"证书已恢复")
                }
            } failure: { error in
                print(message: error)
                if flag {
                    kAlert(error)
                }
            }
        }
    }
    
    func exportCert(_ cert: CertItem, password: String) {
        if !FileManager.default.fileExists(atPath: FileManager.default.exportCertDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: FileManager.default.exportCertDirectory, withIntermediateDirectories: true)
            } catch let error {
                print(message: error.localizedDescription)
            }
        }
        
        let p12Path = FileManager.default.exportCertDirectory.appendingPathComponent(cert.certInfo.name + ".p12").path
        let p12Data = cert.certificate.encryptedP12Data(withPassword: password)
        FileManager.default.createFile(atPath: p12Path, contents: p12Data)
        
        if let profile = cert.profile {
            let profilePath = FileManager.default.exportCertDirectory.appendingPathComponent(profile.name + ".mobileprovision").path
            FileManager.default.createFile(atPath: profilePath, contents: profile.data)
        }
        
        let alertController = QMUIAlertController.init(title: "\(cert.certificate.name)已导出", message: password.count <= 0 ? nil : "密码为\(password)", preferredStyle: .alert)
        alertController.addAction(QMUIAlertAction(title: "确定", style: .cancel, handler: nil))
        alertController.addAction(QMUIAlertAction(title: "查看", style: .default, handler: { _, _ in
            let controller = FolderViewController()
            controller.indexFileURL = FileManager.default.exportCertDirectory
            controller.title = "导出的证书"
            controller.navigationItem.leftBarButtonItem = UIBarButtonItem.init(title: "关闭", style: .plain, target: controller, action: #selector(controller.dismissController))
            let nav = QMUINavigationController.init(rootViewController: controller)
            nav.modalPresentationStyle = .fullScreen
            self.present(nav, animated: true, completion: nil)
        }))
        alertController.showWith(animated: true)
    }
}

extension CertificateListViewController {
    
    @objc 
    func barButtonItemTapped(sender: UIBarButtonItem) {
        if sender.tag == 0 {
            let documentTypes = ["public.data", "public.content", "public.audiovisual-content", "public.movie", "public.audiovisual-content", "public.video", "public.audio", "public.text", "public.data", "public.zip-archive", "com.pkware.zip-archive", "public.composite-content", "public.text"];
            let documentPickerController = UIDocumentPickerViewController(documentTypes: documentTypes, in: .import)
            documentPickerController.delegate = self
            self.present(documentPickerController, animated: true, completion: nil)
        } else {
            self.getAllCloudCerts(flag: true)
        }
        
    }
        
    func loadDataSources() {
        QMUITips.showLoading(in: self.view)
        Async.background { [unowned self] in
            var certificates: [ALTCertificate] = []
            do {
                let array = try FileManager.default.contentsOfDirectory(atPath: FileManager.default.certificatesDirectory.path)
                for name in array {
                    let fileURL: URL = FileManager.default.certificatesDirectory.appendingPathComponent(name)
                    if fileURL.isCertificate {
                        if let data: Data = NSData.init(contentsOf: fileURL) as Data? {
                            if let certificate = ALTCertificate.init(p12Data: data, password: "") {
                                certificates.append(certificate)
                            }
                        }
                    }
                }
            } catch let error {
                print(message: error.localizedDescription)
            }
            
            var profiles: [ALTProvisioningProfile] = []
            do {
                let array = try FileManager.default.contentsOfDirectory(atPath: FileManager.default.profilesDirectory.path)
                for name in array {
                    let fileURL: URL = FileManager.default.profilesDirectory.appendingPathComponent(name)
                    if fileURL.isMobileProvision {
                        if let profile = ALTProvisioningProfile.init(url: fileURL) {
                            profiles.append(profile)
                        }
                    }
                }
            } catch let error {
                print(message: error.localizedDescription)
            }
            self.localCertList.removeAll()
            for certificate in certificates {
                var item: (certificate: ALTCertificate, certInfo: P12CertificateInfo, profile: ALTProvisioningProfile?)
                item.certificate = certificate
                item.certInfo = ReadP12Subject().readCertInfoWhitAltCert(certificate)
                item.profile = nil
                for profile in profiles {
                    for profileCertificate in profile.certificates {
                        if certificate.serialNumber == profileCertificate.serialNumber {
                            if let p = item.profile {
                                if p.expirationDate < profile.expirationDate {
                                    item.profile = profile
                                }
                            } else {
                                item.profile = profile
                            }
                        }
                    }
                }
                self.localCertList.append(item)
            }
            print(message: certificates)
            print(message: profiles)
            Async.main { [unowned self] in
                QMUITips.hideAllTips()
                self.tableView.reloadData()
            }
        }
    }
    
    func deleteItem(_ item: CertItem) {
        // 先删除ProvisioningProfile
        do {
            let array = try FileManager.default.contentsOfDirectory(atPath: FileManager.default.profilesDirectory.path)
            for name in array {
                let fileURL: URL = FileManager.default.profilesDirectory.appendingPathComponent(name)
                if fileURL.isMobileProvision {
                    if let profile = ALTProvisioningProfile.init(url: fileURL) {
                        for certificate in profile.certificates {
                            if item.certificate.serialNumber == certificate.serialNumber {
                                try FileManager.default.removeItem(at: fileURL)
                            }
                        }
                    }
                }
            }
        } catch let error {
            print(message: error.localizedDescription)
        }
        
        // 再删除Certificate
        do {
            let array = try FileManager.default.contentsOfDirectory(atPath: FileManager.default.certificatesDirectory.path)
            for name in array {
                let fileURL: URL = FileManager.default.certificatesDirectory.appendingPathComponent(name)
                if fileURL.isCertificate {
                    if let data: Data = NSData.init(contentsOf: fileURL) as Data? {
                        if let certificate = ALTCertificate.init(p12Data: data, password: "") {
                            if item.certificate.serialNumber == certificate.serialNumber {
                                try FileManager.default.removeItem(at: fileURL)
                            }
                        }
                    }
                }
            }
        } catch let error {
            print(message: error.localizedDescription)
        }
        
        localCertList.removeAll { i -> Bool in
            return item.certificate.serialNumber == i.certificate.serialNumber
        }
        tableView.reloadData()
    }
    
    
}

extension CertificateListViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if controller.documentPickerMode == .import {
            for url in urls {
                if url.isMobileProvision {
                    AppManager.default.importProfile(url: url, completionHandler: { [weak self] in
                        self?.loadDataSources()
                    })
                } else if url.isCertificate {
                    AppManager.default.importCertificate(url: url, completionHandler: { [weak self] in
                        self?.loadDataSources()
                    })
                } else {
                    kAlert("不支持的文件格式")
                }
            }
        }
    }
}

extension CertificateListViewController: QMUITableViewDelegate, QMUITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CertificateInfoCell.cellHeight()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? localCertList.count : cloudCertList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: CertificateInfoCell = tableView.dequeueReusableCell(withIdentifier: CertificateInfoCell.cellIdentifier()) as! CertificateInfoCell
        let item = indexPath.section == 0 ? self.localCertList[indexPath.row] : self.cloudCertList[indexPath.row]
        cell.configCell(certificate: item.certificate, certInfo: item.certInfo, profile: item.profile)
        cell.detailButtonTappedCallback = { [unowned self] in
            let controller = CertificateInfoViewController()
            controller.certificate = item.certificate
            controller.certInfo = item.certInfo
            controller.profile = item.profile
            self.navigationController?.pushViewController(controller, animated: true)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return self.localCertList.count == 0 ? 0.01 : 40
        } else {
            return self.cloudCertList.count == 0 ? 0.01 : 40
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return self.localCertList.count == 0 ? nil : "本地证书"
        } else {
            return self.cloudCertList.count == 0 ? nil : "云端证书"
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item =  indexPath.section == 0 ? self.localCertList[indexPath.row] : self.cloudCertList[indexPath.row]
        if let profile = item.profile {
            AppDefaults.shared.signingCertificate = item.certificate.p12Data()
            AppDefaults.shared.signingCertificateName = item.certificate.name
            AppDefaults.shared.signingCertificateSerialNumber = item.certificate.serialNumber
            AppDefaults.shared.signingCertificatePassword = nil
            AppDefaults.shared.signingProvisioningProfile = profile.data
            if let handler = self.completionHandler {
                handler()
                self.navigationController?.popViewController(animated: true)
            } else {
                QMUITips.showSucceed("已选择\(item.certificate.name)", in: self.view).whiteStyle()
            }
            self.tableView.reloadData()
        } else {
            QMUITips.showError("所选证书尚未导入描述文件！", in: self.view).whiteStyle()
        }
    }
    
    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        let item =  indexPath.section == 0 ? self.localCertList[indexPath.row] : self.cloudCertList[indexPath.row]
        let controller = CertificateInfoViewController()
        controller.certificate = item.certificate
        controller.certInfo = item.certInfo
        controller.profile = item.profile
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let exportAction = UITableViewRowAction(style: .destructive, title: "导出") { _, i in
            UIImpactFeedbackGenerator.init(style: .medium).impactOccurred()

            let item = indexPath.section == 0 ? self.localCertList[indexPath.row] : self.cloudCertList[indexPath.row]

            let alertController = QMUIAlertController.init(title: "请设置\(item.certificate.name)的证书密码", message: nil, preferredStyle: .alert)
            alertController.addTextField { textField in
                textField.keyboardType = .asciiCapableNumberPad
            }
            alertController.addAction(QMUIAlertAction(title: "取消", style: .cancel, handler: nil))
            alertController.addAction(QMUIAlertAction(title: "确定", style: .default, handler: { t, _ in
                if let textField = t.textFields?.first {
                    self.exportCert(item, password: textField.text!)
                }
                
            }))
            alertController.showWith(animated: true)
        }
        exportAction.backgroundColor = kRGBColor(80, 168, 80)
        
        if indexPath.section == 0 {
            let deleteAction = UITableViewRowAction(style: .destructive, title: "删除") { _, i in
                UIImpactFeedbackGenerator.init(style: .medium).impactOccurred()
                let item = self.localCertList[indexPath.row]
                let alertController = QMUIAlertController.init(title: "确定删除\(item.certificate.name)吗？", message: nil, preferredStyle: .alert)
                alertController.addAction(QMUIAlertAction(title: "取消", style: .cancel, handler: nil))
                alertController.addAction(QMUIAlertAction(title: "确定", style: .default, handler: { _, _ in
                    self.deleteItem(item)
                }))
                alertController.showWith(animated: true)
            }
            deleteAction.backgroundColor = kRGBColor(243, 64, 54)
            return [deleteAction, exportAction]
        }
        

        return [exportAction]
    }
}


class CloudCert: HandyJSON {
    
    var id = 0
    var name = ""
    var serialNumber = ""
    var identifier = ""
    var startTime: Int = 0
    var expireTime: Int = 0
    var p12Data = ""
    var devices = ""
    var profileData = ""
    var createdTime = ""
    var updatedTime = ""
    var certPwd = ""
    required init() {}
}
