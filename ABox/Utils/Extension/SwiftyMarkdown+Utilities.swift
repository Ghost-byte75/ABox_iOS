import Foundation
import SwiftyMarkdown

extension SwiftyMarkdown {
    
    func customMarkdownStyle() {
        
        
        self.h1.fontName = "Roboto-Bold"
        self.h1.fontSize = 15
        self.h1.color = kTextColor
        self.h1.fontStyle = .bold
        
        self.h2.fontName = "Roboto-Bold"
        self.h2.fontSize = 14.5
        self.h2.color = kTextColor
        self.h2.fontStyle = .bold
        
        self.h3.fontName = "Roboto-Bold"
        self.h3.fontSize = 14
        self.h3.color = kTextColor
        self.h3.fontStyle = .bold
        
        
        self.h3.fontName = "Roboto-Medium"
        self.h3.fontSize = 13.5
        self.h3.color = kTextColor
        self.h3.fontStyle = .normal
        
        self.h4.fontName = "Roboto-Medium"
        self.h4.fontSize = 13
        self.h4.color = kTextColor
        self.h4.fontStyle = .normal
        
        self.h5.fontName = "Roboto-Medium"
        self.h5.fontSize = 12.5
        self.h5.color = kTextColor
        self.h5.fontStyle = .normal
        
        self.h6.fontName = "Roboto-Medium"
        self.h6.fontSize = 12
        self.h6.color = kTextColor
        self.h6.fontStyle = .italic
        
        self.body.fontName = "Roboto-Regular"
        self.body.fontSize = 12
        self.body.color = kTextColor
        self.body.fontStyle = .normal
        
        self.blockquotes.fontName = "Roboto-Regular"
        self.blockquotes.fontSize = 12
        self.blockquotes.color = kTextColor
        self.blockquotes.fontStyle = .normal
        
        self.link.fontName = "Roboto-Regular"
        self.link.fontSize = 12
        self.link.color = kTextColor
        self.link.fontStyle = .italic
        
        
 
    }
    
}
