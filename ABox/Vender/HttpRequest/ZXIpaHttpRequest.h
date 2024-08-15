#import <Foundation/Foundation.h>
#define ZXUA @"com.apple.appstored/1.0 iOS/14.3 model/iPhone10,2 hwp/t8015 build/18C66 (6; dt:158) AMS/1"

NS_ASSUME_NONNULL_BEGIN
typedef void(^kGetDataEventHandler) (BOOL result, id data);

@interface ZXIpaHttpRequest : NSObject

///通用请求
+(void)baseReq:(NSURLRequest *)req callBack:(kGetDataEventHandler)_result;
///get请求url
+(void)getUrl:(NSString *)urlStr callBack:(kGetDataEventHandler)_result;
///get请求request
+(void)getReq:(NSURLRequest *)req callBack:(kGetDataEventHandler)_result;
///下载小文件
+(void)downLoadWithUrlStr:(NSString *)urlStr path:(NSString *)path callBack:(kGetDataEventHandler)_result;

@end

NS_ASSUME_NONNULL_END
