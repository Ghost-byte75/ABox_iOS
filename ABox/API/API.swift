import UIKit
import RxAlamofire
import Alamofire
import RxSwift
import HandyJSON

class API {

    static let `default` = API()
    let disposeBag = DisposeBag()
    
    let RSAPublicKey = "uFem6itVNqsym6zKP0BGdY4DrPnIvnq5b3DWein8fX4T7uo6HdPwILqcXvJg9YQQh83XnoMQaQIuDF8aRizosOAmpWixWQfyXWSB"
    
#if DEBUG
        // debug
        let appBaseURL = "http://127.0.0.1"
#else
        // release
        let appBaseURL = "http://127.0.0.1"
#endif


    
    func request(url: String, method: Alamofire.HTTPMethod = .get, parameters: [String: Any]? = nil, success: ((Any?)->())?, failure: ((String)->())?) {
        var requestUrl = url
        if !url.hasPrefix("http") {
            requestUrl = appBaseURL + url
        }
        print(message: parameters)
        RxAlamofire.requestString(method, URL(string: requestUrl)!, parameters: parameters, headers: API.httpRqeusetHeaders()).subscribe { (response, responseString) in
            print(message: "requestUrl:\(requestUrl)\nparameters:\(String(describing: parameters))\nresponse:\(responseString)")
            if let httpResult = HttpResponse.deserialize(from: responseString) {
                if httpResult.success {
                    if httpResult.encrypt {
                        if let content: String = httpResult.result as? String {
                            let decryptText = NSString.decryptAES(content, key: AESNormalKey)
                            success?(decryptText)
                        }
                    } else {
                        success?(httpResult.result)
                    }
                } else {
                    failure?(httpResult.message)
                }
            } else {
                failure?("服务器开小差了")
            }
        } onError: { error in
            failure?(error.localizedDescription)
        }.disposed(by: disposeBag)
    }
    
    
    func upload(data: Data, filename: String, dir: String? = nil, progress: ((Progress)->())?, success: ((String)->())?, failure: ((String)->())?) {
        let savePath = FileManager.default.importFileDirectory.appendingPathComponent(filename).path
        FileManager.default.createFile(atPath: savePath, contents: data, attributes: nil)
        let url = URL(fileURLWithPath: savePath)
        self.upload(file: url, filename: filename, dir: dir, progress: progress, success: success, failure: failure)
    }

    
    func upload(file: URL, filename: String, dir: String? = nil, progress: ((Progress)->())?, success: ((String)->())?, failure: ((String)->())?) {
        let requestUrl = appBaseURL + "/file/upload"
        let params = ["filename": dir == nil ? filename : "\(dir!)/\(filename)"]
        self.upload(file: file, to: requestUrl, params: params, progress: progress, success: { result in
            if let httpResult = HttpResponse.deserialize(from: result as? String) {
                if httpResult.success {
                    var ipaURL = httpResult.result as! String
                    ipaURL = ipaURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
                    success?(ipaURL)
                } else {
                    failure?(httpResult.message)
                }
            } else {
                failure?("服务器开小差了")
            }
        }, failure: failure)
    }
    
    func upload(file: URL, to: URLConvertible, params: [String:Any], method: HTTPMethod = .post, progress: ((Progress)->())?, success: ((Any?)->())?, failure: ((String)->())?) {

        RxAlamofire.upload(multipartFormData: { multipartFormData in
            for (key,value) in params {
                if let content = value as? String {
                    multipartFormData.append(content.data(using: String.Encoding.utf8)!, withName: key)
                }
            }
            multipartFormData.append(file, withName: "file")
        }, to: to, method: method).subscribe { rxProgress in
            
            rxProgress.uploadProgress { uploadProgress in
                print(uploadProgress.fractionCompleted)
                progress?(uploadProgress)
            }
            rxProgress.responseString { response in
                print(response)
                switch response.result {
                case .success(let value):
                    success?(value)
                case .failure(let error):
                    failure?(error.localizedDescription)
                }
            }
            
        }.disposed(by: disposeBag)
        
    }
    
    func uploadToPgyer(file: URL, progress: ((Progress)->())?, success: ((Any?)->())?, failure: ((String)->())?) {
        self.upload(file: file,
                    to: URL(string: "https://upload.pgyer.com/apiv1/app/upload")!,
                    params: ["uKey": "", "_api_key": ""],
                    method: .post,
                    progress: progress,
                    success: { result in
            if let json: String = result as? String {
                if let data = json.data(using: String.Encoding.utf8) {
                        do {
                            let dict: [String: Any] = try JSONSerialization.jsonObject(with: data, options: [JSONSerialization.ReadingOptions.init(rawValue: 0)]) as! [String : Any]
                            let code: Int = dict["code"] as! Int
                            let message: String = dict["message"] as! String
                            if code == 0 {
                                if let data : [String: Any] = dict["data"] as? [String : Any] {
                                    let appShortcut: String = data["appShortcutUrl"] as! String
                                    if appShortcut.count > 0 {
                                        let appShortcutUrl = "https://www.pgyer.com/\(appShortcut)"
                                        success?(appShortcutUrl)
                                    } else {
                                        failure?("上传失败！")
                                    }
                                }
                            } else {
                                failure?(message)
                            }
                        } catch let error as NSError {
                            print(error)
                            failure?("上传失败！\n\(error.localizedDescription)")
                        }
                    }
            } else {
                failure?("上传失败！")
            }
        }, failure: { error in
            failure?(error)
        })                   
    }
    

    static func httpRqeusetHeaders() -> HTTPHeaders {
        var headers: HTTPHeaders = [:]
        headers["osVersion"] = "\(kVersion)"
        
        if let appBundleIdentifier: String = kAppBundleIdentifier! as? String {
            headers["Referer"] = appBundleIdentifier
        }
        
        if let appVersion: String = kAppVersion! as? String {
            headers["appVersion"] = appVersion
        }
        
        if let udid = AppDefaults.shared.deviceUDID {
            headers["udid"] = udid
            let timeInterval: TimeInterval = Date().timeIntervalSince1970
            let timeStamp = Int(timeInterval) - 10
            var sign = String.init(format: "%@:%d", udid,timeStamp)
            sign = String.rsa_encrypt(sign, publicKey: API.default.RSAPublicKey)
            headers["sign"] = sign
        }
        return headers
    }
    
    static func httpURLRequest(url: URL) -> URLRequest {
        var request = URLRequest.init(url: url)
        let headers = API.httpRqeusetHeaders().dictionary
        for key in headers.keys {
            if let value = headers[key] {
                request.addValue(value, forHTTPHeaderField: key)
            }
        }
        return request
    }
    
    
}


/// MARK: - Result
class HttpResponse: HandyJSON {
    var message: String = "服务器开小差了"
    var error: String = ""
    var result: Any?
    var code: Int = 0
    var success = true
    var timestamp = ""
    var encrypt = false
    required init() {}
}


