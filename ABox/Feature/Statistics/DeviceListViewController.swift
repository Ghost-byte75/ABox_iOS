import UIKit
import HandyJSON

class DeviceListViewController: QMUICommonTableViewController {
    
    var allDataSource: [ABoxDevice] = []
    var deviceList: [ABoxDevice] = []

    private var selectedSegmentIndex = 0
    private var segmentedControl: UISegmentedControl!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "📱 已注册设备"
        self.titleView?.style = .subTitleVertical
        // Do any additional setup after loading the view.
        QMUITips.showLoading(in: self.view)
        API.default.request(url: "/device/list") { [unowned self] result in
            if let models = [ABoxDevice].deserialize(from: result as? String) {
                self.allDataSource = models as! [ABoxDevice]
                self.reloadTable(segmentIndex: selectedSegmentIndex)
                self.titleView?.subtitle = "\(models.count)"

            }
            QMUITips.hideAllTips()
        } failure: { error in
            QMUITips.hideAllTips()
        }
    }
    
    override func initTableView() {
        super.initTableView()
        self.tableView.setEmptyDataSet(title: "暂无数据", descriptionString: nil, image: nil)
        let tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: kUIScreenWidth, height: 50))
        let items = ["注册时间", "启动时间", "使用流量"]
        self.segmentedControl = UISegmentedControl.init(items: items)
        tableHeaderView.addSubview(self.segmentedControl)
        self.segmentedControl.snp.makeConstraints { maker in
            maker.width.equalTo(items.count * 85)
            maker.height.equalTo(30)
            maker.centerX.equalTo(tableHeaderView)
            maker.top.equalTo(12.5)
        }
        self.segmentedControl.selectedSegmentIndex = selectedSegmentIndex
        self.segmentedControl.addTarget(self, action: #selector(segmentedControlChange(sender:)), for: .valueChanged)
        tableView.tableHeaderView = tableHeaderView
    }
    
    @objc
    func segmentedControlChange(sender: UISegmentedControl) {
        self.selectedSegmentIndex = sender.selectedSegmentIndex
        self.reloadTable(segmentIndex: self.selectedSegmentIndex)
    }
    
    func reloadTable(segmentIndex: Int) {
        self.deviceList = self.allDataSource
        if segmentIndex == 0 {
            self.deviceList.sort(by: {$0.created > $1.created})
        } else if segmentIndex == 1 {
            self.deviceList.sort(by: {$0.updated > $1.updated})
        } else if segmentIndex == 2 {
            self.deviceList.sort(by: {$0.totalFlow > $1.totalFlow})
        }
        tableView.reloadData()
    }
    
}

extension DeviceListViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return deviceList.count
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
        let device = self.deviceList[indexPath.row]
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
        let device = self.deviceList[indexPath.row]
        let controller = SignedIPAListViewController.init(style: .grouped)
        controller.udid = device.udid
        self.navigationController?.pushViewController(controller, animated: true)
    }
}
