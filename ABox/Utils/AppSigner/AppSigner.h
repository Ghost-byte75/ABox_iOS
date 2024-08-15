#import <Foundation/Foundation.h>
#import <SSZipArchive/SSZipArchive.h>
#import "ABApplication.h"

@class ALTCertificate;
@class ALTProvisioningProfile;
@class ABApplication;

NS_ASSUME_NONNULL_BEGIN

@interface AppSigner : NSObject

- (void)unzipAppBundleAtURL:(NSURL *)ipaURL
         outputDirectoryURL:(NSURL *)outputDirectoryURL
            progressHandler:(void (^_Nullable)(NSString *entry, unz_file_info zipInfo, long entryNumber, long total))progressHandler
          completionHandler:(void (^)(BOOL success, ABApplication *_Nullable application, NSError *_Nullable error))completionHandler;


- (void)signAppWithAplication:(ABApplication *)application
                  certificate:(ALTCertificate *)certificate
          provisioningProfile:(ALTProvisioningProfile *)profile
                        dylib:(NSURL *_Nullable)dylibURL
                 entitlements:(NSString *_Nullable)entitlementsPath
               removeEmbedded:(BOOL)removeEmbedded
                   logHandler:(void (^)(NSString *log))logHandler
            completionHandler:(void (^)(BOOL success, NSString *_Nullable error, NSURL *_Nullable url))completionHandler;

+ (NSString *)printMachOInfoWithFileURL:(NSURL *)fileURL;

- (void)setFilePosixPermissions:(NSURL *)fileURL;

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
+ (int)fileTypeWithData:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
