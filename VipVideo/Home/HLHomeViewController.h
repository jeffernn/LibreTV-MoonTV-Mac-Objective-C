//Jeffern影视平台 ©Jeffern 2025/7/15

#import <Cocoa/Cocoa.h>

@interface HLHomeViewController : NSViewController

@property (nonatomic, assign) BOOL isFullScreen;

- (void)promptForCustomSiteURLAndLoadIfNeeded;
- (void)changeUserCustomSiteURL:(id)sender;

@end

