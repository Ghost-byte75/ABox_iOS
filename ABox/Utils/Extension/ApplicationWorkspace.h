#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ApplicationWorkspace: NSObject


+ (NSArray *)allApplicationIdentifiers;
+ (BOOL)isInstalledWithIdentifier:(NSString *)identifier;

/// 直接打开某个APP
+ (BOOL)isOpenApp:(NSString*)bundleIdentifier;

@end

NS_ASSUME_NONNULL_END
