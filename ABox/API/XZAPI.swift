import Foundation

import RxAlamofire
import Alamofire
import RxSwift
import HandyJSON

class XZAPI {
    
    static let `default` = XZAPI()
    let disposeBag = DisposeBag()
    
#if DEBUG
    // debug
    let appBaseURL = "http://127.0.0.1"
#else
    // release
    let appBaseURL = "http://127.0.0.2"
#endif
    
    func request<T>(url: String, method: Alamofire.HTTPMethod = .get, parameters: [String: Any]? = nil, success: ((T?)->())?, failure: ((String)->())?) {
        let requestUrl = appBaseURL + url
        RxAlamofire.requestString(method, URL(string: requestUrl)!, parameters: parameters, headers: API.httpRqeusetHeaders()).subscribe { (response, responseString) in
            print(message: "requestUrl:\(requestUrl)\nheaders:\(API.httpRqeusetHeaders())\nparameters:\(String(describing: parameters))\nresponse:\(responseString)")
            if let httpResult = XZHttpResponse<T>.deserialize(from: responseString) {
                success?(httpResult.data)
            } else {
                failure?("服务器开小差了")
            }
        } onError: { error in
            failure?(error.localizedDescription)
        }.disposed(by: disposeBag)
    }
}


/// MARK: - Result
class XZHttpResponse<T>: HandyJSON {
    var message: String = "服务器开小差了"
    var data: T?
    var code: Int = 0
    required init() {}
}
