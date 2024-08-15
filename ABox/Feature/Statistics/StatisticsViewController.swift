import UIKit
import Async

class StatisticsViewController: QMUICommonTableViewController {
    
    var cellTitles = ["📱 用户设备列表",
                      "🎟️ UDID列表",
                      "📝 已签名IPA",
                      "🔐 管理解锁码"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.title = "统计"
    }
    
    override func setupNavigationItems() {
        super.setupNavigationItems()
    }

}


extension StatisticsViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellTitles.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "cell"
        var cell = tableView.dequeueReusableCell(withIdentifier: identifier)
        if cell == nil {
            cell = QMUITableViewCell(for: tableView, with: .value1, reuseIdentifier: identifier)
            cell?.selectionStyle = .none
            cell?.textLabel?.font = UIFont.medium(aSize: 14)
            cell?.textLabel?.textColor = kTextColor
            cell?.detailTextLabel?.font = UIFont.regular(aSize: 13)
            cell?.detailTextLabel?.textColor = kTextColor
            cell?.accessoryType = .disclosureIndicator
        }
      
        cell?.textLabel?.text = cellTitles[indexPath.row]
        return cell!
    
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            let controller = DeviceListViewController.init(style: .grouped)
            self.navigationController?.pushViewController(controller, animated: true)
        } else if indexPath.row == 1 {
            let controller = UDIDListViewController.init(style: .grouped)
            self.navigationController?.pushViewController(controller, animated: true)
        } else if indexPath.row == 2 {
            let controller = SignedIPAListViewController.init(style: .grouped)
            self.navigationController?.pushViewController(controller, animated: true)
        } else {
            let controller = RedeemCodeViewController()
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 10
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
    
}



