#import "CDLoadCommand.h"
#import <Foundation/Foundation.h>
#import "CDExtensions.h"

@interface CDLCSubLibrary : CDLoadCommand

@property (readonly) NSString *name;

@end
