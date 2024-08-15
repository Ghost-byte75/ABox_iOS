import UIKit
import RxSwift
import RxCocoa
import SnapKit

import SafariServices



class ViewController: QMUICommonViewController, SFSafariViewControllerDelegate {

    let disposeBag = DisposeBag()
    
    var getUDID = false
    
    override func initSubviews() {
        super.initSubviews()
        self.view.backgroundColor = .white
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.supportedOrientationMask = .portrait
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    override func shouldHideKeyboardWhenTouch(in view: UIView?) -> Bool {
        return true
    }
    
    override func qmui_navigationBarBackgroundImage() -> UIImage? {
        return UIImage.qmui_image(with: .white)
    }
    
    
    func getUDIDWithSafari() {
        self.getUDID = true
        let safariViewController = SFSafariViewController(url: AppManager.default.getUDIDURL)
        safariViewController.configuration.entersReaderIfAvailable = false
        safariViewController.configuration.barCollapsingEnabled = false
        safariViewController.dismissButtonStyle = .done
        safariViewController.delegate = self
        self.present(safariViewController, animated: true, completion: nil)
        
    }
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        if self.getUDID {
            self.getUDID = false
            if let siriSettingsURL = URL(string: "App-Prefs://") {
                UIApplication.shared.open(siriSettingsURL)
            }
        }
    }

}


