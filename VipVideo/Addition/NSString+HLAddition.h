//Jeffern影视平台 ©Jeffern 2025/7/15

#import <AppKit/AppKit.h>


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (HLAddition)

+ (NSString *)compareCurrentTime:(NSDate *)compareDate;

/**
 *  URLEncode
 */
- (NSString *)URLEncodedString;

/**
 *  URLDecode
 */
-(NSString *)URLDecodedString;
@end

NS_ASSUME_NONNULL_END
