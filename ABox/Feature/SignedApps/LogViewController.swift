import UIKit
import QMUIKit
import RxSwift
import RxCocoa

class LogViewController: ViewController {

    public var completionHandler: ((String)->(Void))?
    public let completeButton = QMUIButton()
    public var logs: [NSAttributedString] = []

    private var tableView = QMUITableView.init(frame: .zero, style: .grouped)
    private var scrolling = false
    private let backgroundColor = UIColor.black
    private let progressConsole = M13ProgressConsole.init(frame: CGRect.init(x: 10, y: -20, width: 300, height: 40))
    private var progressCell: LogCell?

    override func initSubviews() {
        super.initSubviews()
        
        let viewWidth: CGFloat = kDeviceIsiPad ? 500 : kUIScreenWidth - 40
        let viewHeight: CGFloat = viewWidth*kUIScreenHeight/kUIScreenWidth - kUINavigationContentTop - (kUI_IPHONEX ? 80 : 40)
        self.contentSizeInPopup = CGSize(width: viewWidth, height: viewHeight)
        
        self.title = "签名日志"
        self.view.backgroundColor = backgroundColor

        completeButton.setTitle("完成", for: .normal)
        completeButton.tag = 1
        completeButton.isHidden = true
        completeButton.setTitleColor(.white, for: .normal)
        completeButton.titleLabel?.font = UIFont.medium(aSize: 16)
        completeButton.layer.cornerRadius = 5
        completeButton.layer.masksToBounds = true
        completeButton.layer.borderWidth = 1.5
        completeButton.layer.borderColor = UIColor.white.cgColor
        completeButton.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        self.view.addSubview(completeButton)
            
        tableView.backgroundColor = backgroundColor
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.register(LogCell.self, forCellReuseIdentifier: LogCell.cellIdentifier())
        tableView.showsVerticalScrollIndicator = true
        tableView.indicatorStyle = .white
        self.view.addSubview(tableView)
        
        progressConsole.prefix = ""
        progressConsole.progressType = .init(rawValue: 2)
        progressConsole.indeterminate = true
        progressConsole.addNewLine(with: "        ")
        progressConsole.setProgress(0.01)
        let tableFooterView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: kUIScreenWidth, height: 20))
        tableFooterView.clipsToBounds = true
        tableFooterView.addSubview(progressConsole)
        self.tableView.tableFooterView = tableFooterView
    }
    
    override func setupNavigationItems() {
        super.setupNavigationItems()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        completeButton.snp.makeConstraints { maker in
            maker.width.equalTo(130)
            maker.height.equalTo(40)
            maker.bottom.equalTo(-10)
            maker.centerX.equalTo(self.view)
        }

        tableView.snp.makeConstraints { maker in
            maker.top.left.right.equalTo(self.view)
            maker.bottom.equalTo(self.completeButton.snp.top).offset(-10)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
       
    }
    
    func loggingFinish() {
        completeButton.isHidden = false
        tableView.tableFooterView = nil
    }
    
    
    @objc
    func buttonTapped(_ sender: UIButton) {
        self.popupController?.dismiss(completion: { [unowned self] in
            if let completionHandler = completionHandler {
                var logStr = ""
                for log in self.logs {
                    logStr = logStr + "\n" + log.string
                }
                print(message: "签名日志：\(logStr)")
                completionHandler(logStr)
            }
        })
    }

    func appendLog(_ string: String, color: UIColor? = nil, font: UIFont? = nil) {
        var attributes = [NSAttributedString.Key.foregroundColor : UIColor.white, NSAttributedString.Key.font: UIFont.regular(aSize: 12)]
        if let textColor = color {
            attributes[NSAttributedString.Key.foregroundColor] = textColor
        }
        if let textFont = font {
            attributes[NSAttributedString.Key.font] = textFont
        } else {
            if string.contains("===============") {
                attributes[NSAttributedString.Key.font] = UIFont.medium(aSize: 13)
            }
        }
        let attributedString = NSAttributedString(string: string, attributes: attributes)
        self.appendLog(attributedString)
    }
    
    func appendLog(_ attributedString: NSAttributedString) {
        self.logs.append(attributedString)
        if self.scrolling == false {
            self.scrolling = true
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
                self.tableView.reloadData()
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
                    self.tableView.qmui_scrollToBottom()
                    self.scrolling = false
                }
            }
        }
    }
}

extension LogViewController: QMUITableViewDelegate, QMUITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.logs.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let attributedString = self.logs[indexPath.section]
        if attributedString.string.contains("===") {
            return 30
        }
        let cellWidth: CGFloat = (kDeviceIsiPad ? 500 : kUIScreenWidth - 40) - 20
        return LogCell.cellHeight(text: attributedString.string, cellWidth: cellWidth)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: LogCell = tableView.dequeueReusableCell(withIdentifier: LogCell.cellIdentifier(), for: indexPath) as! LogCell
        cell.selectionStyle = .none
        cell.backgroundColor = backgroundColor
        cell.contentLabel.backgroundColor = backgroundColor
        let attributedString = self.logs[indexPath.section]
        cell.contentLabel.attributedText = attributedString
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
}
