import UIKit
import WebKit

class UserAgreementViewController: ViewController {

    var hideNext = false
    var webView: WKWebView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.title = "用户协议"
        initWebView()
        webViewLoadURL()
    }

    func initWebView() {
        let configuration = WKWebViewConfiguration()
        configuration.preferences = WKPreferences()
        configuration.preferences.javaScriptEnabled = true
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
        self.webView = WKWebView.init(frame: CGRect.zero, configuration: configuration)
        self.webView?.uiDelegate = self
        self.webView?.navigationDelegate = self
        self.webView?.allowsBackForwardNavigationGestures = true
        self.view.addSubview(webView!)
        webView.snp.makeConstraints { make in
            make.edges.equalTo(self.view)
        }
    }
    
    func webViewLoadURL() {
        let path = Bundle.main.path(forResource: "agreement", ofType: "html")!
        let url = URL(fileURLWithPath: path)
        self.webView?.loadFileURL(url, allowingReadAccessTo: Bundle.main.bundleURL)
        print(message: Bundle.main.bundleURL)
//        self.webView?.load(URLRequest(url: URL(string: "https://abox.xz-store1993.cn/agreement.html")!))
    }
    
    override func setupNavigationItems() {
        super.setupNavigationItems()
        if !hideNext {
            AppDefaults.shared.installIPAService = 0
            self.navigationItem.rightBarButtonItem = UIBarButtonItem.init(title: "下一步", style: .plain, target: self, action: #selector(aggreUserAgreement))
        }
    }
    
    @objc
    func aggreUserAgreement() {
        
        let alert = QMUIAlertController.init(title: "用户协议", message: "请问是否已阅读本用户协议，并同意协议所包含的条款？", preferredStyle: .alert)
        alert.addCancelAction()
        alert.addAction(QMUIAlertAction.init(title: "同意", style: .default, handler: { _, _ in
            AppDefaults.shared.aggreUserAgreement = true
            //kApplication.keyWindow?.rootViewController = TabBarViewController()
            //if let _ = AppDefaults.shared.deviceUDID {
                kApplication.keyWindow?.rootViewController = TabBarViewController()
            //} else {
            //    kApplication.keyWindow?.rootViewController = GetUDIDViewController()
            //}
        }))
        alert.showWith(animated: true)
        
    }
}


extension UserAgreementViewController: WKUIDelegate {
        
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        completionHandler(true)
    }

}


extension UserAgreementViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        if let url = webView.url {
            print(message: url)
        }
    }
    
}

extension UserAgreementViewController: WKScriptMessageHandler {
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
    }
    
}
