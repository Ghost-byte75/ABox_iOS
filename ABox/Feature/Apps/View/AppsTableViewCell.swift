import UIKit
import SnapKit
import AlamofireImage
import RxCocoa
import RxSwift

class AppsTableViewCell: UITableViewCell {
    
    let appBGView = UIView()
    let iconView = UIImageView()
    let nameLabel = UILabel()
    let categoryLabel = UILabel()
    let versionLabel = UILabel()
    let infoLabel = QMUILabel()
    let downloadButton = QMUIButton()
    let fileSizeLabel = UILabel()
    let disposeBag = DisposeBag()
    var app = AppModel()
    var openURL: ((URL) -> (Void))?
    var openApp: ((AppModel) -> (Void))?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initSubviews()
    }
    
    func configCell(_ model: AppModel) {
        self.app = model
        self.nameLabel.text = model.name
        
        if model.version.count > 0 {
            self.categoryLabel.text = "v" + model.version
        }
        if model.sourceName.count > 0 {
            self.categoryLabel.text = model.sourceName
        }
        if model.version.count > 0 && model.sourceName.count > 0 {
            self.categoryLabel.text = "v" + model.version + " - " + model.sourceName
        }
        
        self.versionLabel.text = model.versionDate
        self.infoLabel.text = model.versionDescription
        self.iconView.ab_setImage(withURLString: model.iconURL, placeholderImage: UIImage.init(named: "ipa"))
        
        if app.lock {
            self.downloadButton.setTitle("解锁", for: .normal)
        } else {
            self.downloadButton.setTitle(model.downloaded() ? "已下载" : "下载", for: .normal)
        }
        
        let infoAttStr = NSMutableAttributedString.init(string: model.versionDescription)
        let urls = String.getUrls(str: model.versionDescription)
        for url in urls {
            if let range = model.versionDescription.range(of: url) {
                infoAttStr.setAttributes([NSAttributedString.Key.underlineStyle: 1,
                                          NSAttributedString.Key.underlineColor: UIColor.blue,
                                          NSAttributedString.Key.foregroundColor: UIColor.blue], range: NSRange(range, in: model.versionDescription))
            }
        }
        self.infoLabel.attributedText = infoAttStr
        
        self.fileSizeLabel.text = model.size > 1000 ? String.fileSizeDesc(model.size) : nil
        
    }
    
    static func cellHeight(appInfo: String) -> CGFloat {
        let textHeight = UITableViewCell.cellHeight(text: appInfo, width: kUIScreenWidth - 40, lineHiehgt: 15, font: UIFont.regular(aSize: 12))
        return textHeight + 100
    }
    
    static func cellIdentifier() -> String {
        return "appsTableViewCell"
    }    
    
    func initSubviews() {
        
        self.selectionStyle = .none
        self.backgroundColor = .clear
        
        appBGView.layer.cornerRadius = 15
        appBGView.layer.masksToBounds = true
        appBGView.backgroundColor = .white
        self.contentView.addSubview(appBGView)
        
        iconView.layer.borderWidth = 1
        iconView.layer.borderColor = kBackgroundColor.cgColor
        iconView.layer.cornerRadius = 15
        iconView.layer.masksToBounds = true
        self.appBGView.addSubview(iconView)
        
        nameLabel.font = UIFont.bold(aSize: 13.5)
        nameLabel.textColor = kRGBColor(39, 64, 139)
        self.appBGView.addSubview(nameLabel)
        
        categoryLabel.font = UIFont.medium(aSize: 12)
        categoryLabel.textColor = kTextColor
        self.appBGView.addSubview(categoryLabel)
        
        versionLabel.font = UIFont.regular(aSize: 12)
        versionLabel.textColor = kTextColor
        self.appBGView.addSubview(versionLabel)
        
        infoLabel.font = UIFont.regular(aSize: 12)
        infoLabel.qmui_lineHeight = 15
        infoLabel.textColor = kTextColor
        infoLabel.numberOfLines = 0
        self.appBGView.addSubview(infoLabel)
        infoLabel.isUserInteractionEnabled = true
        infoLabel.bk_(whenTapped: { [unowned self] in
            let urls = String.getUrls(str: self.app.versionDescription)
            if urls.count > 0 {
                if let url = URL(string: urls.first!) {
                    self.openURL?(url)
                }
            }
        })
        
        downloadButton.setTitle("已下载", for: .normal)
        downloadButton.backgroundColor = kRGBColor(24, 116, 205)
        downloadButton.setTitleColor(.white, for: .normal)
        downloadButton.titleLabel?.font = UIFont.medium(aSize: 12)
        downloadButton.layer.cornerRadius = 12.5
        downloadButton.layer.masksToBounds = true
        self.appBGView.addSubview(downloadButton)
        downloadButton.rx.tap.bind { [unowned self] in
            self.openApp?(self.app)
            var appDesc = ""
            if let json = self.app.toJSONString() {
                appDesc = json
            }
            API.default.request(url: "/app/installs", method: .put, parameters: ["id": self.app.id, "desc": appDesc], success: nil, failure: nil)
        }.disposed(by: disposeBag)
        
        fileSizeLabel.font = UIFont.light(aSize: 10)
        fileSizeLabel.textAlignment = .center
        fileSizeLabel.textColor = kSubtextColor
        self.appBGView.addSubview(fileSizeLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        
        appBGView.snp.makeConstraints({ maker in
            maker.left.equalTo(10)
            maker.right.equalTo(-10)
            maker.top.equalTo(5)
            maker.bottom.equalTo(-5)
        })
        
        iconView.snp.makeConstraints { maker in
            maker.width.height.equalTo(60)
            maker.left.top.equalTo(10)
        }
        
        nameLabel.snp.makeConstraints { maker in
            maker.left.equalTo(iconView.snp.right).offset(10)
            maker.top.equalTo(iconView)
            maker.right.equalTo(-70)
            maker.height.equalTo(20)
        }
        
        categoryLabel.snp.makeConstraints { maker in
            maker.left.equalTo(nameLabel)
            maker.top.equalTo(nameLabel.snp.bottom)
            maker.right.equalTo(nameLabel)
            maker.height.equalTo(nameLabel)
        }
        
        versionLabel.snp.makeConstraints { maker in
            maker.left.equalTo(nameLabel)
            maker.top.equalTo(categoryLabel.snp.bottom)
            maker.right.equalTo(nameLabel)
            maker.height.equalTo(nameLabel)
        }

        
        infoLabel.snp.makeConstraints { maker in
            maker.top.equalTo(iconView.snp.bottom).offset(10)
            maker.left.equalTo(10)
            maker.right.equalTo(-10)
            maker.bottom.equalTo(-10)
        }
        
        downloadButton.snp.makeConstraints { maker in
            maker.right.equalTo(-10)
            maker.centerY.equalTo(nameLabel)
            maker.height.equalTo(25)
            maker.width.equalTo(50)
        }
        
        fileSizeLabel.snp.makeConstraints { maker in
            maker.right.equalTo(0)
            maker.width.equalTo(70)
            maker.height.equalTo(15)
            maker.top.equalTo(downloadButton.snp.bottom).offset(5)
        }

    }

}


