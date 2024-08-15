#import "CDLoadCommand.h"
#import <Foundation/Foundation.h>
#import "CDExtensions.h"

@interface CDLCDylib : CDLoadCommand

@property (readonly) NSString *path;
@property (nonatomic, readonly) uint32_t timestamp;
@property (nonatomic, readonly) uint32_t currentVersion;
@property (nonatomic, readonly) uint32_t compatibilityVersion;

@property (nonatomic, readonly) NSString *formattedCurrentVersion;
@property (nonatomic, readonly) NSString *formattedCompatibilityVersion;

@end
