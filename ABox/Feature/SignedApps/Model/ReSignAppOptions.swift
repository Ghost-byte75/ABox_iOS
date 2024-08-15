import UIKit

class ReSignAppOptions: NSObject {

    var appName = ""
    var appBundleID = ""
    var appVersion = ""
    var removeMinimumOSVersionEnabled = false
    var copyInstallEnabled = false
    var fileSharingEnabled = false
    var removePlugInsEnabled = true
    var removeWatchEnabled = true
    var fixIconEnabled = false
    var removeOpenURLEnabled = false
    var onlyModifyEnabled = false
    var removeEmbeddedEnabled = false
    var customIcon: UIImage?
    var dylibURLs: [URL] = []
    var classdumpOutputURL: URL?
    
}
