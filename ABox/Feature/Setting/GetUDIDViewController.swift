import UIKit



class GetUDIDViewController: ViewController {

    let appIcon = UIImageView(image: UIImage(named: "icon-1024"))
    let titleLabel = QMUILabel()
    let contentLabel = QMUILabel()
    let button = QMUIButton()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        // 初次安装
        // configUserDefaults()
    }
    
//    func configUserDefaults() {
//        UserDefaults.standard.set(true, forKey: "kUseAltSign")
//    }
    

    override func initSubviews() {
        super.initSubviews()

        self.view.backgroundColor = kRGBColor(250, 250, 250)

        self.view.addSubview(appIcon)
        appIcon.layer.cornerRadius = 10
        appIcon.layer.masksToBounds = true
        appIcon.snp.makeConstraints { maker in
            maker.width.height.equalTo(175)
            maker.centerX.equalTo(self.view)
            maker.top.equalTo(100)
        }
        
        titleLabel.textAlignment = .center
        titleLabel.text = "欢迎使用\(kAppDisPlayName!)"
        titleLabel.font = UIFont.medium(aSize: 20)
        self.view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.left.equalTo(25)
            maker.right.equalTo(-25)
            maker.height.equalTo(20)
            maker.top.equalTo(appIcon.snp.bottom).offset(25)
        }
        contentLabel.textAlignment = .left
        contentLabel.numberOfLines = 0
//        contentLabel.backgroundColor = .yellow
        contentLabel.text = "\(kAppDisPlayName!)需要获取UDID用于验证您的设备以查找可用的证书。您存储的设备信息仅供统计、管理之用，在任何情况下都不会与任何人共享。\n点击【获取UDID】按钮后，将在Safari浏览器中下载配置描述文件\n下载完成后请在【设置】App中安装描述文件。"
        contentLabel.font = UIFont.regular(aSize: 15)
        contentLabel.textColor = kTextColor
        let height = contentLabel.sizeThatFits(CGSize.init(width: kUIScreenWidth - 50, height: CGFloat.greatestFiniteMagnitude)).height
        self.view.addSubview(contentLabel)
        contentLabel.snp.makeConstraints { maker in
            maker.left.equalTo(25)
            maker.right.equalTo(-25)
            maker.height.equalTo(height)
            maker.top.equalTo(titleLabel.snp.bottom).offset(15)
        }
        
        button.layer.cornerRadius = 25
        button.layer.masksToBounds = true
        button.titleLabel?.font = UIFont.medium(aSize: 17)
        button.setTitle("获取UDID", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = kButtonColor
        self.view.addSubview(button)
        button.snp.makeConstraints { maker in
            maker.width.equalTo(160)
            maker.height.equalTo(50)
            maker.centerX.equalTo(self.view)
            maker.top.equalTo(contentLabel.snp.bottom).offset(80)
        }
        
        button.rx.tap.bind {
            //AppManager.default.getUDID()
            self.getUDIDWithSafari()

        }.disposed(by: disposeBag)
    }

}
