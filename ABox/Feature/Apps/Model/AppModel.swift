import UIKit
import HandyJSON

class AppModel: HandyJSON {
    
    var id = ""
    var name = ""
    var version = ""
    var versionDate = ""
    var versionDescription = ""
    var downloadURL = ""
    var iconURL = ""
    var tintColor = "95b5d6"
    var size: Int = 0
    var weigh: Int = 0
    var type = ""
    var lock = false
    var cellHeight: Float = 0
    var sourceIdentifier = ""
    var sourceName = ""
    
    required init() {}
    
    func fileName() -> String {
        if let name: String = UserDefaults.standard.object(forKey: self.downloadURL) as? String {
            return name
        }
        return "\(self.name)_\(self.version)_\(self.id)_\(self.sourceIdentifier.count > 0 ? self.sourceIdentifier : self.versionDate).ipa"
    }
    
    func ipaURL() -> URL {
        return FileManager.default.appsDirectory.appendingPathComponent(fileName())
    }
    
    func downloaded() -> Bool {
        let fileExists = FileManager.default.fileExists(atPath: self.ipaURL().path)
        if !fileExists {
            UserDefaults.standard.removeObject(forKey: self.downloadURL)
        }
        print(message: "fileExists: \(fileExists)\nipaURL:\(self.ipaURL().path)")
        return fileExists
    }
    
 
}



