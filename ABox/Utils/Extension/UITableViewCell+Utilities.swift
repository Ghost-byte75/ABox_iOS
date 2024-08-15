import Foundation
import UIKit

extension UITableViewCell {
    
    static func cellHeight(text: String, width: CGFloat, lineHiehgt: CGFloat, font: UIFont) -> CGFloat {
        let contentLabel = QMUILabel()
        contentLabel.font = font
        contentLabel.text = text
        contentLabel.numberOfLines = 0
        contentLabel.qmui_lineHeight = lineHiehgt
        return contentLabel.sizeThatFits(CGSize.init(width: width, height: CGFloat.greatestFiniteMagnitude)).height
    }
    
    static func cellHeilt(attributedText: NSAttributedString, width: CGFloat)  -> CGFloat {
        let contentLabel = QMUILabel()
        contentLabel.numberOfLines = 0
        contentLabel.qmui_textAttributes = attributedText.attributes(at: 0, effectiveRange: nil)
        contentLabel.text = attributedText.string
        return contentLabel.sizeThatFits(CGSize.init(width: width, height: CGFloat.greatestFiniteMagnitude)).height

    }
}



