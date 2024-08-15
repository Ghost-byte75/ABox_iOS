#import <Foundation/Foundation.h>
//#import <AltSign/ALTCertificate.h>
#import "ALTCertificate.h"

NS_ASSUME_NONNULL_BEGIN

@interface P12CertificateInfo: NSObject

@property (nonatomic, copy) NSString *country;          //国家或地区 C
@property (nonatomic, copy) NSString *name;             //常用名词  CN
@property (nonatomic, copy) NSString *organization;     //组织 O
@property (nonatomic, copy) NSString *organizationUnit; //组织单位 OU
@property (nonatomic, copy) NSString *userID;           //用户ID UI
@property (nonatomic, assign) long long startTime;
@property (nonatomic, assign) long long expireTime;
@property (nonatomic, assign) BOOL revoked;

@end

typedef void(^ReadP12CompleteHandler)(P12CertificateInfo *certInfo);

@interface ReadP12Subject: NSObject

- (P12CertificateInfo *)readCertInfoWhitAltCert:(ALTCertificate *)altCertificate;
- (void)readCertInfoWhitAltCert:(ALTCertificate *)altCertificate complete:(ReadP12CompleteHandler)callBack;

@end

NS_ASSUME_NONNULL_END
