import UIKit
import Material

class SignCoreViewController: ViewController {

    var completionHandler:(() -> ())?

    fileprivate let tableView = QMUITableView.init(frame: CGRect.zero, style: .grouped)

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "签名核心"
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.showsVerticalScrollIndicator = false
        self.tableView.showsHorizontalScrollIndicator = false
        self.tableView.setEmptyDataSet(title: nil, descriptionString: nil, image: nil)
        self.view.addSubview(self.tableView)
        self.tableView.snp.makeConstraints { maker in
            maker.left.top.right.equalTo(0)
            maker.bottom.equalTo(0)
        }
        self.tableView.reloadData()
    }

}

extension SignCoreViewController: QMUITableViewDelegate, QMUITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "cell"
        var cell = tableView.dequeueReusableCell(withIdentifier: identifier)
        if cell == nil {
            cell = QMUITableViewCell(for: tableView, with: .value1, reuseIdentifier: identifier)
            cell?.backgroundColor = .white
            cell?.selectionStyle = .none
            cell?.textLabel?.font = UIFont.medium(aSize: 13)
            cell?.textLabel?.textColor = kTextColor
            cell?.detailTextLabel?.font = UIFont.regular(aSize: 13)
            cell?.detailTextLabel?.textColor = kTextColor
        }
        cell?.accessoryType = .disclosureIndicator
        let useAltSign = UserDefaults.standard.bool(forKey: "kUseAltSign")
        if indexPath.section == 0 {
            cell?.textLabel?.text = "zsign"
            cell?.imageView?.image = useAltSign ? nil : Icon.check?.tint(with: kGreenColor)
        } else {
            cell?.textLabel?.text = "ldid"
            cell?.imageView?.image = useAltSign ? Icon.check?.tint(with: kGreenColor) : nil
        }
        return cell!
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 10
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 70
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return section == 0 ? "\nMaybe is the most quickly codesign alternative for iOS12+ in the world, cross-platform ( macOS, Linux , Windows ), more features." : "\nldid is a tool made by saurik for modifying a binary's entitlements easily. ldid also generates SHA1 and SHA256 hashes for the binary signature, so the iPhone kernel executes the binary. "
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let useAltSign = indexPath.section == 1
        UserDefaults.standard.set(useAltSign, forKey: "kUseAltSign")
        UserDefaults.standard.synchronize()
        self.completionHandler?()
        self.navigationController?.popViewController(animated: true)
    }
        
}
