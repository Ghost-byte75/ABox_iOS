import Foundation
import Material
import Async
import UIKit

//获取沙盒Document路径
let kDocumentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first

//获取沙盒Cache路径
let kCachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first

//获取沙盒temp路径
let kTempPath = NSTemporaryDirectory()

//颜色
func kRGBAColor(_ r: CGFloat,_ g: CGFloat,_ b: CGFloat,_ a: CGFloat) -> UIColor {
    return UIColor.init(red: r/255.0, green: g/255.0, blue: b/255.0, alpha: a)
}

func kRGBColor(_ r: CGFloat,_ g: CGFloat,_ b: CGFloat) -> UIColor {
    return UIColor.init(red: r/255.0, green: g/255.0, blue: b/255.0, alpha: 1.0)
}

// 主题色
let kMainRedColor = UIColor.qmui_color(withHexString: "#ff654f")!
// 界面背景色
let kBackgroundColor = kRGBColor(246, 246, 246)
// 全局默认的分割线颜色
let kSeparatorColor = kRGBColor(222, 224, 224)
// 全局默认的虚线分隔线的颜色
let kSeparatorDashedColor = kRGBColor(17, 17, 17)
let kTextColor = kRGBColor(31, 31, 31)
let kSubtextColor = kRGBColor(101, 101, 101)
let kButtonColor = kRGBColor(32, 150, 243)
let kGreenColor = UIColor.qmui_color(withHexString: "#00c853")!

// UINavigationBar 的背景
let kNavBarBackgroundColor = UIColor.white
// UINavigationBar 的 tintColor，也即导航栏上面的按钮颜色
let kNavBarTintColor = UIColor.black
// NavBarBarTintColor : UINavigationBar.barTintColor，也即背景色
let kNavBarBarTintColor = UIColor.black

//开发的时候打印，但是发布的时候不打印,使用方法，输入print(message: "输入")
func print<T>(message: T, fileName: String = #file, methodName: String = #function, lineNumber: Int = #line) {
    #if DEBUG
    let dformatter = DateFormatter()
    dformatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    let lastName = ((fileName as NSString).pathComponents.last!)
    let formatMessage = "\n\(dformatter.string(from: Date()))\n\(lastName) 第\(lineNumber)行 \(methodName)\n\(message)\n"
    print(formatMessage)
    Async.main {
        QMUIConsole.log(withLevel: "AppLog", name: lastName, logString: "\n\(lastName) 第\(lineNumber)行\n\(methodName)\n\(message)\n")
    }
    #endif
}

// UserDefaults 操作
let kUserDefaults = UserDefaults.standard
func kUserDefaultsRead(_ keyStr: String) -> String? {
    return kUserDefaults.string(forKey: keyStr)
}
func kUserDefaultsWrite(_ obj: Any, _ keyStr: String) {
    kUserDefaults.set(obj, forKey: keyStr)
}
func kUserValue(_ A: String) -> Any? {
    return kUserDefaults.value(forKey: A)
}

//获取屏幕大小
let kUIScreenSize = UIScreen.main.responds(to: #selector(getter: UIScreen.nativeBounds)) ? CGSize(width: UIScreen.main.nativeBounds.size.width / UIScreen.main.nativeScale, height: UIScreen.main.nativeBounds.size.height / UIScreen.main.nativeScale) : UIScreen.main.bounds.size
let kUIScreenWidth = kUIScreenSize.width
let kUIScreenHeight = kUIScreenSize.height
let kUIScreenBounds = UIScreen.main.bounds

//APP版本号
let kAppVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"]
let kAppBuildVersion = Bundle.main.infoDictionary?["CFBundleVersion"]
let kAppDisPlayName = Bundle.main.infoDictionary?["CFBundleDisplayName"]
//当前系统版本号
let kVersion = (UIDevice.current.systemVersion as NSString).floatValue
//BundleIdentifier
let kAppBundleIdentifier = Bundle.main.infoDictionary?["CFBundleIdentifier"]

//检测用户版本号
let kiOS16 = (kVersion >= 16.0 && kVersion < 17.0)
let kiOS15 = (kVersion >= 15.0 && kVersion < 16.0)
let kiOS14 = (kVersion >= 14.0 && kVersion < 15.0)
let kiOS13 = (kVersion >= 13.0 && kVersion < 14.0)
let kiOS12 = (kVersion >= 12.0 && kVersion < 13.0)
let kiOS11 = (kVersion >= 11.0 && kVersion < 12.0)
let kiOS10 = (kVersion >= 10.0 && kVersion < 11.0)
let kiOS9 = (kVersion >= 9.0 && kVersion < 10.0)
let kiOS8 = (kVersion >= 8.0 && kVersion < 9.0)

let kiOS16Later = (kVersion >= 16.0)
let kiOS15Later = (kVersion >= 15.0)
let kiOS14Later = (kVersion >= 14.0)
let kiOS13Later = (kVersion >= 13.0)
let kiOS12Later = (kVersion >= 12.0)
let kiOS11Later = (kVersion >= 11.0)
let kiOS10Later = (kVersion >= 10.0)
let kiOS9Later = (kVersion >= 9.0)
let kiOS8Later = (kVersion >= 8.0)

//获取当前语言
let kAppCurrentLanguage = Locale.preferredLanguages[0]
//判断是否为iPhone
let kDeviceIsiPhone = UIDevice.current.userInterfaceIdiom == .phone
//判断是否为iPad
let kDeviceIsiPad = UIDevice.current.userInterfaceIdiom == .pad

//判断 iPhone 的屏幕尺寸
let kSCREEN_MAX_LENGTH = max(kUIScreenWidth, kUIScreenHeight)
let kSCREEN_MIN_LENGTH = min(kUIScreenWidth, kUIScreenHeight)

//适配 350 375 414       568 667 736
func kAutoLayoutWidth(_ width: CGFloat) -> CGFloat {
    return width*kUIScreenWidth / 375
}
func kAutoLayoutHeigth(_ height: CGFloat) -> CGFloat {
    return height*kUIScreenHeight / 667
}

//机型判断
let kUI_IPHONE = (UIDevice.current.userInterfaceIdiom == .phone)
let kUI_IPHONE5 = (kUI_IPHONE && kSCREEN_MAX_LENGTH == 568.0)
let kUI_IPHONE6 = (kUI_IPHONE && kSCREEN_MAX_LENGTH == 667.0)
let kUI_IPHONEPLUS = (kUI_IPHONE && kSCREEN_MAX_LENGTH == 736.0)
let kUI_IPHONEX = (kUI_IPHONE && kSCREEN_MAX_LENGTH > 780.0)

//获取状态栏、标题栏、导航栏高度
let kUIStatusBarHeight: CGFloat = QMUIHelper.isNotchedScreen ? 44 : 20
let kUINavigationBarHeight: CGFloat = 44
let kUINavigationContentTop: CGFloat = 88

// 注册通知
func kNOTIFY_ADD(observer: Any, selector: Selector, name: String) {
    return NotificationCenter.default.addObserver(observer, selector: selector, name: Notification.Name(rawValue: name), object: nil)
}
// 发送通知
func kNOTIFY_POST(name: String, object: Any) {
    return NotificationCenter.default.post(name: Notification.Name(rawValue: name), object: object)
}
// 移除通知
func kNOTIFY_REMOVE(observer: Any, name: String) {
    return NotificationCenter.default.removeObserver(observer, name: Notification.Name(rawValue: name), object: nil)
}

//代码缩写
let kApplication = UIApplication.shared
let kAPPKeyWindow = kApplication.keyWindow
let kAppDelegate = kApplication.delegate
let kAppNotificationCenter = NotificationCenter.default
let kAppRootViewController = kAppDelegate?.window??.rootViewController

//字体 字号
func kFontSize(_ a: CGFloat) -> UIFont {
    return UIFont.systemFont(ofSize: a)
}
func kFontBoldSize(_ a: CGFloat) -> UIFont {
    return UIFont.boldSystemFont(ofSize: a)
}
func kFontForIPhone5or6Size(_ a: CGFloat, _ b: CGFloat) -> UIFont {
    return kUI_IPHONE5 ? kFontSize(a) : kFontSize(b)
}

/**
 字符串是否为空
 @param str NSString 类型 和 子类
 @return  BOOL类型 true or false
 */
func kStringIsEmpty(_ str: String?) -> Bool {
    if let string = str {
        if string.isEmpty {
            return true
        }
        if string.count < 1 {
            return true
        }
        if string == "(null)" {
            return true
        }
        if string == "null" {
            return true
        }
    }
    return false
}

// 字符串判空 如果为空返回@“”
func kStringNullToempty(_ str: String) -> String {
    let resutl = kStringIsEmpty(str) ? "" : str
    return resutl
}
func kStringNullToReplaceStr(_ str: String,_ replaceStr: String) -> String {
    let resutl = kStringIsEmpty(str) ? replaceStr : str
    return resutl
}

/**
 数组是否为空
 @param array NSArray 类型 和 子类
 @return BOOL类型 true or false
 */
func kArrayIsEmpty(_ array: [String]) -> Bool {
    let str: String! = array.joined(separator: "")
    if str == nil {
        return true
    }
    if str == "(null)" {
        return true
    }
    if array.count == 0 {
        return true
    }
    if array.isEmpty {
        return true
    }
    return false
}
/**
 字典是否为空
 @param dic NSDictionary 类型 和子类
 @return BOOL类型 true or false
 */
func kDictIsEmpty(_ dict: NSDictionary) -> Bool {
    let str: String! = "\(dict)"
    if str == nil {
        return true
    }
    if str == "(null)" {
        return true
    }
    if dict .isKind(of: NSNull.self) {
        return true
    }
    if dict.allKeys.count == 0 {
        return true
    }
    return false
}

var showingAlert = false

func kAlert(_ title: String, message: String? = nil, showCancel: Bool = false, preferredStyle: QMUIAlertControllerStyle = .alert,  callBack: (()->())? = nil) {
    guard showingAlert else {
        UIImpactFeedbackGenerator.init(style: .medium).impactOccurred()
        let alertController = QMUIAlertController.init(title: title, message: message, preferredStyle: preferredStyle)
        if showCancel {
            alertController.addAction(QMUIAlertAction(title: "取消", style: .cancel, handler: { _, _ in
                showingAlert = false
            }))
        }
        alertController.addAction(QMUIAlertAction(title: "确定", style: .default, handler: { _, _ in
            showingAlert = false
            callBack?()
        }))
        alertController.showWith(animated: true)
        showingAlert = true
        return
    }
}

let wordTypes = ["doc", "docm", "docx", "docx", "dot", "dotm", "dotx", "odt", "xps"]
let excelTypes = ["csv", "xls", "xlsb", "xlsm", "xlsx", "xlt", "xltm", "xltx", "xlw", "xml"]
let pptTypes = ["pot", "potm", "potx", "ppa", "ppam", "pps", "ppsm", "ppsx", "ppt", "pptm", "pptx"]
let imageTypes = ["png", "jpeg", "jpg", "gif", "webp", "bpg", "svg", "raw", "apng"]
let codeTypes = ["swift", "h", "m", "cpp", "mm", "js", "json", "py", "ry", "java", "lua", "ts", "xib", "nib"]
let archiverTypes = ["rar", "7z", "lha", "lzh", "zipx", "sit", "sitx", "1", "hqx", "bin", "macbin", "as", "gz", "gzip", "tgz", "tgz", "bz2", "bzip2", "bz", "tbz2", "tbz", "xz", "txz", "tar", "iso", "cdi", "nrg", "mdf", "gtar", "z", "tar", "tar-z", "lzma", "xar", "xip", "ace", "arj", "arc", "pak", "spk", "zoo", "lbr", "lqr", "lzr", "pma", "cab", "rpm", "deb", "alz", "dd", "cpt", "pit", "now", "sea", "exe", "msi", "cpio", "cpgz", "pax", "warc", "ha", "adf", "adz", "dms", "f", "lzx", "dcs", "pkd", "xms", "zom", "pp", "nsa", "sar"]

let kDownloadTableName = "download_tbl"
let kSignedAppTableName = "signedApp_tbl"
let kAppLibraryTableName = "appLibrary_tbl"

let AESNormalKey = "116abcdefghi2235"
let kZipCompressionLevel = "ZipCompressionLevel"


let SourcePrivateKey = """
-----BEGIN RSA PRIVATE KEY-----
MIIEpQIBAAKCAQEArzX27YBOi0fHf38zy1YixtNGW7GKBNsppFBhT95obvpAr5vw
ZLvakizcWtTK5Jzdvhx0SvyEWX9KUrp9O0oj+9zxLgVZU6w2yPvirZ+WOwz/of53
IQuWUgSnE+wUetFsFATnjoQjNX9T3JsdzrqQEdRBV4s5YJjoMmX3dkyjbi+oKs5+
XCNiI7KiRcv/ELUcT8pvVVgzkf19w2fnm7Lk0x/BfIPnLQHAa2XzzturJ9pSyyFB
XJ7jVbDEs+Dyb5KSwYy+Q6sA0NrLARcfxK6vI4tdbkLKDI8izRLMqMrAUPyiO9WJ
TZc8pA7x6sDCVpV0hs72t7IWmXw8KYvoglBYhQIDAQABAoIBAAaiA1wQXGjXac0A
0sQi2aQvQV2dRf1TEqt+w4BTih6RaLt9KseVePvJqPnjTl8DNT3KM/jWwGfm8rhZ
CP6imuQhBBxa5XvObDCFoJo0DWrk3hSS3o2os6MdO/n8GPZhUTcczGtPw0l2LYWP
dbxqwaN7JpIa2iw2/atSwuB+nD1CjoQhli9q9Nr5ScotbP5TvW1Db8agXxMh9GgH
GXoPhc8N8s4i8/6+7FnJ9LYeUKRP8pN/79pIPMmkyPg6qgzUgf74Q9LKS7hT3vyN
CQERS15hZTfR+AAXPwHtAStWJ1GlMRTVllNSNoboOsRJdE9FTZ1oI+qxWB4Ql+ts
pie30y0CgYEA5Vytmqvcq0HMnZMW7SVcx4v3gGxfVDpGA+enMtNvWJnQeYBDZw5y
907t+8jSvJlRE7DXN82vV+6yNrSCAIYUTDx+RtiLR+91qAYw0UalRDfbkP7EYB4Q
Uz1bNmm6ywhPeTyEa7vcMPZIum6FM2ykgP0pWD8j17dCEAu9UpY7NfMCgYEAw49H
WC7eXfHgkvDntz7zphLgjKwUCmvwEYp+ncF0KTXt/jMrvzIr0m1vxALVXU/XrZEa
vhurb44KxTMam7PHqEoCGxAaaDqxDDxrW2E3s81f+bYNchO4K8pTE1+inlIDc0mK
XcJgxm4IFPftfUw2Z/WaVqwEg6pUy6MqXBnl/acCgYEArZuW9Eo9/4sQm/0oD1yG
e6xgLN7a0WBCetYvYnNUBpZ2jGEfo7P2JWejD0AU8xiBnAvw+5Y+sKpGTs4W0Nqs
JoBrfKiP1GVWg1YcQWvd0GMPWRLeBXr8FGWO0wL4lpG1xiieewV5R75DkonxXNlR
Myls0BUKxk86O/cG2KpKKy0CgYEArhQCrCq8YuAGyoaLnYD6HmE7Zb1f8Y73moWw
A/nKz0xkWB1w2bdtbtlf3hmvmGqUULqUFZpH1vuX9sZw7xzvo4yNp02EVDe6lmvK
HQPDM9ijkINQILYRAVoO7XX6KfhTffJ+qst2newgYZn428pVu+DSzEg/lHyxErxh
3q5nHo0CgYEA1IOPGGpvqxgoe+AD3yCccRaoJOij1T2bHcu1H1GcOcuWrIdjgQDb
MYu4QiwjQiydMeXxokQcPUKi/S7pgA7fB4cCe0axJVLnyyYj/P9dXH7i2C+S3iRk
A4vszKOKgwB/Kmogk0TQxiON/8KU3Q0ukoB0HBt+TnIxeKEY776C450=
-----END RSA PRIVATE KEY-----
"""
