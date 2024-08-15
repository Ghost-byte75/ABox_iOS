import UIKit

class WebUploaderController: ViewController {
    
    let iconView = UIImageView(image: UIImage(named: "icon_wifi"))
    let tipLabel = UILabel()
    var webUploader: GCDWebUploader!
    var webUploaderRunning = false
    var dismissBlock: (() -> ())?
    
    deinit {
        print(message: "WebUploaderController deinit")
        webUploader.stop()
        webUploader = nil
    }
    
    override func initSubviews() {
        super.initSubviews()
        self.view.addSubview(iconView)
        iconView.snp.makeConstraints { maker in
            maker.width.height.equalTo(170)
            maker.centerX.equalTo(self.view)
            maker.bottom.equalTo(self.view.snp.centerY)
        }
        
        tipLabel.textAlignment = .center
        tipLabel.textColor = kSubtextColor
        tipLabel.font = UIFont.regular(aSize: 14)
        tipLabel.numberOfLines = 0
        self.view.addSubview(tipLabel)
        tipLabel.snp.makeConstraints { maker in
            maker.left.right.equalTo(0)
            maker.height.equalTo(150)
            maker.top.equalTo(iconView.snp.bottom)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "WiFi文件传输"
        self.startWebUploader()
    }
    
    override func setupNavigationItems() {
        super.setupNavigationItems()
        self.navigationItem.leftBarButtonItem = UIBarButtonItem.init(title: "关闭", style: .done, target: self, action: #selector(dismissController))
    }
    
    @objc
    func dismissController() {
        if webUploaderRunning {
            UIImpactFeedbackGenerator.init(style: .medium).impactOccurred()
            let alertController = QMUIAlertController.init(title: "关闭此页面将导致Wi-Fi文件传输关闭", message: nil, preferredStyle: .alert)
            alertController.addAction(QMUIAlertAction(title: "取消", style: .cancel, handler: nil))
            alertController.addAction(QMUIAlertAction(title: "确定", style: .default, handler: { [weak self] _, _ in
                self!.dismissBlock?()
                self?.dismiss(animated: true, completion: nil)
            }))
            alertController.showWith(animated: true)
        } else {
            self.dismissBlock?()
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func startWebUploader() {
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].path
        self.webUploader = GCDWebUploader(uploadDirectory: path)
        self.webUploader.start(withPort: 80, bonjourName: "\(kAppDisPlayName!)")
        if let url = webUploader.serverURL {
            print(message: "浏览器访问：\(url.absoluteString)")
            let tipStr = "在浏览器输入以下网址：\n\n\(url.absoluteString)\n\n注意：电脑与该设备必须在同一局域网下\n文件传输过程中不能退出此页面或锁屏"
            let tipAttStr = NSMutableAttributedString.init(string: tipStr)
            if let range = tipStr.range(of: url.absoluteString) {
                tipAttStr.setAttributes([NSAttributedString.Key.font: UIFont.medium(aSize: 18), NSAttributedString.Key.foregroundColor: kButtonColor], range: NSRange(range, in: tipStr))
            }
            tipLabel.attributedText = tipAttStr
            webUploaderRunning = true
        } else {
            tipLabel.text = "无法建立文件传输服务器，请在Wi-Fi环境下使用"
            webUploaderRunning = false
        }
    }
    
}
