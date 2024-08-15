import UIKit
import Material

class InputURLViewController: ViewController {
    
    open var type = 0
    open var completionWithURL:((URL) -> ())?
    fileprivate let closeButton = UIButton()
    fileprivate let titleLabel = UILabel()
    fileprivate let textView = QMUITextView()
    fileprivate let downloadButton = Button()    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        let width: CGFloat = kDeviceIsiPad ? 500 : kUIScreenWidth - 40
        let height: CGFloat = width*3/5
        self.contentSizeInPopup = CGSize(width: width, height: height)
        self.view.layer.cornerRadius = 20
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.popupController?.navigationBarHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.textView.text = UIPasteboard.general.string
        //self.textView.text = "https://www.pgyer.com/4QXB"
    }

    override func initSubviews() {
        super.initSubviews()
        
        closeButton.setImage(UIImage(named: "CloseIcon"), for: .normal)
        closeButton.tintColor = kTextColor
        closeButton.addTarget(self, action: #selector(closeButtonDidTap), for: .touchUpInside)
        self.view.addSubview(closeButton)
        closeButton.snp.makeConstraints { maker in
            maker.width.height.equalTo(30)
            maker.top.equalTo(15)
            maker.left.equalTo(15)
        }
        
        titleLabel.text = type == 0 ? "从网络下载" : "输入网页地址"
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.bold(aSize: 24)
        titleLabel.textColor = kTextColor
        self.view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.left.right.equalTo(0)
            maker.top.equalTo(closeButton.snp.bottom).offset(5)
            maker.height.equalTo(30)
        }

        self.textView.placeholder = "http://"
        self.textView.keyboardType = .URL
        self.textView.font = UIFont.regular(aSize: 15)
        self.textView.layer.borderColor = kRGBColor(220, 220, 220).cgColor
        self.textView.layer.borderWidth = 1
        self.textView.layer.cornerRadius = 5
        self.view.addSubview(self.textView)
        self.textView.snp.makeConstraints { maker in
            maker.left.equalTo(20)
            maker.right.equalTo(-80)
            maker.top.equalTo(titleLabel.snp.bottom).offset(20)
            maker.bottom.equalTo(-20)
        }
        
        self.downloadButton.setImage(UIImage(named: "download"), for: .normal)
        self.downloadButton.layer.cornerRadius = 25
        self.downloadButton.addTarget(self, action: #selector(downloadButtonDidTap), for: .touchUpInside)
        self.view.addSubview(self.downloadButton)
        self.downloadButton.snp.makeConstraints { maker in
            maker.width.height.equalTo(50)
            maker.centerY.equalTo(self.textView)
            maker.right.equalTo(-15)
        }
    }


}


extension InputURLViewController {
    
    @objc
    func closeButtonDidTap() {
        self.popupController?.dismiss()
    }
        
    @objc
    func downloadButtonDidTap() {
        self.view.endEditing(true)
        let urlString = self.textView.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        if let url = URL(string: urlString) {
            self.popupController?.dismiss(completion: {
                self.completionWithURL?(url)
            })
        } else {
            kAlert("输入的URL不支持！")
        }
    }
}
