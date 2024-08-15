#import "CDVisitor.h"
#import <Foundation/Foundation.h>
#import "CDExtensions.h"

// This builds up a dictionary mapping class names to a framework names.
// It is only used by CDMultiFileVisitor to generate individual imports when creating separate header files.

// Some protocols appear in multiple frameworks.  This just records the last framework that contained a reference, which
// produces incorrect results.  For example, -r AppKit.framework, and Foundation.framework is processed before several
// others, including Symbolication.

// If we follow framework dependancies, the earliest reference to NSCopying is CoreFoundation, but NSCopying is really
// defined in Foundation.

// But it turns out that we can just use forward references for protocols.

@interface CDClassFrameworkVisitor : CDVisitor

// NSString (class name) -> NSString (framework name)
@property (nonatomic, readonly) NSDictionary *frameworkNamesByClassName;

// NSString (protocol name) -> NSString (framework name)
@property (nonatomic, readonly) NSDictionary *frameworkNamesByProtocolName;

@end
