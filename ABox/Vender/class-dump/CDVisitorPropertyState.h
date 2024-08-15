// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import <Foundation/Foundation.h>
#import "CDExtensions.h"

@class CDOCProperty;

@interface CDVisitorPropertyState : NSObject

- (id)initWithProperties:(NSArray *)properties;

- (CDOCProperty *)propertyForAccessor:(NSString *)str;

- (BOOL)hasUsedProperty:(CDOCProperty *)property;
- (void)useProperty:(CDOCProperty *)property;

@property (nonatomic, readonly) NSArray *remainingProperties;

@end
