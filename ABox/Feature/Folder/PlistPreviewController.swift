import Foundation

class PlistPreviewController: ViewController {

    public var plistURL: URL?
    private let tableView = QMUITableView.init(frame: CGRect.zero, style: .grouped)
    private var previewDict = NSMutableDictionary()
    private var allKeys: [String] = []
    private var cellSecitonOpen: [Int: Bool] = [:]
    
    init(dictionary: NSMutableDictionary) {
        self.init()
        self.previewDict = dictionary
        for key in dictionary.allKeys {
            allKeys.append("\(key)")
        }
        allKeys.sort()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func setupNavigationItems() {
        super.setupNavigationItems()
        
        let addKeyValueButton = UIBarButtonItem.init(title: "添加键值", style: .done, target: self, action: #selector(addKeyValue))
        addKeyValueButton.tintColor = kButtonColor
        if let _ = self.plistURL {
            let saveButton = UIBarButtonItem.init(title: "保存", style: .done, target: self, action: #selector(savePlist))
            saveButton.tintColor = kButtonColor
            self.navigationItem.rightBarButtonItems = [saveButton, addKeyValueButton]
        } else {
            self.navigationItem.rightBarButtonItem = addKeyValueButton
        }
    }
    
    override func initSubviews() {
        super.initSubviews()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.showsVerticalScrollIndicator = false
        self.tableView.showsHorizontalScrollIndicator = false
        self.tableView.register(SignedAppsCell.self, forCellReuseIdentifier: SignedAppsCell.cellIdentifier())
        self.tableView.setEmptyDataSet(title: nil, descriptionString: nil, image: UIImage(named: "file-storage"))
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.left.top.right.equalTo(0)
            maker.bottom.equalTo(0)
        }
    }
    
    @objc
    func savePlist() {
        previewDict.write(toFile: plistURL!.path, atomically: true)
        QMUITips.showSucceed("保存成功", in: self.view)
    }
    
    @objc
    func addKeyValue() {
        let dialogViewController = QMUIDialogTextFieldViewController()
        dialogViewController.title = "添加键值"
        dialogViewController.addTextField(withTitle: "键") { label, textfield, layer in
            
        }
        dialogViewController.addTextField(withTitle: "值") { label, textfield, layer in
            
        }
        dialogViewController.addCancelButton(withText: "取消", block: nil)
        dialogViewController.addSubmitButton(withText: "确定") { [unowned self] _ in
            dialogViewController.hide()
            let key = dialogViewController.textFields![0].text!
            let value = dialogViewController.textFields![1].text!
            self.previewDict[key] = value
            allKeys.append(key)
            allKeys.sort()
            self.tableView.reloadData()
        }
        dialogViewController.show()
        
    }
}

extension PlistPreviewController: QMUITableViewDelegate, QMUITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.row == 0 ? 55 : 40
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return allKeys.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let key = allKeys[section]
        if let value = previewDict[key] {
            if value is NSArray {
                if let open = cellSecitonOpen[section] {
                    if open {
                        if let array: NSArray = value as? NSArray {
                            return array.count + 1
                        }
                    }
                }
            }
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "cell"
        var cell = tableView.dequeueReusableCell(withIdentifier: identifier)
        if cell == nil {
            cell = QMUITableViewCell(for: tableView, with: .value1, reuseIdentifier: identifier)
            cell?.selectionStyle = .none
            cell?.textLabel?.font = UIFont.medium(aSize: 13)
            cell?.textLabel?.numberOfLines = 0
            cell?.textLabel?.textColor = .black
            cell?.detailTextLabel?.font = UIFont.regular(aSize: 12)
            cell?.detailTextLabel?.textColor = .black
            cell?.tintColor = kButtonColor
        }
        cell?.accessoryType = .none
        cell?.backgroundColor = indexPath.row == 0 ? .white : kBackgroundColor

        let key = allKeys[indexPath.section]
        if let value = previewDict[key] {
            print(message: "\(key): \(type(of: value))")
            if value is NSArray {
                if let array: NSArray = value as? NSArray {
                    if indexPath.row == 0 {
                        cell?.textLabel?.text = key
                        cell?.detailTextLabel?.text = "Array[\(array.count)]"
                        let button = UIButton.init(frame: CGRect.init(x: 0, y: 0, width: 20, height: 20))
                        button.layer.cornerRadius = 10
                        button.layer.masksToBounds = true
                        button.layer.borderColor = kButtonColor.cgColor
                        button.layer.borderWidth = 1.2
                        button.setImage(UIImage.init(named: "icon_add")?.resizeWith(width: 20)?.tint(with: kButtonColor), for: .normal)
                        cell?.accessoryView = button
                        button.rx.tap.bind { [unowned self] in
                            let dialogViewController = QMUIDialogTextFieldViewController()
                            dialogViewController.title = "添加值"
                            dialogViewController.addTextField(withTitle: "值") { label, textfield, layer in
                                
                            }
                            dialogViewController.addCancelButton(withText: "取消", block: nil)
                            dialogViewController.addSubmitButton(withText: "确定") { [unowned self] _ in
                                dialogViewController.hide()
                                let value = dialogViewController.textFields![0].text!
                                let mutableArray = NSMutableArray.init(array: array)
                                mutableArray.add(value)
                                self.previewDict[key] = mutableArray
                                self.cellSecitonOpen[indexPath.section] = true
                                self.tableView.reloadData()
                            }
                            dialogViewController.show()
                        }.disposed(by: disposeBag)
                    } else {
                        cell?.textLabel?.text = "Item\(indexPath.row - 1)"
                        let item = array[indexPath.row - 1]
                        if item is NSDictionary {
                            cell?.detailTextLabel?.text = "Dictionary[\((item as! NSDictionary).allKeys.count)]"
                            cell?.accessoryType = .disclosureIndicator
                        } else {
                            cell?.detailTextLabel?.text = "\(item)"
                            cell?.accessoryType = .detailButton
                        }
                    }
                }
            } else if value is NSDictionary {
                cell?.textLabel?.text = key
                cell?.accessoryType = .disclosureIndicator
                if let dictionary: NSDictionary = value as? NSDictionary {
                    cell?.detailTextLabel?.text = "Dictionary[\(dictionary.allKeys.count)]"
                }
            } else {
                cell?.textLabel?.text = key
                cell?.detailTextLabel?.text = "\(value)"
                cell?.accessoryType = .detailButton
            }
        }
        cell?.accessoryView?.tintColor = kButtonColor
        return cell!
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.001
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.001
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let key = allKeys[indexPath.section]
        if let value = previewDict[key] {
            if value is NSDictionary {
                if let dictionary: NSMutableDictionary = value as? NSMutableDictionary {
                    let controller = PlistPreviewController.init(dictionary: dictionary)
                    controller.title = key
                    self.navigationController?.pushViewController(controller, animated: true)
                }
            } else if value is NSArray {
                if let array: NSArray = value as? NSArray {
                    if indexPath.row == 0 {
                        if let open = cellSecitonOpen[indexPath.section] {
                            cellSecitonOpen[indexPath.section] = !open
                        } else {
                            cellSecitonOpen[indexPath.section] = true
                        }
                        tableView.reloadData()
                    } else {
                        let item = array[indexPath.row - 1]
                        if item is NSDictionary {
                            if let dictionary: NSMutableDictionary = item as? NSMutableDictionary {
                                let controller = PlistPreviewController.init(dictionary: dictionary)
                                controller.title = key
                                self.navigationController?.pushViewController(controller, animated: true)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        print(message: "accessoryButtonTappedForRowWith indexPath:\(indexPath.section)")
        let key = allKeys[indexPath.section]
        if let value = previewDict[key] {
            if value is NSArray {
                if let array: NSArray = value as? NSArray {
                    self.showDialogTextFieldViewController(title: key, text: "\(array[indexPath.row - 1])") { submitText in
                        let mutableArray: NSMutableArray = NSMutableArray.init(array: array)
                        mutableArray[indexPath.row - 1] = submitText
                        self.previewDict[key] = mutableArray
                        self.tableView.reloadData()
                    }
                }
            } else {
                self.showDialogTextFieldViewController(title: key, text: "\(value)") { [self] submitText in
                    if self.previewDict[key] is String {
                        self.previewDict[key] = submitText
                    } else if self.previewDict[key] is Bool {
                        if let boolValue: Bool = Bool(submitText) {
                            self.previewDict[key] = boolValue
                        } else {
                            kAlert("请输入0或者1，0表示NO，1表示YES。")
                        }
                    } else {
                        kAlert("该类型参数暂不支持修改！")
                    }
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction.init(style: .destructive, title: "删除") { [unowned self] _, _ in
            let key = allKeys[indexPath.section]
            if indexPath.row == 0 {
                previewDict.removeObject(forKey: key)
                allKeys.removeAll()
                for key in previewDict.allKeys {
                    allKeys.append("\(key)")
                }
                allKeys.sort()
            } else {
                if let value = previewDict[key] {
                    if value is NSArray {
                        let array: NSMutableArray = NSMutableArray.init(array: value as! NSArray)
                        array.removeObject(at: indexPath.row - 1)
                        previewDict[key] = array
                    }
                }
            }
            self.tableView.reloadData()
        }
        deleteAction.backgroundColor = kRGBColor(243, 64, 54)
        return [deleteAction]
    }

    func showDialogTextFieldViewController(title: String, text: String, keyboardType: UIKeyboardType = .default, submitBlock: ((String) -> ())?) {
        let dialogViewController = QMUIDialogTextFieldViewController()
        dialogViewController.title = title
        dialogViewController.addTextField(withTitle: nil) { (titleLabel, textField, separatorLayer) in
            textField.text = text
            textField.placeholder = text
            textField.keyboardType = keyboardType
            textField.maximumTextLength = 100
        }
        dialogViewController.addCancelButton(withText: "取消", block: nil)
        dialogViewController.addSubmitButton(withText: "确定") { d in
            d.hide()
            let text = dialogViewController.textFields![0].text!
            submitBlock?(text)
        }
        dialogViewController.show()
    }
}
