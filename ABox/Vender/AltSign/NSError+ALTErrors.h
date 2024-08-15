#import <Foundation/Foundation.h>

extern NSErrorDomain const AltSignErrorDomain;
typedef NS_ERROR_ENUM(AltSignErrorDomain, ALTError)
{
    ALTErrorUnknown,
    ALTErrorInvalidApp,
    ALTErrorMissingAppBundle,
    ALTErrorMissingInfoPlist,
    ALTErrorMissingProvisioningProfile,
};

extern NSErrorDomain const ALTAppleAPIErrorDomain;
typedef NS_ERROR_ENUM(ALTAppleAPIErrorDomain, ALTAppleAPIError)
{
    ALTAppleAPIErrorUnknown,
    ALTAppleAPIErrorInvalidParameters,
    
    ALTAppleAPIErrorIncorrectCredentials,
    ALTAppleAPIErrorAppSpecificPasswordRequired,
    
    ALTAppleAPIErrorNoTeams,
    
    ALTAppleAPIErrorInvalidDeviceID,
    ALTAppleAPIErrorDeviceAlreadyRegistered,
    
    ALTAppleAPIErrorInvalidCertificateRequest,
    ALTAppleAPIErrorCertificateDoesNotExist,
    
    ALTAppleAPIErrorInvalidAppIDName,
    ALTAppleAPIErrorInvalidBundleIdentifier,
    ALTAppleAPIErrorBundleIdentifierUnavailable,
    ALTAppleAPIErrorAppIDDoesNotExist,
    ALTAppleAPIErrorMaximumAppIDLimitReached,
    
    ALTAppleAPIErrorInvalidAppGroup,
    ALTAppleAPIErrorAppGroupDoesNotExist,
    
    ALTAppleAPIErrorInvalidProvisioningProfileIdentifier,
    ALTAppleAPIErrorProvisioningProfileDoesNotExist,
    
    ALTAppleAPIErrorRequiresTwoFactorAuthentication,
    ALTAppleAPIErrorIncorrectVerificationCode,
    ALTAppleAPIErrorAuthenticationHandshakeFailed,
    
    ALTAppleAPIErrorInvalidAnisetteData,
};

NS_ASSUME_NONNULL_BEGIN

@interface NSError (ALTError)

@end

NS_ASSUME_NONNULL_END
