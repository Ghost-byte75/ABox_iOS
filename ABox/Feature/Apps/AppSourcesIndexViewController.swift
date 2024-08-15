import UIKit
import RxAlamofire

class AppSourcesIndexViewController: AppsViewController {
    
    var appSource: AppSourceModel = AppSourceModel()
    let tableView = QMUITableView.init(frame: CGRect.zero, style: .grouped)

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.getAppList()
    }
    
    override func initSubviews() {
        super.initSubviews()
        self.title = self.appSource.name
        prepareTableView()
    }
    
    override func setupNavigationItems() {

    }

    func prepareTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.setEmptyDataSet(title: "暂无数据", descriptionString: nil, image: nil)
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.register(AppsTableViewCell.self, forCellReuseIdentifier: AppsTableViewCell.cellIdentifier())
        tableView.mj_header = MJRefreshNormalHeader.init(refreshingBlock: { [unowned self] in
            self.getAppList()
        })
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(self.view)
        }
    }
    
    override func getAppList() {
        SourceAPI.default.request(url: self.appSource.sourceURL) { appSource in
            self.appSource = appSource
            self.tableView.reloadData()
            self.tableView.mj_header?.endRefreshing()
        } failure: { error in
            self.tableView.mj_header?.endRefreshing()
            print(message: error)
        }
    }
    
    override func unlockAppSource(_ app: AppModel) {
        let alertController = QMUIAlertController.init(title: "来自“\(appSource.name)”的消息", message: "\n需要使用解锁码，任意解锁一个即全部解锁", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.layer.cornerRadius = 5
            textField.keyboardType = .URL
        }
        alertController.addCancelAction()
        alertController.addAction(QMUIAlertAction(title: "获取解锁码", style: .destructive, handler: { myAlertController, myAlertAction in
            if let payURL = URL(string: self.appSource.payURL) {
                self.openURLWithSafari(payURL)
            }
        }))
        alertController.addAction(QMUIAlertAction(title: "解锁", style: .default, handler: { myAlertController, myAlertAction in
            if let textField = myAlertController.textFields?.first {
                if let text = textField.text {
                    self.activateAppSource(code: text, source: self.appSource)
                }
            }
        }))
        alertController.showWith(animated: true)
    }

}

extension AppSourcesIndexViewController {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 1 : self.appSource.apps.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            let heigit = UITableViewCell.cellHeight(text: appSource.message, width: kUIScreenWidth - 40, lineHiehgt: 20, font: UIFont.regular(aSize: 13.5))
            return max(heigit, 60)
        } else {
            let model = self.appSource.apps[indexPath.row]
            if model.cellHeight < 10 {
                let cellHeight = AppsTableViewCell.cellHeight(appInfo: model.versionDescription)
                model.cellHeight = Float(cellHeight)
                return cellHeight
            } else {
                return CGFloat(model.cellHeight)
            }
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cellID = "cell"
            var cell = tableView.dequeueReusableCell(withIdentifier: cellID)
            if cell == nil {
                cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellID)
                cell?.selectionStyle = .none
                cell?.detailTextLabel?.font = UIFont.regular(aSize: 13.5)
                cell?.detailTextLabel?.textColor = kRGBColor(51, 51, 51)
                cell?.detailTextLabel?.numberOfLines = 0
            }
            cell?.detailTextLabel?.text = appSource.message
            return cell!
        } else {
            let cell: AppsTableViewCell = tableView.dequeueReusableCell(withIdentifier: AppsTableViewCell.cellIdentifier()) as! AppsTableViewCell
            
            let model: AppModel = self.appSource.apps[indexPath.row]
            cell.configCell(model)
            cell.openURL = { [weak self] url in
                self?.openURLWithSafari(url)
            }
            cell.openApp = { [weak self] app in
                self?.openApp(app)
            }
            return cell
        }
    }

}
