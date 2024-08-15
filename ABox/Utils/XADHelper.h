#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface XADHelper : NSObject

- (BOOL)archiverIsEncryptedWithPath:(NSString *)path;

- (int)unarchiverWithPath:(NSString *)path dest:(NSString *)destpath password:(NSString *__nullable)password;

@end

NS_ASSUME_NONNULL_END
