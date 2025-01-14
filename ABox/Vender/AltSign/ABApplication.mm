#import "ABApplication.h"
#import "ALTProvisioningProfile.h"
#include "macho.h"

ALTDeviceType ALTDeviceTypeFromUIDeviceFamily(NSInteger deviceFamily)
{
    switch (deviceFamily)
    {
        case 1: return ALTDeviceTypeiPhone;
        case 2: return ALTDeviceTypeiPad;
        case 3: return ALTDeviceTypeAppleTV;
        default: return ALTDeviceTypeNone;
    }
}

@interface ABApplication ()

@property (nonatomic, copy, nullable, readonly) NSString *iconName;

@end

@implementation ABApplication
@synthesize entitlements = _entitlements;
@synthesize entitlementsString = _entitlementsString;
@synthesize provisioningProfile = _provisioningProfile;

- (instancetype)initWithFileURL:(NSURL *)fileURL
{
    self = [super init];
    if (self)
    {
        NSBundle *bundle = [NSBundle bundleWithURL:fileURL];
        if (bundle == nil)
        {
            return nil;
        }
        
        // Load info dictionary directly from disk, since NSBundle caches values
        // that might not reflect the updated values on disk (such as bundle identifier).
        NSURL *infoPlistURL = [bundle.bundleURL URLByAppendingPathComponent:@"Info.plist"];
        NSDictionary *infoDictionary = [NSDictionary dictionaryWithContentsOfURL:infoPlistURL];
        if (infoDictionary == nil)
        {
            return nil;
        }
        
        NSString *executableName = infoDictionary[@"CFBundleExecutable"];
        NSURL *executableFileURL = [fileURL URLByAppendingPathComponent:executableName];
        
        NSString *name = infoDictionary[@"CFBundleDisplayName"] ?: infoDictionary[(NSString *)kCFBundleNameKey];
        NSString *bundleIdentifier = infoDictionary[(NSString *)kCFBundleIdentifierKey];
  
        // 兼容TrollStore的tipa，会有name == nil的情况
//        if (name == nil || bundleIdentifier == nil)
//        {
//            return nil;
//        }
        
        NSString *version = infoDictionary[@"CFBundleShortVersionString"] ?: @"1.0";
        NSString *minimumVersionString = infoDictionary[@"MinimumOSVersion"] ?: @"1.0";
        
        NSArray *versionComponents = [minimumVersionString componentsSeparatedByString:@"."];
        
        NSInteger majorVersion = [versionComponents.firstObject integerValue];
        NSInteger minorVersion = (versionComponents.count > 1) ? [versionComponents[1] integerValue] : 0;
        NSInteger patchVersion = (versionComponents.count > 2) ? [versionComponents[2] integerValue] : 0;
        
        NSOperatingSystemVersion minimumVersion;
        minimumVersion.majorVersion = majorVersion;
        minimumVersion.minorVersion = minorVersion;
        minimumVersion.patchVersion = patchVersion;
        
        NSArray<NSNumber *> *deviceFamilies = infoDictionary[@"UIDeviceFamily"];
        ALTDeviceType supportedDeviceTypes = ALTDeviceTypeNone;
        
        if ([deviceFamilies isKindOfClass:[NSNumber class]])
        {
            NSInteger rawDeviceFamily = [(NSNumber *)deviceFamilies integerValue];
            supportedDeviceTypes = ALTDeviceTypeFromUIDeviceFamily(rawDeviceFamily);
        }
        else if ([deviceFamilies isKindOfClass:[NSArray class]] && deviceFamilies.count > 0)
        {
            for (NSNumber *deviceFamily in deviceFamilies)
            {
                NSInteger rawDeviceFamily = [deviceFamily integerValue];
                supportedDeviceTypes |= ALTDeviceTypeFromUIDeviceFamily(rawDeviceFamily);
            }
        }
        else
        {
            supportedDeviceTypes = ALTDeviceTypeiPhone;
        }
        
        NSDictionary *icons = infoDictionary[@"CFBundleIcons"];
        NSDictionary *primaryIcon = icons[@"CFBundlePrimaryIcon"];
        
        NSString *iconName = nil;
        
        if ([primaryIcon isKindOfClass:[NSString class]])
        {
            iconName = (NSString *)primaryIcon;
        }
        else
        {
            NSArray *iconFiles = primaryIcon[@"CFBundleIconFiles"];
            if (iconFiles == nil)
            {
                iconFiles = infoDictionary[@"CFBundleIconFiles"];
            }
            
            iconName = [iconFiles lastObject];
            if (iconName == nil)
            {
                iconName = infoDictionary[@"CFBundleIconFile"];
            }
        }
        
        _bundle = bundle;
        _fileURL = [fileURL copy];
        _name = [name copy];
        _bundleIdentifier = [bundleIdentifier copy];
        _version = [version copy];
        _minimumiOSVersion = minimumVersion;
        _supportedDeviceTypes = supportedDeviceTypes;
        _iconName = [iconName copy];
        _executableName = [executableName copy];
        _executableFileURL = [executableFileURL copy];
        
    }
    
    return self;
}

#if TARGET_OS_IPHONE
- (UIImage *)icon
{
    NSString *iconName = self.iconName;
    if (iconName == nil)
    {
        return nil;
    }
    
    UIImage *icon = [UIImage imageNamed:iconName inBundle:self.bundle compatibleWithTraitCollection:nil];
    return icon;
}
#endif

- (NSDictionary<ALTEntitlement,id> *)entitlements
{
    if (_entitlements == nil)
    {
        NSDictionary<NSString *, id> *appEntitlements = @{};
        
        if (self.entitlementsString.length != 0)
        {
            NSData *entitlementsData = [self.entitlementsString dataUsingEncoding:NSUTF8StringEncoding];
            
            NSError *error = nil;
            NSDictionary *entitlements = [NSPropertyListSerialization propertyListWithData:entitlementsData options:0 format:nil error:&error];
            
            if (entitlements != nil)
            {
                appEntitlements = entitlements;
            }
            else
            {
                NSLog(@"Error parsing entitlements: %@", error);
            }
        }
        
        _entitlements = appEntitlements;
    }
    
    return _entitlements;
}

- (ALTProvisioningProfile *)provisioningProfile
{
    if (_provisioningProfile == nil)
    {
        NSURL *provisioningProfileURL = [self.fileURL URLByAppendingPathComponent:@"embedded.mobileprovision"];
        _provisioningProfile = [[ALTProvisioningProfile alloc] initWithURL:provisioningProfileURL];
    }
    
    return _provisioningProfile;
}

- (NSSet<ABApplication *> *)appExtensions
{
    NSMutableSet *appExtensions = [NSMutableSet set];
    
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtURL:self.bundle.builtInPlugInsURL includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsSubdirectoryDescendants errorHandler:nil];
    for (NSURL *fileURL in enumerator)
    {
        if (![fileURL.pathExtension.lowercaseString isEqualToString:@"appex"])
        {
            continue;
        }
        
        ABApplication *appExtension = [[ABApplication alloc] initWithFileURL:fileURL];
        if (appExtension == nil)
        {
            continue;
        }
        
        [appExtensions addObject:appExtension];
    }
    
    return appExtensions;
}

- (BOOL)encrypted {
    bool encrypted = false;
    char *macho_path = (char *)[self.executableFileURL.path UTF8String];
    ZMachO macho;
    if (macho.Init(macho_path)) {
        for (size_t i = 0; i < macho.m_arrArchOes.size(); i++) {
            ZArchO *archo = macho.m_arrArchOes[i];
            if (archo->m_bEncrypted) {
                encrypted = true;
            }
        }
        macho.Free();
    }
    return encrypted;
}


@end
