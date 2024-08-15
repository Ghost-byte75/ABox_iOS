#import "CDFile.h"
#import <Foundation/Foundation.h>
#import "CDExtensions.h"

@class CDFatArch;

@interface CDFatFile : CDFile

@property (readonly) NSMutableArray *arches;
@property (nonatomic, readonly) NSArray *archNames;

- (void)addArchitecture:(CDFatArch *)fatArch;
- (BOOL)containsArchitecture:(CDArch)arch;

@end
