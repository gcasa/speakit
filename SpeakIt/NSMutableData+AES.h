//
//  NSMutableData+AES.h
//  Mosaic eReader
//

#import <Foundation/Foundation.h>


@interface NSMutableData (AES256)

- (NSMutableData*) dataByEncryptingDataWithKey: (NSData *) keyData;
- (NSMutableData*) dataByDecryptingDataWithKey: (NSData *) keyData;

@end
