import UIKit
import HandyJSON

class AppLibraryModel: HandyJSON {
    
    var key = ""
    var appName = ""
    var appBundleFileName = ""
    var ipaFileName = ""
    var importDate = ""
    var deleted = false
    
    func appBundleURL() -> URL {
        return FileManager.default.appLibraryDirectory.appendingPathComponent("\(self.key)/\(self.appBundleFileName)")
    }
    
    func ipaFileURL() -> URL {
        return FileManager.default.appLibraryDirectory.appendingPathComponent("\(self.key)/\(self.ipaFileName)")
    }
    
    static func importApplication(_ application: ABApplication, key: String, ipaURL: URL, toDirectoryURL: URL) {
        let ipaFileName = ipaURL.lastPathComponent
        if AppLibraryModel.isImported(ipaFileName) {
            let alertController = QMUIAlertController.init(title: "文件已存在", message: "已存在\(ipaFileName)，是否继续导入。", preferredStyle: .alert)
            alertController.addCancelAction()
            alertController.addAction(QMUIAlertAction(title: "确定", style: .default, handler: { _, _ in
                UserDefaults.standard.removeObject(forKey: ipaFileName)
                AppLibraryModel.importApplication(application, key: key, ipaURL: ipaURL, toDirectoryURL: toDirectoryURL)
            }))
            alertController.showWith(animated: true)
            return
        }
            
        let appLibraryModel = AppLibraryModel()
        appLibraryModel.key = key
        appLibraryModel.appName = application.name
        appLibraryModel.appBundleFileName = application.fileURL.lastPathComponent
        appLibraryModel.importDate = Date().toString(.custom("MM-dd HH:mm"))
        do {
            let copyURL = toDirectoryURL.appendingPathComponent(ipaURL.lastPathComponent)
            try FileManager.default.copyItem(at: ipaURL, to: copyURL)
            appLibraryModel.ipaFileName = ipaFileName
            Client.shared.store?.createTable(withName: kAppLibraryTableName)
            Client.shared.store?.put(appLibraryModel.toJSONString()!, withId: key, intoTable: kAppLibraryTableName)
            UserDefaults.standard.setValue("\(key)/\(appLibraryModel.appBundleFileName)", forKey: ipaFileName)
            kAlert("已导入应用库", message: ipaFileName)
        } catch let error {
            kAlert(error.localizedDescription)
        }
    }
    
    static func isImported(_ key: String) -> Bool {
        if let value = UserDefaults.standard.string(forKey: key) {
            let url = FileManager.default.appLibraryDirectory.appendingPathComponent(value)
            return FileManager.default.fileExists(atPath: url.path)
        }
        return false
    }
    
    required init() {}
}

class SignedAppModel: HandyJSON {
    
    var signedDate = Date().toString(.custom("yyyy-MM-dd HH:mm:ss"))
    var ipaName = ""
    var iconName = ""
    var signedCertificateName = ""
    var name = ""
    var bundleIdentifier = ""
    var version = ""
    var minimumiOSVersion = ""
    var log = ""
    var deleted = false

    required init() {}

}
