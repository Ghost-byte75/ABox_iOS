import UIKit
import RxAlamofire
import RxSwift
import RxCocoa
import Async
import TYPagerController
import QMUIKit
import IOSSecuritySuite
import Material

class AppsViewController: ViewController {
    
    private var appSources: [AppSourceModel] = []
    private var allDataSource: [AppModel] = []
    private var tableDataSources: [[AppModel]] = []
    private var searchResults: [AppModel] = []
    private var mySearchController: QMUISearchController!
    private let pagerBar = TYTabPagerBar()
    private let pagerView = TYPagerView()
    private var pagerBarDataSoucre = ["默认", "最新", "应用", "游戏", "影音", "工具", "插件"];
    private let kAppCacheDataKey = "kAppData"
    private var selectApp: AppModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        //loadCache()
        getAppList()
        appCheckLastVersion()
        getCloudCerts()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if Client.shared.device.disable {
            exit(0)
        }
        if Client.shared.needRefreshAppList {
            Client.shared.needRefreshAppList = false
            self.getAppList()
        }
    }
    
    override func initSubviews() {
        super.initSubviews()
        self.edgesForExtendedLayout = .bottom
        preparePagerBar()
        preparePagerView()
    }
    
    override func setupNavigationItems() {
        super.setupNavigationItems()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: Icon.add, style: .plain, target: self, action: #selector(managerAppSource))
        
        mySearchController = QMUISearchController.init(contentsViewController: self)
        mySearchController.searchResultsDelegate = self
        mySearchController.hidesNavigationBarDuringPresentation = false
        mySearchController.tableView.register(AppsTableViewCell.self, forCellReuseIdentifier: AppsTableViewCell.cellIdentifier())
        mySearchController.tableView.tag = 999
        mySearchController.tableView.backgroundColor = kBackgroundColor
        mySearchController.tableView.separatorStyle = .none
        mySearchController.tableView.snp.makeConstraints { maker in
            maker.left.bottom.right.equalTo(0)
            maker.top.equalTo(self.qmui_navigationBarMaxYInViewCoordinator)
        }
        mySearchController.tableView.setEmptyDataSet(title: "暂无数据", descriptionString: nil, image: nil)
        mySearchController.searchBar.placeholder = "搜索"
        self.navigationItem.titleView = mySearchController?.searchBar
    }
    
    func preparePagerBar() {
        pagerBar.backgroundColor = .white
        pagerBar.layout.barStyle = .progressView
        pagerBar.layout.normalTextColor = kRGBColor(41, 41, 41)
        pagerBar.layout.normalTextFont = UIFont.bold(aSize: 15)
        pagerBar.layout.selectedTextColor = kRGBColor(1, 1, 1)
        pagerBar.layout.selectedTextFont = UIFont.bold(aSize: 18)
        pagerBar.layout.progressHeight = 4
        pagerBar.layout.progressWidth = 45
        pagerBar.layout.progressColor = kButtonColor
        pagerBar.dataSource = self
        pagerBar.delegate = self
        pagerBar.register(TYTabPagerBarCell.self, forCellWithReuseIdentifier: TYTabPagerBarCell.cellIdentifier())
        view.addSubview(pagerBar)
        pagerBar.snp.remakeConstraints { (make) in
            make.left.equalTo(view.snp.left)
            make.right.equalTo(view.snp.right)
            make.top.equalTo(0)
            make.height.equalTo(45)
        }
        pagerBar.reloadData()
    }
    
    func preparePagerView() {
        pagerView.dataSource = self
        pagerView.delegate = self
        view.addSubview(pagerView)
        pagerView.snp.remakeConstraints { (make) in
            make.left.equalTo(view.snp.left)
            make.right.equalTo(view.snp.right)
            make.top.equalTo(pagerBar.snp.bottom).offset(5)
            make.bottom.equalTo(kUI_IPHONEX ? -34 : 0)
        }
    }
    
    
    func getAppList() {
        self.appSources.removeAll()
        if let text = AppDefaults.shared.appSources {
            let urls = text.split(separator: ",")
            for url in urls {
                SourceAPI.default.request(url: String(url)) { appSource in
                    self.appSources.append(appSource)
                    self.reloadDataSource()
                } failure: { error in
                    print(error)
                }
            }
        }
       
    }
    
    func savaCache() {
        if self.allDataSource.count <= 0 {
            return
        }
        if let jsonString = self.allDataSource.toJSONString() {
            let encryptText = NSString.encryptAES(jsonString, key: AESNormalKey)
            UserDefaults.standard.setValue(encryptText, forKey: kAppCacheDataKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    func loadCache() {
        if let value: String = UserDefaults.standard.value(forKey: kAppCacheDataKey) as? String {
            let decryptText = NSString.decryptAES(value, key: AESNormalKey)
            if let models = [AppModel].deserialize(from: decryptText) {
                self.allDataSource = models as! [AppModel]
                self.reloadDataSource()
            }
        } else {
            self.showEmptyViewWithLoading()
        }
    }
    
    func reloadDataSource() {
        self.allDataSource.removeAll()
        for appSource in appSources {
            for app in appSource.apps {
                self.allDataSource.append(app)
            }
        }
        
        for appModel in self.allDataSource {
            appModel.cellHeight = Float(UITableViewCell.cellHeight(text: appModel.versionDescription, width: kUIScreenWidth - 40, lineHiehgt: 15, font: UIFont.regular(aSize: 12)) + 100)
        }

        if self.allDataSource.count > 0 {
            
            self.pagerBar.isHidden = false
            self.pagerView.isHidden = false
            self.tableDataSources.removeAll()
            self.tableDataSources.append(self.allDataSource.sorted(by: {$0.weigh > $1.weigh}))
            self.tableDataSources.append(self.allDataSource.sorted(by: {$0.versionDate > $1.versionDate}))
            
            for index in 1...5 {
                let v = self.allDataSource.filter({ app -> Bool in
                    return app.type == "\(index)"
                })
                self.tableDataSources.append(v)
            }
            self.pagerBar.reloadData()
            self.pagerView.reloadData()
        }
    }
    
    @objc
    func managerAppSource() {
        let controller = AppSourcesViewController()
        controller.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func unlockAppSource(_ app: AppModel) {
        var appSource: AppSourceModel?
        for source in appSources {
            if source.identifier == app.sourceIdentifier && app.sourceIdentifier.count > 0 {
                appSource = source
            }
        }
        
        if let appSource = appSource {
            let alertController = QMUIAlertController.init(title: "来自“\(appSource.name)”的消息", message: "\n需要使用解锁码，任意解锁一个即全部解锁", preferredStyle: .alert)
            alertController.addTextField { textField in
                textField.layer.cornerRadius = 5
                textField.keyboardType = .URL
            }
            alertController.addCancelAction()
            alertController.addAction(QMUIAlertAction(title: "获取解锁码", style: .destructive, handler: { myAlertController, myAlertAction in
                if let payURL = URL(string: appSource.payURL) {
                    self.openURLWithSafari(payURL)
                }
            }))
            alertController.addAction(QMUIAlertAction(title: "解锁", style: .default, handler: { myAlertController, myAlertAction in
                if let textField = myAlertController.textFields?.first {
                    if let text = textField.text {
                        self.activateAppSource(code: text, source: appSource)
                    }
                }
            }))
            alertController.showWith(animated: true)
        } else {
            kAlert("该软件源源不支持解锁。")
        }
    }
    
    func activateAppSource(code: String, source: AppSourceModel) {
        if code.count <= 0 {
            kAlert("请先输入解锁码")
            return
        }
        QMUITips.showLoading(in: self.view).whiteStyle()
        if let requestURL = URL(string: source.unlockURL) {
            RxAlamofire.requestString(.get, requestURL, parameters: ["udid": AppDefaults.shared.deviceUDID!,"code": code], headers: API.httpRqeusetHeaders()).subscribe { (response, responseString) in
                QMUITips.hideAllTips()
                print(message: "requestUrl:\(requestURL.absoluteString)\nresponse:\(responseString)")
                
                let data = responseString.data(using: String.Encoding.utf8)
                if let dict = try? JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [String: Any] {
                    // {"code":0,"msg":"解锁码不存在"}
                    if let msg: String = dict["msg"] as? String {
                        kAlert(msg)
                        if msg.contains("成功") {
                            self.getAppList()
                        }
                    }
                }
    
            } onError: { error in
                QMUITips.hideAllTips()
                kAlert(error.localizedDescription)
            }.disposed(by: disposeBag)
        } else {
            kAlert("软件源的解锁地址不正确。")
        }
    }
    
    
    func openApp(_ app: AppModel) {
        UIImpactFeedbackGenerator.init(style: .medium).impactOccurred()
        if AppDefaults.shared.deviceUDID == nil {
            let alertController = QMUIAlertController.init(title: "UDID", message: "请先获取UDID，下载配置描述文件后请在【设置】应用中安装。", preferredStyle: .actionSheet)
            alertController.addAction(QMUIAlertAction.init(title: "获取", style: .destructive, handler: { _, _ in
                //AppManager.default.getUDID()
                self.getUDIDWithSafari()
            }))
            alertController.addAction(QMUIAlertAction.init(title: "取消", style: .cancel, handler: nil))
            alertController.showWith(animated: true)
            return
        }
        
        if app.lock {
            self.unlockAppSource(app)
        } else {
            if app.downloaded() {
                self.signIPA(url: app.ipaURL())
            } else {
                if app.downloadURL.contains("lanzou") {
                    self.getLZdownloadURL(app)
                } else {
                    self.downloadIPA(app)
                }
            }
        }
 
    }
    
    func getLZdownloadURL(_ app: AppModel) {
        if app.downloadURL.contains(";") {
            let urls = app.downloadURL.split(separator: ";")
            let actionSheetView = QMUIAlertController(title: "请选择下载线路", message: "遇到线路不可用，更换其他线路下载", preferredStyle: .actionSheet)
            for i in 0..<urls.count {
                let url = urls[i]
                actionSheetView.addAction(QMUIAlertAction(title: "线路\(i+1)", style: .default, handler: { _, _ in
                    let webVC = WebViewController(url: URL(string: String(url))!)
                    webVC.hidesBottomBarWhenPushed = true
                    webVC.completionWithURL = { [unowned self] ipaURL in
                        print(message: ipaURL.absoluteString)
                        app.downloadURL = ipaURL.absoluteString
                        self.downloadIPA(app)
                    }
                    self.navigationController?.pushViewController(webVC, animated: true)
                }))
                
            }
            actionSheetView.addCancelAction()
            actionSheetView.showWith(animated: true)
        } else {
            let webVC = WebViewController(url: URL(string: app.downloadURL)!)
            webVC.hidesBottomBarWhenPushed = true
            webVC.completionWithURL = { [unowned self] ipaURL in
                print(message: ipaURL.absoluteString)
                app.downloadURL = ipaURL.absoluteString
                self.downloadIPA(app)
            }
            self.navigationController?.pushViewController(webVC, animated: true)
        }
    }
    
    func downloadIPA(_ app: AppModel) {        
        UIImpactFeedbackGenerator.init(style: .medium).impactOccurred()
        if let tabBarViewController: TabBarViewController = self.tabBarController as? TabBarViewController {
            if let downloadUrl = URL(string: app.downloadURL) {
                let task = CreateDownloadTask()
                task.downloadURL = downloadUrl
                task.filename = app.fileName()
                task.appSource = app.sourceName
                tabBarViewController.downloadController.createTask = task
                Async.main(after: 0.1) {
                    self.tabBarController?.selectedIndex = 3
                }
               
//                let alertController = QMUIAlertController.init(title: app.name, message:"已添加至下载任务中" , preferredStyle: .alert)
//                alertController.addCancelAction()
//                alertController.addAction(QMUIAlertAction(title: "查看", style: .default, handler: { _, _ in
//                    self.tabBarController?.selectedIndex = 3
//                }))
//                alertController.showWith(animated: true)
            }
        } else {
            let _ = DownloadManager.shared.downloadIPA(urlStr: app.downloadURL, filename: app.fileName(), completionHandler: { fileURL, error in
                if let ipaURL = fileURL {
                    if ipaURL.absoluteString != app.ipaURL().absoluteString {
                        do {
                            try FileManager.default.moveItem(at: ipaURL, to: app.ipaURL())
                            self.signIPA(url: app.ipaURL())
                        } catch let error as NSError {
                            kAlert(error.localizedDescription)
                        }
                    } else {
                        self.signIPA(url: app.ipaURL())
                    }
                } else {
                    if let error = error {
                        kAlert(error)
                    }
                }
            })
        }
      
        
    }
    
    func signIPA(url: URL) {
        if AppDefaults.shared.trollStoreEnable! {
            AppManager.default.trollStoreInstallApp(ipaURL: url)
        } else {
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
        }
    }
    
    func getCloudCerts() {
        if AppDefaults.shared.signingCertificate != nil {
            return
        }
        if let udid = AppDefaults.shared.deviceUDID {
            XZAPI.default.request(url: "/api/external/api/cert.htm", parameters: ["udid": udid]) { (result: [CloudCert]?) in
                if let list = result {
                    for cloudCert in list {
                        if let certData = Data.init(base64Encoded: cloudCert.p12Data), let profileData = Data(base64Encoded: cloudCert.profileData) {
                            if let altCert = ALTCertificate(p12Data: certData, password: cloudCert.certPwd) {
                                print(message: altCert)
                                AppDefaults.shared.signingCertificate = altCert.p12Data()
                                AppDefaults.shared.signingCertificateName = altCert.name
                                AppDefaults.shared.signingCertificateSerialNumber = altCert.serialNumber
                                AppDefaults.shared.signingCertificatePassword = nil
                                
                                let p12Name = "\(altCert.name).p12"
                                let p12SavePath = FileManager.default.certificatesDirectory.appendingPathComponent(p12Name).path
                                FileManager.default.createFile(atPath: p12SavePath, contents: altCert.p12Data(), attributes: nil)
                            }
                            if let altProfile = ALTProvisioningProfile(data: profileData) {
                                AppDefaults.shared.signingProvisioningProfile = altProfile.data
                                print(message: altProfile)
                                
                                let profileName = "\(altProfile.uuid).mobileprovision"
                                let profileSavePath = FileManager.default.profilesDirectory.appendingPathComponent(profileName).path
                                FileManager.default.createFile(atPath: profileSavePath, contents: profileData, attributes: nil)
                            }
                        }
                    }
                }
            } failure: { error in
                print(message: error)
            }
        }
    }
    
    func getNotice() {
        XZAPI.default.request(url: "/api/external/api/notice.htm") { (result: String?) in
            if let notice = result {
                print(message: notice)
                if notice.count > 0 {
                    let sha1 = String.sha1(string: notice)
                    if let appNoticeSha1 = AppDefaults.shared.appNoticeSha1 {
                        if sha1 == appNoticeSha1 {
                            return
                        }
                    }
                    kAlert("公告",message: notice)
                    AppDefaults.shared.appNoticeSha1 = sha1
                }
            }
        } failure: { error in
            print(message: error)
        }
    }
    
    func appCheckLastVersion() {
        XZAPI.default.request(url: "/api/external/api/version.htm") { (result: [String: String]?) in
            if let dict = result {
                print(message: dict)
                if let url = dict["url"], let content = dict["content"], let version = dict["version"] {
                    if url.count > 0 || content.count > 0 {
                        let alertController = QMUIAlertController.init(title: "更新提示", message: content, preferredStyle: .alert)
                        alertController.addCancelAction()
                        alertController.addAction(QMUIAlertAction(title: "更新", style: .default, handler: { _, _ in
                            if let downloadURL = URL(string: "\(url)?udid=\(AppDefaults.shared.deviceUDID!)") {
                                print(message: "downloadURL:\(downloadURL)")
                                if UIApplication.shared.canOpenURL(downloadURL) {
                                    UIApplication.shared.open(downloadURL, options: [:], completionHandler: nil)
                                } else {
                                    print("无法打开URL")
                                }
                            }
                        }))
                        alertController.showWith(animated: true)
                    }
                }
            } else {
                self.getNotice()
            }
        } failure: { error in
            print(message: error)
        }
    }
}

extension AppsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var model: AppModel!
        if tableView == self.mySearchController.tableView {
            model = self.searchResults[indexPath.row]
        } else {
            model = self.tableDataSources[tableView.tag][indexPath.row]
        }
        if model.cellHeight < 10 {
            let cellHeight = AppsTableViewCell.cellHeight(appInfo: model.versionDescription)
            model.cellHeight = Float(cellHeight)
            return cellHeight
            
        } else {
            return CGFloat(model.cellHeight)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.mySearchController.tableView {
            return searchResults.count
        }
        if self.tableDataSources.count == 0 {
            return 0
        }
        return self.tableDataSources[tableView.tag].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: AppsTableViewCell = tableView.dequeueReusableCell(withIdentifier: AppsTableViewCell.cellIdentifier()) as! AppsTableViewCell
        
        var model: AppModel!
        if tableView == self.mySearchController.tableView {
            model = self.searchResults[indexPath.row]
        } else {
            model = self.tableDataSources[tableView.tag][indexPath.row]
        }
        
        cell.configCell(model)
        cell.openURL = { [weak self] url in
            self?.openURLWithSafari(url)
        }
        cell.openApp = { [weak self] app in
            self?.openApp(app)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
}

extension AppsViewController: QMUISearchControllerDelegate {
    func searchController(_ searchController: QMUISearchController!, updateResultsForSearch searchString: String!) {
        if let searchText: String = searchString {
            if searchText.count > 0 {
                self.searchResults = allDataSource.filter { model -> Bool in
                    return model.name.lowercased().contains(searchText.lowercased()) || model.versionDescription.lowercased().contains(searchText.lowercased())
                }
            }
        }
        searchController.tableView.reloadData()
    }
    
    func willPresent(_ searchController: QMUISearchController!) {
        self.setNeedsStatusBarAppearanceUpdate()
        
    }
    
    func willDismiss(_ searchController: QMUISearchController!) {
        self.setNeedsStatusBarAppearanceUpdate()
    }
}

// MARK:- TYTabPagerBarDataSource
extension AppsViewController: TYTabPagerBarDataSource {
    
    func numberOfItemsInPagerTabBar() -> Int {
        return pagerBarDataSoucre.count
    }
    
    func pagerTabBar(_ pagerTabBar: TYTabPagerBar, cellForItemAt index: Int) -> UICollectionViewCell & TYTabPagerBarCellProtocol {
        let cell = pagerTabBar.dequeueReusableCell(withReuseIdentifier: TYTabPagerBarCell.cellIdentifier(), for: index)
        cell.titleLabel.text = pagerBarDataSoucre[index]
        return cell
    }
}

// MARK:- TYTabPagerBarDelegate
extension AppsViewController: TYTabPagerBarDelegate {
    func pagerTabBar(_ pagerTabBar: TYTabPagerBar, widthForItemAt index: Int) -> CGFloat {
        return 70
    }
    
    func pagerTabBar(_ pagerTabBar: TYTabPagerBar, didSelectItemAt index: Int) {
        self.pagerView.scrollToView(at: index, animate: true)
    }
}

// MARK:- TYPagerViewDataSource
extension AppsViewController: TYPagerViewDataSource {
    func numberOfViewsInPagerView() -> Int {
        return pagerBarDataSoucre.count
    }
    
    func pagerView(_ pagerView: TYPagerView, viewFor index: Int, prefetching: Bool) -> UIView {
        let tableView = UITableView.init(frame: CGRect.zero, style: .grouped)
        tableView.tag = index
        tableView.delegate = self
        tableView.dataSource = self
        tableView.setEmptyDataSet(title: "暂无数据", descriptionString: "点击右上角添加软件源", image: nil)
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.register(AppsTableViewCell.self, forCellReuseIdentifier: AppsTableViewCell.cellIdentifier())
        tableView.mj_header = MJRefreshNormalHeader.init(refreshingBlock: { [unowned self] in
            tableView.mj_header?.endRefreshing()
            self.getAppList()
        })
        return tableView;
        
    }
}

// MARK:- TYPagerViewDelegate
extension AppsViewController: TYPagerViewDelegate {
    func pagerView(_ pagerView: TYPagerView, transitionFrom fromIndex: Int, to toIndex: Int, animated: Bool) {
        self.pagerBar.scrollToItem(from: fromIndex, to: toIndex, animate: animated)
    }
    
    func pagerView(_ pagerView: TYPagerView, transitionFrom fromIndex: Int, to toIndex: Int, progress: CGFloat) {
        self.pagerBar.scrollToItem(from: fromIndex, to: toIndex, progress: progress)
    }
}

