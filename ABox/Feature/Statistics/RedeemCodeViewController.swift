import UIKit
import HandyJSON
import Material

class RedeemCode: HandyJSON {
    
    var code = ""
    var device = ""
    var created = ""
    var activatdTime = ""
    var activatd = false
    
    required init() {}
}

class RedeemCodeViewController: QMUICommonTableViewController {
    
    var allCodeList: [RedeemCode] = []
    var codeList: [RedeemCode] = []

    private var selectedSegmentIndex = 0
    private var segmentedControl: UISegmentedControl!
    private var addCodeButton = Button()

    override func viewDidLoad() {
        super.viewDidLoad()

        addCodeButton.frame = CGRect(x: kUIScreenWidth - 70, y: kUIScreenHeight - 170, width: 55, height: 55)
        addCodeButton.backgroundColor = kButtonColor
        addCodeButton.layer.cornerRadius = 27.5
        addCodeButton.setImage(Icon.add?.qmui_image(withTintColor: .white), for: .normal)
        addCodeButton.addTarget(self, action: #selector(addCodeButtonTapped), for: .touchUpInside)
        self.view.addSubview(addCodeButton)
        
        self.title = "🔐 解锁码"
        self.titleView?.style = .subTitleVertical
        self.requestAllData()
    }
    
    override func initTableView() {
        super.initTableView()
        self.tableView.setEmptyDataSet(title: "暂无数据", descriptionString: nil, image: nil)
        let tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: kUIScreenWidth, height: 50))
        let items = ["全部", "已使用", "未使用"]
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
        if segmentIndex == 0 {
            self.codeList = self.allCodeList
            
        } else if segmentIndex == 1 {
            self.codeList = self.allCodeList.filter({ code in
                return code.activatd
            })
        } else if segmentIndex == 2 {
            self.codeList = self.allCodeList.filter({ code in
                return !code.activatd
            })
        }
        self.codeList.sort(by: {$0.created > $1.created})
        self.tableView.reloadData()
        self.titleView?.subtitle = "\(self.codeList.count)"
    }
    
    func requestAllData() {
        QMUITips.showLoading(in: self.view)
        API.default.request(url: "/redeemCode/list") { [unowned self] result in
            if let models = [RedeemCode].deserialize(from: result as? String) {
                self.allCodeList = models as! [RedeemCode]
                self.reloadTable(segmentIndex: selectedSegmentIndex)
            }
            QMUITips.hideAllTips()
        } failure: { error in
            QMUITips.hideAllTips()
        }
    }
    
    func deleteCode(_ code: String) {
        QMUITips.showLoading(in: self.view)
        API.default.request(url: "/redeemCode", method: .delete, parameters: ["code": code]) { [unowned self] result in
            QMUITips.hideAllTips()
            self.requestAllData()
            kAlert("解锁码已删除「\(code)」")
        } failure: { error in
            QMUITips.hideAllTips()
            kAlert("解锁码删除失败\n\(error)")
        }
    }
    
    @objc
    func addCodeButtonTapped() {
        QMUITips.showLoading(in: self.view)
        API.default.request(url: "/redeemCode/create", method: .post, parameters: ["num": 10]) { [unowned self] result in
            QMUITips.hideAllTips()
            self.requestAllData()
            kAlert("解锁码添加成功")
        } failure: { error in
            QMUITips.hideAllTips()
            kAlert("解锁码添加失败\n\(error)")
        }
    }
    
}

extension RedeemCodeViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return codeList.count
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
        let redeemCode = self.codeList[indexPath.row]
        cell?.textLabel?.text = redeemCode.code
        var info = "状态：\(redeemCode.activatd ? "已使用" : "未使用")"
        if redeemCode.activatdTime.count > 0 {
            info.append("\n使用时间：\(redeemCode.activatdTime)")
        }
        if redeemCode.device.count > 0 {
            info.append("\n使用设备：\(redeemCode.device)")
        }
        info.append("\n创建时间：\(redeemCode.created)")
        cell?.detailTextLabel?.text = info
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let redeemCode = self.codeList[indexPath.row]
        return redeemCode.activatd ? 120 : 80
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let redeemCode = self.codeList[indexPath.row]
        if redeemCode.device.count > 0 {
            let controller = SignedIPAListViewController.init(style: .grouped)
            controller.udid = redeemCode.device
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let redeemCode = self.codeList[indexPath.row]
        let copyAction = UITableViewRowAction.init(style: .default, title: "复制") { _, i in
            UIImpactFeedbackGenerator.init(style: .medium).impactOccurred()
            UIPasteboard.general.string = redeemCode.code
            kAlert("已复制「\(redeemCode.code)」")
        }
        copyAction.backgroundColor = kButtonColor
        
        if !redeemCode.activatd {
            let deleteAction = UITableViewRowAction.init(style: .destructive, title: "删除") { [unowned self] _, i in
                UIImpactFeedbackGenerator.init(style: .medium).impactOccurred()
                self.deleteCode(redeemCode.code)
            }
            deleteAction.backgroundColor = kRGBColor(243, 64, 54)
            return [deleteAction, copyAction]
        } else {
            return [copyAction]
        }
        
    
    }
}
