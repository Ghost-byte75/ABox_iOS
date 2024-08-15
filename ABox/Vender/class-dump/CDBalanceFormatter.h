#import <Foundation/Foundation.h>
#import "CDExtensions.h"

@interface CDBalanceFormatter : NSObject

- (id)initWithString:(NSString *)str;

- (void)parse:(NSString *)open index:(NSUInteger)openIndex level:(NSUInteger)level;

- (NSString *)format;

@end
