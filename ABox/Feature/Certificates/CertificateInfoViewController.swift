import UIKit

class CertificateInfoViewController: ViewController {

    fileprivate let tableView = QMUITableView.init(frame: CGRect.zero, style: .grouped)
    
    var certificate: ALTCertificate?
    var certInfo: P12CertificateInfo?
    var profile: ALTProvisioningProfile?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func initSubviews() {
        super.initSubviews()
        if self.title == nil {
            self.title = "证书信息"
        }
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

extension CertificateInfoViewController: QMUITableViewDelegate, QMUITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return certificate == nil ? 0 : 7
        } else if section == 1 {
            if let _ = profile {
                return 6
            }
        } else if section == 2 {
            if let profile = profile {
                return profile.deviceIDs.count
            }
        }
        return 0
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
        
        if indexPath.section == 0 {
            if let certInfo = certInfo {
                if indexPath.row == 0 {
                    cell?.textLabel?.text = "用户ID"
                    cell?.detailTextLabel?.text = certInfo.userID
                } else if indexPath.row == 1 {
                    cell?.textLabel?.text = "常用名称"
                    cell?.detailTextLabel?.text = certInfo.name
                } else if indexPath.row == 2 {
                    cell?.textLabel?.text = "国家或地区"
                    cell?.detailTextLabel?.text = certInfo.country
                } else if indexPath.row == 3 {
                    cell?.textLabel?.text = "组织"
                    cell?.detailTextLabel?.text = certInfo.organization
                } else if indexPath.row == 4 {
                    cell?.textLabel?.text = "组织单位"
                    cell?.detailTextLabel?.text = certInfo.organizationUnit
                } else if indexPath.row == 5 {
                    cell?.textLabel?.text = "创建时间"
                    let startDate = Date.init(timeIntervalSince1970: TimeInterval(certInfo.startTime))
                    cell?.detailTextLabel?.text = startDate.toString(.custom("yyyy-MM-dd HH:mm"))
                } else if indexPath.row == 6 {
                    cell?.textLabel?.text = "到期时间"
                    let expireDate = Date.init(timeIntervalSince1970: TimeInterval(certInfo.expireTime))
                    cell?.detailTextLabel?.text = expireDate.toString(.custom("yyyy-MM-dd HH:mm"))
                }
            }
        } else if indexPath.section == 1 {
            if let profile = profile {
                if indexPath.row == 0 {
                    cell?.textLabel?.text = "名称"
                    cell?.detailTextLabel?.text = profile.name
                } else if indexPath.row == 1 {
                   cell?.textLabel?.text = "UUID"
                    cell?.detailTextLabel?.text = profile.uuid.uuidString
                } else if indexPath.row == 2 {
                    cell?.textLabel?.text = "BundleIdentifier"
                    cell?.detailTextLabel?.text = profile.bundleIdentifier
                 } else if indexPath.row == 3 {
                    cell?.textLabel?.text = "TeamIdentifier"
                    cell?.detailTextLabel?.text = profile.teamIdentifier
                 } else if indexPath.row == 4 {
                    cell?.textLabel?.text = "创建时间"
                    cell?.detailTextLabel?.text = profile.creationDate.toString(.custom("yyyy-MM-dd HH:mm"))
                 } else if indexPath.row == 5 {
                    cell?.textLabel?.text = "到期时间"
                    cell?.detailTextLabel?.text = profile.expirationDate.toString(.custom("yyyy-MM-dd HH:mm"))
                 }
            }
        } else if indexPath.section == 2 {
            cell?.textLabel?.textColor = kTextColor
            if let profile = profile {
                let deviceID = profile.deviceIDs[indexPath.row]
                cell?.textLabel?.text = deviceID
                if let udid = AppDefaults.shared.deviceUDID {
                    if deviceID == udid {
                        cell?.textLabel?.textColor = .red
                    }
                }
                cell?.detailTextLabel?.text = nil
            }
        }
        return cell!
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 && certificate == nil {
            return 0.01
        }
        return 35
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return certificate == nil ? nil : "证书信息"
        } else if section == 1 {
            if let _ = profile {
                return "描述文件信息"
            }
        } else if section == 2 {
            if let profile = profile {
                if profile.deviceIDs.count > 0 {
                    return "设备UDID(\(profile.deviceIDs.count))"
                }
            }
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
        
}
