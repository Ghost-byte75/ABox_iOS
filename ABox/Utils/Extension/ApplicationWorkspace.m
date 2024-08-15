#import "ApplicationWorkspace.h"
#import <objc/runtime.h>
#import <dlfcn.h>


@implementation ApplicationWorkspace


+ (NSArray *)allApplicationIdentifiers {
    Class LSApplicationWorkspace_class = NSClassFromString(@"LSApplicationWorkspace");
    NSObject *workspace = [LSApplicationWorkspace_class performSelector:NSSelectorFromString(@"defaultWorkspace")];
    NSArray *allApplications = [workspace performSelector:@selector(allApplications)];
    NSMutableArray *identifiers = [NSMutableArray arrayWithCapacity:allApplications.count];
    for (id application in allApplications) {
        NSString *identifier = [application performSelector:NSSelectorFromString(@"applicationIdentifier")];
        [identifiers addObject:identifier];
    }
    NSLog(@"identifiers: %@",identifiers);
    return identifiers;
}


+ (BOOL)isInstalledWithIdentifier:(NSString *)identifier {
    NSArray *identifiers = [ApplicationWorkspace allApplicationIdentifiers];
    if ([identifiers containsObject:identifier]) {
        return YES;
    }
    return NO;
}

/// 直接打开某个APP
+ (BOOL)isOpenApp:(NSString*)bundleIdentifier {
    Class LSApplicationWorkspace = objc_getClass("LSApplicationWorkspace");
    NSObject *workspace = [LSApplicationWorkspace performSelector:@selector(defaultWorkspace)];
    // 没有安装返回NO
    BOOL isOpenApp = [workspace performSelector:@selector(openApplicationWithBundleID:) withObject:bundleIdentifier];
    return isOpenApp;
}

@end
