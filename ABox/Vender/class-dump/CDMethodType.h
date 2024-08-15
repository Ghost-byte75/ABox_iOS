#import <Foundation/Foundation.h>
#import "CDExtensions.h"

@class CDType;

@interface CDMethodType : NSObject

- (id)initWithType:(CDType *)type offset:(NSString *)offset;

@property (readonly) CDType *type;
@property (readonly) NSString *offset;

@end
