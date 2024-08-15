import Foundation

extension URL {
    
    public var isCertificate: Bool {
        return self.pathExtension.lowercased() == "p12"
    }
    
    public var isMobileProvision: Bool {
        return self.pathExtension.lowercased() == "mobileprovision"
    }
    
    public var isIPA: Bool {
        return self.pathExtension.lowercased() == "ipa"
    }
    
    public var isDylib: Bool {
        return self.pathExtension.lowercased() == "dylib"
    }
    
    public var isFramework: Bool {
        return self.pathExtension.lowercased() == "framework"
    }
    
    public var parametersFromQueryString: [String: String]? {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: true),
        let queryItems = components.queryItems else { return nil }
        return queryItems.reduce(into: [String: String]()) { (result, item) in
            result[item.name] = item.value
        }
    }
    
}
