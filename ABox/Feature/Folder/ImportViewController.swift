import UIKit
import Material

class ImportViewController: ViewController {

    open var completionWithTapIndex:((Int) -> ())?
    fileprivate let closeButton = UIButton()
    fileprivate let titleLabel = UILabel()
    fileprivate let gridView = QMUIGridView()
    fileprivate let buttonDate = [("相册", "imp_a"), ("文件", "imp_f"), ("电脑/浏览器", "imp_p")]

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.popupController?.navigationBarHidden = true
    }

    override func initSubviews() {
        super.initSubviews()
        let width: CGFloat = kDeviceIsiPad ? 500 : kUIScreenWidth - 40
        let height: CGFloat = width*3/5
        self.contentSizeInPopup = CGSize(width: width, height: height)
        self.view.layer.cornerRadius = 20

        closeButton.setImage(UIImage(named: "CloseIcon"), for: .normal)
        closeButton.tintColor = kTextColor
        closeButton.addTarget(self, action: #selector(closeButtonDidTap), for: .touchUpInside)
        self.view.addSubview(closeButton)
        closeButton.snp.makeConstraints { maker in
            maker.width.height.equalTo(30)
            maker.top.equalTo(15)
            maker.left.equalTo(15)
        }
        
        titleLabel.text = "导入文件"
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.bold(aSize: 24)
        titleLabel.textColor = kTextColor
        self.view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.left.right.equalTo(0)
            maker.top.equalTo(closeButton.snp.bottom).offset(5)
            maker.height.equalTo(30)
        }
        
        let rowHeight = (width - 80)/3
        gridView.columnCount = 3
        gridView.rowHeight = rowHeight
        gridView.separatorWidth = 20
        gridView.separatorColor = .clear
        for i in 0..<buttonDate.count {
            let button = QMUIButton()
            let item = buttonDate[i]
            button.tag = i
            button.setBackgroundImage(UIImage(named: item.1), for: .normal)
            let label = UILabel()
            label.text = item.0
            label.font = UIFont.medium(aSize: 12)
            label.textColor = kSubtextColor
            label.textAlignment = .center
            button.addSubview(label)
            label.snp.makeConstraints { maker in
                maker.left.right.bottom.equalTo(button)
                maker.height.equalTo(rowHeight/3)
            }
            button.addTarget(self, action: #selector(importButtonDidTap(_:)), for: .touchUpInside)
            gridView.addSubview(button)
        }
        self.view.addSubview(gridView)
        gridView.snp.makeConstraints { maker in
            maker.left.equalTo(20)
            maker.right.equalTo(-20)
            maker.height.equalTo(rowHeight)
            maker.top.equalTo(titleLabel.snp.bottom).offset(20)
        }
    }    
}

extension ImportViewController {
    
    @objc
    func closeButtonDidTap() {
        self.popupController?.dismiss()
    }
    
    @objc
    func importButtonDidTap(_ sender: UIButton) {
        self.popupController?.dismiss(completion: {
            self.completionWithTapIndex?(sender.tag)
        })
    }
}
