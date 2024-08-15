#import <Foundation/Foundation.h>

uint64_t read_uleb128(const uint8_t **ptrptr, const uint8_t *end);

int64_t read_sleb128(const uint8_t **ptrptr, const uint8_t *end);
