#import <Foundation/Foundation.h>
#import "CDExtensions.h"

@interface CDDataCursor : NSObject

- (id)initWithData:(NSData *)data;

@property (readonly) NSData *data;
- (const void *)bytes;

@property (nonatomic, assign) NSUInteger offset;

- (void)advanceByLength:(NSUInteger)length;
- (NSUInteger)remaining;

- (uint8_t)readByte;

- (uint16_t)readLittleInt16;
- (uint32_t)readLittleInt32;
- (uint64_t)readLittleInt64;

- (uint16_t)readBigInt16;
- (uint32_t)readBigInt32;
- (uint64_t)readBigInt64;

- (float)readLittleFloat32;
- (float)readBigFloat32;

- (double)readLittleFloat64;
//- (double)readBigFloat64;

- (void)appendBytesOfLength:(NSUInteger)length intoData:(NSMutableData *)data;
- (void)readBytesOfLength:(NSUInteger)length intoBuffer:(void *)buf;
- (BOOL)isAtEnd;

- (NSString *)readCString;
- (NSString *)readStringOfLength:(NSUInteger)length encoding:(NSStringEncoding)encoding;

@end
