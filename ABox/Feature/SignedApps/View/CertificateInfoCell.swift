import UIKit
import Async
import SwiftDate
import Material

class CertificateInfoCell: UITableViewCell {

    var detailButtonTappedCallback: (() -> ())?
    
    let nameLabel = UILabel()
    let expiraLabel = UILabel()
    let statusLabel = UILabel()
    let profileInfoLabel = UILabel()
    let lineView = UIView()
    let detailButton = UIButton(type: .custom)
    let activityIndicatorView = UIActivityIndicatorView()

//    override init!(for tableView: UITableView!, with style: UITableViewself.CellStyle, reuseIdentifier: String) {
//        super.init(for: tableView, with: style, reuseIdentifier: reuseIdentifier)
//        initSubviews()
//    }
    
//    override init!(for tableView: UITableView!, withReuseIdentifier reuseIdentifier: String) {
//        super.init(for: tableView, withReuseIdentifier: reuseIdentifier)
//        initSubviews()
//
//    }
    
//    override init(style: UITableViewself.CellStyle, reuseIdentifier: String?) {
//        super.init(style: style, reuseIdentifier: reuseIdentifier)
//        initSubviews()
//    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initSubviews()
    }
        
    static func cellHeight() -> CGFloat {
        return 95
    }
    
    static func cellIdentifier() -> String {
        return "CertificateInfoCell"
    }
    
    func initSubviews() {
        
        self.backgroundColor = .white
        self.selectionStyle = .none
        
        nameLabel.font = UIFont.medium(aSize: 13)
        nameLabel.textColor = kTextColor
        self.contentView.addSubview(nameLabel)
        
        expiraLabel.font = UIFont.regular(aSize: 12)
        expiraLabel.textColor = kTextColor
        self.contentView.addSubview(expiraLabel)
        
        profileInfoLabel.font = UIFont.regular(aSize: 12)
        profileInfoLabel.textColor = kTextColor
        self.contentView.addSubview(profileInfoLabel)
        
        statusLabel.font = UIFont.bold(aSize: 11)
        statusLabel.textColor = kTextColor
        statusLabel.textAlignment = .right
        self.contentView.addSubview(statusLabel)
        
        lineView.backgroundColor = kSeparatorColor
        self.contentView.addSubview(lineView)
        
        detailButton.isHidden = true
        detailButton.setImage(UIImage(named: "info")?.tint(with: kButtonColor), for: .normal)
//        detailButton.setImage(Icon.moreVertical?.tint(with: kButtonColor), for: .normal)
        detailButton.frame = CGRect(x: 0, y: 0, width: 35, height: 35)
        detailButton.addTarget(self, action: #selector(whenDetailButtonTapped), for: .touchUpInside)
        self.contentView.addSubview(detailButton)
        
        activityIndicatorView.frame = CGRect(x: 0, y: 0, width: 35, height: 35)
        self.contentView.addSubview(activityIndicatorView)

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        
        nameLabel.snp.makeConstraints { maker in
            maker.left.equalTo(10)
            maker.top.equalTo(10)
            maker.right.equalTo(-10)
            maker.height.equalTo(25)
        }
        
        expiraLabel.snp.makeConstraints { maker in
            maker.left.equalTo(10)
            maker.top.equalTo(nameLabel.snp.bottom)
            maker.right.equalTo(nameLabel)
            maker.height.equalTo(nameLabel)
        }

        profileInfoLabel.snp.makeConstraints { maker in
            maker.left.equalTo(10)
            maker.top.equalTo(expiraLabel.snp.bottom)
            maker.right.equalTo(nameLabel)
            maker.height.equalTo(nameLabel)
        }
        
        statusLabel.snp.makeConstraints { maker in
            maker.right.equalTo(-45)
            maker.centerY.equalTo(expiraLabel)
            maker.width.equalTo(70)
            maker.height.equalTo(nameLabel)
        }
        
        lineView.snp.makeConstraints { maker in
            maker.left.bottom.right.equalTo(0)
            maker.height.equalTo(0.5)
        }
        
        activityIndicatorView.snp.makeConstraints { make in
            make.width.height.equalTo(35)
            make.centerY.equalTo(self.contentView)
            make.right.equalTo(-10)
        }
        
        detailButton.snp.makeConstraints { make in
            make.width.height.equalTo(35)
            make.centerY.equalTo(self.contentView)
            make.right.equalTo(-10)
        }
    }
    
    @objc
    func whenDetailButtonTapped() {
        self.detailButtonTappedCallback?()
    }
    
    func configCell(certificate: ALTCertificate, certInfo: P12CertificateInfo, profile: ALTProvisioningProfile?) {
        self.nameLabel.text = certificate.name
        if AppDefaults.shared.signingCertificateSerialNumber == certificate.serialNumber {
            self.nameLabel.text = "⭐️ \(certificate.name)"
        }
        let expireDate = Date.init(timeIntervalSince1970: TimeInterval(certInfo.expireTime))
        self.expiraLabel.text = "过期时间：\(expireDate.toString(.custom("yyyy-MM-dd HH:mm")))"

        if expireDate < Date() {
            // 已过期
            self.statusLabel.textColor = .red
            self.statusLabel.text = "证书已过期"
            self.detailButton.isHidden = false
        } else {

            let revokedKey = certificate.serialNumber
            certInfo.revoked = UserDefaults.standard.bool(forKey: revokedKey)
            
            if certInfo.revoked {
                self.detailButton.isHidden = false
                self.statusLabel.text = "证书已撤销"
                self.statusLabel.textColor = .red
            } else {
                let checkedKey = "\(certificate.serialNumber)-\(Date().toString(.custom("yyyy-MM-dd-HH")))"
                if UserDefaults.standard.bool(forKey: checkedKey) {
                    self.detailButton.isHidden = false
                    self.statusLabel.text = "证书有效"
                    self.statusLabel.textColor = kGreenColor
                } else {
                    self.activityIndicatorView.startAnimating()
                    ReadP12Subject().readCertInfoWhitAltCert(certificate) { certInfo in
                        Async.main {
                            self.activityIndicatorView.stopAnimating()
                            self.activityIndicatorView.isHidden = true
                            self.detailButton.isHidden = false
                            self.statusLabel.text = certInfo.revoked ? "证书已撤销" : "证书有效"
                            self.statusLabel.textColor = certInfo.revoked ? .red : kGreenColor
                            UserDefaults.standard.set(true, forKey: checkedKey)
                            UserDefaults.standard.set(certInfo.revoked, forKey: revokedKey)
                            
                        }
                    }
                }
            }
        }
        
        if let profile = profile {
            self.profileInfoLabel.text = "描述文件：\(profile.name)"
            self.profileInfoLabel.textColor = kTextColor
            if let udid = AppDefaults.shared.deviceUDID {
                if profile.deviceIDs.contains(udid) {
                    self.profileInfoLabel.text = "描述文件：\(profile.name) ⚡️"
                }
            }
        } else {
            self.profileInfoLabel.text = "未导入描述文件"
            self.profileInfoLabel.textColor = .red
        }
    }
}
