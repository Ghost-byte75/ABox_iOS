import UIKit

class DeviceInfoViewController: QMUICommonTableViewController {
    
    var device: ABoxDevice = ABoxDevice()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = device.name

    }
    
    override func initTableView() {
        super.initTableView()
        self.view.backgroundColor = .white
    }
    
}

extension DeviceInfoViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
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
        cell?.textLabel?.text = device.udid
        var info = "设备型号：\(device.name)\n使用流量：\(String.fileSizeDesc(device.totalFlow))\n注册时间：\(device.created)\n启动时间：\(device.updated)\n是否越狱：\(device.jailbroken)\nABox版本：\(device.clientVersion)\n系统版本：\(device.osVersion)\n是否封禁：\(device.disable)"
      
        if device.remarks.count > 0 {
            info.append("\n备注：\(device.remarks)")
        }
        cell?.detailTextLabel?.text = info
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 250
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 10
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let controller = SignedIPAListViewController.init(style: .grouped)
        controller.udid = device.udid
        self.navigationController?.pushViewController(controller, animated: true)
    }
}
