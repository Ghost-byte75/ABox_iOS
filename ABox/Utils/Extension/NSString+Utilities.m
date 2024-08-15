#import "NSString+Utilities.h"
#include <CommonCrypto/CommonDigest.h>
#include <CommonCrypto/CommonHMAC.h>
#include <CommonCrypto/CommonCryptor.h>

NSString *const kInitVector = @"16-Bytes--String";
size_t const kKeySize = kCCKeySizeAES128;


@implementation NSString (Utilities)

+ (NSString *)hmacsha1:(NSString *)data secret:(NSString *)key {
    const char *cKey  = [key cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cData = [data cStringUsingEncoding:NSASCIIStringEncoding];
    unsigned char cHMAC[CC_SHA1_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA1, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    NSData *HMAC = [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];
    NSString *hash = [HMAC base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    return hash;
}


// base64转字符串（解密）
+ (NSString *)decodingFromBase64String:(NSString *)string Encoding:(NSStringEncoding)encoding {
    if (string.length > 0) {
        NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:string options:0];
        NSString *decodedString = [[NSString alloc] initWithData:decodedData encoding:encoding];
        return decodedString;
    }
    return @"";
}

- (NSString *)parseUDID {
    NSString *udid = @"";
    NSArray *array = [self componentsSeparatedByString:@"<key>UDID</key>"];
    NSArray *array1 = [array.lastObject componentsSeparatedByString:@"</string>"];
    NSArray *array2 = [array1.firstObject componentsSeparatedByString:@"<string>"];
    udid = array2.lastObject;
    NSLog(@"udid:%@",udid);
    return udid;
}

+ (NSString *)encryptAES:(NSString *)content key:(NSString *)key {
    NSData *contentData = [content dataUsingEncoding:NSUTF8StringEncoding];
    NSUInteger dataLength = contentData.length;

    // 为结束符'\0' +1
    char keyPtr[kKeySize + 1];
    memset(keyPtr, 0, sizeof(keyPtr));
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];

    // 密文长度
    size_t encryptSize = dataLength + kCCBlockSizeAES128;
    void *encryptedBytes = malloc(encryptSize);
    size_t actualOutSize = 0;

    NSData *initVector = [kInitVector dataUsingEncoding:NSUTF8StringEncoding];

    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt,
                                          kCCAlgorithmAES,
                                          kCCOptionPKCS7Padding,  // 系统默认使用 CBC，然后指明使用 PKCS7Padding
                                          keyPtr,
                                          kKeySize,
                                          initVector.bytes,
                                          contentData.bytes,
                                          dataLength,
                                          encryptedBytes,
                                          encryptSize,
                                          &actualOutSize);

    if (cryptStatus == kCCSuccess) {
        // 对加密后的数据进行 base64 编码
        return [[NSData dataWithBytesNoCopy:encryptedBytes length:actualOutSize] base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    }
    free(encryptedBytes);
    return @"";
}

+ (NSString *)decryptAES:(NSString *)content key:(NSString *)key {
    // 把 base64 String 转换成 Data
    NSData *contentData = [[NSData alloc] initWithBase64EncodedString:content options:NSDataBase64DecodingIgnoreUnknownCharacters];
    NSUInteger dataLength = contentData.length;

    char keyPtr[kKeySize + 1];
    memset(keyPtr, 0, sizeof(keyPtr));
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];

    size_t decryptSize = dataLength + kCCBlockSizeAES128;
    void *decryptedBytes = malloc(decryptSize);
    size_t actualOutSize = 0;

    NSData *initVector = [kInitVector dataUsingEncoding:NSUTF8StringEncoding];

    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt,
                                          kCCAlgorithmAES,
                                          kCCOptionPKCS7Padding,
                                          keyPtr,
                                          kKeySize,
                                          initVector.bytes,
                                          contentData.bytes,
                                          dataLength,
                                          decryptedBytes,
                                          decryptSize,
                                          &actualOutSize);

    if (cryptStatus == kCCSuccess) {
        return [[NSString alloc] initWithData:[NSData dataWithBytesNoCopy:decryptedBytes length:actualOutSize] encoding:NSUTF8StringEncoding];
    }
    free(decryptedBytes);
    return @"";
}


/**
 对字符串的每个字符进行UTF-8编码
 
 @return 百分号编码后的字符串
 */
- (NSString *)URLUTF8EncodingString {
    if (self.length == 0) {
        return self;
    }
    NSString *encodeStr = [self stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSLog(@"encodeStr:%@",encodeStr);
    return encodeStr;
}

/**
 对字符串的每个字符进行彻底的 UTF-8 解码
 连续编码2次，需要连续解码2次，第三次继续解码时，则返回为空
 @return 百分号编码解码后的字符串
 */
- (NSString *)URLUTF8DecodingString {
    if (self.length == 0) {
        return self;
    }
    if ([self stringByRemovingPercentEncoding] == nil
        || [self isEqualToString:[self stringByRemovingPercentEncoding]]) {
        return self;
    }
    NSString *decodedStr = [self stringByRemovingPercentEncoding];
    while ([decodedStr stringByRemovingPercentEncoding] != nil) {
        decodedStr = [decodedStr stringByRemovingPercentEncoding];
    }
    return decodedStr;
}

+ (NSString *)bulidDate {
    return [NSString stringWithFormat:@"%s %s",__DATE__,__TIME__];
}

@end
