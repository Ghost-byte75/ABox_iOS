import UIKit

class MoveFolderViewController: ViewController {

    var dismissBlock: (() -> ())?
    var isFirst = false
    var file = File()
    var folderURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    
    fileprivate let tableView = QMUITableView.init(frame: CGRect.zero, style: .grouped)
    fileprivate let cellIdentifier = "folderCell"
    fileprivate var folders: [File] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "移动到\(self.folderURL.lastPathComponent)"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getFolders()
    }
    
    override func setupNavigationItems() {
        super.setupNavigationItems()
        if isFirst {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem.init(title: "关闭", style: .done, target: self, action: #selector(dismissController))
        }
        self.navigationItem.rightBarButtonItem = UIBarButtonItem.init(title: "确定", style: .done, target: self, action: #selector(moveFileToFolder))
    }
            
    
    @objc
    func dismissController() {
        self.dismiss(animated: true, completion: nil)
    }
        
    
    @objc
    func getFolders() {
        let fileManger = FileManager.default
        do {
            let dirArray = try fileManger.contentsOfDirectory(atPath: folderURL.path)
            self.folders.removeAll()
            for name in dirArray {
                if name.hasPrefix(".") {
                    continue
                }
                let subPath: URL = folderURL.appendingPathComponent(name)
                let file = File.init(fileURL: subPath)
                if file.isFolder {
                    self.folders.append(file)
                }
            }
            self.folders.sort { (file1, file2) -> Bool in
                if let date1 = file1.modificationDate {
                    if let date2 = file2.modificationDate {
                        return date1 > date2
                    }
                }
                return false
            }
            self.tableView.reloadData()
        } catch let error {
            print(message: error.localizedDescription)
        }
        self.tableView.mj_header?.endRefreshing()
    }

    override func initSubviews() {
        super.initSubviews()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.showsVerticalScrollIndicator = false
        self.tableView.showsHorizontalScrollIndicator = false
        self.tableView.setEmptyDataSet(title: nil, descriptionString: nil, image: UIImage(named: "file-storage"))
        self.tableView.register(QMUITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        self.tableView.mj_header = MJRefreshNormalHeader(refreshingTarget: self, refreshingAction: #selector(getFolders))
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.left.top.right.equalTo(0)
            maker.bottom.equalTo(0)
        }
    }
    
    @objc
    func moveFileToFolder() {
        let newPath = self.folderURL.path
        let moveToPath = newPath + "/" + file.name
        let moveURL = URL(fileURLWithPath: moveToPath)
        do {
            try FileManager.default.moveItem(at: file.url, to: moveURL)
            self.dismissBlock?()
            self.dismiss(animated: true, completion: nil)
        } catch let error {
            print(message: error.localizedDescription)
            kAlert(error.localizedDescription)
//            self.dismiss(animated: true, completion: nil)
        }
    }
}


extension MoveFolderViewController: QMUITableViewDelegate, QMUITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.folders.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "cell"
        var cell = tableView.dequeueReusableCell(withIdentifier: identifier)
        if (cell == nil) {
            cell = QMUITableViewCell(for: tableView, with: .subtitle, reuseIdentifier: identifier)
            cell?.backgroundColor = .white
            cell?.selectionStyle = .none
            cell?.textLabel?.font = UIFont.medium(aSize: 14)
            cell?.textLabel?.textColor = kTextColor
            cell?.detailTextLabel?.font = UIFont.regular(aSize: 12)
            cell?.detailTextLabel?.textColor = kSubtextColor
        }
        let file = folders[indexPath.row]
        cell?.textLabel?.text = file.name
        if file.isFolder {
            cell?.imageView?.image = UIImage(named: "file_ext_folder")
            cell?.detailTextLabel?.text = "\(String.timeStr(file.modificationDate))"
            cell?.accessoryType = .disclosureIndicator
        } else {
            cell?.accessoryType = .none
            if let image = UIImage(named: file.type) {
                cell?.imageView?.image = image.resize(toHeight: 40)
            } else {
                cell?.imageView?.image = UIImage(named: "unknown")?.resize(toHeight: 40)
            }
            cell?.detailTextLabel?.text = "\(String.timeStr(file.modificationDate)) - \(file.sizeDesc)"
        }
        return cell!
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 10
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let folder = self.folders[indexPath.row]
        let controller = MoveFolderViewController()
        controller.dismissBlock = self.dismissBlock
        controller.file = self.file
        controller.folderURL = folder.url
        self.navigationController?.pushViewController(controller, animated: true)
    }

}

