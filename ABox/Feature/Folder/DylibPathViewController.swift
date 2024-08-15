import UIKit
import Material
import RxCocoa
import RxSwift

class DylibPathViewController: ViewController {
    
    var executableURL: URL!
    var dylibLoadPaths: [String] = []
    var deleteMode = false
    
    private let tableView = QMUITableView.init(frame: CGRect.zero, style: .grouped)
    private var addButton = Button()
    private let cellIdentifier = "DylibPathCell"

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        let paths: [String] = ClassDumpUtils.dylibLoadPaths(withExecutablePath: executableURL.path)
        dylibLoadPaths = paths.filter({ value in
            return value.hasPrefix("@")
        })
//        dylibLoadPaths = ClassDumpUtils.dylibLoadPaths(withExecutablePath: executableURL.path).reversed()
                
        if deleteMode {
            self.title = "删除插件"
            self.tableView.isEditing = true
        } else {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem.init(image: Icon.add?.qmui_image(withTintColor: .black), style: .done, target: self, action: #selector(installDylib))
        }
        self.tableView.reloadData()
    }
    
    override func initSubviews() {
        super.initSubviews()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.showsVerticalScrollIndicator = false
        self.tableView.showsHorizontalScrollIndicator = false
        self.tableView.setEmptyDataSet(title: nil, descriptionString: nil, image: UIImage(named: "file-storage"))
        self.tableView.register(QMUITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.left.top.right.equalTo(0)
            maker.bottom.equalTo(0)
        }
    }
    
    @objc
    func installDylib() {
        let dialogViewController = QMUIDialogTextFieldViewController()
        dialogViewController.title = "注入依赖路径"
        dialogViewController.addTextField(withTitle: nil) { (titleLabel, textField, separatorLayer) in
            textField.placeholder = "dylib path"
            textField.text = "@executable_path/"
            textField.maximumTextLength = 100
            textField.becomeFirstResponder()
        }
        dialogViewController.shouldManageTextFieldsReturnEventAutomatically = true
        dialogViewController.addCancelButton(withText: "取消", block: nil)
        dialogViewController.addSubmitButton(withText: "确定") { [unowned self] d in
            d.hide()
            let path = dialogViewController.textFields![0].text!.removeAllSapce
            patch_binary(self.executableURL.path, path, "load")
            self.dylibLoadPaths = ClassDumpUtils.dylibLoadPaths(withExecutablePath: executableURL.path)
            self.tableView.reloadData()
        }
        dialogViewController.show()
    }
    
    func uninstallDylib(dylibPath: String, index: Int) {
        let alertController = QMUIAlertController.init(title: "确定删除吗？", message: dylibPath, preferredStyle: .alert)
        alertController.addCancelAction()
        alertController.addAction(QMUIAlertAction(title: "确定", style: .destructive, handler: { _, _ in
            
            // 删除文件
            var dylibRealPath: String = self.executableURL.deletingLastPathComponent().appendingPathComponent(dylibPath).path
            if dylibPath.contains("@executable_path/") {
                dylibRealPath = dylibRealPath.replacingOccurrences(of: "@executable_path/", with: "")
            } else if dylibPath.contains("@loader_path/") {
                dylibRealPath = dylibRealPath.replacingOccurrences(of: "@loader_path/", with: "")
            } else if dylibPath.contains("@rpath/") {
                dylibRealPath = dylibRealPath.replacingOccurrences(of: "@rpath/", with: "")
            }
            if FileManager.default.fileExists(atPath: dylibRealPath) {
                do {
                    try FileManager.default.removeItem(atPath: dylibRealPath)
                } catch let error {
                    print(message: "删除\(dylibRealPath)失败，\(error.localizedDescription)")
                }
            }
            // uninstallDylib
            remove_binary(self.executableURL.path, dylibPath)
            self.dylibLoadPaths.remove(at: index)
            self.tableView.reloadData()
        }))
        alertController.showWith(animated: true)
    }
    
    func renameDylib(dylibPath: String) {
        let dialogViewController = QMUIDialogTextFieldViewController()
        dialogViewController.title = "修改插件路径"
        dialogViewController.addTextField(withTitle: nil) { (titleLabel, textField, separatorLayer) in
            textField.placeholder = "dylib path"
            textField.text = "@executable_path/"
            textField.maximumTextLength = 100
            textField.becomeFirstResponder()
        }
        dialogViewController.shouldManageTextFieldsReturnEventAutomatically = true
        dialogViewController.addCancelButton(withText: "取消", block: nil)
        dialogViewController.addSubmitButton(withText: "确定") { [unowned self] d in
            d.hide()
            let path = dialogViewController.textFields![0].text!.removeAllSapce
            change_binary(self.executableURL.path, dylibPath, path)
            self.dylibLoadPaths = ClassDumpUtils.dylibLoadPaths(withExecutablePath: executableURL.path)
            self.tableView.reloadData()
        }
        dialogViewController.show()
    }
}

extension DylibPathViewController: QMUITableViewDelegate, QMUITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return  1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dylibLoadPaths.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "cell"
        var cell = tableView.dequeueReusableCell(withIdentifier: identifier)
        if (cell == nil) {
            cell = QMUITableViewCell(for: tableView, with: .subtitle, reuseIdentifier: identifier)
            cell?.backgroundColor = .white
            cell?.selectionStyle = .none
            cell?.textLabel?.font = UIFont.regular(aSize: 14)
            cell?.textLabel?.textColor = kTextColor
            cell?.textLabel?.numberOfLines = 0
        }
        let dylibPath = dylibLoadPaths[indexPath.row]
        cell?.textLabel?.text = dylibPath
        cell?.textLabel?.textColor = (dylibPath == "/usr/lib/libsubstrate.dylib" || dylibPath == "/Library/Frameworks/CydiaSubstrate.framework/CydiaSubstrate") ? .red : .black
        return cell!
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return self.deleteMode ? .delete : .none
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        UIImpactFeedbackGenerator.init(style: .medium).impactOccurred()
        if editingStyle == .delete {
            let dylibPath = dylibLoadPaths[indexPath.row]
            self.uninstallDylib(dylibPath: dylibPath, index: indexPath.row)
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        UIImpactFeedbackGenerator.init(style: .medium).impactOccurred()
        if deleteMode {
            return
        }
        let dylibPath = dylibLoadPaths[indexPath.row]
        let alert = QMUIAlertController.init(title: self.executableURL.lastPathComponent, message: dylibPath, preferredStyle: .actionSheet)
        alert.addAction(QMUIAlertAction.init(title: "修改", style: .default, handler: { [unowned self] _, _ in
            self.renameDylib(dylibPath: dylibPath)

        }))
        alert.addAction(QMUIAlertAction.init(title: "删除", style: .destructive, handler: { [unowned self] _, _ in
            self.uninstallDylib(dylibPath: dylibPath, index: indexPath.row)
        }))
        alert.addCancelAction()
        alert.showWith(animated: true)
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let dylibPath = dylibLoadPaths[indexPath.row]
        let renameAction = UITableViewRowAction.init(style: .default, title: "修改") { [unowned self] _, i in
            UIImpactFeedbackGenerator.init(style: .medium).impactOccurred()
            self.renameDylib(dylibPath: dylibPath)
        }
        renameAction.backgroundColor = kButtonColor
        
        let deleteAction = UITableViewRowAction.init(style: .destructive, title: "删除") { [unowned self] _, i in
            self.uninstallDylib(dylibPath: dylibPath, index: indexPath.row)
        }
        deleteAction.backgroundColor = kRGBColor(243, 64, 54)
        return self.deleteMode ? [deleteAction] : [deleteAction, renameAction]
    }
}
