#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (Utilities)

+ (NSString *)hmacsha1:(NSString *)data secret:(NSString *)key;

// base64转字符串（解密）
+ (NSString *)decodingFromBase64String:(NSString *)string Encoding:(NSStringEncoding)encoding;
- (NSString *)parseUDID;


+ (NSString *)encryptAES:(NSString *)content key:(NSString *)key;
+ (NSString *)decryptAES:(NSString *)content key:(NSString *)key;



/**
 对字符串的每个字符进行UTF-8编码
 
 @return 百分号编码后的字符串
 */
- (NSString *)URLUTF8EncodingString;


/**
 对字符串的每个字符进行彻底的 UTF-8 解码
 连续编码2次，需要连续解码2次，第三次继续解码时，则返回为空
 @return 百分号编码解码后的字符串
 */
- (NSString *)URLUTF8DecodingString;


// 获取编译时间
+ (NSString *)bulidDate;

@end

NS_ASSUME_NONNULL_END
