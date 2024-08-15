import UIKit
import Async

class SignedAppsViewController: ViewController {

    var segmentIndex = 0
    
    fileprivate let tableView = QMUITableView.init(frame: CGRect.zero, style: .grouped)
    fileprivate var appLibraryList: [AppLibraryModel] = []
    fileprivate var signedAppList: [SignedAppModel] = []
    fileprivate var segmentedControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if Client.shared.showSignedAppList {
            self.segmentIndexChange(1)
            Client.shared.showSignedAppList = false
        } else {
            loadAppsData()
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }

    override func initSubviews() {
        super.initSubviews()
        
        self.segmentedControl = UISegmentedControl.init(items: ["未签名", "已签名"])
        self.segmentedControl.selectedSegmentIndex = segmentIndex
        self.segmentedControl.addTarget(self, action: #selector(segmentedControlChange(sender:)), for: .valueChanged)
        self.view.addSubview(self.segmentedControl)
        self.segmentedControl.snp.makeConstraints { maker in
            maker.top.equalTo(kUINavigationContentTop + 7.5)
            maker.width.equalTo(200)
            maker.centerX.equalTo(self.view)
            maker.height.equalTo(35)
        }
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
//        self.tableView.separatorStyle = .none
        self.tableView.showsVerticalScrollIndicator = false
        self.tableView.showsHorizontalScrollIndicator = false
        self.tableView.register(SignedAppsCell.self, forCellReuseIdentifier: SignedAppsCell.cellIdentifier())
        self.tableView.setEmptyDataSet(title: nil, descriptionString: nil, image: UIImage(named: "file-storage"))
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.top.equalTo(self.segmentedControl.snp.bottom).offset(7.5)
            maker.left.right.equalTo(0)
            maker.bottom.equalTo(0)
        }
    }
    
    func segmentIndexChange(_ value: Int) {
        self.segmentIndex = value
        self.segmentedControl.selectedSegmentIndex = self.segmentIndex
        self.loadAppsData()
    }

    @objc
    func segmentedControlChange(sender: UISegmentedControl) {
        self.segmentIndex = sender.selectedSegmentIndex
        self.loadAppsData()
    }
    
}

extension SignedAppsViewController: QMUITableViewDelegate, QMUITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return segmentIndex == 0 ? 60 : SignedAppsCell.cellHeight()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return segmentIndex == 0 ? appLibraryList.count : signedAppList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if segmentIndex == 0 {
            let identifier = "cell"
            var cell = tableView.dequeueReusableCell(withIdentifier: identifier)
            if (cell == nil) {
                cell = QMUITableViewCell(for: tableView, with: .subtitle, reuseIdentifier: identifier)
                cell?.backgroundColor = .white
                cell?.selectionStyle = .none
                cell?.textLabel?.font = UIFont.medium(aSize: 14)
                cell?.textLabel?.textColor = kTextColor
                cell?.detailTextLabel?.font = UIFont.regular(aSize: 12)
                cell?.detailTextLabel?.textColor = kSubtextColor
                cell?.detailTextLabel?.numberOfLines = 0
            }
            let appLibraryModel = self.appLibraryList[indexPath.row]
            let fileURL = FileManager.default.appLibraryDirectory.appendingPathComponent("\(appLibraryModel.key)/\(appLibraryModel.appBundleFileName)")
            let application = ABApplication.init(fileURL: fileURL)!
            cell?.imageView?.image = application.icon?.resize(toWidth: 40)?.qmui_image(withClippedCornerRadius: 10)
            cell?.textLabel?.text = "\(application.fileURL.lastPathComponent) - \(application.name)"
            cell?.detailTextLabel?.text = "v\(application.version) - \(application.bundleIdentifier) - \(appLibraryModel.importDate)"
            cell?.accessoryType = .disclosureIndicator
            return cell!
                    
        } else {
            let cell: SignedAppsCell = tableView.dequeueReusableCell(withIdentifier: SignedAppsCell.cellIdentifier()) as! SignedAppsCell
            let model = self.signedAppList[indexPath.row]
            cell.configCell(model)
            cell.accessoryType = model.log.count > 0 ? .detailButton : .none
            cell.installApp = { app in
                let ipaURL = FileManager.default.signedAppsDirectory.appendingPathComponent(app.ipaName)
                let iconImage = UIImage(contentsOfFile: FileManager.default.appIconsDirectory.appendingPathComponent(app.iconName).path)
                AppManager.default.installApp(ipaURL: ipaURL, icon: iconImage, ipaInfo: "\(app.name)/\(app.bundleIdentifier)/\(app.version)")
            }
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        UIImpactFeedbackGenerator.init(style: .medium).impactOccurred()
        if segmentIndex == 0 {
            let appLibraryModel = self.appLibraryList[indexPath.row]
            let alertController = QMUIAlertController.init(title: appLibraryModel.appName, message: "签名期间请不要退出对话框，否则可能会导致签名失败", preferredStyle: .actionSheet)
            
            alertController.addAction(QMUIAlertAction.init(title: "签名", style: .default, handler: { _, _ in
                
                let application = ABApplication.init(fileURL: appLibraryModel.appBundleURL())!
                let controller = ReSignAppViewController.init(application: application, appSigner: AppSigner(), originIPAURL: appLibraryModel.ipaFileURL())
                controller.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(controller, animated: true)
                
//                do {
//                    let dictURL = FileManager.default.unzipIPADirectory.appendingPathComponent(UUID().uuidString)
//                    let finalURL = dictURL.appendingPathComponent(appLibraryModel.appBundleURL().lastPathComponent)
//                    try FileManager.default.createDirectory(at: dictURL, withIntermediateDirectories: true)
//                    try FileManager.default.copyItem(at: appLibraryModel.appBundleURL(), to: finalURL)
//                    let application = ABApplication.init(fileURL: finalURL)!
//                    let controller = ReSignAppViewController.init(application: application, appSigner: AppSigner(), originIPAURL: appLibraryModel.ipaFileURL())
//                    controller.hidesBottomBarWhenPushed = true
//                    self.navigationController?.pushViewController(controller, animated: true)
//                } catch let error {
//                    kAlert(error.localizedDescription)
//                }
             
            }))
            
            alertController.addAction(QMUIAlertAction.init(title: "删除", style: .destructive, handler: { _, _ in
                self.deleteApp(appLibraryModel, indexRow: indexPath.row)
            }))
                    
            alertController.addAction(QMUIAlertAction.init(title: "取消", style: .cancel, handler: nil))
            alertController.showWith(animated: true)
        } else {
            let app = self.signedAppList[indexPath.row]
            let ipaURL = FileManager.default.signedAppsDirectory.appendingPathComponent(app.ipaName)
            let alertController = QMUIAlertController.init(title: ipaURL.lastPathComponent, message: "安装期间请不要退出对话框，否则可能会导致安装失败", preferredStyle: .actionSheet)
            
            if app.deleted == false {
                alertController.addAction(QMUIAlertAction.init(title: "安装", style: .default, handler: { _, _ in
                    let iconImage = UIImage(contentsOfFile: FileManager.default.appIconsDirectory.appendingPathComponent(app.iconName).path)
                    AppManager.default.installApp(ipaURL: ipaURL, icon: iconImage, ipaInfo: "\(app.name)/\(app.bundleIdentifier)/\(app.version)")
                }))
                alertController.addAction(QMUIAlertAction.init(title: "重新签名", style: .default, handler: { _, _ in
                    let hud = QMUITips.showProgressView(self.view, status: "正在解压IPA")
                    Async.main(after: 0.1, {
                        let appSigner = AppSigner()
                        appSigner.unzipAppBundle(at: ipaURL,
                                                 outputDirectoryURL: FileManager.default.unzipIPADirectory.appendingPathComponent(UUID().uuidString, isDirectory: true),
                                                 progressHandler: { entry, zipInfo, entryNumber, total in
                            hud.setProgress(CGFloat(entryNumber)/CGFloat(total), animated: true)
                        },
                                                 completionHandler: { (success, application, error) in
                            hud.removeFromSuperview()
                            if let application = application {
                                let controller = ReSignAppViewController.init(application: application, appSigner: appSigner, originIPAURL: ipaURL)
                                controller.hidesBottomBarWhenPushed = true
                                self.navigationController?.pushViewController(controller, animated: true)
                            } else {
                                kAlert("无法读取应用信息，不受支持的格式。")
                            }
                        })
                    })
                }))
            }
            
            alertController.addAction(QMUIAlertAction.init(title: "分享", style: .default, handler: { _, _ in
                self.shareApp(app)
            }))

            alertController.addAction(QMUIAlertAction.init(title: "删除", style: .destructive, handler: { _, _ in
                self.deleteApp(app, indexRow: indexPath.row)
            }))
                    
            alertController.addAction(QMUIAlertAction.init(title: "取消", style: .cancel, handler: nil))
            alertController.showWith(animated: true)
        }
    }

    
    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        if segmentIndex == 1 {
            let model = self.signedAppList[indexPath.row]
            var logs: [NSAttributedString] = []
            for log in model.log.split(separator: "\n") {
                logs.append(NSAttributedString.init(string: "\(log)", attributes: nil))
            }
            
            let logViewController = LogViewController()
            logViewController.logs = logs
            let popupController = STPopupController(rootViewController: logViewController)
            popupController.style = .formSheet
            popupController.hidesCloseButton = true
            popupController.containerView.layer.cornerRadius = 5
            popupController.present(in: self)
            Async.main(after: 0.5) {
                logViewController.loggingFinish()
            }
        }
       
    }
}

extension SignedAppsViewController {
    
    func loadAppsData() {
        self.appLibraryList.removeAll()
        
        if let results: [YTKKeyValueItem] = Client.shared.store?.getAllItems(fromTable: kAppLibraryTableName) as? [YTKKeyValueItem] {
            for item in results {
                if let array: [String] = item.itemObject as? [String] {
                    if array.count > 0 {
                        if let model = AppLibraryModel.deserialize(from: array.first) {
                            if let _ = ABApplication(fileURL: model.appBundleURL()) {
                                print(message: model.appBundleURL().path)
                                self.appLibraryList.append(model)
                            } else {
                                model.deleted = true
                                Client.shared.store?.deleteObject(byId: model.key, fromTable: kAppLibraryTableName)
                            }
                        }
                    }
                }
            }
        }
        self.appLibraryList.reverse()
    
        self.signedAppList.removeAll()
        if let results: [YTKKeyValueItem] = Client.shared.store?.getAllItems(fromTable: kSignedAppTableName) as? [YTKKeyValueItem] {
            for item in results {
                if let array: [String] = item.itemObject as? [String] {
                    if array.count > 0 {
                        if let model = SignedAppModel.deserialize(from: array.first) {
                            if model.ipaName.count > 0 {
                                if FileManager.default.fileExists(atPath: FileManager.default.signedAppsDirectory.appendingPathComponent(model.ipaName).path) == false {
                                    model.deleted = true
                                }
                                self.signedAppList.append(model)
                            }
                        }
                    }
                }
            }
            self.signedAppList.sort { (v1, v2) -> Bool in
                return v1.signedDate > v2.signedDate
            }
        }
        self.tableView.reloadData()
    }
    
    func deleteApp(_ app: AppLibraryModel, indexRow: Int) {
        QMUITips.showLoading(in: self.view).whiteStyle()
        Async.background {
            do {
                try FileManager.default.removeItem(at: FileManager.default.appLibraryDirectory.appendingPathComponent(app.key))
//                try FileManager.default.removeItem(at: app.appBundleURL())
//                try FileManager.default.removeItem(at: app.ipaFileURL())
            } catch let error {
                print(message: error.localizedDescription)
            }
        } .main {
            QMUITips.hideAllTips()
            Client.shared.store?.deleteObject(byId: app.key, fromTable: kAppLibraryTableName)
            self.appLibraryList.remove(at: indexRow)
            self.tableView.reloadData()
        }
    }
    
    func deleteApp(_ app: SignedAppModel, indexRow: Int) {
        QMUITips.showLoading(in: self.view).whiteStyle()
        let ipaURL = FileManager.default.signedAppsDirectory.appendingPathComponent(app.ipaName)
        Async.background {
            do {
                try FileManager.default.removeItem(at: ipaURL)
            } catch let error {
                print(message: error.localizedDescription)
            }
        } .main {
            QMUITips.hideAllTips()
            Client.shared.store?.deleteObject(byId: app.ipaName, fromTable: kSignedAppTableName)
            self.signedAppList.remove(at: indexRow)
            self.tableView.reloadData()
        }
    }
    
    func shareApp(_ app: SignedAppModel) {
        let ipaURL = FileManager.default.signedAppsDirectory.appendingPathComponent(app.ipaName)
        let activityVC = UIActivityViewController(activityItems: [ipaURL], applicationActivities: nil)
        self.present(activityVC, animated: true, completion: nil)
    }
    
}


