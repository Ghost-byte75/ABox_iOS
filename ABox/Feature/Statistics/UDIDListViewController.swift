import UIKit
import HandyJSON

class UDIDListViewController: QMUICommonTableViewController {
    
    var udidList: [UDIDModel] = []
    var pageNum = 1

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "🎟️ UDID列表"
        udidListRequest()
    }
    
    func udidListRequest() {
        API.default.request(url: "/udid/list") { [unowned self] result in
            if let models: [UDIDModel] = [UDIDModel].deserialize(from: result as? [Any]) as? [UDIDModel]{
                self.tableView.mj_header?.endRefreshing()
                self.tableView.mj_footer?.endRefreshing()
                if self.pageNum == 1 {
                    self.udidList.removeAll()
                }
                self.udidList = self.udidList + models
                self.tableView.reloadData()
            }
        } failure: { error in
            self.tableView.mj_header?.endRefreshing()
            self.tableView.mj_footer?.endRefreshing()
            kAlert(error)
        }
    }

    override func initTableView() {
        super.initTableView()
        self.tableView.setEmptyDataSet(title: "暂无数据", descriptionString: nil, image: nil)
        self.tableView.mj_header = MJRefreshNormalHeader.init(refreshingBlock: { [unowned self] in
            self.pageNum = 1
            self.udidListRequest()
        })
        
        self.tableView.mj_footer = MJRefreshAutoFooter.init(refreshingBlock: {[unowned self] in
            self.pageNum = self.pageNum + 1
            self.udidListRequest()
        })
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return udidList.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "cell"
        var cell = tableView.dequeueReusableCell(withIdentifier: identifier)
        if cell == nil {
            cell = QMUITableViewCell(for: tableView, with: .subtitle, reuseIdentifier: identifier)
            cell?.selectionStyle = .none
            cell?.textLabel?.font = UIFont.medium(aSize: 14)
            cell?.textLabel?.textColor = kTextColor
            cell?.detailTextLabel?.font = UIFont.regular(aSize: 14)
            cell?.detailTextLabel?.textColor = kTextColor
            cell?.accessoryType = .none
            cell?.detailTextLabel?.numberOfLines = 0
            cell?.detailTextLabel?.adjustsFontSizeToFitWidth = true
        }
        let model = self.udidList[indexPath.row]
   
        let info = "UDID：\(model.udid)\nIMEI：\(model.imei)\n设备型号：\(model.product)\n首次查询：\(model.created)\n最后查询：\(model.updated)"
        cell?.detailTextLabel?.text = info
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 10
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = self.udidList[indexPath.row]
        UIPasteboard.general.string = model.udid
        QMUITips.showSucceed("已复制UDID\n\(model.udid)", in: self.view).whiteStyle()
    }

}

class UDIDModel: HandyJSON {
    
    var udid = ""
    var imei = ""
    var product = ""
    var created = ""
    var updated = ""

    required init() {}
}
