import UIKit
import WebKit
import RxSwift
import RxCocoa
import HandyJSON
import Async

class WebViewController: ViewController {

    open var completionWithURL:((URL) -> ())?

    fileprivate var webView: WKWebView!
    fileprivate var requestURL: URL!
    fileprivate let customUA = "Mozilla/5.0 (iPhone; CPU iPhone OS 14_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15E148 Safari/604.1"
    fileprivate let kWebViewTitle = "title"

    //只要重写init方法，就必须要实现的下面三个init方法，少一个都不行
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    init(url: URL) {
        self.init()
        self.requestURL = url
    }
    
    deinit {
        self.webView?.removeObserver(self, forKeyPath: kWebViewTitle)
        NotificationCenter.default.removeObserver(self)
        print(message: "LWebViewController Deinit")
    }
    
    override func initSubviews() {
        super.initSubviews()
        self.webView = WKWebView()
        self.webView.uiDelegate = self
        self.webView.navigationDelegate = self
        self.view.addSubview(webView)
        webView.snp.makeConstraints { maker in
            maker.edges.equalTo(self.view)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.webView?.addObserver(self, forKeyPath: kWebViewTitle, options: .new, context: nil)
        self.webViewLoad(url: requestURL)
     
    }
    
    func webViewLoad(url: URL) {
        webView.customUserAgent = customUA
        let request = URLRequest(url: url)
        self.webView.load(request)
    }
    
    func downloadIPA(urlStr: String) {
        if let url = URL(string: urlStr) {
            self.completionWithURL?(url)
            self.navigationController?.popViewController(animated: true)
        }
    }
    
}

extension WebViewController: WKUIDelegate, WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        webView.customUserAgent = customUA
        if let x = navigationAction.targetFrame {
            if x.isMainFrame == false {
                webView.load(navigationAction.request)
            }
        }
        return nil
    }
    
     func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        webView.customUserAgent = customUA
        if let url = navigationAction.request.url {
            print(message: url.absoluteString)
            
            if url.absoluteString.contains("pos.baidu.com")  {
                decisionHandler(.cancel)
            } else if url.absoluteString.hasPrefix("itms-services") || url.absoluteString.contains("itemService=") {
                if let plistURLStr = url.parametersFromQueryString?["url"] {
                    var newPlistReq = navigationAction.request
                    newPlistReq.url = URL(string: plistURLStr)
                    //self.downloadManifest(urlStr: plistURLStr)
                    ZXIpaHttpRequest.downLoad(withUrlStr: plistURLStr, path: ".ipaCache.plist") { result, data in
                        if result {
                            if let plistDic = NSDictionary.init(contentsOfFile: data as! String) {
                                print(message: plistDic)
                                self.downloadIPAForm(dict: plistDic)
                            }
                        } else {
                            print(message: data)
                        }
                    }
                }
                decisionHandler(.cancel)
            } else if url.isIPA || url.absoluteString.contains(".ipa&") {
                self.downloadIPA(urlStr: url.absoluteString)
                decisionHandler(.cancel)
            } else {
                if navigationAction.targetFrame == nil {
                    webView.load(navigationAction.request)
                }
                decisionHandler(.allow)
            }
        } else {
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
            }
            decisionHandler(.allow)
        }
    }

    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        webView.customUserAgent = customUA
        decisionHandler(WKNavigationResponsePolicy.allow)
    }
    
}


extension WebViewController {
    
    func downloadManifest(urlStr: String) {
        let _ = DownloadManager.shared.download(urlStr: urlStr) { fileURL in
            if let dict = NSDictionary(contentsOf: fileURL) {
                self.downloadIPAForm(dict: dict)
            }
        } failure: { error in
            kAlert(error)
        }
    }

    
    func downloadIPAForm(dict: NSDictionary) {
        if let arr: NSArray = dict["items"] as? NSArray {
            if let item: NSDictionary = arr[0] as? NSDictionary {
                do {
                    let data = try JSONSerialization.data(withJSONObject: item, options: .prettyPrinted)
                    let json = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
                    if let json = json {
                        if let assets = [Asset].deserialize(from: json as String, designatedPath: "assets") {
                            for asset in assets {
                                if let a = asset {
                                    if a.kind == "software-package" {
                                        Async.main {
                                            self.downloadIPA(urlStr: a.url)
                                        }
                                    }
                                }
                            }
                        }
                    }
                } catch let error {
                    print("error: \(error)")
                }
            }
        }
    }
    
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == kWebViewTitle {
            self.title = self.webView?.title
        }
    }
}


class Asset: HandyJSON {
    var kind = ""
    var url = ""
    required init() {}
}
