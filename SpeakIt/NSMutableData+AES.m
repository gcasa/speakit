//
//  NSMutableData+AES256.m
//  Mosaic eReader
//

#import "NSMutableData+AES.h"
#import <CommonCrypto/CommonCryptor.h>

@implementation NSMutableData (AES256)

- (NSMutableData*) dataByEncryptingDataWithKey: (NSData *) keyData
{
    size_t numBytesEncrypted = 0;
    NSUInteger dataLength = [self length];
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
	void *buffer = malloc(bufferSize);
    CCCryptorStatus result = 0;
    NSMutableData *output = nil;
    
    // NSLog(@"********* Key is %d bytes",[keyData length]);
    {
        result = CCCrypt(kCCEncrypt, kCCAlgorithmAES128, 
                         kCCOptionECBMode | kCCOptionPKCS7Padding,
                         [keyData bytes], kCCKeySizeAES256,
                         NULL,
                         [self mutableBytes], [self length],
                         buffer, bufferSize,
                         &numBytesEncrypted );
    }
    
    output = [NSMutableData dataWithBytes:buffer length:numBytesEncrypted];
    free(buffer);
    if( result == kCCSuccess )
    {
        return output;
    }
    return nil;
}

- (NSMutableData*) dataByDecryptingDataWithKey: (NSData *) keyData
{
    size_t numBytesEncrypted = 0;
    NSUInteger dataLength = [self length];
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
	void *buffer = malloc(bufferSize);
    CCCryptorStatus result = 0;
    NSMutableData *output = nil;
    
    assert([keyData length] == kCCKeySizeAES256);

    // NSLog(@"********* Key is %d bytes",[keyData length]);
    {
        result = CCCrypt(kCCDecrypt, kCCAlgorithmAES128, 
                         kCCOptionECBMode | kCCOptionPKCS7Padding,
                         [keyData bytes], kCCKeySizeAES256,
                         NULL,
                         [self mutableBytes], [self length],
                         buffer, bufferSize,
                         &numBytesEncrypted );
    }
    
    output = [NSMutableData dataWithBytes:buffer length:numBytesEncrypted];
    free(buffer);
    if( result == kCCSuccess )
    {
        return output;
    }
    return nil;
}
@end
