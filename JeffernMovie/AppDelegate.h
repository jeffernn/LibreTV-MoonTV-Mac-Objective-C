//Jeffern影视平台 ©Jeffern 2025/7/15


#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (nonatomic, strong) NSMutableArray *windonwArray;
@property (nonatomic, strong) NSStatusItem *statusItem;

- (void)openProjectWebsite:(id)sender;
- (void)clearAppCache:(id)sender;
- (void)openBuiltInSite:(id)sender;
- (void)checkForUpdates;
// 新增：声明生成历史HTML的方法
- (NSString *)generateHistoryHTML;
- (void)startUpdateWithVersion:(NSString *)version downloadURL:(NSString *)url;

@end

