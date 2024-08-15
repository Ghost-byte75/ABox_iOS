import UIKit
import RxAlamofire

class AppSourcesViewController: ViewController {
    
    var appSources: [AppSourceModel] = []
    let tableView = QMUITableView.init(frame: CGRect.zero, style: .grouped)

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "软件源"
        self.getAppSourcesData()
    }
    
    func getAppSourcesData() {
        if let text = AppDefaults.shared.appSources {
            appSources.removeAll()
            let urls = text.split(separator: ",")
            for url in urls {
                SourceAPI.default.request(url: String(url)) { appSource in
                    self.appSources.append(appSource)
                    self.tableView.reloadData()
                } failure: { error in
                    print(message: error)
                }
            }
        }
    }
    
    func addAppSource(url: String) {
        if !url.hasPrefix("http") {
            kAlert("输入的软件源不合法。")
            return
        }
        
        if let s = AppDefaults.shared.appSources {
            if s.contains(url) {
                kAlert("该软件源已存在。")
                return
            }
        }
        let requestURL = String(url)
        SourceAPI.default.request(url: requestURL) { appSource in
            self.appSources.append(appSource)
            self.tableView.reloadData()
            var s = ""
            if let value = AppDefaults.shared.appSources {
                s = value
            }
            s = s + appSource.sourceURL + ","
            AppDefaults.shared.appSources = s            
            Client.shared.needRefreshAppList = true
        } failure: { error in
            kAlert(error)
        }
    }
    
    override func initSubviews() {
        super.initSubviews()
        prepareTableView()
    }
    

    func prepareTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorColor = kSeparatorColor
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.register(AppSourceTableViewCell.self, forCellReuseIdentifier: AppSourceTableViewCell.cellIdentifier())
        tableView.mj_header = MJRefreshNormalHeader.init(refreshingBlock: { [unowned self] in
            tableView.mj_header?.endRefreshing()
            self.getAppSourcesData()
        })
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(self.view)
        }
    }

}

extension AppSourcesViewController: QMUITableViewDelegate, QMUITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 1 : self.appSources.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.section == 0 ? 60 : 55
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cellID = "cell"
            var cell = tableView.dequeueReusableCell(withIdentifier: cellID)
            if cell == nil {
                cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellID)
                cell?.selectionStyle = .none
                cell?.textLabel?.font = UIFont.regular(aSize: 14.5)
                cell?.textLabel?.textColor = kTextColor
                cell?.detailTextLabel?.font = UIFont.light(aSize: 12)
                cell?.detailTextLabel?.textColor = kSubtextColor
            }
            cell?.imageView?.image = UIImage(named: "ic_plus150x150")?.resize(toWidth: 25)
            cell?.textLabel?.text = "添加软件源"
            cell?.detailTextLabel?.text = "请输入软件源链接"
            return cell!
        } else {
            let cell: AppSourceTableViewCell = tableView.dequeueReusableCell(withIdentifier: AppSourceTableViewCell.cellIdentifier()) as! AppSourceTableViewCell
            let appSource = self.appSources[indexPath.row]
            cell.configCell(appSource)
            return cell
        }
     
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 1 ? (self.appSources.count <= 0 ? nil : "已添加的源") : nil
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 10 : 30
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            let alertController = QMUIAlertController.init(title: "添加软件源", message: "\n添加的软件源与\(kAppDisPlayName!)无关，请勿添加违法违规类软件源。\n如发现添加的软件源含侵权等违规内容请自行删除！\n点击添加则为同意此条款。", preferredStyle: .alert)
            alertController.addTextField { textField in
                textField.layer.cornerRadius = 5
                textField.keyboardType = .URL
            }
            alertController.addCancelAction()
            alertController.addAction(QMUIAlertAction(title: "添加", style: .default, handler: { myAlertController, myAlertAction in
                if let textField = myAlertController.textFields?.first {
                    if let text = textField.text {
                        self.addAppSource(url: text.removeAllSapce)
                    }
                }
            }))
            alertController.showWith(animated: true)
        } else {
            let appSource = self.appSources[indexPath.row]
            let controller = AppSourcesIndexViewController()
            controller.appSource = appSource
            self.navigationController?.pushViewController(controller, animated: true)
            
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction.init(style: .destructive, title: "删除") { [unowned self] _, i in
            UIImpactFeedbackGenerator.init(style: .medium).impactOccurred()
            let appSource = self.appSources[indexPath.row]
            let urls = AppDefaults.shared.appSources!.split(separator: ",")
            var list: [String] = []
            for url in urls {
                if String(url) != appSource.sourceURL {
                    list.append(String(url))
                }
            }
            var s = ""
            for url in list {
                s = s + url + ","
            }
            AppDefaults.shared.appSources = s
            self.appSources.remove(at: indexPath.row)
            self.tableView.reloadData()
            Client.shared.needRefreshAppList = true
        }
        deleteAction.backgroundColor = kRGBColor(243, 64, 54)
        return [deleteAction]
    }
}
