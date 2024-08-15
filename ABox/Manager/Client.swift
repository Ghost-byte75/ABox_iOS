import UIKit
import HandyJSON

class Client: NSObject {
    
    public static let shared = Client()

    var device = ABoxDevice()
    var needRefreshAppList = false
    var showSignedAppList = false
    let store = YTKKeyValueStore.init(dbWithName: ".App.db")
    
#if DEBUG
    let masterUDIDs = ["00000000-0000000000000000"]
#else
    let masterUDIDs = ["00000000-0000000000000000"]
#endif
    
    var requestBackgroundTask: Bool = false

    var isMaster: Bool {
        if let udid = AppDefaults.shared.deviceUDID {
            return masterUDIDs.contains(udid)
        }
        return false
    }
    
    func saveDevice(_ device: ABoxDevice) {
        self.device = device
        if let json = device.toJSONString() {
            AppDefaults.shared.deviceInfo = json
        }
    }
    
    func recoverDeviceInfo() {
        if let json = AppDefaults.shared.deviceInfo {
            if let device = ABoxDevice.deserialize(from: json) {
                self.device = device
            }
        }
    }
    
    func updateDeviceInfo() {
        if AppDefaults.shared.deviceUDID != nil {
            API.default.request(url: "/device/update", method: .post, parameters: ["name": QMUIHelper.deviceName, "jailbroken": UIDevice().isJailbroken]) { result in
                if let device: ABoxDevice = ABoxDevice.deserialize(from: result as? String) {
                    if device.disable {
                        exit(0)
                    }
                    self.saveDevice(device)
                }
            } failure: { error in
            }
        }
    }
    
    func updateLog(_ value: String) {
        API.default.request(url: "/device/log", method: .post, parameters: ["log": value], success: nil, failure: nil)
    }
    
    /*
    func checkForUpdates(success: ((Version)->())?, failure: (()->())? = nil) {
        API.default.request(url: "/abox/lastVersion") { result in
            print(message: result!)
            if let model = Version.deserialize(from: result as? [String: Any]) {
                let appVersion = kAppVersion! as! String
                if model.version > appVersion {
                    success?(model)
                } else {
                    failure?()
                }
            } else {
                failure?()
            }
        } failure: { _ in
            failure?()
        }
    }
    */
}


class Version: HandyJSON {
    var id = 0
    var version = ""
    var info = ""
    var downloadUrl = ""
    var created = ""
    required init() {}
}


class ABoxDevice: HandyJSON {
    var udid = ""
    var jailbroken = false
    var disable = false
    var totalFlow: Int = 0
    var clientVersion = ""
    var redeemCode = ""
    var name = ""
    var created = ""
    var updated = ""
    var osVersion = ""
    var remarks = ""
    required init() {}
}
