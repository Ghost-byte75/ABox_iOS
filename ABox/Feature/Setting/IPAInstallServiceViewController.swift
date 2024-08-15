import UIKit
import Material
import RxAlamofire
import RxSwift

class IPAInstallServiceViewController: ViewController {
    
    var completionHandler:(() -> ())?
    //下面是ipa安装服务器
    fileprivate let cellData = [(service: "gbox.pub",
                                 url: "https://test.gbox.pub/VGVzdDEvY29tLmdib3guVGVzdDE4MzEyOS8xLjA.plist"),
                                (service: "gbox.run",
                                 url: "https://test.gbox.run/VGVzdDEvY29tLmdib3guVGVzdDE4MzEyOS8xLjA.plist")]

    fileprivate let tableView = QMUITableView.init(frame: CGRect.zero, style: .grouped)

    override func viewDidLoad() {
        
        super.viewDidLoad()

        self.title = "IPA安装服务器"
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

extension IPAInstallServiceViewController: QMUITableViewDelegate, QMUITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return cellData.count
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
            cell = IPAInstallServiceCell(for: tableView, with: .value1, reuseIdentifier: identifier)
            
        }
        if let myCell: IPAInstallServiceCell = cell as? IPAInstallServiceCell {
            myCell.imageView?.image = AppDefaults.shared.installIPAService! == indexPath.section ? Icon.check?.tint(with: kGreenColor) : nil
            let item = cellData[indexPath.section]
            myCell.configCell(title: item.service, url: item.url)

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
        return 0.01
    }
//    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
//        return section == cellData.count - 1 ? 60 : 0.01
//    }
    
//    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
//        return section == cellData.count - 1 ? "iOS16暂不支持gitee.com和github.com安装ipa\n如果安装服务器没有响应请尝试更换服务器地址再安装。" : nil
//    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        AppDefaults.shared.installIPAService = indexPath.section
        self.completionHandler?()
        self.navigationController?.popViewController(animated: true)
    }
        
}

class IPAInstallServiceCell: QMUITableViewCell {
    
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
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initSubviews() {
        self.backgroundColor = .white
        self.selectionStyle = .none
        self.textLabel?.font = UIFont.medium(aSize: 14)
        self.textLabel?.textColor = kTextColor
        self.detailTextLabel?.font = UIFont.regular(aSize: 13)
        self.detailTextLabel?.textColor = kTextColor
    }
    
    func configCell(title:String, url: String) {
        self.textLabel?.text = title
        self.accessoryType = .disclosureIndicator
        let activityIndicatorView = UIActivityIndicatorView.init(frame: CGRect.init(x: 0, y: 0, width: 35, height: 35))
        activityIndicatorView.startAnimating()
        self.accessoryView = activityIndicatorView
        let startTime = CFAbsoluteTimeGetCurrent()
        RxAlamofire.requestString(.get, URL(string: url)!).subscribe { (response, responseString) in
            let endTime = CFAbsoluteTimeGetCurrent()
            let timeStr = String.init(format: "%0.0fms", (endTime - startTime)*1000)
            activityIndicatorView.stopAnimating()
            self.accessoryView = nil
            self.detailTextLabel?.text = "可用(\(timeStr))"
            self.detailTextLabel?.textColor = kGreenColor
        } onError: { error in
            activityIndicatorView.stopAnimating()
            self.detailTextLabel?.text = "无响应"
            self.accessoryView = nil
            self.detailTextLabel?.textColor = kMainRedColor
        }.disposed(by: disposeBag)
    }
    
    static func cellIdentifier() -> String {
        return "IPAInstallServiceCell"
    }
    
}
