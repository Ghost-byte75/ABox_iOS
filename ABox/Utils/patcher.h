#ifndef patcher_h
#define patcher_h

#import "AppSigner.h"
#import <Foundation/Foundation.h>
#import <sys/ttycom.h>
#import <sys/ioctl.h>
#include <stdio.h>
#include <stdlib.h>
#include <dlfcn.h>
#import "defines.h"
#import "headers.h"
#import "operations.h"
#include "operations.h"
#include "defines.h"
#include "headers.h"
#include "NSData+Reading.h"

#define fileExists(file) [[NSFileManager defaultManager] fileExistsAtPath:@(file)]
#define IPAPATCHER_SUCCESS 1
#define IPAPATCHER_FAILURE -1
#define EMPTY_STR @""

#define DEBUG 1
#define DEBUG_ON 1

#define __FILENAME__ (__builtin_strrchr(__FILE__, '/') ? __builtin_strrchr(__FILE__, '/') + 1 : __FILE__)
#define ASSERT(test, message, fatal) do \
if (!(test)) { \
int saved_errno = errno; \
NSLog(@"ASSERT(%d:%s)@%s:%u[%s]\nError message: %@", saved_errno, #test, __FILENAME__, __LINE__, __FUNCTION__, message); \
} \
while (false)

int change_binary(NSString *binaryPath, NSString *from, NSString*to);
int remove_binary(NSString *binaryPath, NSString* dylibPath);

/// patch_binary
/// @param binaryPath binary
/// @param dylibPath dylib path
/// @param lc load: LC_LOAD_DYLIB  weak: LC_LOAD_WEAK_DYLIB  reexport:LC_REEXPORT_DYLIB  upward:LC_LOAD_UPWARD_DYLIB
int patch_binary(NSString *binaryPath, NSString* dylibPath, NSString *lc);


// lc_cmd weak:LC_LOAD_WEAK_DYLIB load:LC_LOAD_DYLIB
// lc_path: @executable_path @rpath
int patch_ipa(NSString *app_path, NSMutableArray *dylib_paths, NSString *lc_cmd, NSString *lc_path);

#endif /* patcher_h */
