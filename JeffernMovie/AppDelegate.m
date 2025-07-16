//Jeffern影视平台 ©Jeffern 2025/7/15


#import "AppDelegate.h"
#import "NSURLProtocol+WKWebVIew.h"
#import "HLHomeWindowController.h"
#import "HLHomeViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)checkForUpdates {
    // 1.1.1为当前版本
    NSString *currentVersion = @"1.1.8";
    NSURL *url = [NSURL URLWithString:@"https://github.com/jeffernn/LibreTV-Mac-Objective-C/releases/latest"];
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error || !data) return;
        NSString *html = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"/releases/tag/v([0-9.]+)" options:0 error:nil];
        NSTextCheckingResult *match = [regex firstMatchInString:html options:0 range:NSMakeRange(0, html.length)];
        if (match && match.numberOfRanges > 1) {
            NSString *latestVersion = [html substringWithRange:[match rangeAtIndex:1]];
            if ([latestVersion compare:currentVersion options:NSNumericSearch] == NSOrderedDescending) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSAlert *alert = [[NSAlert alloc] init];
                    alert.messageText = [NSString stringWithFormat:@"发现新版本 v%@，是否前往更新？", latestVersion];
                    [alert addButtonWithTitle:@"确定"];
                    [alert addButtonWithTitle:@"取消"];
                    if ([alert runModal] == NSAlertFirstButtonReturn) {
                        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/jeffernn/LibreTV-Mac-Objective-C/releases/latest"]];
                    }
                });
            }
        }
    }];
    [task resume];
}

// 在applicationDidFinishLaunching中调用
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self checkForUpdates];
    // Insert code here to initialize your application
    [NSURLProtocol wk_registerScheme:@"http"];
    [NSURLProtocol wk_registerScheme:@"https"];
    self.windonwArray = [NSMutableArray array];

    NSMenu *mainMenu = [NSApp mainMenu];
    NSMenuItem *appMenuItem = [mainMenu itemAtIndex:0];
    NSMenu *appSubMenu = [appMenuItem submenu];

    // 删除所有“隐藏”、"项目地址"、"✨"、"清除缓存"、"内置影视"、"关于"、"退出"相关菜单项，避免重复
    NSArray *titlesToRemove = @[@"隐藏", @"项目地址", @"✨", @"清除缓存", @"内置影视", @"关于", @"退出"];
    for (NSInteger i = appSubMenu.numberOfItems - 1; i >= 0; i--) {
        NSMenuItem *item = [appSubMenu itemAtIndex:i];
        for (NSString *title in titlesToRemove) {
            if ([item.title containsString:title]) {
                [appSubMenu removeItemAtIndex:i];
                break;
            }
        }
    }

    // 插入“关于应用”菜单项
    NSMenuItem *aboutItem = [[NSMenuItem alloc] initWithTitle:@"关于应用" action:@selector(orderFrontStandardAboutPanel:) keyEquivalent:@""];
    [aboutItem setTarget:NSApp];
    [appSubMenu insertItem:aboutItem atIndex:0];

    // 插入“退出应用”菜单项
    NSMenuItem *quitItem = [[NSMenuItem alloc] initWithTitle:@"退出应用" action:@selector(terminate:) keyEquivalent:@"q"];
    [quitItem setTarget:NSApp];
    [appSubMenu insertItem:quitItem atIndex:1];

    // 插入“项目地址”菜单项
    NSMenuItem *projectWebsiteItem = [[NSMenuItem alloc] initWithTitle:@"项目地址" action:@selector(openProjectWebsite:) keyEquivalent:@""];
    [projectWebsiteItem setTarget:self];
    [appSubMenu insertItem:projectWebsiteItem atIndex:0];

    // 插入“清除缓存”菜单项（在项目地址上方）
    NSMenuItem *clearCacheItem = [[NSMenuItem alloc] initWithTitle:@"清除缓存" action:@selector(clearAppCache:) keyEquivalent:@""];
    [clearCacheItem setTarget:self];
    [appSubMenu insertItem:clearCacheItem atIndex:0];

    // 插入“内置影视”二级菜单（在清除缓存上方）
    NSMenu *builtInMenu = [[NSMenu alloc] initWithTitle:@"内置影视"];
    NSArray *siteTitles = @[@"茶杯狐", @"奈飞工厂", @"观影网", @"omofun动漫", @"CCTV"];
    NSArray *siteUrls = @[@"https://cupfox.love/", @"https://yanetflix.com/", @"https://www.gying.si", @"https://www.omofun2.xyz", @"https://tv.cctv.com/live/"];
    for (NSInteger i = 0; i < siteTitles.count; i++) {
        NSMenuItem *siteItem = [[NSMenuItem alloc] initWithTitle:siteTitles[i] action:@selector(openBuiltInSite:) keyEquivalent:@""];
        siteItem.target = self;
        siteItem.representedObject = siteUrls[i];
        [builtInMenu addItem:siteItem];
    }
    NSMenuItem *builtInRoot = [[NSMenuItem alloc] initWithTitle:@"内置影视" action:nil keyEquivalent:@""];
    [appSubMenu insertItem:builtInRoot atIndex:1];
    [appSubMenu setSubmenu:builtInMenu forItem:builtInRoot];

    // 插入“✨”菜单项
    NSMenuItem *initSettingItem = [[NSMenuItem alloc] initWithTitle:@"✨" action:@selector(changeUserCustomSiteURL:) keyEquivalent:@""];
    [initSettingItem setTarget:nil];
    [appSubMenu insertItem:initSettingItem atIndex:0];
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

// 使点击左上角关闭按钮时应用完全退出
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

// 新增方法实现
- (void)openProjectWebsite:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/jeffernn/LibreTV-Mac-Objective-C"]];
}

- (void)clearAppCache:(id)sender {
    // 清除NSUserDefaults
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:[[NSBundle mainBundle] bundleIdentifier]];
    [[NSUserDefaults standardUserDefaults] synchronize];
    // 删除config.json
    NSString *configPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/JeffernMovie/config.json"];
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:configPath]) {
        NSError *error = nil;
        [fm removeItemAtPath:configPath error:&error];
    }
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"缓存已清除，应用将自动重启";
    [alert runModal];
    // 重启应用
    NSString *appPath = [[NSBundle mainBundle] bundlePath];
    [[NSWorkspace sharedWorkspace] launchApplication:appPath];
    [NSApp terminate:nil];
}

- (void)openBuiltInSite:(id)sender {
    NSString *url = ((NSMenuItem *)sender).representedObject;
    if (url) {
        // 只通知主界面加载新网址，不再缓存到NSUserDefaults
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ChangeUserCustomSiteURLNotification" object:url];
    }
}

@end
