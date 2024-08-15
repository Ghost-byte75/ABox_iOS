// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import <Foundation/Foundation.h>
#import "CDExtensions.h"

@class CDOCProtocol;

@interface CDProtocolUniquer : NSObject

// Gather
- (CDOCProtocol *)protocolWithAddress:(uint64_t)address;
- (void)setProtocol:(CDOCProtocol *)protocol withAddress:(uint64_t)address;

// Process
- (void)createUniquedProtocols;

// Results
- (NSArray *)uniqueProtocolsAtAddresses:(NSArray *)addresses;
- (NSArray *)uniqueProtocolsSortedByName;

@end
