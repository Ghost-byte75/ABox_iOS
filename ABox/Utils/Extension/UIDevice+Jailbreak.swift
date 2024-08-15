import UIKit
import IOSSecuritySuite

extension UIDevice {
    
    var isJailbroken: Bool {
        return IOSSecuritySuite.amIJailbroken()
//        if
//            FileManager.default.fileExists(atPath: "/Applications/Cydia.app") ||
//            FileManager.default.fileExists(atPath: "/Library/MobileSubstrate/MobileSubstrate.dylib") ||
//            FileManager.default.fileExists(atPath: "/bin/bash") ||
//            FileManager.default.fileExists(atPath: "/usr/sbin/sshd") ||
//            FileManager.default.fileExists(atPath: "/etc/apt") ||
//            FileManager.default.fileExists(atPath: "/private/var/lib/apt/") {
//            return true
//        } else {
//            return false
//        }
    }

}

//  || UIApplication.shared.canOpenURL(URL(string:"cydia://")!
