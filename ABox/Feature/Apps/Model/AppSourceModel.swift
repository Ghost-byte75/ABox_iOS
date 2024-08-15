import UIKit
import HandyJSON

class AppSourceModel: HandyJSON {    
    var sourceURL = ""
    var name = ""
    var message =  ""
    var identifier = ""
    var sourceicon = ""
    var unlockURL =  ""
    var payURL = ""
    var apps: [AppModel] = []
    required init() {}
}
