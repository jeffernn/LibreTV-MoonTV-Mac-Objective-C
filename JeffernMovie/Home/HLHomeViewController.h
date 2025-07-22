//Jeffern影视平台 ©Jeffern 2025/7/15

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface HLHomeViewController : NSViewController <WKNavigationDelegate>

@property (nonatomic, assign) BOOL isFullScreen;
@property (nonatomic, assign) BOOL isPreventingSleep;

- (void)promptForCustomSiteURLAndLoadIfNeeded;
- (void)changeUserCustomSiteURL:(id)sender;
- (void)addHistoryWithName:(NSString *)name url:(NSString *)url;
- (void)clearHistory;
- (void)showLocalHistoryHTML;
- (void)preloadFrequentlyUsedSites;
- (void)enablePreventSleep;
- (void)disablePreventSleep;
- (void)saveSessionState;
- (void)restoreSessionState;
- (NSString *)generateRedButtonJavaScript;
- (void)handleCustomSitesDidChangeNotification:(NSNotification *)notification;
- (void)reinjectRedButtonJavaScript;

@end

