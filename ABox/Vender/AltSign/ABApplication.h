#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif


//#import <AltSign/ALTCapabilities.h>
//#import <AltSign/ALTDevice.h>

#import "ALTCapabilities.h"
#import "ALTDevice.h"

@class ALTProvisioningProfile;

NS_ASSUME_NONNULL_BEGIN

@interface ABApplication : NSObject

@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSString *bundleIdentifier;
@property (nonatomic, copy, readonly) NSString *version;
@property (nonatomic, copy, readonly) NSString *executableName;
@property (nonatomic, copy, readonly) NSURL *executableFileURL;

#if TARGET_OS_IPHONE
@property (nonatomic, readonly, nullable) UIImage *icon;
#endif

@property (nonatomic, readonly, nullable) ALTProvisioningProfile *provisioningProfile;
@property (nonatomic, readonly) NSSet<ABApplication *> *appExtensions;

@property (nonatomic, readonly) NSOperatingSystemVersion minimumiOSVersion;
@property (nonatomic, readonly) ALTDeviceType supportedDeviceTypes;

@property (nonatomic, copy, readonly) NSDictionary<ALTEntitlement, id> *entitlements;
@property (nonatomic, copy, readonly) NSString *entitlementsString;

@property (nonatomic, copy, readonly) NSURL *fileURL;
@property (nonatomic, readonly) NSBundle *bundle;

@property (nonatomic, assign) BOOL hasPrivateEntitlements;

- (nullable instancetype)initWithFileURL:(NSURL *)fileURL;

- (BOOL)encrypted;

@end

NS_ASSUME_NONNULL_END
