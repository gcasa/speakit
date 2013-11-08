//
//  SIDeviceDescriptor.h
//  SpeakIt
//
//  Created by Gregory Casamento on 11/7/13.
//  Copyright (c) 2013 Gregory Casamento. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SIDeviceDescriptor : NSObject

@property (nonatomic,strong) NSString *deviceName;
@property (nonatomic,strong) NSString *deviceUID;

@end
