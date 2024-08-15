#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
typedef void(^kDownloadEventHandler) (BOOL result, int64_t totalBytesWritten,int64_t totalBytesExpectedToWrite,NSString * __nullable path);

@interface ZXFileDownload : NSObject

///大文件下载
-(NSURLSession *)downLoadWithUrlStr:(NSString *)urlStr callBack:(kDownloadEventHandler)_result;
-(NSURLConnection *)downLoadWithUrlStrByURLConnection:(NSString *)urlStr filePath:(NSString *)filePath callBack:(kDownloadEventHandler)_result;

@end

NS_ASSUME_NONNULL_END
