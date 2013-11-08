//
//  NSString+SHA1.m
//  Mosaic eReader
//
//  Created by Gregory Casamento on 11/7/10.
//  Copyright 2010 . All rights reserved.
//

#import "NSString+SHA1.h"
#import "NSDataAdditions.h"

@implementation NSString (SHA1)

- (NSString *) stringByHashingStringWithSHA1
{
	NSData *dataForString = [self dataUsingEncoding: NSASCIIStringEncoding];
	NSData *shaDigest = [dataForString sha1DigestFromData];
	NSUInteger index = 0;
	NSString *result = @""; //[NSString stringWithString: @""];
	char *data = (char *)[shaDigest bytes];
	
	for(index = 0; index < [shaDigest length]; index++)
	{
		NSString *string = [NSString stringWithFormat: @"%X",(char)data[index]];
		if([string length] >= 2)
		{
			string = [string substringFromIndex: [string length] - 2];
		}
		else
		{
			string = [@"0" stringByAppendingString: string];
		}
		result = [result stringByAppendingString: string];
	}
	
	return result;
}
@end