//Jeffern影视平台 ©Jeffern 2025/7/15


#import "AppDelegate.h"
#import "NSURLProtocol+WKWebVIew.h"
#import "HLHomeWindowController.h"
#import "HLHomeViewController.h"
#import <WebKit/WebKit.h>

// 1. 顶部声明自定义进度窗
@interface UpdateProgressView : NSView
@property (nonatomic, strong) NSTextField *titleLabel;
@property (nonatomic, strong) NSProgressIndicator *indicator;
@end
@implementation UpdateProgressView
- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.titleLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 50, frame.size.width, 32)];
        self.titleLabel.stringValue = @"正在更新⏳";
        self.titleLabel.alignment = NSTextAlignmentCenter;
        self.titleLabel.editable = NO;
        self.titleLabel.bezeled = NO;
        self.titleLabel.drawsBackground = NO;
        self.titleLabel.selectable = NO;
        self.titleLabel.font = [NSFont boldSystemFontOfSize:22];
        [self addSubview:self.titleLabel];
        self.indicator = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(30, 20, frame.size.width-60, 20)];
        self.indicator.indeterminate = NO;
        self.indicator.minValue = 0;
        self.indicator.maxValue = 100;
        self.indicator.doubleValue = 0;
        [self.indicator setControlSize:NSControlSizeRegular];
        [self.indicator setStyle:NSProgressIndicatorBarStyle];
        [self addSubview:self.indicator];
    }
    return self;
}
@end

// 新版UpdateProgressPanel：无标题栏、圆角、阴影美化
@interface UpdateProgressPanel : NSPanel
@property (nonatomic, strong) UpdateProgressView *progressView;
@end
@implementation UpdateProgressPanel
- (instancetype)initWithTitle:(NSString *)title {
    self = [super initWithContentRect:NSMakeRect(0, 0, 320, 100)
                            styleMask:NSWindowStyleMaskBorderless
                              backing:NSBackingStoreBuffered defer:NO];
    if (self) {
        self.opaque = NO;
        self.backgroundColor = [NSColor colorWithCalibratedWhite:1 alpha:0.98];
        self.hasShadow = YES;
        self.movableByWindowBackground = YES;
        self.contentView.wantsLayer = YES;
        self.contentView.layer.cornerRadius = 16;
        self.progressView = [[UpdateProgressView alloc] initWithFrame:NSMakeRect(0, 0, 320, 80)];
        // 居中
        NSRect contentFrame = self.contentView.frame;
        CGFloat y = (contentFrame.size.height - 80) / 2;
        self.progressView.frame = NSMakeRect(0, y, 320, 80);
        [self.contentView addSubview:self.progressView];
    }
    return self;
}
@end

@interface AppDelegate () <NSURLSessionDownloadDelegate>
@property (nonatomic, strong) UpdateProgressPanel *progressPanel;
@property (nonatomic, strong) NSString *currentDownloadURL; // 新增：当前下载URL
@property (nonatomic, strong) NSString *currentVersion; // 新增：当前版本
@end

@implementation AppDelegate

- (void)checkForUpdates {
    [self checkForUpdatesWithManualCheck:NO];
}

// 新增：带手动检查标识的版本检查方法
- (void)checkForUpdatesWithManualCheck:(BOOL)isManualCheck {
    NSString *originalURL = @"https://github.com/jeffernn/LibreTV-MoonTV-Mac-Objective-C/releases/latest";
    [self checkForUpdatesWithURL:originalURL isRetry:NO isManualCheck:isManualCheck];
}

// 修改：带重试机制的版本检查
- (void)checkForUpdatesWithURL:(NSString *)urlString isRetry:(BOOL)isRetry isManualCheck:(BOOL)isManualCheck {
    NSString *currentVersion = @"1.3.1";
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.timeoutInterval = 6.0; // 6秒超时
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            // 如果是超时错误且不是重试，则切换到代理
            if (error.code == NSURLErrorTimedOut && !isRetry) {
                NSString *proxyURL = [NSString stringWithFormat:@"https://gh-proxy.com/%@", urlString];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self checkForUpdatesWithURL:proxyURL isRetry:YES isManualCheck:isManualCheck];
                });
                return;
            }
            return; // 其他错误或重试失败，直接返回
        }
        
        if (!data) return;
        
        NSString *html = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"/releases/tag/v([0-9.]+)" options:0 error:nil];
        NSTextCheckingResult *match = [regex firstMatchInString:html options:0 range:NSMakeRange(0, html.length)];
        
        if (match && match.numberOfRanges > 1) {
            NSString *latestVersion = [html substringWithRange:[match rangeAtIndex:1]];
            if ([latestVersion compare:currentVersion options:NSNumericSearch] == NSOrderedDescending) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSAlert *alert = [[NSAlert alloc] init];
                    alert.messageText = [NSString stringWithFormat:@"发现新版本 v%@，是否立即更新？", latestVersion];
                    [alert addButtonWithTitle:@"确定"];
                    [alert addButtonWithTitle:@"取消"];
                    if ([alert runModal] == NSAlertFirstButtonReturn) {
                        NSString *downloadURL = [NSString stringWithFormat:@"https://github.com/jeffernn/LibreTV-MoonTV-Mac-Objective-C/releases/download/v%@/JeffernMovie.app.zip", latestVersion];
                        [self startUpdateWithVersion:latestVersion downloadURL:downloadURL];
                    }
                });
            } else if (isManualCheck) {
                // 手动检查且已是最新版本，显示提醒
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSAlert *alert = [[NSAlert alloc] init];
                    alert.messageText = @"已是最新版本";
                    alert.informativeText = [NSString stringWithFormat:@"当前版本 v%@ 已是最新版本", currentVersion];
                    [alert addButtonWithTitle:@"确定"];
                    [alert runModal];
                });
            }
        }
    }];
    [task resume];
}

// 自动下载、解压、替换并重启
- (void)startUpdateWithVersion:(NSString *)version downloadURL:(NSString *)url {
    self.currentVersion = version;
    self.currentDownloadURL = url;
    [self startDownloadWithURL:url isRetry:NO];
}

// 新增：带重试机制的下载方法
- (void)startDownloadWithURL:(NSString *)urlString isRetry:(BOOL)isRetry {
    // 首次下载时显示进度窗口
    if (!isRetry) {
        self.progressPanel = [[UpdateProgressPanel alloc] initWithTitle:@"正在更新"];
        [self.progressPanel center];
        [self.progressPanel makeKeyAndOrderFront:nil];
        [self.progressPanel setLevel:NSModalPanelWindowLevel];
        [self.progressPanel orderFrontRegardless];
        self.progressPanel.progressView.titleLabel.stringValue = @"正在更新";
        self.progressPanel.progressView.indicator.doubleValue = 0;
    }
    
    NSURL *downloadURL = [NSURL URLWithString:urlString];
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.timeoutIntervalForRequest = 6.0; // 6秒超时
    config.timeoutIntervalForResource = 300.0; // 5分钟总超时
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithURL:downloadURL];
    [downloadTask resume];
    
    // 设置超时检测
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(6.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (downloadTask.state == NSURLSessionTaskStateRunning && !isRetry) {
            // 15秒后仍在运行且不是重试，取消当前任务并切换到代理
            [downloadTask cancel];
            NSString *proxyURL = [NSString stringWithFormat:@"https://gh-proxy.com/%@", urlString];
            [self startDownloadWithURL:proxyURL isRetry:YES];
        }
    });
}

// 下载进度回调
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    double percent = (double)totalBytesWritten / (double)totalBytesExpectedToWrite * 100.0;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.progressPanel.progressView.indicator.doubleValue = percent;
    });
}

// 下载完成回调
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.progressPanel.progressView.indicator.doubleValue = 0;
    });
    
    NSString *zipPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"JeffernMovie.app.zip"];
    [[NSFileManager defaultManager] removeItemAtPath:zipPath error:nil];
    NSError *moveZipError = nil;
    [[NSFileManager defaultManager] moveItemAtPath:location.path toPath:zipPath error:&moveZipError];
    if (moveZipError) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressPanel orderOut:nil];
            [self showUpdateFailedAlert];
        });
        return;
    }
    
    NSString *unzipDir = [NSTemporaryDirectory() stringByAppendingPathComponent:@"update_unzip"];
    [[NSFileManager defaultManager] removeItemAtPath:unzipDir error:nil];
    [[NSFileManager defaultManager] createDirectoryAtPath:unzipDir withIntermediateDirectories:YES attributes:nil error:nil];
    
    NSTask *unzipTask = [[NSTask alloc] init];
    unzipTask.launchPath = @"/usr/bin/unzip";
    unzipTask.arguments = @[@"-o", zipPath, @"-d", unzipDir];
    [unzipTask launch];
    [unzipTask waitUntilExit];
    
    NSString *newAppPath = [unzipDir stringByAppendingPathComponent:@"JeffernMovie.app"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:newAppPath]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressPanel orderOut:nil];
            [self showUpdateFailedAlert];
        });
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.progressPanel.progressView.indicator.doubleValue = 0;
    });
    
    NSString *currentAppPath = [[NSBundle mainBundle] bundlePath];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *removeError = nil;
    [fm removeItemAtPath:currentAppPath error:&removeError];
    NSError *moveError = nil;
    [fm moveItemAtPath:newAppPath toPath:currentAppPath error:&moveError];
    if (moveError) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressPanel orderOut:nil];
            [self showUpdateFailedAlert];
        });
        return;
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:(self.currentVersion ? self.currentVersion : @"") forKey:@"JustUpdatedVersion"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSString *script = [NSString stringWithFormat:@"(sleep 1; open \"%@\") &", currentAppPath];
    system([script UTF8String]);
    
    [[NSFileManager defaultManager] removeItemAtPath:zipPath error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:unzipDir error:nil];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressPanel orderOut:nil];
        [NSApp terminate:nil];
    });
}

// 新增：下载失败回调
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error && error.code == NSURLErrorTimedOut) {
        // 超时错误，检查是否需要重试
        if ([self.currentDownloadURL hasPrefix:@"https://github.com/"] && ![self.currentDownloadURL hasPrefix:@"https://gh-proxy.com/"]) {
            // 原始链接超时，切换到代理
            NSString *proxyURL = [NSString stringWithFormat:@"https://gh-proxy.com/%@", self.currentDownloadURL];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self startDownloadWithURL:proxyURL isRetry:YES];
            });
            return;
        }
    }
    
    // 其他错误或代理也失败，显示错误弹窗
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressPanel orderOut:nil];
        [self showUpdateFailedAlert];
    });
}

// 在applicationDidFinishLaunching中调用
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // 检查是否刚刚更新
    NSString *justUpdated = [[NSUserDefaults standardUserDefaults] objectForKey:@"JustUpdatedVersion"];
    if (justUpdated) {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = [NSString stringWithFormat:@"更新成功🎉", justUpdated];
        [alert runModal];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"JustUpdatedVersion"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    [self checkForUpdates];
    // Insert code here to initialize your application
    [NSURLProtocol wk_registerScheme:@"http"];
    [NSURLProtocol wk_registerScheme:@"https"];
    self.windonwArray = [NSMutableArray array];

    NSMenu *mainMenu = [NSApp mainMenu];

    // 1. 创建并添加“内置影视”为一级主菜单
    NSMenu *builtInMenu = [[NSMenu alloc] initWithTitle:@"内置影视"];
    // 二级菜单“✨”跳转到自定义网址
    NSMenuItem *starItem = [[NSMenuItem alloc] initWithTitle:@"✨✨✨" action:@selector(changeUserCustomSiteURL:) keyEquivalent:@""];
    [starItem setTarget:self];
    [builtInMenu addItem:starItem];
    NSArray *siteTitles = @[@"Emby",@"可可影视", @"奈飞工厂", @"omofun动漫",@"北觅影视",@"人人影视",@"66TV",@"红狐狸影视",@"低端影视",@"多瑙影视",@"CCTV",@"抖音短剧"];
    NSArray *siteUrls = @[@"https://dongman.theluyuan.com/",@"https://www.keke1.app/",@"https://yanetflix.com/", @"https://www.omofun2.xyz/",@"https://v.luttt.com/",@"https://kuaizi.cc/",@"https://www.66dyy.net/",@"https://honghuli.com/",@"https://ddys.pro/",@"https://www.duonaovod.com/",@"https://tv.cctv.com/live/",@"https://www.jinlidj.com/"];
    for (NSInteger i = 0; i < siteTitles.count; i++) {
        NSMenuItem *siteItem = [[NSMenuItem alloc] initWithTitle:siteTitles[i] action:@selector(openBuiltInSite:) keyEquivalent:@""];
        siteItem.target = self;
        siteItem.representedObject = siteUrls[i];
        [builtInMenu addItem:siteItem];
        // 在Emby下方插入分隔线和复选框
        if ([siteTitles[i] isEqualToString:@"抖音短剧"]) {
            NSMenuItem *separator = [NSMenuItem separatorItem];
            [builtInMenu addItem:separator];
            NSMenuItem *autoOpenLastSiteItem = [[NSMenuItem alloc] initWithTitle:@"勾选后下次启动时自动打开上次影视站" action:@selector(toggleAutoOpenLastSite:) keyEquivalent:@""];
            autoOpenLastSiteItem.target = self;
            NSNumber *autoOpenObj = [[NSUserDefaults standardUserDefaults] objectForKey:@"AutoOpenLastSite"];
            BOOL checked = autoOpenObj ? [autoOpenObj boolValue] : NO;
            autoOpenLastSiteItem.state = checked ? NSControlStateValueOn : NSControlStateValueOff;
            [builtInMenu addItem:autoOpenLastSiteItem];
        }
    }
    NSMenuItem *builtInMenuItem = [[NSMenuItem alloc] initWithTitle:@"内置影视" action:nil keyEquivalent:@""];
    [builtInMenuItem setSubmenu:builtInMenu];
    [mainMenu insertItem:builtInMenuItem atIndex:1];

    // 2. 创建并添加“功能”为一级主菜单
    NSMenu *featuresMenu = [[NSMenu alloc] initWithTitle:@"功能列表"];
    NSMenuItem *historyItem = [[NSMenuItem alloc] initWithTitle:@"观影记录" action:@selector(showHistory:) keyEquivalent:@""];
    [historyItem setTarget:self];
    [featuresMenu addItem:historyItem];
    NSMenuItem *checkUpdateItem = [[NSMenuItem alloc] initWithTitle:@"检测更新" action:@selector(checkForUpdates:) keyEquivalent:@""];
    [checkUpdateItem setTarget:self];
    [featuresMenu addItem:checkUpdateItem];
    NSMenuItem *clearCacheItem = [[NSMenuItem alloc] initWithTitle:@"清除缓存" action:@selector(clearAppCache:) keyEquivalent:@""];
    [clearCacheItem setTarget:self];
    [featuresMenu addItem:clearCacheItem];
    NSMenuItem *featuresMenuItem = [[NSMenuItem alloc] initWithTitle:@"功能" action:nil keyEquivalent:@""];
    [featuresMenuItem setSubmenu:featuresMenu];
    [mainMenu insertItem:featuresMenuItem atIndex:2];

    // 3. 创建并添加“福利”为一级主菜单
    NSMenu *fuliMenu = [[NSMenu alloc] initWithTitle:@"福利"];
    NSMenuItem *shadowrocketItem = [[NSMenuItem alloc] initWithTitle:@"ShadoWrocket" action:@selector(openFuliLink:) keyEquivalent:@""];
    shadowrocketItem.target = self;
    shadowrocketItem.representedObject = @"https://s.jiesuo.one/s/e645da4602ac4891a0533a7c1163f5c9";
    [fuliMenu addItem:shadowrocketItem];
    NSMenuItem *tunnelItem = [[NSMenuItem alloc] initWithTitle:@"Base64隧道" action:@selector(openFuliLink:) keyEquivalent:@""];
    tunnelItem.target = self;
    tunnelItem.representedObject = @"https://shouji.dpdns.org/free_nodes";
    [fuliMenu addItem:tunnelItem];
    NSMenuItem *fuliMenuItem = [[NSMenuItem alloc] initWithTitle:@"福利" action:nil keyEquivalent:@""];
    [fuliMenuItem setSubmenu:fuliMenu];
    [mainMenu insertItem:fuliMenuItem atIndex:3];

    // 4. 创建并添加“关于”为一级主菜单
    NSMenu *aboutMenu = [[NSMenu alloc] initWithTitle:@"关于"];
    NSMenuItem *projectWebsiteItem = [[NSMenuItem alloc] initWithTitle:@"项目地址" action:@selector(openProjectWebsite:) keyEquivalent:@""];
    [projectWebsiteItem setTarget:self];
    [aboutMenu addItem:projectWebsiteItem];
    NSMenuItem *aboutItem = [[NSMenuItem alloc] initWithTitle:@"关于应用" action:@selector(orderFrontStandardAboutPanel:) keyEquivalent:@""];
    [aboutItem setTarget:NSApp];
    [aboutMenu addItem:aboutItem];
    NSMenuItem *aboutMenuItem = [[NSMenuItem alloc] initWithTitle:@"关于" action:nil keyEquivalent:@""];
    [aboutMenuItem setSubmenu:aboutMenu];
    [mainMenu insertItem:aboutMenuItem atIndex:4];

    // 2.5. 创建并添加“自定义站”为一级主菜单
    NSMenu *customSiteMenu = [[NSMenu alloc] initWithTitle:@"自定义站"];
    // 读取自定义站点数组
    NSArray *customSites = [[NSUserDefaults standardUserDefaults] arrayForKey:@"CustomSites"] ?: @[];
    for (NSDictionary *site in customSites) {
        NSString *name = site[@"name"] ?: @"未命名";
        NSString *url = site[@"url"] ?: @"";
        NSMenuItem *siteItem = [[NSMenuItem alloc] initWithTitle:name action:@selector(openCustomSite:) keyEquivalent:@""];
        siteItem.target = self;
        siteItem.representedObject = url;
        // 添加删除子菜单
        NSMenu *siteSubMenu = [[NSMenu alloc] initWithTitle:name];
        // 添加编辑子菜单
        NSMenuItem *editItem = [[NSMenuItem alloc] initWithTitle:@"编辑" action:@selector(editCustomSite:) keyEquivalent:@""];
        editItem.target = self;
        editItem.tag = [customSites indexOfObject:site]; // 用tag标记索引
        [siteSubMenu addItem:editItem];
        // 添加删除子菜单
        NSMenuItem *deleteItem = [[NSMenuItem alloc] initWithTitle:@"删除" action:@selector(deleteCustomSite:) keyEquivalent:@""];
        deleteItem.target = self;
        deleteItem.tag = [customSites indexOfObject:site]; // 用tag标记索引
        [siteSubMenu addItem:deleteItem];
        [siteItem setSubmenu:siteSubMenu];
        [customSiteMenu addItem:siteItem];
    }
    // 分隔线和添加按钮
    [customSiteMenu addItem:[NSMenuItem separatorItem]];
    NSMenuItem *addSiteItem = [[NSMenuItem alloc] initWithTitle:@"添加站点" action:@selector(showAddCustomSiteDialog:) keyEquivalent:@""];
    addSiteItem.target = self;
    [customSiteMenu addItem:addSiteItem];
    // 新增：自动打开上次影视站复选框
    NSMenuItem *autoOpenLastSiteItem2 = [[NSMenuItem alloc] initWithTitle:@"勾选后下次启动时自动打开上次影视站" action:@selector(toggleAutoOpenLastSite:) keyEquivalent:@""];
    autoOpenLastSiteItem2.target = self;
    NSNumber *autoOpenObj2 = [[NSUserDefaults standardUserDefaults] objectForKey:@"AutoOpenLastSite"];
    BOOL checked2 = autoOpenObj2 ? [autoOpenObj2 boolValue] : NO;
    autoOpenLastSiteItem2.state = checked2 ? NSControlStateValueOn : NSControlStateValueOff;
    [customSiteMenu addItem:autoOpenLastSiteItem2];
    NSMenuItem *customSiteMenuItem = [[NSMenuItem alloc] initWithTitle:@"自定义站" action:nil keyEquivalent:@""];
    [customSiteMenuItem setSubmenu:customSiteMenu];
    [mainMenu insertItem:customSiteMenuItem atIndex:3];

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
    NSString *url = @"https://github.com/jeffernn/LibreTV-MoonTV-Mac-Objective-C";
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ChangeUserCustomSiteURLNotification" object:url];
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
    // 使用本地图片作为背景
    NSString *imgPath = [[NSBundle mainBundle] pathForResource:@"1" ofType:@"JPG" inDirectory:@"img"];
    NSString *bgUrl = [NSString stringWithFormat:@"file://%@", imgPath];
    NSMutableString *html = [NSMutableString string];
    [html appendString:
     @"<!DOCTYPE html><html lang=\"zh-CN\"><head><meta charset=\"UTF-8\">"
     "<title>历史记录</title>"
     "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">"
     "<link href=\"https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css\" rel=\"stylesheet\">"
     "<link href=\"https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css\" rel=\"stylesheet\">"
     "<style>"
     "body{min-height:100vh;font-family:'PingFang SC','Microsoft YaHei',Arial,sans-serif;"];
    [html appendString:@"background: url('"];
    [html appendString:bgUrl];
    [html appendString:@"') no-repeat center center fixed;"];
    [html appendString:@"background-size:cover;"];
    [html appendString:@"}"];
    [html appendString:@".history-container{max-width:1500px;margin:48px auto 0 auto;padding:32px 24px 24px 24px;background:rgba(255,255,255,0.28);border-radius:24px;box-shadow:0 8px 32px rgba(0,0,0,0.10);backdrop-filter:blur(24px);-webkit-backdrop-filter:blur(24px);}"];
    [html appendString:@".history-title{font-size:2.2rem;font-weight:700;text-align:center;color:#222;margin-bottom:24px;text-shadow:0 2px 8px #fff2;letter-spacing:2px;}"];
    [html appendString:@".clear-btn{display:block;margin:0 auto 32px auto;padding:12px 40px;font-size:1.18rem;font-weight:600;color:#222;background:rgba(255,255,255,0.38);border:none;border-radius:16px;box-shadow:0 2px 12px #0002;backdrop-filter:blur(12px);-webkit-backdrop-filter:blur(12px);transition:background 0.2s,color 0.2s;cursor:pointer;text-shadow:0 1px 2px #fff8;}" ];
    [html appendString:@".clear-btn:hover{background:rgba(255,255,255,0.55);color:#2193b0;}"];
    [html appendString:@".history-list{padding:0;list-style:none;min-height:120px;}"];
    [html appendString:@".history-item{background:rgba(255,255,255,0.38);border-radius:16px;box-shadow:0 2px 8px rgba(0,0,0,0.06);margin-bottom:18px;padding:18px 24px;transition:box-shadow 0.18s,background 0.18s;backdrop-filter:blur(8px);-webkit-backdrop-filter:blur(8px);}"];
    [html appendString:@".history-item:hover{background:rgba(109,213,237,0.18);box-shadow:0 4px 16px rgba(33,147,176,0.10);}"];
    [html appendString:@".site-title{font-size:1.18rem;font-weight:600;color:#222;text-decoration:none;display:block;line-height:1.5;}"];
    [html appendString:@".site-title:hover{color:#2193b0;text-decoration:underline;}"];
    [html appendString:@".site-time{color:#666;font-size:0.98rem;margin-top:6px;display:block;}"];
    [html appendString:@".empty-tip{color:#888;text-align:center;font-size:1.2rem;margin-top:48px;}"];
    [html appendString:@".pagination{text-align:center;margin-top:18px;display:flex;justify-content:center;align-items:center;gap:18px;}"];
    [html appendString:@".pagination button{margin:0 16px 0 16px;padding:6px 18px;border-radius:8px;border:none;background:#fff;color:#222;font-weight:600;box-shadow:0 2px 8px #0001;cursor:pointer;transition:background 0.2s;}"];
    [html appendString:@".pagination button:disabled{background:#eee;color:#aaa;cursor:not-allowed;}"];
    [html appendString:@"</style></head><body>"];
    [html appendString:@"<div class=\"history-container\">"];
    [html appendString:@"<div class=\"history-title\"><i class=\"fas fa-history me-2\"></i>历史记录</div>"];
    [html appendString:@"<button class=\"clear-btn\" onclick=\"window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.clearHistory && window.webkit.messageHandlers.clearHistory.postMessage(null)\">清除历史</button>"];
    [html appendString:@"<ul class=\"history-list\"></ul>"];
    [html appendString:@"<div class=\"empty-tip\" style=\"display:none;\">暂无历史记录</div>"];
    [html appendString:@"<div class=\"pagination\"><button id=\"prevPage\">上一页</button><span id=\"pageInfo\"></span><button id=\"nextPage\">下一页</button></div>"];
    // 插入分页JS
    NSError *jsonError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:history options:0 error:&jsonError];
    NSString *historyJson = @"[]";
    if (jsonData && !jsonError) {
        historyJson = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    [html appendString:@"<script>\n"];
    [html appendFormat:@"var historyData = %@;\n", historyJson];
    [html appendString:@"var pageSize = 6;\nvar currentPage = 1;\nvar totalPages = Math.ceil(historyData.length / pageSize);\n"];
    [html appendString:@"function renderPage(page) {\n"];
    [html appendString:@"  var list = document.querySelector('.history-list');\n"];
    [html appendString:@"  list.innerHTML = '';\n"];
    [html appendString:@"  var start = (page-1)*pageSize;\n"];
    [html appendString:@"  var end = Math.min(start+pageSize, historyData.length);\n"];
    [html appendString:@"  for (var i=start; i<end; i++) {\n"];
    [html appendString:@"    var item = historyData[i];\n"];
    [html appendString:@"    var li = document.createElement('li');\n"];
    [html appendString:@"    li.className = 'history-item';\n"];
    [html appendString:@"    var a = document.createElement('a');\n"];
    [html appendString:@"    a.className = 'site-title';\n"];
    [html appendString:@"    a.href = item.url || '';\n"];
    [html appendString:@"    a.target = '_blank';\n"];
    [html appendString:@"    a.textContent = item.name || item.url || '';\n"];
    [html appendString:@"    li.appendChild(a);\n"];
    [html appendString:@"    var time = document.createElement('span');\n"];
    [html appendString:@"    time.className = 'site-time';\n"];
    [html appendString:@"    time.innerHTML = '<i class=\\\"far fa-clock me-1\\\"></i>' + (item.time || '');\n"];
    [html appendString:@"    li.appendChild(time);\n"];
    [html appendString:@"    list.appendChild(li);\n"];
    [html appendString:@"  }\n"];
    [html appendString:@"  document.getElementById('pageInfo').textContent = '第 ' + page + ' / ' + (totalPages || 1) + ' 页';\n"];
    [html appendString:@"  document.getElementById('prevPage').disabled = (page <= 1);\n"];
    [html appendString:@"  document.getElementById('nextPage').disabled = (page >= totalPages);\n"];
    [html appendString:@"  document.querySelector('.empty-tip').style.display = (historyData.length === 0) ? 'block' : 'none';\n"];
    [html appendString:@"}\n"];
    [html appendString:@"document.getElementById('prevPage').onclick = function() { if (currentPage > 1) { currentPage--; renderPage(currentPage); } };\n"];
    [html appendString:@"document.getElementById('nextPage').onclick = function() { if (currentPage < totalPages) { currentPage++; renderPage(currentPage); } };\n"];
    [html appendString:@"renderPage(currentPage);\n"];
    [html appendString:@"</script></body></html>"];
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
    NSAlert *confirmationAlert = [[NSAlert alloc] init];
    confirmationAlert.messageText = @"确定要清除缓存吗？";
    confirmationAlert.informativeText = @"此操作将清除所有设置和历史记录，此操作不可恢复，请谨慎操作。";
    [confirmationAlert addButtonWithTitle:@"确定"];
    [confirmationAlert addButtonWithTitle:@"取消"];

    if ([confirmationAlert runModal] == NSAlertFirstButtonReturn) {
        // 清除NSUserDefaults
        [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:[[NSBundle mainBundle] bundleIdentifier]];
        [[NSUserDefaults standardUserDefaults] synchronize];
        // 删除LastBuiltInSiteURL缓存
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"LastBuiltInSiteURL"];
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
}

// 新增：切换复选框状态
- (void)toggleAutoOpenLastSite:(NSMenuItem *)sender {
    BOOL newState = sender.state == NSControlStateValueOff;
    sender.state = newState ? NSControlStateValueOn : NSControlStateValueOff;
    [[NSUserDefaults standardUserDefaults] setBool:newState forKey:@"AutoOpenLastSite"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    // 取消勾选时，自动删除上次缓存
    if (!newState) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"LastBuiltInSiteURL"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    // 刷新两个菜单的复选框状态
    NSMenu *mainMenu = [NSApp mainMenu];
    // 内置影视
    NSInteger builtInIdx = [mainMenu indexOfItemWithTitle:@"内置影视"];
    if (builtInIdx != -1) {
        NSMenu *builtInMenu = [[mainMenu itemAtIndex:builtInIdx] submenu];
        for (NSMenuItem *item in builtInMenu.itemArray) {
            if ([item.title containsString:@"勾选后下次启动时自动打开上次影视站"]) {
                item.state = sender.state;
            }
        }
    }
    // 自定义站
    NSInteger customIdx = [mainMenu indexOfItemWithTitle:@"自定义站"];
    if (customIdx != -1) {
        NSMenu *customMenu = [[mainMenu itemAtIndex:customIdx] submenu];
        for (NSMenuItem *item in customMenu.itemArray) {
            if ([item.title containsString:@"勾选后下次启动时自动打开上次影视站"]) {
                item.state = sender.state;
            }
        }
    }
}

- (void)openBuiltInSite:(id)sender {
    NSString *url = ((NSMenuItem *)sender).representedObject;
    if (url) {
        // 记录上次访问
        [[NSUserDefaults standardUserDefaults] setObject:url forKey:@"LastBuiltInSiteURL"];
        [[NSUserDefaults standardUserDefaults] synchronize];
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

// 新增统一错误弹窗方法
- (void)showUpdateFailedAlert {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"更新失败";
    alert.informativeText = @"请手动下载安装新版本";
    [alert addButtonWithTitle:@"前往下载"];
    [alert addButtonWithTitle:@"取消"];
    if ([alert runModal] == NSAlertFirstButtonReturn) {
        NSString *url = @"https://github.com/jeffernn/LibreTV-MoonTV-Mac-Objective-C/releases/latest";
        NSURL *testURL = [NSURL URLWithString:url];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:testURL];
        request.timeoutInterval = 6.0;
        NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            NSString *openURL = url;
            if (error && error.code == NSURLErrorTimedOut) {
                openURL = [NSString stringWithFormat:@"https://gh-proxy.com/%@", url];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:openURL]];
            });
        }];
        [task resume];
    }
}

// 新增：检测更新菜单项处理方法
- (void)checkForUpdates:(id)sender {
    [self checkForUpdatesWithManualCheck:YES];
}

- (void)openFuliLink:(id)sender {
    NSString *url = ((NSMenuItem *)sender).representedObject;
    if (url) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ChangeUserCustomSiteURLNotification" object:url];
    }
}

// 新增：自定义站点菜单点击事件
- (void)openCustomSite:(id)sender {
    NSString *url = ((NSMenuItem *)sender).representedObject;
    if (url) {
        // 记录上次访问（与内置影视一致）
        [[NSUserDefaults standardUserDefaults] setObject:url forKey:@"LastBuiltInSiteURL"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ChangeUserCustomSiteURLNotification" object:url];
    }
}

// 新增：添加自定义站点弹窗逻辑
- (void)showAddCustomSiteDialog:(id)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"添加自定义站点";
    alert.informativeText = @"请输入站点名称和网址（如 https://example.com）";
    NSTextField *nameField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 30, 240, 24)];
    nameField.placeholderString = @"站点名称";
    NSTextField *urlField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 240, 24)];
    urlField.placeholderString = @"站点网址";
    NSView *accessory = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 240, 54)];
    [accessory addSubview:nameField];
    [accessory addSubview:urlField];
    alert.accessoryView = accessory;
    [alert addButtonWithTitle:@"确定"];
    [alert addButtonWithTitle:@"取消"];
    NSModalResponse resp = [alert runModal];
    if (resp == NSAlertFirstButtonReturn) {
        NSString *name = [nameField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSString *url = [urlField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (name.length == 0 || url.length == 0) {
            NSAlert *warn = [[NSAlert alloc] init];
            warn.messageText = @"名称和网址不能为空";
            [warn runModal];
            return;
        }
        // 简单校验网址
        if (![url hasPrefix:@"http://"] && ![url hasPrefix:@"https://"]) {
            NSAlert *warn = [[NSAlert alloc] init];
            warn.messageText = @"网址必须以 http:// 或 https:// 开头";
            [warn runModal];
            return;
        }
        NSMutableArray *customSites = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] arrayForKey:@"CustomSites"] ?: @[]];
        [customSites addObject:@{ @"name": name, @"url": url }];
        [[NSUserDefaults standardUserDefaults] setObject:customSites forKey:@"CustomSites"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        // 刷新菜单
        [self rebuildCustomSiteMenu];
    }
}
// 新增：刷新自定义站菜单
- (void)rebuildCustomSiteMenu {
    NSMenu *mainMenu = [NSApp mainMenu];
    NSInteger idx = [mainMenu indexOfItemWithTitle:@"自定义站"];
    if (idx == -1) return;
    NSMenuItem *customSiteMenuItem = [mainMenu itemAtIndex:idx];
    NSMenu *customSiteMenu = [[NSMenu alloc] initWithTitle:@"自定义站"];
    NSArray *customSites = [[NSUserDefaults standardUserDefaults] arrayForKey:@"CustomSites"] ?: @[];
    for (NSInteger i = 0; i < customSites.count; i++) {
        NSDictionary *site = customSites[i];
        NSString *name = site[@"name"] ?: @"未命名";
        NSString *url = site[@"url"] ?: @"";
        NSMenuItem *siteItem = [[NSMenuItem alloc] initWithTitle:name action:@selector(openCustomSite:) keyEquivalent:@""];
        siteItem.target = self;
        siteItem.representedObject = url;
        // 添加删除子菜单
        NSMenu *siteSubMenu = [[NSMenu alloc] initWithTitle:name];
        // 添加编辑子菜单
        NSMenuItem *editItem = [[NSMenuItem alloc] initWithTitle:@"编辑" action:@selector(editCustomSite:) keyEquivalent:@""];
        editItem.target = self;
        editItem.tag = i;
        [siteSubMenu addItem:editItem];
        // 添加删除子菜单
        NSMenuItem *deleteItem = [[NSMenuItem alloc] initWithTitle:@"删除" action:@selector(deleteCustomSite:) keyEquivalent:@""];
        deleteItem.target = self;
        deleteItem.tag = i;
        [siteSubMenu addItem:deleteItem];
        [siteItem setSubmenu:siteSubMenu];
        [customSiteMenu addItem:siteItem];
    }
    [customSiteMenu addItem:[NSMenuItem separatorItem]];
    NSMenuItem *addSiteItem = [[NSMenuItem alloc] initWithTitle:@"添加站点" action:@selector(showAddCustomSiteDialog:) keyEquivalent:@""];
    addSiteItem.target = self;
    [customSiteMenu addItem:addSiteItem];
    // 新增：自动打开上次影视站复选框
    NSMenuItem *autoOpenLastSiteItem2 = [[NSMenuItem alloc] initWithTitle:@"勾选后下次启动时自动打开上次影视站" action:@selector(toggleAutoOpenLastSite:) keyEquivalent:@""];
    autoOpenLastSiteItem2.target = self;
    NSNumber *autoOpenObj2 = [[NSUserDefaults standardUserDefaults] objectForKey:@"AutoOpenLastSite"];
    BOOL checked2 = autoOpenObj2 ? [autoOpenObj2 boolValue] : NO;
    autoOpenLastSiteItem2.state = checked2 ? NSControlStateValueOn : NSControlStateValueOff;
    [customSiteMenu addItem:autoOpenLastSiteItem2];
    [customSiteMenuItem setSubmenu:customSiteMenu];
}

// 新增：删除自定义站点逻辑
- (void)deleteCustomSite:(NSMenuItem *)sender {
    NSInteger idx = sender.tag;
    NSMutableArray *customSites = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] arrayForKey:@"CustomSites"] ?: @[]];
    if (idx < 0 || idx >= customSites.count) return;
    NSDictionary *site = customSites[idx];
    NSString *name = site[@"name"] ?: @"未命名";
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = [NSString stringWithFormat:@"确定要删除站点『%@』吗？", name];
    [alert addButtonWithTitle:@"确定"];
    [alert addButtonWithTitle:@"取消"];
    if ([alert runModal] == NSAlertFirstButtonReturn) {
        [customSites removeObjectAtIndex:idx];
        [[NSUserDefaults standardUserDefaults] setObject:customSites forKey:@"CustomSites"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self rebuildCustomSiteMenu];
    }
}

// 新增：编辑自定义站点逻辑
- (void)editCustomSite:(NSMenuItem *)sender {
    NSInteger idx = sender.tag;
    NSMutableArray *customSites = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] arrayForKey:@"CustomSites"] ?: @[]];
    if (idx < 0 || idx >= customSites.count) return;
    NSDictionary *site = customSites[idx];
    NSString *oldName = site[@"name"] ?: @"";
    NSString *oldUrl = site[@"url"] ?: @"";
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"编辑自定义站点";
    alert.informativeText = @"请修改站点名称和网址";
    NSTextField *nameField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 30, 240, 24)];
    nameField.placeholderString = @"站点名称";
    nameField.stringValue = oldName;
    NSTextField *urlField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 240, 24)];
    urlField.placeholderString = @"站点网址";
    urlField.stringValue = oldUrl;
    NSView *accessory = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 240, 54)];
    [accessory addSubview:nameField];
    [accessory addSubview:urlField];
    alert.accessoryView = accessory;
    [alert addButtonWithTitle:@"保存"];
    [alert addButtonWithTitle:@"取消"];
    NSModalResponse resp = [alert runModal];
    if (resp == NSAlertFirstButtonReturn) {
        NSString *name = [nameField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSString *url = [urlField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (name.length == 0 || url.length == 0) {
            NSAlert *warn = [[NSAlert alloc] init];
            warn.messageText = @"名称和网址不能为空";
            [warn runModal];
            return;
        }
        if (![url hasPrefix:@"http://"] && ![url hasPrefix:@"https://"]) {
            NSAlert *warn = [[NSAlert alloc] init];
            warn.messageText = @"网址必须以 http:// 或 https:// 开头";
            [warn runModal];
            return;
        }
        customSites[idx] = @{ @"name": name, @"url": url };
        [[NSUserDefaults standardUserDefaults] setObject:customSites forKey:@"CustomSites"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self rebuildCustomSiteMenu];
    }
}

@end
