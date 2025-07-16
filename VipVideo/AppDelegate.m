//Jeffern影视平台 ©Jeffern 2025/7/15


#import "AppDelegate.h"
#import "NSURLProtocol+WKWebVIew.h"
#import "HLHomeWindowController.h"
#import "HLHomeViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    [NSURLProtocol wk_registerScheme:@"http"];
    [NSURLProtocol wk_registerScheme:@"https"];
    // 清空主菜单，只保留应用名菜单
    NSMenu *mainMenu = [NSApp mainMenu];
    while (mainMenu.numberOfItems > 1) {
        [mainMenu removeItemAtIndex:1];
    }
    self.windonwArray = [NSMutableArray array];

    // 动态添加“初始化设置”菜单项
    NSMenuItem *appMenuItem = [mainMenu itemAtIndex:0];
    NSMenu *appSubMenu = [appMenuItem submenu];
    NSMenuItem *initSettingItem = [[NSMenuItem alloc] initWithTitle:@"✨" action:@selector(changeUserCustomSiteURL:) keyEquivalent:@""];
    [initSettingItem setTarget:nil]; // 让 responder chain 处理
    // 插入到“关于”后面
    NSInteger aboutIndex = [appSubMenu indexOfItemWithTitle:[NSString stringWithFormat:@"关于 %@", [[NSProcessInfo processInfo] processName]]];
    if (aboutIndex != NSNotFound) {
        [appSubMenu insertItem:initSettingItem atIndex:aboutIndex+1];
    } else {
        [appSubMenu insertItem:initSettingItem atIndex:1];
    }
    // 删除“隐藏”相关菜单项
    for (NSInteger i = appSubMenu.numberOfItems - 1; i >= 0; i--) {
        NSMenuItem *item = [appSubMenu itemAtIndex:i];
        if ([item.title containsString:@"隐藏"]) {
            [appSubMenu removeItemAtIndex:i];
        }
    }
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication
                    hasVisibleWindows:(BOOL)flag{
    if (!flag){
        //点击icon 主窗口显示
        [NSApp activateIgnoringOtherApps:NO];
        [[[NSApplication sharedApplication].windows firstObject] makeKeyAndOrderFront:self];
    }
    return YES;
}


@end
