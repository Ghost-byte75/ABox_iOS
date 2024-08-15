import UIKit
import HandyJSON
import Async

class SignedIPAListViewController: QMUICommonTableViewController {

    var udid: String?
    var ipaList: [SignedIPAModel] = []
    var pageNum = 1

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "📝 已签名IPA"
        if let udid = udid {
            self.titleView?.style = .subTitleVertical
            self.titleView?.subtitle = udid
        }

        // Do any additional setup after loading the view.
        self.signedIPAListRequest()
  
    }
    
    override func initTableView() {
        super.initTableView()
        self.tableView.setEmptyDataSet(title: "暂无数据", descriptionString: nil, image: nil)
        self.tableView.mj_header = MJRefreshNormalHeader.init(refreshingBlock: { [unowned self] in
            self.pageNum = 1
            self.signedIPAListRequest()
        })
        
        self.tableView.mj_footer = MJRefreshAutoFooter.init(refreshingBlock: {[unowned self] in
            self.pageNum = self.pageNum + 1
            self.signedIPAListRequest()
        })
        
    }
    
    func signedIPAListRequest() {
        let parameters: [String: Any] = ["pageNum": self.pageNum]
        API.default.request(url: "/signedIPA/list", parameters: parameters) { [unowned self] result in
            self.tableView.mj_header?.endRefreshing()
            self.tableView.mj_footer?.endRefreshing()
            if let models: [SignedIPAModel] = [SignedIPAModel].deserialize(from: result as? String) as? [SignedIPAModel] {
                if self.pageNum == 1 {
                    self.ipaList.removeAll()
                }
                self.ipaList = self.ipaList + models
                self.tableView.reloadData()
            }
        } failure: { error in
            self.tableView.mj_header?.endRefreshing()
            self.tableView.mj_footer?.endRefreshing()
            kAlert(error)
        }
    }
    
}

extension SignedIPAListViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ipaList.count
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
        }
        let model = self.ipaList[indexPath.row]
        cell?.textLabel?.text = "应用名字：\(model.name)"
        cell?.detailTextLabel?.text = "应用版本：\(model.version)\n应用BundleID：\(model.bundleId)\n签名时间：\(model.created)\n证书：\(model.certificateName)\n描述文件：\(model.profileName)\n设备UDID：\(model.device)\nABox版本：\(model.aboxVersion)"
        cell?.accessoryType = model.log.count > 0 ? .detailButton : .none
        return cell!
    
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return kAutoLayoutWidth(210)
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 10
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = self.ipaList[indexPath.row]
        API.default.request(url: "/device", method: .get, parameters: ["deviceUDID": model.device]) { result in
            if let device = ABoxDevice.deserialize(from: result as? String) {
                let controller = DeviceInfoViewController()
                controller.device = device
                self.navigationController?.pushViewController(controller, animated: true)
            }
        } failure: { error in
            kAlert(error)
        }
    }
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        let model = self.ipaList[indexPath.row]
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

class SignedIPAModel: HandyJSON {
    
    var name = ""
    var version = ""
    var created = ""
    var bundleId = ""
    var certificateName = ""
    var profileName = ""
    var device = ""
    var aboxVersion = ""
    var log = ""
    
    required init() {}
}
