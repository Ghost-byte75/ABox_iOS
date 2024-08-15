#import "ZLogManager.h"

@interface ZLogManager()

@end

static ZLogManager *manager = nil;
@implementation ZLogManager

+ (instancetype)shareManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

+ (id)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [super allocWithZone:zone];
    });
    return manager;
}

- (void)printLog:(char *)log {
    NSString *logString = [NSString stringWithUTF8String:log];
    if (logString.length <= 0) {
        return;
    }
    if (self.block) {
        self.block(logString);
    }
}

- (void)printLogString:(NSString *)log {
    if (log.length <= 0) {
        return;
    }
    NSString *logString = [NSString stringWithFormat:@">>> %@",log];
    if (self.block) {
        self.block(logString);
    }
}


- (void)printZipLog:(NSString *)log {
    if (log.length <= 0) {
        return;
    }
    NSString *logString = [NSString stringWithFormat:@">>> %@",log];
    if (self.block) {
        self.block(logString);
    }
}

@end
