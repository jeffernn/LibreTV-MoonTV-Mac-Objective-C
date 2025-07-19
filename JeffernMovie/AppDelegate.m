//Jeffern影视平台 ©Jeffern 2025/7/15


#import "AppDelegate.h"
#import "NSURLProtocol+WKWebVIew.h"
#import "HLHomeWindowController.h"
#import "HLHomeViewController.h"
#import <WebKit/WebKit.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)checkForUpdates {
    // 1.1.1为当前版本
    NSString *currentVersion = @"1.2.4";
    NSURL *url = [NSURL URLWithString:@"https://github.com/jeffernn/LibreTV-MoonTV-Mac-Objective-C/releases/latest"];
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
                        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/jeffernn/LibreTV-MoonTV-Mac-Objective-C/releases/latest"]];
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

    // 先清空所有菜单项
    while (appSubMenu.numberOfItems > 0) {
        [appSubMenu removeItemAtIndex:0];
    }
    // 2. 内置影视
    NSMenu *builtInMenu = [[NSMenu alloc] initWithTitle:@"内置影视"];
    // 二级菜单“✨”跳转到自定义网址
    NSMenuItem *starItem = [[NSMenuItem alloc] initWithTitle:@"Back->✨" action:@selector(changeUserCustomSiteURL:) keyEquivalent:@""];
    [starItem setTarget:self];
    [builtInMenu addItem:starItem];
    NSArray *siteTitles = @[@"海纳TV", @"奈飞工厂", @"omofun动漫",@"红狐狸影视",@"低端影视",@"多瑙影视",@"CCTV",@"Emby"];
    NSArray *siteUrls = @[@"https://www.hainatv.net/",@"https://yanetflix.com/", @"https://www.omofun2.xyz/",@"https://honghuli.com/",@"https://ddys.pro/",@"https://www.duonaovod.com/",@"https://tv.cctv.com/live/",@"https://dongman.theluyuan.com/"];
    for (NSInteger i = 0; i < siteTitles.count; i++) {
        NSMenuItem *siteItem = [[NSMenuItem alloc] initWithTitle:siteTitles[i] action:@selector(openBuiltInSite:) keyEquivalent:@""];
        siteItem.target = self;
        siteItem.representedObject = siteUrls[i];
        [builtInMenu addItem:siteItem];
    }
    NSMenuItem *builtInRoot = [[NSMenuItem alloc] initWithTitle:@"内置影视" action:nil keyEquivalent:@""];
    [appSubMenu addItem:builtInRoot];
    [appSubMenu setSubmenu:builtInMenu forItem:builtInRoot];
    
    // 新增：历史记录菜单项
    NSMenuItem *historyItem = [[NSMenuItem alloc] initWithTitle:@"历史记录" action:@selector(showHistory:) keyEquivalent:@""];
    [historyItem setTarget:self];
    [appSubMenu addItem:historyItem];
    
    // 3. 清除缓存
    NSMenuItem *clearCacheItem = [[NSMenuItem alloc] initWithTitle:@"清除缓存" action:@selector(clearAppCache:) keyEquivalent:@""];
    [clearCacheItem setTarget:self];
    [appSubMenu addItem:clearCacheItem];
    // 4. 项目地址
    NSMenuItem *projectWebsiteItem = [[NSMenuItem alloc] initWithTitle:@"项目地址" action:@selector(openProjectWebsite:) keyEquivalent:@""];
    [projectWebsiteItem setTarget:self];
    [appSubMenu addItem:projectWebsiteItem];
    // 5. 关于应用
    NSMenuItem *aboutItem = [[NSMenuItem alloc] initWithTitle:@"关于应用" action:@selector(orderFrontStandardAboutPanel:) keyEquivalent:@""];
    [aboutItem setTarget:NSApp];
    [appSubMenu addItem:aboutItem];
    // 6. 退出应用
    NSMenuItem *quitItem = [[NSMenuItem alloc] initWithTitle:@"退出应用" action:@selector(terminate:) keyEquivalent:@"q"];
    [quitItem setTarget:NSApp];
    [appSubMenu addItem:quitItem];
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
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/jeffernn/LibreTV-MoonTV-Mac-Objective-C"]];
}

// 新增：生成本地静态HTML文件并展示历史记录
- (NSString *)generateHistoryHTML {
    // 读取本地历史记录
    NSString *historyPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/JeffernMovie/history.json"];
    NSData *data = [NSData dataWithContentsOfFile:historyPath];
    NSArray *history = @[];
    if (data) {
        history = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if (![history isKindOfClass:[NSArray class]]) history = @[];
    }
    NSMutableString *html = [NSMutableString string];
    [html appendString:
     @"<!DOCTYPE html><html lang=\"zh-CN\"><head><meta charset=\"UTF-8\">"
     "<title>历史记录</title>"
     "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">"
     "<link href=\"https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css\" rel=\"stylesheet\">"
     "<link href=\"https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css\" rel=\"stylesheet\">"
     "<style>"
     "body{background:linear-gradient(135deg,#23243a 0%,#2d314d 100%);min-height:100vh;font-family:'PingFang SC','Microsoft YaHei',Arial,sans-serif;}"
     ".history-container{max-width:1000px;margin:48px auto 0 auto;}"
     ".history-title{font-size:2.2rem;font-weight:700;text-align:center;color:#ffda6a;margin-bottom:36px;text-shadow:0 2px 8px #0002;letter-spacing:2px;}"
     ".history-list{padding:0;list-style:none;}"
     ".history-item{background:rgba(255,255,255,0.08);border-radius:16px;box-shadow:0 4px 24px rgba(0,0,0,0.13);margin-bottom:22px;padding:22px 28px;transition:box-shadow 0.18s,background 0.18s;}"
     ".history-item:hover{background:rgba(255,255,255,0.16);box-shadow:0 8px 32px rgba(0,0,0,0.18);}" 
     ".site-title{font-size:1.22rem;font-weight:600;color:#fff;text-decoration:none;display:block;line-height:1.5;}"
     ".site-title:hover{color:#0d6efd;text-decoration:underline;}"
     ".site-time{color:#b0b0b0;font-size:0.98rem;margin-top:6px;display:block;}"
     ".empty-tip{color:#aaa;text-align:center;font-size:1.2rem;margin-top:48px;}"
     "</style></head><body>"
     "<div class=\"history-container\">"
     "<div class=\"history-title\"><i class=\"fas fa-history me-2\"></i>历史记录</div>"
     "<ul class=\"history-list\">"];
    if (history.count == 0) {
        [html appendString:@"<div class=\"empty-tip\">暂无历史记录</div>"];
    } else {
        for (NSDictionary *item in history) {
            NSString *name = item[@"name"] ?: item[@"url"];
            NSString *url = item[@"url"] ?: @"";
            NSString *time = item[@"time"] ?: @"";
            [html appendFormat:
                @"<li class=\"history-item\">"
                "<a class=\"site-title\" href=\"%@\" target=\"_blank\">%@</a>"
                "<span class=\"site-time\"><i class=\"far fa-clock me-1\"></i>%@</span>"
                "</li>", url, name, time];
        }
    }
    [html appendString:@"</ul></div></body></html>"];
    // 写入临时文件
    NSString *renderedPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"history_rendered.html"];
    [html writeToFile:renderedPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    return renderedPath;
}

- (void)showHistory:(id)sender {
    // 生成最新HTML
    [self generateHistoryHTML];
    // 获取主界面控制器
    NSWindow *mainWindow = [NSApplication sharedApplication].mainWindow;
    NSViewController *vc = mainWindow.contentViewController;
    if ([vc isKindOfClass:NSClassFromString(@"HLHomeViewController")]) {
        [(id)vc showLocalHistoryHTML];
    } else if ([vc respondsToSelector:@selector(childViewControllers)]) {
        for (NSViewController *child in vc.childViewControllers) {
            if ([child isKindOfClass:NSClassFromString(@"HLHomeViewController")]) {
                [(id)child showLocalHistoryHTML];
                break;
            }
        }
    }
}

// WKWebView JS 调用原生
// 删除原有WKScriptMessageHandler实现

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
    // 新增：删除历史记录缓存
    NSString *historyPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/JeffernMovie/history.json"];
    if ([fm fileExistsAtPath:historyPath]) {
        NSError *error = nil;
        [fm removeItemAtPath:historyPath error:&error];
    }
    // 新增：同步清理UI历史
    for (NSWindow *window in [NSApp windows]) {
        for (NSViewController *vc in window.contentViewController.childViewControllers) {
            if ([vc isKindOfClass:NSClassFromString(@"HLHomeViewController")]) {
                [(id)vc clearHistory];
            }
        }
    }
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"缓存已清除，应用将自动重启";
    [alert runModal];
    // 重启应用（shell脚本方式，兼容性最强）
    NSString *appPath = [[NSBundle mainBundle] bundlePath];
    NSString *script = [NSString stringWithFormat:@"(sleep 1; open \"%@\") &", appPath];
    system([script UTF8String]);
    [NSApp terminate:nil];
}

- (void)openBuiltInSite:(id)sender {
    NSString *url = ((NSMenuItem *)sender).representedObject;
    if (url) {
        // 只通知主界面加载新网址，不再缓存到NSUserDefaults
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ChangeUserCustomSiteURLNotification" object:url];
    }
}

// 新增：主菜单“✨”弹出填写弹窗
- (void)showCustomSiteInput:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ChangeUserCustomSiteURLNotification" object:nil];
}

// 新增：让“内置影视”菜单的“✨”选项可用，点击后弹出设置
- (void)changeUserCustomSiteURL:(id)sender {
    // 获取当前设置的网址
    NSString *customUrl = [[NSUserDefaults standardUserDefaults] objectForKey:@"UserCustomSiteURL"];
    if (customUrl && customUrl.length > 0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ChangeUserCustomSiteURLNotification" object:customUrl];
    }
}

@end
