import UIKit
import RxAlamofire
import Alamofire
import RxSwift
import HandyJSON

class LanzouAPI {
    
    static let `default` = LanzouAPI()
    let disposeBag = DisposeBag()
    let agent = "Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1"
    
    func requestDownload(url: String, success: ((String)->())?, failure: ((String)->())?) {
        let requestUrl = "https://www.yuanxiapi.cn/api/lanzou/?url=\(url)"
        RxAlamofire.requestJSON(.get, URL(string: requestUrl)!).subscribe { (response, json) in
            print(message: " responseString:\(json)")
            print(message: response.url)
            if let lanzou = LanzouResponse.deserialize(from: json as? [String: Any]) {
                if lanzou.code == 200 {
                    success?(lanzou.download)
                } else {
                    failure?(lanzou.msg)
                }
            } else {
                failure?("接口失效了")
            }
        } onError: { error in
            failure?(error.localizedDescription)
        }.disposed(by: disposeBag)
        
//        RxAlamofire.requestString(.get, URL(string: requestUrl)!, parameters: ["url": url], headers: nil).subscribe { (response, responseString) in
//            print(message: " responseString:\(responseString)")
//            if let lanzou = LanzouResponse.deserialize(from: responseString) {
//                if lanzou.code == 200 {
//                    success?(lanzou.download)
//                } else {
//                    failure?(lanzou.msg)
//                }
//            } else {
//                failure?("接口失效了")
//            }
//        } onError: { error in
//            failure?(error.localizedDescription)
//        }.disposed(by: disposeBag)
    }
}


class LanzouResponse: HandyJSON {
    var code = 0
    var msg = ""
    var url = ""
    var name = ""
    var date = ""
    var size = ""
    var sesc = ""
    var download = ""
    required init() {}
}
