import UIKit

import RxAlamofire
import Alamofire
import RxSwift
import HandyJSON

class SourceAPI {
    
    static let `default` = SourceAPI()
    let disposeBag = DisposeBag()
    
    func request(url: String, success: ((AppSourceModel)->())?, failure: ((String)->())?) {
        if !url.hasPrefix("http") || URL(string: url) == nil {
            failure?("非法源地址：\(url)")
            return
        }
        RxAlamofire.requestString(.get, URL(string: url)!, parameters: ["udid": AppDefaults.shared.deviceUDID!], headers: API.httpRqeusetHeaders()).subscribe { (response, responseString) in
            let data = responseString.data(using: String.Encoding.utf8)
            if let dict = try? JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [String: Any] {
                if let result: String = dict["result"] as? String {
                    print(message: result)
                    let decryptResult = String.rsa_decrypt(result, privateKey: SourcePrivateKey)
                    print(message: "解密：\(decryptResult)")
                    if let appSource = AppSourceModel.deserialize(from: decryptResult) {
                        for app in appSource.apps {
                            app.sourceIdentifier = appSource.identifier
                            app.sourceName = appSource.name
                        }
                        appSource.sourceURL = url
                        success?(appSource)
                    } else {
                        failure?("解析失败")
                    }
                } else {
                    failure?("解析失败")
                }
            } else {
                failure?("解析失败")
            }
        } onError: { error in
            failure?(error.localizedDescription)
        }.disposed(by: disposeBag)
    }
    

}



