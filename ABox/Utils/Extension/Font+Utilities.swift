import Foundation

import Material

extension UIFont {
    
    static func regular(aSize: CGFloat) -> UIFont {
        return RobotoFont.regular(with: aSize)
    }
    
    static func medium(aSize: CGFloat) -> UIFont {
        return RobotoFont.medium(with: aSize)
    }
    
    static func bold(aSize: CGFloat) -> UIFont {
        return RobotoFont.bold(with: aSize)
    }
    
    static func light(aSize: CGFloat) -> UIFont {
        return RobotoFont.light(with: aSize)
    }
    
    static func thin(aSize: CGFloat) -> UIFont {
        return RobotoFont.thin(with: aSize)
    }
    
}

