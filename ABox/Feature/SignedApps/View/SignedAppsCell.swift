import UIKit
import RxCocoa
import RxSwift

class SignedAppsCell: QMUITableViewCell {
    
    var installApp:((SignedAppModel) -> ())?

    let iconView = UIImageView()
    let nameLabel = UILabel()
    let versionLabel = UILabel()
    let signedDateLabel = UILabel()
    let infoLabel = QMUILabel()
    let lineView = UIView()
    let deletedFlagView = UILabel()
    let installButton = QMUIButton(type: .custom)

    var app = SignedAppModel()
    let disposeBag = DisposeBag()
    

    override init!(for tableView: UITableView!, with style: UITableViewCell.CellStyle, reuseIdentifier: String) {
        super.init(for: tableView, with: style, reuseIdentifier: reuseIdentifier)
        initSubviews()
    }
    
    override init!(for tableView: UITableView!, withReuseIdentifier reuseIdentifier: String) {
        super.init(for: tableView, withReuseIdentifier: reuseIdentifier)
        initSubviews()
        
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initSubviews()
    }
    
    
    func configCell(_ model: SignedAppModel) {
        self.app = model
        self.iconView.image = UIImage(contentsOfFile: FileManager.default.appIconsDirectory.appendingPathComponent(model.iconName).path)
        self.nameLabel.text = model.name
        self.versionLabel.text = "v" + model.version + "    " + model.bundleIdentifier
        self.signedDateLabel.text = model.signedDate
        self.infoLabel.text = "签名证书：\(model.signedCertificateName)"
        self.deletedFlagView.isHidden = !model.deleted
        self.installButton.isHidden = model.deleted
    }
    
    
    static func cellHeight() -> CGFloat {
        return 105
    }
    
    static func cellIdentifier() -> String {
        return "signedAppsCell"
    }
    
    func initSubviews() {
        
        self.backgroundColor = .white
        self.selectionStyle = .none
        
        iconView.layer.borderWidth = 1
        iconView.layer.borderColor = kBackgroundColor.cgColor
        iconView.layer.cornerRadius = 15
        iconView.layer.masksToBounds = true
        self.contentView.addSubview(iconView)
        
        nameLabel.font = UIFont.bold(aSize: 13.5)
        nameLabel.textColor = kRGBColor(39, 64, 139)
        self.contentView.addSubview(nameLabel)
        
        versionLabel.font = UIFont.regular(aSize: 12)
        versionLabel.textColor = kTextColor
        self.contentView.addSubview(versionLabel)
        
        signedDateLabel.font = UIFont.regular(aSize: 12)
        signedDateLabel.textColor = kTextColor
        self.contentView.addSubview(signedDateLabel)
        
        infoLabel.font = UIFont.medium(aSize: 12.5)
        infoLabel.qmui_lineHeight = 15
        infoLabel.textColor = kTextColor
        infoLabel.numberOfLines = 0
        self.contentView.addSubview(infoLabel)
        
        lineView.backgroundColor = kSeparatorColor
        self.contentView.addSubview(lineView)
        
        deletedFlagView.textColor = .red
        deletedFlagView.text = "原文件已删除"
        deletedFlagView.textAlignment = .right
        deletedFlagView.font = UIFont.regular(aSize: 12)
        self.contentView.addSubview(deletedFlagView)
        
        installButton.setTitle("安装", for: .normal)
        installButton.backgroundColor = kRGBColor(24, 116, 205)
        installButton.setTitleColor(.white, for: .normal)
        installButton.titleLabel?.font = UIFont.medium(aSize: 12)
        installButton.layer.cornerRadius = 12.5
        installButton.layer.masksToBounds = true
        self.contentView.addSubview(installButton)
        installButton.rx.tap.bind { [unowned self] in
            self.installApp?(self.app)
        }.disposed(by: disposeBag)


    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        
        iconView.snp.makeConstraints { maker in
            maker.width.height.equalTo(60)
            maker.left.top.equalTo(10)
        }
        
        nameLabel.snp.makeConstraints { maker in
            maker.left.equalTo(iconView.snp.right).offset(10)
            maker.top.equalTo(iconView)
            maker.right.equalTo(0)
            maker.height.equalTo(20)
        }

        signedDateLabel.snp.makeConstraints { maker in
            maker.left.equalTo(nameLabel)
            maker.top.equalTo(nameLabel.snp.bottom)
            maker.right.equalTo(nameLabel)
            maker.height.equalTo(nameLabel)
        }
        
        versionLabel.snp.makeConstraints { maker in
            maker.left.equalTo(nameLabel)
            maker.top.equalTo(signedDateLabel.snp.bottom)
            maker.right.equalTo(nameLabel)
            maker.height.equalTo(nameLabel)
        }
        
        infoLabel.snp.makeConstraints { maker in
            maker.top.equalTo(iconView.snp.bottom).offset(10)
            maker.left.equalTo(10)
            maker.right.equalTo(-10)
            maker.bottom.equalTo(-10)
        }
        
        lineView.snp.makeConstraints { maker in
            maker.left.bottom.right.equalTo(0)
            maker.height.equalTo(0.5)
        }
        
        deletedFlagView.snp.makeConstraints { maker in
            maker.right.equalTo(-15)
            maker.centerY.equalTo(self.contentView)
            maker.height.equalTo(20)
            maker.width.equalTo(100)
        }
        
        installButton.snp.makeConstraints { maker in
            maker.right.equalTo(-10)
            maker.centerY.equalTo(self.contentView)
            maker.height.equalTo(25)
            maker.width.equalTo(50)
        }
        
        
    }

}

