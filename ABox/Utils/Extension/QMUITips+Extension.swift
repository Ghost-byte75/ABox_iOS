import Foundation
import UIKit


extension QMUITips {
    
    func whiteStyle() {
        let backgroundView: QMUIToastBackgroundView = self.backgroundView as! QMUIToastBackgroundView
        backgroundView.shouldBlurBackgroundView = true
        backgroundView.styleColor = kRGBAColor(222, 222, 222, 0.8)
        self.tintColor = .black
    }
    
    static func showProgressView(_ inView: UIView, status: String) -> M13ProgressHUD {
        let hud = M13ProgressHUD(progressView: M13ProgressViewRing())!
        hud.maskType = .init(1)
        hud.hudBackgroundColor = kRGBColor(241, 241, 241)
        hud.progressViewSize = CGSize(width: 60, height: 60)
        hud.animationPoint = CGPoint(x: kUIScreenWidth/2, y: kUIScreenHeight/2)
        hud.primaryColor = kTextColor
        hud.secondaryColor = kTextColor
        hud.statusFont = UIFont.medium(aSize: 13)
        hud.statusColor = kTextColor
        inView.addSubview(hud)
        hud.show(true)
        hud.status = status
        return hud
    }
    
}



