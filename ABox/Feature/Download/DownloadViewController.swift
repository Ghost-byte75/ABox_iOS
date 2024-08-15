import UIKit
import Material
import Async

class CreateDownloadTask {
    open var downloadURL: URL!
    open var filename: String? = nil
    open var appSource: String? = nil
}

class DownloadViewController: ViewController {
    

    open var createTask: CreateDownloadTask? = nil

    fileprivate let tableView = QMUITableView.init(frame: CGRect.zero, style: .grouped)
    fileprivate let cellIdentifier = "DownloadCell"
    fileprivate var tasks: [DownloadTask] = []
    fileprivate var downloadURLs: [String] = []
    fileprivate var addTaskButton = Button()
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let task = self.createTask {
            self.addTask(downloadURL: task.downloadURL, filename: task.filename, appSource: task.appSource)
            self.createTask = nil
        }
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        getHistoryDownloadList()
    }
    

    override func initSubviews() {
        super.initSubviews()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.showsVerticalScrollIndicator = false
        self.tableView.showsHorizontalScrollIndicator = false
        self.tableView.setEmptyDataSet(title: nil, descriptionString: nil, image: UIImage(named: "file-storage"))
        self.tableView.register(DownloadTableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.left.top.right.equalTo(0)
            maker.bottom.equalTo(0)
        }
        
        addTaskButton.frame = CGRect(x: kUIScreenWidth - 70, y: kUIScreenHeight - 170, width: 55, height: 55)
        addTaskButton.backgroundColor = kButtonColor
        addTaskButton.layer.cornerRadius = 27.5
        addTaskButton.setImage(Icon.add?.qmui_image(withTintColor: .white), for: .normal)
        addTaskButton.addTarget(self, action: #selector(dragMoving(control:event:)), for: .touchDragInside)
        addTaskButton.addTarget(self, action: #selector(dragEnded(control:event:)), for: .touchDragOutside)
        addTaskButton.addTarget(self, action: #selector(addTaskButtonTapped), for: .touchUpInside)
        self.view.addSubview(addTaskButton)
    }
    
    @objc
    func addTaskButtonTapped() {
        UIImpactFeedbackGenerator.init(style: .medium).impactOccurred()
        let alertController = QMUIAlertController.init(title: "选择下载方式", message: nil, preferredStyle: .actionSheet)
        alertController.addAction(QMUIAlertAction.init(title: "从网络下载", style: .default, handler: { [unowned self] _, _ in
            self.showInputURLViewController(type: 0)
        }))
        alertController.addAction(QMUIAlertAction.init(title: "提取网页IPA资源", style: .default, handler: { [unowned self] _, _ in
            self.showInputURLViewController(type: 1)
        }))
        alertController.addAction(QMUIAlertAction.init(title: "取消", style: .cancel, handler: nil))
        alertController.showWith(animated: true)
    }
    
    func showInputURLViewController(type: Int) {
        let controller = InputURLViewController()
        controller.type = type
        let popupController = STPopupController(rootViewController: controller)
        popupController.style = .formSheet
        popupController.containerView.backgroundColor = .clear
        popupController.present(in: self)
        controller.completionWithURL = { [unowned self] url in
            if type == 0 {
                self.addTask(downloadURL: url)
            } else {
                self.addTaskFromWebController(url: url)
            }
            Client.shared.updateLog("下载文件[\(url)]")
        }
    }
    
    func addTaskFromWebController(url: URL) {
        let webVC = WebViewController(url: url)
        webVC.hidesBottomBarWhenPushed = true
        webVC.completionWithURL = { [unowned self] ipaURL in
            self.addTask(downloadURL: ipaURL)
        }
        self.navigationController?.pushViewController(webVC, animated: true)
    }
    
    func addTask(downloadURL: URL, filename: String? = nil, appSource: String? = nil) {
        if downloadURL.absoluteString.hasPrefix("itms-services") {
            self.downloadIPA(url: downloadURL)
        } else {
            if downloadURLs.contains(downloadURL.absoluteString) {
                kAlert("当前下载链接已存在")
                return
            }
            let task = DownloadTask()
            task.info.state = .downloading
            task.info.appSource = appSource
            task.info.downloadURL = downloadURL.absoluteString
            task.info.createDate = Date().toString(.custom("yyyy-MM-dd HH:mm"))
            task.info.filetype = downloadURL.pathExtension.lowercased()
            task.info.filename = filename
            task.startDownload()
            self.downloadURLs.append(downloadURL.absoluteString)
            self.tasks.insert(task, at: 0)
            self.tableView.reloadData()            
        }
    }
    
    func getHistoryDownloadList() {
        self.tasks.removeAll()
        if let results: [YTKKeyValueItem] = Client.shared.store?.getAllItems(fromTable: kDownloadTableName) as? [YTKKeyValueItem] {
            for item in results {
                if let array: [String] = item.itemObject as? [String] {
                    if array.count > 0 {
                        if let infoModel = DownloadTaskInfo.deserialize(from: array.first) {
                            let task = DownloadTask()
                            task.info = infoModel
                            if task.info.state == .finished {
                                if let fileName = task.info.filename {
                                    let url = FileManager.default.downloadDirectory.appendingPathComponent(fileName)
                                    if FileManager.default.fileExists(atPath: url.path) == false {
                                        task.info.state = .deleted
                                    }
                                }
                            } 
//                            else if task.info.state == .downloading || task.info.state == .paused {
//                                task.info.state = .downloading
//                                task.startDownload()
//                            }
                            
                            downloadURLs.append(task.info.downloadURL)
                            tasks.append(task)
                        }
                    }
                }
            }
            tasks.sort { (d1, d2) -> Bool in
                return d1.info.createDate > d2.info.createDate
            }
            self.tableView.reloadData()
        }
    }
    
    @objc
    func dragMoving(control: UIControl, event: UIEvent) {
        if let center = event.allTouches?.first?.location(in: self.view) {
            control.center = center
        }
    }
    
    @objc
    func dragEnded(control: UIControl, event: UIEvent) {
        if let center = event.allTouches?.first?.location(in: self.view) {
            control.center = center
        }
    }
    
    func deleteTask(task :DownloadTask, indexPath: IndexPath) {
        Client.shared.store?.deleteObject(byId: task.info.id, fromTable: kDownloadTableName)
        self.tasks.remove(at: indexPath.row)
        self.downloadURLs.remove(at: indexPath.row)
        self.tableView.reloadData()
        if let filename = task.info.filename {
            let fileURL = FileManager.default.downloadDirectory.appendingPathComponent(filename)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                do {
                    try FileManager.default.removeItem(at: fileURL)
                } catch let error {
                    print(message: error.localizedDescription)
                }
                
            }
        }
    }
    
    func handleDownload(task :DownloadTask, indexPath: IndexPath) {
        UIImpactFeedbackGenerator.init(style: .medium).impactOccurred()
        let alertController = QMUIAlertController.init(title: task.info.filename, message: nil, preferredStyle: .actionSheet)
        alertController.addCancelAction()
        alertController.addAction(QMUIAlertAction(title: "查看文件位置", style: .default, handler: { _, _ in
            let controller = FolderViewController()
            controller.indexFileURL = FileManager.default.downloadDirectory
            controller.title = "下载"
            controller.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(controller, animated: true)
        }))
        if task.info.filetype == "ipa" {
            alertController.addAction(QMUIAlertAction(title: "导入应用库", style: .default, handler: { _, _ in
                if let filename = task.info.filename {
                    let fileURL = FileManager.default.downloadDirectory.appendingPathComponent(filename)
                    if FileManager.default.fileExists(atPath: fileURL.path) {
                        let hud = QMUITips.showProgressView(kAPPKeyWindow!, status: "正在解压IPA")
                        Async.main(after: 0.1, {
                            let appSigner = AppSigner()
                            let key = UUID().uuidString
                            let toDirectoryURL = FileManager.default.appLibraryDirectory.appendingPathComponent(key, isDirectory: true)
                            appSigner.unzipAppBundle(at: fileURL,
                                                     outputDirectoryURL: toDirectoryURL,
                                                     progressHandler: { entry, zipInfo, entryNumber, total in
                                hud.setProgress(CGFloat(entryNumber)/CGFloat(total), animated: true)
                            },
                                                     completionHandler: { (success, application, error) in
                                hud.removeFromSuperview()
                                if let application = application {
                                    AppLibraryModel.importApplication(application, key: key, ipaURL: fileURL, toDirectoryURL: toDirectoryURL)
                                } else {
                                    kAlert("无法读取应用信息，不受支持的格式。")
                                }
                            })
                        })
                    }
                }
            }))
        }
        
        alertController.addAction(QMUIAlertAction(title: "分享", style: .default, handler: { _, _ in
            if let filename = task.info.filename {
                let fileURL = FileManager.default.downloadDirectory.appendingPathComponent(filename)
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
                    self.present(activityVC, animated: true, completion: nil)
                }
            }
        }))
        
        alertController.addAction(QMUIAlertAction(title: "删除", style: .destructive, handler: { _, _ in
            self.deleteTask(task: task, indexPath: indexPath)
        }))
        
        alertController.showWith(animated: true)
    }
}

extension DownloadViewController: QMUITableViewDelegate, QMUITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 95
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let task = tasks[indexPath.row]
        if let cell: DownloadTableViewCell = tableView.dequeueReusableCell(withIdentifier: task.info.id) as? DownloadTableViewCell {
            return cell
        } else {
            let cell: DownloadTableViewCell = DownloadTableViewCell(for: tableView, withReuseIdentifier: task.info.id)
            cell.configCell(task)
            cell.openFileURLHandle = { [unowned self] t in
                self.handleDownload(task: t, indexPath: indexPath)
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

    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let task = self.tasks[indexPath.row]
        let deleteAction = UITableViewRowAction.init(style: .destructive, title: "删除") { [unowned self] _, i in
            self.deleteTask(task: task, indexPath: indexPath)
        }
        deleteAction.backgroundColor = kRGBColor(243, 64, 54)
        return [deleteAction]
    }  
}


extension DownloadViewController {
    
    func downloadIPA(url: URL) {
        if let plistURLStr = url.parametersFromQueryString?["url"] {
            let _ = DownloadManager.shared.download(urlStr: plistURLStr) { fileURL in
                if let dict = NSDictionary(contentsOf: fileURL) {
                    if let arr: NSArray = dict["items"] as? NSArray {
                        if let item: NSDictionary = arr[0] as? NSDictionary {
                            do {
                                let data = try JSONSerialization.data(withJSONObject: item, options: .prettyPrinted)
                                let json = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
                                if let json = json {
                                    if let assets = [Asset].deserialize(from: json as String, designatedPath: "assets") {
                                        for asset in assets {
                                            if let a = asset {
                                                if a.kind == "software-package" {
                                                    self.addTask(downloadURL: URL(string: a.url)!)
                                                }
                                            }
                                        }
                                    }
                                }
                            } catch let error {
                                kAlert(error.localizedDescription)
                            }
                        }
                    }
                }
            } failure: { error in
                kAlert(error)
            }
        }
    }
}
