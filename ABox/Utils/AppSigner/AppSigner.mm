#import "AppSigner.h"

#import "ABApplication.h"
#import "ReadP12Subject.h"
//#import <AltSign/ALTDevice.h>
//#import <AltSign/ALTCertificate.h>
//#import <AltSign/ALTProvisioningProfile.h>
//#import <AltSign/NSFileManager+Zip.h>
//#import <AltSign/NSError+ALTErrors.h>
#import "ALTDevice.h"
#import "ALTCertificate.h"
#import "ALTProvisioningProfile.h"
#import "ALTCapabilities.h"
#import "NSError+ALTErrors.h"
#import "NSFileManager+Zip.h"

#include <string>
#include <openssl/pkcs12.h>
#include <openssl/pem.h>
#include "zsign.h"
#import "ZLogManager.h"

const char *AppleRootCertificateData = ""
"-----BEGIN CERTIFICATE-----\n"
"MIIEuzCCA6OgAwIBAgIBAjANBgkqhkiG9w0BAQUFADBiMQswCQYDVQQGEwJVUzET\n"
"MBEGA1UEChMKQXBwbGUgSW5jLjEmMCQGA1UECxMdQXBwbGUgQ2VydGlmaWNhdGlv\n"
"biBBdXRob3JpdHkxFjAUBgNVBAMTDUFwcGxlIFJvb3QgQ0EwHhcNMDYwNDI1MjE0\n"
"MDM2WhcNMzUwMjA5MjE0MDM2WjBiMQswCQYDVQQGEwJVUzETMBEGA1UEChMKQXBw\n"
"bGUgSW5jLjEmMCQGA1UECxMdQXBwbGUgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkx\n"
"FjAUBgNVBAMTDUFwcGxlIFJvb3QgQ0EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAw\n"
"ggEKAoIBAQDkkakJH5HbHkdQ6wXtXnmELes2oldMVeyLGYne+Uts9QerIjAC6Bg+\n"
"+FAJ039BqJj50cpmnCRrEdCju+QbKsMflZ56DKRHi1vUFjczy8QPTc4UadHJGXL1\n"
"XQ7Vf1+b8iUDulWPTV0N8WQ1IxVLFVkds5T39pyez1C6wVhQZ48ItCD3y6wsIG9w\n"
"tj8BMIy3Q88PnT3zK0koGsj+zrW5DtleHNbLPbU6rfQPDgCSC7EhFi501TwN22IW\n"
"q6NxkkdTVcGvL0Gz+PvjcM3mo0xFfh9Ma1CWQYnEdGILEINBhzOKgbEwWOxaBDKM\n"
"aLOPHd5lc/9nXmW8Sdh2nzMUZaF3lMktAgMBAAGjggF6MIIBdjAOBgNVHQ8BAf8E\n"
"BAMCAQYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQUK9BpR5R2Cf70a40uQKb3\n"
"R01/CF4wHwYDVR0jBBgwFoAUK9BpR5R2Cf70a40uQKb3R01/CF4wggERBgNVHSAE\n"
"ggEIMIIBBDCCAQAGCSqGSIb3Y2QFATCB8jAqBggrBgEFBQcCARYeaHR0cHM6Ly93\n"
"d3cuYXBwbGUuY29tL2FwcGxlY2EvMIHDBggrBgEFBQcCAjCBthqBs1JlbGlhbmNl\n"
"IG9uIHRoaXMgY2VydGlmaWNhdGUgYnkgYW55IHBhcnR5IGFzc3VtZXMgYWNjZXB0\n"
"YW5jZSBvZiB0aGUgdGhlbiBhcHBsaWNhYmxlIHN0YW5kYXJkIHRlcm1zIGFuZCBj\n"
"b25kaXRpb25zIG9mIHVzZSwgY2VydGlmaWNhdGUgcG9saWN5IGFuZCBjZXJ0aWZp\n"
"Y2F0aW9uIHByYWN0aWNlIHN0YXRlbWVudHMuMA0GCSqGSIb3DQEBBQUAA4IBAQBc\n"
"NplMLXi37Yyb3PN3m/J20ncwT8EfhYOFG5k9RzfyqZtAjizUsZAS2L70c5vu0mQP\n"
"y3lPNNiiPvl4/2vIB+x9OYOLUyDTOMSxv5pPCmv/K/xZpwUJfBdAVhEedNO3iyM7\n"
"R6PVbyTi69G3cN8PReEnyvFteO3ntRcXqNx+IjXKJdXZD9Zr1KIkIxH3oayPc4Fg\n"
"xhtbCS+SsvhESPBgOJ4V9T0mZyCKM2r3DYLP3uujL/lTaltkwGMzd/c6ByxW69oP\n"
"IQ7aunMZT7XZNn/Bh1XZp5m5MkL72NVxnn6hUrcbvZNCJBIqxw8dtk2cXmPIS4AX\n"
"UKqK1drk/NAJBzewdXUh\n"
"-----END CERTIFICATE-----\n";

const char *AppleWWDRCertificateData = ""
"-----BEGIN CERTIFICATE-----\n"
"MIIEUTCCAzmgAwIBAgIQfK9pCiW3Of57m0R6wXjF7jANBgkqhkiG9w0BAQsFADBi\n"
"MQswCQYDVQQGEwJVUzETMBEGA1UEChMKQXBwbGUgSW5jLjEmMCQGA1UECxMdQXBw\n"
"bGUgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkxFjAUBgNVBAMTDUFwcGxlIFJvb3Qg\n"
"Q0EwHhcNMjAwMjE5MTgxMzQ3WhcNMzAwMjIwMDAwMDAwWjB1MUQwQgYDVQQDDDtB\n"
"cHBsZSBXb3JsZHdpZGUgRGV2ZWxvcGVyIFJlbGF0aW9ucyBDZXJ0aWZpY2F0aW9u\n"
"IEF1dGhvcml0eTELMAkGA1UECwwCRzMxEzARBgNVBAoMCkFwcGxlIEluYy4xCzAJ\n"
"BgNVBAYTAlVTMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA2PWJ/KhZ\n"
"C4fHTJEuLVaQ03gdpDDppUjvC0O/LYT7JF1FG+XrWTYSXFRknmxiLbTGl8rMPPbW\n"
"BpH85QKmHGq0edVny6zpPwcR4YS8Rx1mjjmi6LRJ7TrS4RBgeo6TjMrA2gzAg9Dj\n"
"+ZHWp4zIwXPirkbRYp2SqJBgN31ols2N4Pyb+ni743uvLRfdW/6AWSN1F7gSwe0b\n"
"5TTO/iK1nkmw5VW/j4SiPKi6xYaVFuQAyZ8D0MyzOhZ71gVcnetHrg21LYwOaU1A\n"
"0EtMOwSejSGxrC5DVDDOwYqGlJhL32oNP/77HK6XF8J4CjDgXx9UO0m3JQAaN4LS\n"
"VpelUkl8YDib7wIDAQABo4HvMIHsMBIGA1UdEwEB/wQIMAYBAf8CAQAwHwYDVR0j\n"
"BBgwFoAUK9BpR5R2Cf70a40uQKb3R01/CF4wRAYIKwYBBQUHAQEEODA2MDQGCCsG\n"
"AQUFBzABhihodHRwOi8vb2NzcC5hcHBsZS5jb20vb2NzcDAzLWFwcGxlcm9vdGNh\n"
"MC4GA1UdHwQnMCUwI6AhoB+GHWh0dHA6Ly9jcmwuYXBwbGUuY29tL3Jvb3QuY3Js\n"
"MB0GA1UdDgQWBBQJ/sAVkPmvZAqSErkmKGMMl+ynsjAOBgNVHQ8BAf8EBAMCAQYw\n"
"EAYKKoZIhvdjZAYCAQQCBQAwDQYJKoZIhvcNAQELBQADggEBAK1lE+j24IF3RAJH\n"
"Qr5fpTkg6mKp/cWQyXMT1Z6b0KoPjY3L7QHPbChAW8dVJEH4/M/BtSPp3Ozxb8qA\n"
"HXfCxGFJJWevD8o5Ja3T43rMMygNDi6hV0Bz+uZcrgZRKe3jhQxPYdwyFot30ETK\n"
"XXIDMUacrptAGvr04NM++i+MZp+XxFRZ79JI9AeZSWBZGcfdlNHAwWx/eCHvDOs7\n"
"bJmCS1JgOLU5gm3sUjFTvg+RTElJdI+mUcuER04ddSduvfnSXPN/wmwLCTbiZOTC\n"
"NwMUGdXqapSqqdv+9poIZ4vvK7iqF0mDr8/LvOnP6pVxsLRFoszlh6oKw0E6eVza\n"
"UDSdlTs=\n"
"-----END CERTIFICATE-----\n";

const char *LegacyAppleWWDRCertificateData = ""
"-----BEGIN CERTIFICATE-----\n"
"MIIEIjCCAwqgAwIBAgIIAd68xDltoBAwDQYJKoZIhvcNAQEFBQAwYjELMAkGA1UE\n"
"BhMCVVMxEzARBgNVBAoTCkFwcGxlIEluYy4xJjAkBgNVBAsTHUFwcGxlIENlcnRp\n"
"ZmljYXRpb24gQXV0aG9yaXR5MRYwFAYDVQQDEw1BcHBsZSBSb290IENBMB4XDTEz\n"
"MDIwNzIxNDg0N1oXDTIzMDIwNzIxNDg0N1owgZYxCzAJBgNVBAYTAlVTMRMwEQYD\n"
"VQQKDApBcHBsZSBJbmMuMSwwKgYDVQQLDCNBcHBsZSBXb3JsZHdpZGUgRGV2ZWxv\n"
"cGVyIFJlbGF0aW9uczFEMEIGA1UEAww7QXBwbGUgV29ybGR3aWRlIERldmVsb3Bl\n"
"ciBSZWxhdGlvbnMgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkwggEiMA0GCSqGSIb3\n"
"DQEBAQUAA4IBDwAwggEKAoIBAQDKOFSmy1aqyCQ5SOmM7uxfuH8mkbw0U3rOfGOA\n"
"YXdkXqUHI7Y5/lAtFVZYcC1+xG7BSoU+L/DehBqhV8mvexj/avoVEkkVCBmsqtsq\n"
"Mu2WY2hSFT2Miuy/axiV4AOsAX2XBWfODoWVN2rtCbauZ81RZJ/GXNG8V25nNYB2\n"
"NqSHgW44j9grFU57Jdhav06DwY3Sk9UacbVgnJ0zTlX5ElgMhrgWDcHld0WNUEi6\n"
"Ky3klIXh6MSdxmilsKP8Z35wugJZS3dCkTm59c3hTO/AO0iMpuUhXf1qarunFjVg\n"
"0uat80YpyejDi+l5wGphZxWy8P3laLxiX27Pmd3vG2P+kmWrAgMBAAGjgaYwgaMw\n"
"HQYDVR0OBBYEFIgnFwmpthhgi+zruvZHWcVSVKO3MA8GA1UdEwEB/wQFMAMBAf8w\n"
"HwYDVR0jBBgwFoAUK9BpR5R2Cf70a40uQKb3R01/CF4wLgYDVR0fBCcwJTAjoCGg\n"
"H4YdaHR0cDovL2NybC5hcHBsZS5jb20vcm9vdC5jcmwwDgYDVR0PAQH/BAQDAgGG\n"
"MBAGCiqGSIb3Y2QGAgEEAgUAMA0GCSqGSIb3DQEBBQUAA4IBAQBPz+9Zviz1smwv\n"
"j+4ThzLoBTWobot9yWkMudkXvHcs1Gfi/ZptOllc34MBvbKuKmFysa/Nw0Uwj6OD\n"
"Dc4dR7Txk4qjdJukw5hyhzs+r0ULklS5MruQGFNrCk4QttkdUGwhgAqJTleMa1s8\n"
"Pab93vcNIx0LSiaHP7qRkkykGRIZbVf1eliHe2iK5IaMSuviSRSqpd1VAKmuu0sw\n"
"ruGgsbwpgOYJd+W+NKIByn/c4grmO7i77LpilfMFY0GCzQ87HUyVpNur+cmV6U/k\n"
"TecmmYHpvPm0KdIBembhLoz2IYrF+Hjhga6/05Cdqa3zr/04GpZnMBxRpVzscYqC\n"
"tGwPDBUf\n"
"-----END CERTIFICATE-----\n";

std::string CertificatesContent(ALTCertificate *altCertificate)
{
    NSData *altCertificateP12Data = [altCertificate p12Data];
    
    BIO *inputP12Buffer = BIO_new(BIO_s_mem());
    BIO_write(inputP12Buffer, altCertificateP12Data.bytes, (int)altCertificateP12Data.length);
    
    auto inputP12 = d2i_PKCS12_bio(inputP12Buffer, NULL);
    
    // Extract key + certificate from .p12.
    EVP_PKEY *key;
    X509 *certificate;
    PKCS12_parse(inputP12, "", &key, &certificate, NULL);
    
    // Prepare certificate chain of trust.
    auto *certificates = sk_X509_new(NULL);
    
    BIO *rootCertificateBuffer = BIO_new_mem_buf(AppleRootCertificateData, (int)strlen(AppleRootCertificateData));
    BIO *wwdrCertificateBuffer = nil;
    
    unsigned long issuerHash = X509_issuer_name_hash(certificate);
    if (issuerHash == 0x817d2f7a)
    {
        // Use legacy WWDR certificate.
        wwdrCertificateBuffer = BIO_new_mem_buf(LegacyAppleWWDRCertificateData, (int)strlen(LegacyAppleWWDRCertificateData));
    }
    else
    {
        // Use latest WWDR certificate.
        wwdrCertificateBuffer = BIO_new_mem_buf(AppleWWDRCertificateData, (int)strlen(AppleWWDRCertificateData));
    }
    
    auto rootCertificate = PEM_read_bio_X509(rootCertificateBuffer, NULL, NULL, NULL);
    if (rootCertificate != NULL)
    {
        sk_X509_push(certificates, rootCertificate);
    }
    
    auto wwdrCertificate = PEM_read_bio_X509(wwdrCertificateBuffer, NULL, NULL, NULL);
    if (wwdrCertificate != NULL)
    {
        sk_X509_push(certificates, wwdrCertificate);
    }
    
    // Create new .p12 in memory with private key and certificate chain.
    char emptyString[] = "";
    auto outputP12 = PKCS12_create(emptyString, emptyString, key, certificate, certificates, 0, 0, 0, 0, 0);
    
    BIO *outputP12Buffer = BIO_new(BIO_s_mem());
    i2d_PKCS12_bio(outputP12Buffer, outputP12);
    
    char *buffer = NULL;
    NSUInteger size = BIO_get_mem_data(outputP12Buffer, &buffer);
    
    NSData *p12Data = [NSData dataWithBytes:buffer length:size];
    
    // Free .p12 structures
    PKCS12_free(inputP12);
    PKCS12_free(outputP12);
    
    BIO_free(wwdrCertificateBuffer);
    BIO_free(rootCertificateBuffer);
    
    BIO_free(inputP12Buffer);
    BIO_free(outputP12Buffer);
    
    std::string output((const char *)p12Data.bytes, (size_t)p12Data.length);
    return output;
}

@implementation AppSigner

+ (void)load {
    OpenSSL_add_all_algorithms();
}

- (void)unzipAppBundleAtURL:(NSURL *)ipaURL
         outputDirectoryURL:(NSURL *)outputDirectoryURL
            progressHandler:(void (^_Nullable)(NSString *entry, unz_file_info zipInfo, long entryNumber, long total))progressHandler
          completionHandler:(void (^)(BOOL success, ABApplication *application, NSError *error))completionHandler {
    NSData *ipaData = [NSData dataWithContentsOfURL:ipaURL];
    __block NSError *error = nil;
    

    if ([ipaURL.pathExtension.lowercaseString isEqualToString:@"ipa"] || [ipaURL.pathExtension.lowercaseString isEqualToString:@"tipa"]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSLog(@"outputDirectoryURL:%@",outputDirectoryURL);
            //
            BOOL isDir = NO;
            if ([[NSFileManager defaultManager] fileExistsAtPath:outputDirectoryURL.path isDirectory:&isDir]) {
                [[NSFileManager defaultManager] removeItemAtPath:outputDirectoryURL.path error:nil];
            }
            
            // ipa解压文件夹，清理缓存时清理
            if (![[NSFileManager defaultManager] createDirectoryAtURL:outputDirectoryURL withIntermediateDirectories:YES attributes:nil error:&error]) {
                completionHandler(NO, nil, error);
                return;
            }
            [SSZipArchive unzipFileAtPath:ipaURL.path toDestination:outputDirectoryURL.path progressHandler:^(NSString * _Nonnull entry, unz_file_info zipInfo, long entryNumber, long total) {
                progressHandler(entry, zipInfo, entryNumber, total);
            } completionHandler:^(NSString * _Nonnull path, BOOL succeeded, NSError * _Nullable error) {
                NSURL *appBundleURL = [self getAppBundleAtURL:outputDirectoryURL error:&error];
                if (appBundleURL == nil) {
                    completionHandler(NO, nil, error);
                    return;
                }
                // 设置文件权限
                [self setFilePosixPermissions:appBundleURL];
                dispatch_async(dispatch_get_main_queue(), ^{
                    ABApplication *application = [[ABApplication alloc] initWithFileURL:appBundleURL];
                    if (application == nil) {
                        completionHandler(NO, application, [NSError errorWithDomain:AltSignErrorDomain code:ALTErrorMissingAppBundle userInfo:nil]);
                    } else {
                        completionHandler(YES, application, nil);
                    }
                });
            }];
        });
    } else {
        completionHandler(NO, nil, error);
        return;
    }
    
}

- (void)setFilePosixPermissions:(NSURL *)fileURL {
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:0755],NSFilePosixPermissions,nil];
    NSError *error = nil;
    BOOL isDirectory = NO;
    [[NSFileManager defaultManager] fileExistsAtPath:fileURL.path isDirectory:&isDirectory];
    if (isDirectory) {
        NSArray *directoryArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:fileURL.path error:&error];
        for (NSString *fileName in directoryArray) {
            NSURL *url = [fileURL URLByAppendingPathComponent:fileName];
            [self setFilePosixPermissions:url];
        }
    } else {
        BOOL result = [[NSFileManager defaultManager] setAttributes:attributes ofItemAtPath:fileURL.path error:&error];
        if (!result) {
            NSLog(@"设置%@的文件权限%@",fileURL.lastPathComponent, result ? @"成功" : @"失败");
        }
        if (error != nil) {
            NSLog(@"设置%@的文件权限Error:%@",fileURL.lastPathComponent, error);
        }
    }
}

- (void)signAppWithAplication:(ABApplication *)application
                  certificate:(ALTCertificate *)certificate
          provisioningProfile:(ALTProvisioningProfile *)profile
                        dylib:(NSURL *_Nullable)dylibURL
                 entitlements:(NSString *_Nullable)entitlementsPath
               removeEmbedded:(BOOL)removeEmbedded
                   logHandler:(void (^)(NSString *log))logHandler
            completionHandler:(void (^)(BOOL success, NSString *error, NSURL *url))completionHandler {
    
    __block NSError *error = nil;
    NSURL *resignedIPAURL = nil;
    
    if (application == nil) {
        logHandler(@"读取App的信息时发生错误，无效的App");
        completionHandler(NO, @"读取App的信息时发生错误，无效的App", resignedIPAURL);
        return ;
    }
    
    NSBundle *appBundle = [NSBundle bundleWithURL:application.fileURL];
    if (appBundle == nil) {
        logHandler(@"读取App的信息时发生错误，无效的App");
        completionHandler(NO, @"读取App的信息时发生错误，无效的App", resignedIPAURL);
        return ;
    }
    
    NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory,NSUserDomainMask, YES) objectAtIndex:0];
    
    
    logHandler(@"=============== 签名进度 ===============");
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *pwd = @"abc123";
        NSString *certPath = [cachePath stringByAppendingPathComponent:@"signCert.p12"];
        [[NSFileManager defaultManager] createFileAtPath:certPath contents:[certificate encryptedP12DataWithPassword:pwd] attributes:nil];
        NSString *provPath = [cachePath stringByAppendingPathComponent:@"signProfile.mobileprovision"];
        [[NSFileManager defaultManager] createFileAtPath:provPath contents:profile.data attributes:nil];
        
        char *p12 = (char *)[certPath UTF8String];
        char *password = (char *)[pwd?:@"" UTF8String];
        char *prov = (char *)[provPath UTF8String];
        char *ipa = (char *)[application.fileURL.path UTF8String];
        char *dylib = (char *)[dylibURL.path?:@"" UTF8String];
        char *entitlements = (char *)[entitlementsPath?:@"" UTF8String];
        
        char *argv[] = {(char *)"-k", p12, (char *)"-p", password, (char *)"-m", prov, (char *)"-i", ipa, (char *)"-l", dylib, (char *)"-e", entitlements};
        for (int i = 0; i < 12; i += 1) {
            char* option = argv[i];
            printf("%s\n", option);
        }
        NSDate* codesignDate = [NSDate date];
        [ZLogManager shareManager].block = ^(NSString * log) {
            logHandler(log);
        };
        int res = zsign(12, argv);
        if (res == 0) {
            double codesignEndTime = [[NSDate date] timeIntervalSinceDate:codesignDate];
            logHandler([NSString stringWithFormat:@"签名成功，耗时%0.2f秒",codesignEndTime]);
            logHandler(@"开始打包IPA，请勿关闭App或退到后台");
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSDate *zipIPADate = [NSDate date];
                NSURL *resignedIPAURL = [[NSFileManager defaultManager] zipAppBundleAtURL:application.fileURL error:&error];
                double zipIPAEndTime = [[NSDate date] timeIntervalSinceDate:zipIPADate];
                logHandler([[NSString alloc] initWithFormat:@"打包成功，耗时%0.2f秒",zipIPAEndTime]);
#if DEBUG
                NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:resignedIPAURL.path error:nil];
                logHandler([[NSString alloc] initWithFormat:@"文件信息：%@",attributes]);
#endif
                completionHandler(YES, nil, resignedIPAURL);
            });
        } else {
            completionHandler(NO, nil, resignedIPAURL);
        }
    });
    
    
    
}


- (nullable NSURL *)getAppBundleAtURL:(NSURL *)directoryURL error:(NSError **)error
{
    
    NSURL *payloadDirectory = [directoryURL URLByAppendingPathComponent:@"Payload"];
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:payloadDirectory.path error:error];
    if (contents == nil)
    {
        return nil;
    }
    
    for (NSString *filename in contents)
    {
        if ([filename.pathExtension.lowercaseString isEqualToString:@"app"])
        {
            NSURL *appBundleURL = [payloadDirectory URLByAppendingPathComponent:filename];
            NSURL *outputURL = [directoryURL URLByAppendingPathComponent:filename];
            
            if (![[NSFileManager defaultManager] moveItemAtURL:appBundleURL toURL:outputURL error:error])
            {
                return nil;
            }
            
            NSError *deleteError = nil;
            if (![[NSFileManager defaultManager] removeItemAtURL:payloadDirectory error:&deleteError])
            {
                *error = deleteError;
                
                return nil;
            }
            
            return outputURL;
        }
    }
    
    *error = [NSError errorWithDomain:AltSignErrorDomain code:ALTErrorMissingAppBundle userInfo:@{NSURLErrorKey: directoryURL}];
    return nil;
}


+ (NSURL *)zipAppBundleAtURL:(NSURL *)appBundleURL error:(NSError **)error {
    BOOL success = YES;
    NSString *appBundleFilename = [appBundleURL lastPathComponent];
    NSString *appName = [appBundleFilename stringByDeletingPathExtension];
    NSString *ipaName = [NSString stringWithFormat:@"%@.ipa", appName];
    NSURL *ipaURL = [[appBundleURL URLByDeletingLastPathComponent] URLByAppendingPathComponent:ipaName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:ipaURL.path]) {
        if (![[NSFileManager defaultManager] removeItemAtURL:ipaURL error:error]) {
            return nil;
        }
    }
    NSURL *payloadDirectory = [[appBundleURL URLByDeletingLastPathComponent] URLByAppendingPathComponent:@"Payload"];
    BOOL exist = [[NSFileManager defaultManager] fileExistsAtPath:payloadDirectory.path];
    if (exist) {
        [[NSFileManager defaultManager] removeItemAtPath:payloadDirectory.path error:nil];
    }
    [[NSFileManager defaultManager] createDirectoryAtURL:payloadDirectory withIntermediateDirectories:YES attributes:nil error:error];
    NSURL *appBundleDirectory = [payloadDirectory URLByAppendingPathComponent:appBundleFilename isDirectory:YES];
    [[NSFileManager defaultManager] moveItemAtURL:appBundleURL toURL:appBundleDirectory error:error];
    
    success = [SSZipArchive createZipFileAtPath:ipaURL.path
                        withContentsOfDirectory:payloadDirectory.path
                            keepParentDirectory:YES
                               compressionLevel:-1
                                       password:nil
                                            AES:NO
                                progressHandler:^(NSUInteger entryNumber, NSUInteger total) {
        NSLog(@"%.1fM  -->> %.f%%", total*0.1, 100*entryNumber*1.0/total);
    } keepSymlinks:YES];
    NSLog(@"zipAppBundle success：%d",success);
    return success ? ipaURL : nil;
}

+ (NSString *)printMachOInfoWithFileURL:(NSURL *)fileURL {
    char *path = (char *)[fileURL.path UTF8String];
    NSLog(@"MachO Path:%s",path);
    NSMutableString *result = [NSMutableString string];
    [ZLogManager shareManager].block = ^(NSString * log) {
        [result appendFormat:@"%@",log];
    };
    char *argv[] = {(char *)"-i", path};
    zsign(2, argv);
    return result;
}


/*
 // 255216 jpg;
 // 7173 gif;
 // 6677 bmp,
 // 13780 png;
 // 6787 swf
 // 7790 exe dll,
 // 8297 rar
 // 8075 zip
 // 55122 7z
 // 6063 xml
 // 6033 html
 // 239187 aspx
 // 117115 cs
 // 119105 js
 // 102100 txt
 // 255254 sql
 // 3780 PDF
 */
+ (int)fileTypeWithData:(NSData *)data {
    if (data.length < 2) {
        NSLog(@"NOT FILE");
        return 0;
        
    }
    int char1 = 0 ,char2 = 0 ; //必须这样初始化
    [data getBytes:&char1 range:NSMakeRange(0, 1)];
    [data getBytes:&char2 range:NSMakeRange(1, 1)];
    NSString *numStr = [NSString stringWithFormat:@"%i%i",char1,char2];
    NSLog(@"%@",numStr);
    return [numStr intValue];
}

@end


