#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ClassDumpUtils : NSObject

+ (int)classDumpWithExecutablePath:(NSString *)path withOutput:(NSString *)outputPath;

+ (NSArray <NSString *>*)dylibLoadPathsWithExecutablePath:(NSString *)path;

@end

NS_ASSUME_NONNULL_END
