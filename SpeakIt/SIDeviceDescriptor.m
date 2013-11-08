//
//  SIDeviceDescriptor.m
//  SpeakIt
//
//  Created by Gregory Casamento on 11/7/13.
//  Copyright (c) 2013 Gregory Casamento. All rights reserved.
//

#import "SIDeviceDescriptor.h"

@implementation SIDeviceDescriptor

@synthesize deviceName, deviceUID;

- (NSString *)description
{
    return [NSString stringWithFormat:@"(%@) - (%@)",deviceUID,deviceName];
}

@end
