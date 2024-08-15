import UIKit

@propertyWrapper
public struct UserDefaultsItem<Value> {
    
    public let key: String
    
    public var wrappedValue: Value? {
        get {
            switch Value.self {
            case is Data.Type: return AppDefaults.shared.data(forKey: self.key) as? Value
            case is String.Type: return AppDefaults.shared.string(forKey: self.key) as? Value
            case is Bool.Type: return AppDefaults.shared.bool(forKey: self.key) as? Value
            case is Int.Type: return AppDefaults.shared.integer(forKey: self.key) as? Value
            default: return nil
            }
        }
        set {
            AppDefaults.shared.set(newValue, forKey: self.key)
        }
    }
    
    public init(key: String) {
        self.key = key
    }
}


class AppDefaults: UserDefaults {
    
    public static let shared = AppDefaults()
    
    @UserDefaultsItem(key: "cacheFileSize")
    public var cacheFileSize: Int?
    
    @UserDefaultsItem(key: "backgroundTaskEnable")
    public var backgroundTaskEnable: Bool?
    
    @UserDefaultsItem(key: "deviceUDID")
    public var deviceUDID: String?
    
    @UserDefaultsItem(key: "deviceInfo")
    public var deviceInfo: String?
    
    @UserDefaultsItem(key: "aggreUserAgreement")
    public var aggreUserAgreement: Bool?
    
    @UserDefaultsItem(key: "signingCertificate")
    public var signingCertificate: Data?
    
    @UserDefaultsItem(key: "signingCertificateName")
    public var signingCertificateName: String?
    
    @UserDefaultsItem(key: "signingCertificateSerialNumber")
    public var signingCertificateSerialNumber: String?

    @UserDefaultsItem(key: "signingCertificatePassword")
    public var signingCertificatePassword: String?
    
    @UserDefaultsItem(key: "signingProvisioningProfile")
    public var signingProvisioningProfile: Data?
    
    @UserDefaultsItem(key: "installIPAService")
    public var installIPAService: Int?
    
    @UserDefaultsItem(key: "trollStoreEnable")
    public var trollStoreEnable: Bool?
    
    
    @UserDefaultsItem(key: "appNoticeSha1")
    public var appNoticeSha1: String?
    
    
    @UserDefaultsItem(key: "appSources")
    public var appSources: String?
    
    public func reset() {
        self.deviceUDID = nil
        self.deviceInfo = nil
        self.aggreUserAgreement = nil
        self.signingCertificateName = nil
        self.signingCertificateSerialNumber = nil
        self.signingCertificate = nil
        self.signingCertificatePassword = nil
        self.signingProvisioningProfile = nil
    }
}
