//
//  NSData+Additions.h
//  Mosaic eReader
//
//  Created by Gregory Casamento on 11/3/10.
//  Copyright 2010 . All rights reserved.
//

#import <Foundation/Foundation.h>


#import <Foundation/Foundation.h>

@class NSString;

@interface NSData (NSDataAdditions)

+ (NSData *) base64DataFromString:(NSString *)string;
- (NSData *) sha1DigestFromData;

@end
