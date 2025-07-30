//Jeffern影视平台 ©Jeffern 2025/7/15


#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "HLWebsiteMonitor.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (nonatomic, strong) NSMutableArray *windonwArray;
@property (nonatomic, strong) NSStatusItem *statusItem;

- (void)openProjectWebsite:(id)sender;
- (void)openTelegramGroup:(id)sender;
- (void)clearAppCache:(id)sender;
- (void)openBuiltInSite:(id)sender;
- (void)checkForUpdates;
// 新增：声明生成HTML的方法
- (NSString *)generateHistoryHTML;
- (NSString *)generateMonitorHTML;
- (void)startUpdateWithVersion:(NSString *)version downloadURL:(NSString *)url;
- (void)toggleAutoOpenLastSite:(NSMenuItem *)sender;
- (void)showRepackageDialog:(id)sender;
- (void)openURLWithProxyFallback:(NSString *)url;

// 网站监控相关方法
- (void)showWebsiteMonitor:(id)sender;
- (void)checkWebsiteStatus:(id)sender;
- (void)toggleAutoOpenFastestSite:(id)sender;
- (void)openFastestSite;
- (void)handleWebsiteCheckCompleted:(NSNotification *)notification;
- (void)handleCustomSitesDidChange:(NSNotification *)notification;

@end

