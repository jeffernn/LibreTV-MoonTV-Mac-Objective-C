//Jeffern影视平台 ©Jeffern 2025/7/15


#import "AppDelegate.h"
#import "NSURLProtocol+WKWebVIew.h"
#import "HLHomeWindowController.h"
#import "HLHomeViewController.h"
#import "HLWebsiteMonitor.h"
#import <WebKit/WebKit.h>
#import <objc/runtime.h>

// 1. 顶部声明自定义进度窗
@interface UpdateProgressView : NSView
@property (nonatomic, strong) NSTextField *titleLabel;
@property (nonatomic, strong) NSProgressIndicator *indicator;
@end
@implementation UpdateProgressView
- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.titleLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(0, frame.size.height-50, frame.size.width, 32)];
        self.titleLabel.stringValue = @"正在更新";
        self.titleLabel.alignment = NSTextAlignmentCenter;
        self.titleLabel.editable = NO;
        self.titleLabel.bezeled = NO;
        self.titleLabel.drawsBackground = NO;
        self.titleLabel.selectable = NO;
        self.titleLabel.font = [NSFont boldSystemFontOfSize:22];
        self.titleLabel.textColor = [NSColor whiteColor]; // 调为白色
        [self addSubview:self.titleLabel];

        // 进度条高度调大，样式更明显
        self.indicator = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(30, 20, frame.size.width-60, 28)];
        self.indicator.indeterminate = NO;
        self.indicator.minValue = 0;
        self.indicator.maxValue = 100;
        self.indicator.doubleValue = 0;
        [self.indicator setControlSize:NSControlSizeRegular];
        [self.indicator setStyle:NSProgressIndicatorBarStyle];
        self.indicator.controlTint = NSDefaultControlTint;
        self.indicator.usesThreadedAnimation = NO;
        [self.indicator setBezeled:YES];
        [self.indicator setHidden:NO];
        [self addSubview:self.indicator];

        self.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
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
        self.backgroundColor = [NSColor blackColor]; // 改为黑色
        self.hasShadow = YES;
        self.movableByWindowBackground = YES;
        self.contentView.wantsLayer = YES;
        self.contentView.layer.cornerRadius = 16;
        self.contentView.layer.backgroundColor = [[NSColor blackColor] CGColor]; // 改为黑色
        self.progressView = [[UpdateProgressView alloc] initWithFrame:self.contentView.bounds];
        self.progressView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable; // 修复：自适应contentView
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

// 修改：带多级代理重试机制的版本检查
- (void)checkForUpdatesWithURL:(NSString *)urlString isRetry:(BOOL)isRetry isManualCheck:(BOOL)isManualCheck {
    [self checkForUpdatesWithURL:urlString retryLevel:0 isManualCheck:isManualCheck];
}

- (void)checkForUpdatesWithURL:(NSString *)urlString retryLevel:(NSInteger)retryLevel isManualCheck:(BOOL)isManualCheck {
    NSString *currentVersion = @"1.4.3";
    NSURL *url = [NSURL URLWithString:urlString];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.timeoutInterval = 6.0; // 6秒超时

    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            // 如果是超时错误，尝试使用代理
            if (error.code == NSURLErrorTimedOut) {
                NSString *originalURL = urlString;
                // 提取原始GitHub URL（去除代理前缀）
                if ([urlString hasPrefix:@"https://gh-proxy.com/"]) {
                    originalURL = [urlString substringFromIndex:[@"https://gh-proxy.com/" length]];
                } else if ([urlString hasPrefix:@"https://ghfast.top/"]) {
                    originalURL = [urlString substringFromIndex:[@"https://ghfast.top/" length]];
                }

                NSString *nextProxyURL = nil;
                if (retryLevel == 0) {
                    // 第一次重试：使用 gh-proxy.com
                    nextProxyURL = [NSString stringWithFormat:@"https://gh-proxy.com/%@", originalURL];
                } else if (retryLevel == 1) {
                    // 第二次重试：使用 ghfast.top
                    nextProxyURL = [NSString stringWithFormat:@"https://ghfast.top/%@", originalURL];
                }

                if (nextProxyURL && retryLevel < 2) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self checkForUpdatesWithURL:nextProxyURL retryLevel:retryLevel + 1 isManualCheck:isManualCheck];
                    });
                    return;
                }
            }
            return; // 其他错误或所有代理都失败，直接返回
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
    [self startDownloadWithURL:url retryLevel:0];
}

// 新增：带多级代理重试机制的下载方法
- (void)startDownloadWithURL:(NSString *)urlString retryLevel:(NSInteger)retryLevel {
    // 首次下载时显示进度窗口
    if (retryLevel == 0) {
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
        if (downloadTask.state == NSURLSessionTaskStateRunning && retryLevel < 2) {
            // 6秒后仍在运行，取消当前任务并切换到下一个代理
            [downloadTask cancel];

            NSString *originalURL = urlString;
            // 提取原始GitHub URL（去除代理前缀）
            if ([urlString hasPrefix:@"https://gh-proxy.com/"]) {
                originalURL = [urlString substringFromIndex:[@"https://gh-proxy.com/" length]];
            } else if ([urlString hasPrefix:@"https://ghfast.top/"]) {
                originalURL = [urlString substringFromIndex:[@"https://ghfast.top/" length]];
            }

            NSString *nextProxyURL = nil;
            if (retryLevel == 0) {
                // 第一次重试：使用 gh-proxy.com
                nextProxyURL = [NSString stringWithFormat:@"https://gh-proxy.com/%@", originalURL];
            } else if (retryLevel == 1) {
                // 第二次重试：使用 ghfast.top
                nextProxyURL = [NSString stringWithFormat:@"https://ghfast.top/%@", originalURL];
            }

            if (nextProxyURL) {
                [self startDownloadWithURL:nextProxyURL retryLevel:retryLevel + 1];
            }
        }
    });
}

// 下载进度回调
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    if (totalBytesExpectedToWrite > 0) {
        double percent = (double)totalBytesWritten / (double)totalBytesExpectedToWrite * 100.0;
        dispatch_async(dispatch_get_main_queue(), ^{
            self.progressPanel.progressView.indicator.doubleValue = percent;
        });
    }
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
        NSString *currentURL = task.originalRequest.URL.absoluteString;
        NSString *originalURL = self.currentDownloadURL;

        // 提取原始GitHub URL（去除代理前缀）
        if ([currentURL hasPrefix:@"https://gh-proxy.com/"]) {
            originalURL = [currentURL substringFromIndex:[@"https://gh-proxy.com/" length]];
        } else if ([currentURL hasPrefix:@"https://ghfast.top/"]) {
            originalURL = [currentURL substringFromIndex:[@"https://ghfast.top/" length]];
        }

        NSString *nextProxyURL = nil;
        if ([currentURL hasPrefix:@"https://github.com/"]) {
            // 原始链接超时，切换到第一个代理
            nextProxyURL = [NSString stringWithFormat:@"https://gh-proxy.com/%@", originalURL];
        } else if ([currentURL hasPrefix:@"https://gh-proxy.com/"]) {
            // 第一个代理超时，切换到第二个代理
            nextProxyURL = [NSString stringWithFormat:@"https://ghfast.top/%@", originalURL];
        }

        if (nextProxyURL) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSInteger retryLevel = 1;
                if ([currentURL hasPrefix:@"https://gh-proxy.com/"]) {
                    retryLevel = 2;
                }
                [self startDownloadWithURL:nextProxyURL retryLevel:retryLevel];
            });
            return;
        }
    }

    // 其他错误或所有代理都失败，显示错误弹窗
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
        alert.messageText = [NSString stringWithFormat:@"更新成功", justUpdated];
        [alert runModal];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"JustUpdatedVersion"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    [self checkForUpdates];
    // Insert code here to initialize your application
    [NSURLProtocol wk_registerScheme:@"http"];
    [NSURLProtocol wk_registerScheme:@"https"];
    self.windonwArray = [NSMutableArray array];

    // 初始化优选影视监控器
    HLWebsiteMonitor *monitor = [HLWebsiteMonitor sharedInstance];

    // 处理启动计数和缓存清理
    [self handleAppLaunchCountAndCacheCleanup];

    // 监听自定义站点变化通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleCustomSitesDidChange:)
                                                 name:@"CustomSitesDidChangeNotification"
                                               object:nil];

    // 延迟同步站点并进行一次检查，确保应用完全加载
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // 自动同步所有站点
        [monitor syncAllSites];

        // 启动时进行一次检查
        if (monitor.getAllWebsites.count > 0) {
            [monitor checkAllWebsitesNow];
            NSLog(@"应用启动时检查 %ld 个网站状态", monitor.getAllWebsites.count);

            // 监听检查完成通知
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(handleWebsiteCheckCompleted:)
                                                         name:@"WebsiteCheckCompleted"
                                                       object:monitor];
        }
    });

    NSMenu *mainMenu = [NSApp mainMenu];

    // 1. 创建并添加“内置影视”为一级主菜单
    NSMenu *builtInMenu = [[NSMenu alloc] initWithTitle:@"内置影视"];
    // 二级菜单“✨”跳转到自定义网址
    NSMenuItem *starItem = [[NSMenuItem alloc] initWithTitle:@"✨✨✨" action:@selector(changeUserCustomSiteURL:) keyEquivalent:@""];
    [starItem setTarget:self];

    // 为✨✨✨添加二级菜单
    NSMenu *starSubMenu = [[NSMenu alloc] initWithTitle:@"✨✨✨设置"];
    NSMenuItem *repackageItem = [[NSMenuItem alloc] initWithTitle:@"重新封装" action:@selector(showRepackageDialog:) keyEquivalent:@""];
    repackageItem.target = self;
    [starSubMenu addItem:repackageItem];
    [starItem setSubmenu:starSubMenu];

    [builtInMenu addItem:starItem];
    NSArray *siteTitles = @[@"Emby",@"可可影视", @"奈飞工厂", @"omofun动漫",@"北觅影视",@"gimy",@"蛋蛋兔",@"人人影视",@"红狐狸影视",@"低端影视",@"多瑙影视",@"CCTV",@"直播",@"抖音短剧"];
    NSArray *siteUrls = @[@"https://dongman.theluyuan.com/",@"https://www.keke1.app/",@"https://yanetflix.com/", @"https://www.omofun2.xyz/",@"https://v.luttt.com/",@"https://www.jagcys.com/",@"https://www.dandantu.cc/",@"https://kuaizi.cc/",@"https://honghuli.com/",@"https://ddys.pro/",@"https://www.duonaovod.com/",@"https://tv.cctv.com/live/",@"https://live.wxhbts.com/",@"https://www.jinlidj.com/"];
    for (NSInteger i = 0; i < siteTitles.count; i++) {
        NSMenuItem *siteItem = [[NSMenuItem alloc] initWithTitle:siteTitles[i] action:@selector(openBuiltInSite:) keyEquivalent:@""];
        siteItem.target = self;
        siteItem.representedObject = siteUrls[i];
        // Emby项添加二级菜单
        if ([siteTitles[i] isEqualToString:@"Emby"]) {
            NSMenu *embySubMenu = [[NSMenu alloc] initWithTitle:@"Emby设置"];
            NSMenuItem *setEmbyItem = [[NSMenuItem alloc] initWithTitle:@"自定义Emby" action:@selector(showSetEmbyInfoDialog:) keyEquivalent:@""];
            setEmbyItem.target = self;
            [embySubMenu addItem:setEmbyItem];
            // 新增：恢复默认按钮
            NSMenuItem *resetEmbyItem = [[NSMenuItem alloc] initWithTitle:@"恢复默认" action:@selector(resetEmbyToDefault:) keyEquivalent:@""];
            resetEmbyItem.target = self;
            [embySubMenu addItem:resetEmbyItem];
            [siteItem setSubmenu:embySubMenu];
        }
        [builtInMenu addItem:siteItem];
        // 在Emby下方插入分隔线和复选框
        if ([siteTitles[i] isEqualToString:@"抖音短剧"]) {
            NSMenuItem *separator = [NSMenuItem separatorItem];
            [builtInMenu addItem:separator];
            NSMenuItem *autoOpenLastSiteItem = [[NSMenuItem alloc] initWithTitle:@"记录当前站点" action:@selector(toggleAutoOpenLastSite:) keyEquivalent:@""];
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
    NSMenuItem *checkUpdateItem = [[NSMenuItem alloc] initWithTitle:@"检测更新" action:@selector(checkForUpdates:) keyEquivalent:@""];
    [checkUpdateItem setTarget:self];
    [featuresMenu addItem:checkUpdateItem];
    NSMenuItem *clearCacheItem = [[NSMenuItem alloc] initWithTitle:@"清除缓存" action:@selector(clearAppCache:) keyEquivalent:@""];
    [clearCacheItem setTarget:self];
    [featuresMenu addItem:clearCacheItem];

    // 添加优选网站菜单项
    [featuresMenu addItem:[NSMenuItem separatorItem]];
    NSMenuItem *historyItem = [[NSMenuItem alloc] initWithTitle:@"观影记录" action:@selector(showHistory:) keyEquivalent:@""];
    [historyItem setTarget:self];
    [featuresMenu addItem:historyItem];
    NSMenuItem *monitorItem = [[NSMenuItem alloc] initWithTitle:@"优选网站" action:@selector(showWebsiteMonitor:) keyEquivalent:@""];
    [monitorItem setTarget:self];
    [featuresMenu addItem:monitorItem];
    NSMenuItem *featuresMenuItem = [[NSMenuItem alloc] initWithTitle:@"功能" action:nil keyEquivalent:@""];
    [featuresMenuItem setSubmenu:featuresMenu];
    [mainMenu insertItem:featuresMenuItem atIndex:2];

    // 3. 创建并添加“福利”为一级主菜单
    NSMenu *fuliMenu = [[NSMenu alloc] initWithTitle:@"福利列表"];
    NSMenuItem *shadowrocketItem = [[NSMenuItem alloc] initWithTitle:@"ShadoWrocket" action:@selector(openFuliLink:) keyEquivalent:@""];
    shadowrocketItem.target = self;
    shadowrocketItem.representedObject = @"https://s.jiesuo.one/s/e645da4602ac4891a0533a7c1163f5c9";
    [fuliMenu addItem:shadowrocketItem];
        
    NSMenuItem *tunnelItem = [[NSMenuItem alloc] initWithTitle:@"Base64 Tunnel" action:@selector(openFuliLink:) keyEquivalent:@""];
    tunnelItem.target = self;
    tunnelItem.representedObject = @"https://upld.zone.id/uploads/q9iq9e5iq/jsnzkpg.txt";
    [fuliMenu addItem:tunnelItem];
    
    NSMenuItem *clash1tunnelItem = [[NSMenuItem alloc] initWithTitle:@"Clash Tunnel（直链）" action:@selector(openFuliLink:) keyEquivalent:@""];
    clash1tunnelItem.target = self;
    clash1tunnelItem.representedObject = @"https://upld.zone.id/uploads/q9iq9e5iq/clash.txt";
    [fuliMenu addItem:clash1tunnelItem];
    
    NSMenuItem *clash2tunnelItem = [[NSMenuItem alloc] initWithTitle:@"Clash Tunnel（科学）" action:@selector(openFuliLink:) keyEquivalent:@""];
    clash2tunnelItem.target = self;
    clash2tunnelItem.representedObject = @"https://raw.githubusercontent.com/Jsnzkpg/Jsnzkpg/Jsnzkpg/Jsnzkpg";
    [fuliMenu addItem:clash2tunnelItem];
    
    NSMenuItem *singboxtunnelItem = [[NSMenuItem alloc] initWithTitle:@"Clash Tunnel（科学1）" action:@selector(openFuliLink:) keyEquivalent:@""];
    singboxtunnelItem.target = self;
    singboxtunnelItem.representedObject = @"https://clash2sfa.xmdhs.com/sub?sub=https%3A%2F%2Fupld.zone.id%2Fuploads%2Fq9iq9e5iq%2Fclash.txt";
    [fuliMenu addItem:singboxtunnelItem];
    
    NSMenuItem *embyItem = [[NSMenuItem alloc] initWithTitle:@"Emby premium破解(Android TV端)" action:@selector(openFuliLink:) keyEquivalent:@""];
    embyItem.target = self;
    embyItem.representedObject = @"https://github.com/jeffernn/JeffernTV-for-Emby-crack/tree/main";
    [fuliMenu addItem:embyItem];

    NSMenuItem *telegramBotItem = [[NSMenuItem alloc] initWithTitle:@"Telegram自动签到" action:@selector(openFuliLink:) keyEquivalent:@""];
    telegramBotItem.target = self;
    telegramBotItem.representedObject = @"https://github.com/jeffernn/Telegram-bot-auto-checkin";
    [fuliMenu addItem:telegramBotItem];

    NSMenuItem *airportItem = [[NSMenuItem alloc] initWithTitle:@"机场自动签到脚本" action:@selector(openFuliLink:) keyEquivalent:@""];
    airportItem.target = self;
    airportItem.representedObject = @"https://github.com/jeffernn/airport-auto-api-checkin";
    [fuliMenu addItem:airportItem];
    
    NSMenuItem *fuliMenuItem = [[NSMenuItem alloc] initWithTitle:@"福利" action:nil keyEquivalent:@""];
    [fuliMenuItem setSubmenu:fuliMenu];
    [mainMenu insertItem:fuliMenuItem atIndex:3];


    // 4. 创建并添加“关于”为一级主菜单
    NSMenu *aboutMenu = [[NSMenu alloc] initWithTitle:@"关于"];
    NSMenuItem *telegramGroupItem = [[NSMenuItem alloc] initWithTitle:@"电报群聊" action:@selector(openTelegramGroup:) keyEquivalent:@""];
    telegramGroupItem.target = self;
    [aboutMenu addItem:telegramGroupItem];
    NSMenuItem *projectWebsiteItem = [[NSMenuItem alloc] initWithTitle:@"项目地址" action:@selector(openProjectWebsite:) keyEquivalent:@""];
    [projectWebsiteItem setTarget:self];
    [aboutMenu addItem:projectWebsiteItem];
    NSMenuItem *aboutAuthorItem = [[NSMenuItem alloc] initWithTitle:@"关于作者" action:@selector(openAuthorGitHub:) keyEquivalent:@""];
    [aboutAuthorItem setTarget:self];
    [aboutMenu addItem:aboutAuthorItem];
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
    NSMenuItem *autoOpenLastSiteItem2 = [[NSMenuItem alloc] initWithTitle:@"记录当前站点" action:@selector(toggleAutoOpenLastSite:) keyEquivalent:@""];
    autoOpenLastSiteItem2.target = self;
    NSNumber *autoOpenObj2 = [[NSUserDefaults standardUserDefaults] objectForKey:@"AutoOpenLastSite"];
    BOOL checked2 = autoOpenObj2 ? [autoOpenObj2 boolValue] : NO;
    autoOpenLastSiteItem2.state = checked2 ? NSControlStateValueOn : NSControlStateValueOff;
    [customSiteMenu addItem:autoOpenLastSiteItem2];
    NSMenuItem *customSiteMenuItem = [[NSMenuItem alloc] initWithTitle:@"自定义站" action:nil keyEquivalent:@""];
    [customSiteMenuItem setSubmenu:customSiteMenu];
    [mainMenu insertItem:customSiteMenuItem atIndex:2];

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

// 新增：关于作者方法实现
- (void)openAuthorGitHub:(id)sender {
    NSString *url = @"https://github.com/jeffernn";
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ChangeUserCustomSiteURLNotification" object:url];
}

// 新增：电报交流群方法实现
- (void)openTelegramGroup:(id)sender {
    NSString *url = @"https://t.me/+vIMxDGDIWiczMTE1";
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ChangeUserCustomSiteURLNotification" object:url];
}

// 新增：生成本地静态HTML文件并展示观影记录
- (NSString *)generateHistoryHTML {
    // 读取本地观影记录
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
     "<title>观影记录</title>"
     "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">"
     "<link href=\"https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css\" rel=\"stylesheet\">"
     "<link href=\"https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css\" rel=\"stylesheet\">"
     "<style>"
     "body{min-height:100vh;font-family:'PingFang SC','Microsoft YaHei',Arial,sans-serif;"];
    [html appendFormat:@"background:linear-gradient(rgba(0,0,0,0.7),rgba(0,0,0,0.7)),url('%@') center/cover;", bgUrl];
    [html appendString:@"margin:0;padding:20px;color:#fff;}"];
    [html appendString:@".history-container{max-width:1500px;margin:48px auto 0 auto;padding:32px 24px 24px 24px;background:rgba(255,255,255,0.1);border-radius:24px;backdrop-filter:blur(10px);box-shadow:0 8px 32px rgba(0,0,0,0.3);}"];
    [html appendString:@".history-title{font-size:2rem;font-weight:700;text-align:center;margin-bottom:24px;color:#fff;text-shadow:2px 2px 4px rgba(0,0,0,0.5);}"];
    [html appendString:@".history-status{text-align:center;margin-bottom:20px;font-size:1.1rem;color:#ddd;}"];
    [html appendString:@".clear-btn{margin:0 10px;padding:10px 20px;border:none;border-radius:8px;font-weight:600;cursor:pointer;transition:all 0.3s;background:#f87171;color:#fff;}"];
    [html appendString:@".clear-btn:hover{background:#dc2626;}"];
    [html appendString:@".history-list{padding:0;list-style:none;min-height:120px;}"];
    [html appendString:@".history-item{background:rgba(255,255,255,0.05);border-radius:8px;margin-bottom:12px;padding:12px;transition:background 0.3s;border-bottom:1px solid rgba(255,255,255,0.1);}"];
    [html appendString:@".history-item:hover{background:rgba(255,255,255,0.1);}"];
    [html appendString:@".site-title{font-size:1.18rem;font-weight:600;color:#fff;text-decoration:none;display:block;line-height:1.5;}"];
    [html appendString:@".site-title:hover{color:#4ade80;text-decoration:underline;}"];
    [html appendString:@".site-time{color:#ddd;font-size:0.98rem;margin-top:6px;display:block;}"];
    [html appendString:@".empty-tip{color:#888;text-align:center;font-size:1.2rem;margin:40px 0;}"];
    [html appendString:@".pagination{text-align:center;margin-top:20px;display:flex;justify-content:center;align-items:center;gap:18px;}"];
    [html appendString:@".pagination button{margin:0 10px;padding:10px 20px;border:none;border-radius:8px;font-weight:600;cursor:pointer;transition:all 0.3s;background:#3b82f6;color:#fff;}"];
    [html appendString:@".pagination button:hover{background:#2563eb;}"];
    [html appendString:@".pagination button:disabled{background:#6b7280;color:#9ca3af;cursor:not-allowed;}"];
    [html appendString:@".history-actions{text-align:center;margin-bottom:20px;}"];
    [html appendString:@"</style></head><body>"];
    [html appendString:@"<div class=\"history-container\">"];
    [html appendString:@"<div class=\"history-title\"><i class=\"fas fa-history me-2\"></i>观影记录</div>"];

    // 添加状态信息（类似优选网站）
    [html appendString:@"<div class=\"history-status\">记录状态: 正常 | 总记录数: <span id=\"totalCount\">0</span></div>"];

    // 清除记录按钮放在上方
    [html appendString:@"<div class=\"history-actions\">"];
    [html appendString:@"<button class=\"clear-btn\" onclick=\"clearHistoryAction()\"><i class=\"fas fa-trash me-1\"></i>清除记录</button>"];
    [html appendString:@"</div>"];

    [html appendString:@"<ul class=\"history-list\"></ul>"];
    [html appendString:@"<div class=\"empty-tip\" style=\"display:none;\">暂无观影记录</div>"];
    [html appendString:@"<div class=\"pagination\"><button id=\"prevPage\">上一页</button><span id=\"pageInfo\"></span><button id=\"nextPage\">下一页</button></div>"];
    // 插入分页JS
    NSError *jsonError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:history options:0 error:&jsonError];
    NSString *historyJson = @"[]";
    if (jsonData && !jsonError) {
        historyJson = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    [html appendString:@"<script>\n"];
    [html appendFormat:@"var allHistoryData = %@;\n", historyJson];
    [html appendString:@"// 过滤出观影记录（非网站）\n"];
    [html appendString:@"var historyData = allHistoryData.filter(function(item) {\n"];
    [html appendString:@"  return !item.isWebsite;\n"];
    [html appendString:@"});\n"];
    [html appendString:@"var pageSize = 6;\nvar currentPage = 1;\nvar totalPages = Math.ceil(historyData.length / pageSize);\n"];
    [html appendString:@"// 更新总记录数显示\n"];
    [html appendString:@"document.getElementById('totalCount').textContent = historyData.length;\n"];
    [html appendString:@"function renderPage(page) {\n"];
    [html appendString:@"  var list = document.querySelector('.history-list');\n"];
    [html appendString:@"  list.innerHTML = '';\n"];
    [html appendString:@"  var start = (page-1)*pageSize;\n"];
    [html appendString:@"  var end = Math.min(start+pageSize, historyData.length);\n"];
    [html appendString:@"  // 计算当前页面之前的网站记录数量\n"];
    [html appendString:@"  var websiteRecordCount = 0;\n"];
    [html appendString:@"  for (var j=0; j<start; j++) {\n"];
    [html appendString:@"    if (historyData[j].isWebsite) websiteRecordCount++;\n"];
    [html appendString:@"  }\n"];
    [html appendString:@"  for (var i=start; i<end; i++) {\n"];
    [html appendString:@"    var item = historyData[i];\n"];
    [html appendString:@"    var li = document.createElement('li');\n"];
    [html appendString:@"    li.className = 'history-item';\n"];
    [html appendString:@"    var a = document.createElement('a');\n"];
    [html appendString:@"    a.className = 'site-title';\n"];
    [html appendString:@"    a.href = item.url || '';\n"];
    [html appendString:@"    a.target = '_blank';\n"];
    [html appendString:@"    // 判断是否为网站记录，如果是则显示为'观影记录 N'\n"];
    [html appendString:@"    if (item.isWebsite) {\n"];
    [html appendString:@"      websiteRecordCount++;\n"];
    [html appendString:@"      a.textContent = '观影记录 ' + websiteRecordCount;\n"];
    [html appendString:@"    } else {\n"];
    [html appendString:@"      a.textContent = item.name || item.url || '';\n"];
    [html appendString:@"    }\n"];
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
    [html appendString:@"function clearHistoryAction() {\n"];
    [html appendString:@"  try {\n"];
    [html appendString:@"    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.clearHistory) {\n"];
    [html appendString:@"      window.webkit.messageHandlers.clearHistory.postMessage(null);\n"];
    [html appendString:@"    } else {\n"];
    [html appendString:@"      console.log('clearHistory messageHandler not available');\n"];
    [html appendString:@"      alert('清除记录功能暂时不可用');\n"];
    [html appendString:@"    }\n"];
    [html appendString:@"  } catch (e) {\n"];
    [html appendString:@"    console.error('Error calling clearHistory:', e);\n"];
    [html appendString:@"    alert('清除记录时发生错误: ' + e.message);\n"];
    [html appendString:@"  }\n"];
    [html appendString:@"}\n"];
    [html appendString:@"renderPage(currentPage);\n"];
    [html appendString:@"</script></body></html>"];
    // 写入临时文件
    NSString *renderedPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"history_rendered.html"];
    [html writeToFile:renderedPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    return renderedPath;
}

// 新增：生成优选影视HTML文件
- (NSString *)generateMonitorHTML {
    HLWebsiteMonitor *monitor = [HLWebsiteMonitor sharedInstance];
    NSArray<HLMonitoredWebsite *> *websites = [monitor getAllWebsites];

    // 使用本地图片作为背景
    NSString *imgPath = [[NSBundle mainBundle] pathForResource:@"1" ofType:@"JPG" inDirectory:@"img"];
    NSString *bgUrl = [NSString stringWithFormat:@"file://%@", imgPath];

    NSMutableString *html = [NSMutableString string];
    [html appendString:
     @"<!DOCTYPE html><html lang=\"zh-CN\"><head><meta charset=\"UTF-8\">"
     "<title>优选网站</title>"
     "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">"
     "<link href=\"https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css\" rel=\"stylesheet\">"
     "<link href=\"https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css\" rel=\"stylesheet\">"
     "<style>"
     "body{min-height:100vh;font-family:'PingFang SC','Microsoft YaHei',Arial,sans-serif;"];

    [html appendFormat:@"background:linear-gradient(rgba(0,0,0,0.7),rgba(0,0,0,0.7)),url('%@') center/cover;", bgUrl];
    [html appendString:@"margin:0;padding:20px;color:#fff;}"];
    [html appendString:@".monitor-container{max-width:1000px;margin:0 auto;background:rgba(255,255,255,0.1);border-radius:16px;padding:24px;backdrop-filter:blur(10px);box-shadow:0 8px 32px rgba(0,0,0,0.3);}"];
    [html appendString:@".monitor-title{font-size:2rem;font-weight:700;text-align:center;margin-bottom:24px;color:#fff;text-shadow:2px 2px 4px rgba(0,0,0,0.5);}"];
    [html appendString:@".monitor-status{text-align:center;margin-bottom:20px;font-size:1.1rem;color:#ddd;}"];
    [html appendString:@".monitor-table{width:100%;border-collapse:collapse;margin-bottom:20px;background:rgba(255,255,255,0.05);border-radius:8px;overflow:hidden;}"];
    [html appendString:@".monitor-table th{background:rgba(0,0,0,0.3);color:#fff;padding:12px;text-align:left;font-weight:600;border-bottom:2px solid rgba(255,255,255,0.1);}"];
    [html appendString:@".monitor-table td{padding:12px;border-bottom:1px solid rgba(255,255,255,0.1);color:#fff;}"];
    [html appendString:@".monitor-table tr:hover{background:rgba(255,255,255,0.1);}"];
    [html appendString:@".status-online{color:#4ade80;}"];
    [html appendString:@".status-offline{color:#f87171;}"];
    [html appendString:@".status-error{color:#fbbf24;}"];
    [html appendString:@".status-unknown{color:#9ca3af;}"];
    [html appendString:@".monitor-actions{text-align:center;margin-top:20px;}"];
    [html appendString:@".btn-monitor{margin:0 10px;padding:10px 20px;border:none;border-radius:8px;font-weight:600;cursor:pointer;transition:all 0.3s;}"];
    [html appendString:@".btn-primary{background:#3b82f6;color:#fff;}"];
    [html appendString:@".btn-primary:hover{background:#2563eb;}"];
    [html appendString:@".btn-success{background:#10b981;color:#fff;}"];
    [html appendString:@".btn-success:hover{background:#059669;}"];
    [html appendString:@".btn-secondary{background:#6b7280;color:#fff;}"];
    [html appendString:@".btn-secondary:hover{background:#4b5563;}"];
    [html appendString:@".empty-tip{color:#888;text-align:center;font-size:1.2rem;margin:40px 0;}"];
    [html appendString:@"</style></head><body>"];

    [html appendString:@"<div class=\"monitor-container\">"];
    [html appendString:@"<div class=\"monitor-title\"><i class=\"fas fa-satellite-dish me-2\"></i>优选网站</div>"];

    // 状态信息
    [html appendFormat:@"<div class=\"monitor-status\">监控状态: %@ | 站点数量: %ld</div>",
     monitor.isChecking ? @"检查中..." : @"空闲", websites.count];

    // 立即检查按钮（移动到监控状态行之下）
    [html appendString:@"<div class=\"monitor-actions\" style=\"margin-bottom:20px; margin-top:15px;\">"];
    [html appendString:@"<button class=\"btn-monitor btn-primary\" onclick=\"checkWebsites()\"><i class=\"fas fa-sync me-1\"></i>立即检查</button>"];
    [html appendString:@"</div>"];

    if (websites.count == 0) {
        [html appendString:@"<div class=\"empty-tip\">暂无监控数据<br>点击\"立即检查\"同步站点</div>"];
    } else {
        // 按响应时间排序，在线的站点优先
        NSArray *sortedWebsites = [websites sortedArrayUsingComparator:^NSComparisonResult(HLMonitoredWebsite *obj1, HLMonitoredWebsite *obj2) {
            if (obj1.status == HLWebsiteStatusOnline && obj2.status != HLWebsiteStatusOnline) {
                return NSOrderedAscending;
            }
            if (obj1.status != HLWebsiteStatusOnline && obj2.status == HLWebsiteStatusOnline) {
                return NSOrderedDescending;
            }
            if (obj1.status == HLWebsiteStatusOnline && obj2.status == HLWebsiteStatusOnline) {
                return [@(obj1.responseTime) compare:@(obj2.responseTime)];
            }
            return [obj1.name compare:obj2.name];
        }];

        [html appendString:@"<table class=\"monitor-table\">"];
        [html appendString:@"<thead><tr><th>站点名称</th><th>状态</th><th>响应时间</th><th>最后检查</th></tr></thead>"];
        [html appendString:@"<tbody>"];

        for (HLMonitoredWebsite *website in sortedWebsites) {
            NSString *statusText = @"未知";
            NSString *statusEmoji = @"❓";
            NSString *statusClass = @"status-unknown";

            switch (website.status) {
                case HLWebsiteStatusOnline:
                    statusText = @"在线";
                    statusEmoji = @"🟢";
                    statusClass = @"status-online";
                    break;
                case HLWebsiteStatusOffline:
                    statusText = @"离线";
                    statusEmoji = @"🔴";
                    statusClass = @"status-offline";
                    break;
                case HLWebsiteStatusError:
                    statusText = @"错误";
                    statusEmoji = @"🟡";
                    statusClass = @"status-error";
                    break;
                default:
                    statusText = @"未知";
                    statusEmoji = @"❓";
                    statusClass = @"status-unknown";
                    break;
            }

            NSString *responseText = @"-";
            if (website.status == HLWebsiteStatusOnline && website.responseTime > 0) {
                responseText = [NSString stringWithFormat:@"%.0fms", website.responseTime];
            }

            NSString *timeText = @"-";
            if (website.lastCheckTime) {
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                formatter.dateFormat = @"MM-dd HH:mm";
                timeText = [formatter stringFromDate:website.lastCheckTime];
            }

            [html appendFormat:@"<tr><td>%@</td><td class=\"%@\">%@ %@</td><td>%@</td><td>%@</td></tr>",
             website.name, statusClass, statusEmoji, statusText, responseText, timeText];
        }

        [html appendString:@"</tbody></table>"];
    }

    // 底部操作按钮（只保留自动打开设置）
    [html appendString:@"<div class=\"monitor-actions\">"];
    BOOL autoOpenEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"AutoOpenFastestSite"];
    NSString *autoOpenText = autoOpenEnabled ? @"✅ 勾选后下次启动自动打开最优影视站" : @"⚪ 勾选后下次启动自动打开最优影视站";
    [html appendFormat:@"<button class=\"btn-monitor btn-success\" onclick=\"toggleAutoOpen()\">%@</button>", autoOpenText];

    [html appendString:@"</div>"];
    [html appendString:@"</div>"];

    // JavaScript
    [html appendString:@"<script>"];
    [html appendString:@"function checkWebsites() {"];
    [html appendString:@"  try {"];
    [html appendString:@"    alert('开始检查网站状态...\\n\\n稍后自动刷新，请稍后再查看');"];
    [html appendString:@"    window.webkit.messageHandlers.checkWebsites.postMessage('check');"];
    [html appendString:@"  } catch(e) {"];
    [html appendString:@"    console.error('Error calling checkWebsites:', e);"];
    [html appendString:@"    alert('检查网站时发生错误: ' + e.message);"];
    [html appendString:@"  }"];
    [html appendString:@"}"];
    [html appendString:@"function toggleAutoOpen() {"];
    [html appendString:@"  try {"];
    [html appendString:@"    window.webkit.messageHandlers.toggleAutoOpen.postMessage('toggle');"];
    [html appendString:@"  } catch(e) {"];
    [html appendString:@"    console.error('Error calling toggleAutoOpen:', e);"];
    [html appendString:@"    alert('切换自动打开设置时发生错误: ' + e.message);"];
    [html appendString:@"  }"];
    [html appendString:@"}"];
    [html appendString:@"</script></body></html>"];

    // 写入临时文件
    NSString *renderedPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"monitor_rendered.html"];
    [html writeToFile:renderedPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    return renderedPath;
}

- (void)showHistory:(id)sender {
    // 在后台线程生成HTML，避免阻塞主线程
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self generateHistoryHTML];

        // 回到主线程更新UI
        dispatch_async(dispatch_get_main_queue(), ^{
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
        });
    });
}

// WKWebView JS 调用原生
// 删除原有WKScriptMessageHandler实现

- (void)clearAppCache:(id)sender {
    NSAlert *confirmationAlert = [[NSAlert alloc] init];
    confirmationAlert.messageText = @"确定要清除缓存吗？";
    confirmationAlert.informativeText = @"此操作将清除所有设置和观影记录，此操作不可恢复，请谨慎操作。";
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
        // 新增：删除观影记录缓存
        NSString *historyPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/JeffernMovie/history.json"];
        if ([fm fileExistsAtPath:historyPath]) {
            NSError *error = nil;
            [fm removeItemAtPath:historyPath error:&error];
        }
        // 新增：同步清理UI观影记录
        for (NSWindow *window in [NSApp windows]) {
            for (NSViewController *vc in window.contentViewController.childViewControllers) {
                if ([vc isKindOfClass:NSClassFromString(@"HLHomeViewController")]) {
                    [(id)vc clearHistory];
                }
            }
        }
        // 新增：清除Emby自定义设置
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"EmbyCustomURL"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"EmbyCustomUser"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"EmbyCustomPass"];
        // 新增：清除自定义站点
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"CustomSites"];
        [[NSUserDefaults standardUserDefaults] synchronize];

        // 新增：清除优选影视缓存
        HLWebsiteMonitor *monitor = [HLWebsiteMonitor sharedInstance];
        [monitor clearCache];
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
            if ([item.title containsString:@"记录当前站点"]) {
                item.state = sender.state;
            }
        }
    }
    // 自定义站
    NSInteger customIdx = [mainMenu indexOfItemWithTitle:@"自定义站"];
    if (customIdx != -1) {
        NSMenu *customMenu = [[mainMenu itemAtIndex:customIdx] submenu];
        for (NSMenuItem *item in customMenu.itemArray) {
            if ([item.title containsString:@"记录当前站点"]) {
                item.state = sender.state;
            }
        }
    }
}

// 新增：Emby设置弹窗
- (void)showSetEmbyInfoDialog:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *oldUrl = [defaults stringForKey:@"EmbyCustomURL"] ?: @"";
    NSString *oldUser = [defaults stringForKey:@"EmbyCustomUser"] ?: @"";
    NSString *oldPass = [defaults stringForKey:@"EmbyCustomPass"] ?: @"";
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"自定义Emby";
    alert.informativeText = @"请输入Emby网址、账号和密码";
    NSTextField *urlField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 54, 240, 24)];
    urlField.placeholderString = @"Emby网址";
    urlField.stringValue = oldUrl;
    NSTextField *userField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 27, 240, 24)];
    userField.placeholderString = @"账号";
    userField.stringValue = oldUser;
    NSSecureTextField *passField = [[NSSecureTextField alloc] initWithFrame:NSMakeRect(0, 0, 240, 24)];
    passField.placeholderString = @"密码";
    passField.stringValue = oldPass;
    NSView *accessory = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 240, 78)];
    [accessory addSubview:urlField];
    [accessory addSubview:userField];
    [accessory addSubview:passField];
    alert.accessoryView = accessory;
    [alert addButtonWithTitle:@"保存"];
    [alert addButtonWithTitle:@"取消"];
    NSModalResponse resp = [alert runModal];
    if (resp == NSAlertFirstButtonReturn) {
        NSString *url = [urlField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSString *user = [userField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSString *pass = [passField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (url.length == 0 || user.length == 0 || pass.length == 0) {
            NSAlert *warn = [[NSAlert alloc] init];
            warn.messageText = @"网址、账号、密码不能为空";
            [warn runModal];
            return;
        }
        [defaults setObject:url forKey:@"EmbyCustomURL"];
        [defaults setObject:user forKey:@"EmbyCustomUser"];
        [defaults setObject:pass forKey:@"EmbyCustomPass"];
        [defaults synchronize];

        // 添加成功弹窗提示
        NSAlert *successAlert = [[NSAlert alloc] init];
        successAlert.messageText = @"Emby自定义设置成功！";
        [successAlert runModal];
    }
}

// 新增：恢复默认Emby设置方法
- (void)resetEmbyToDefault:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:@"EmbyCustomURL"];
    [defaults removeObjectForKey:@"EmbyCustomUser"];
    [defaults removeObjectForKey:@"EmbyCustomPass"];
    [defaults synchronize];
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"已恢复为内置Emby";
    [alert runModal];
}

// 新增：✨✨✨重新封装弹窗
- (void)showRepackageDialog:(id)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"重新封装";
    alert.informativeText = @"请输入新的网址进行重新封装";
    NSTextField *urlField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 300, 24)];
    urlField.placeholderString = @"https://www.xxx.com";

    // 获取当前的UserCustomSiteURL作为默认值
    NSString *currentUrl = [[NSUserDefaults standardUserDefaults] stringForKey:@"UserCustomSiteURL"];
    if (currentUrl && currentUrl.length > 0) {
        urlField.stringValue = currentUrl;
    }

    alert.accessoryView = urlField;
    [alert addButtonWithTitle:@"确定"];
    [alert addButtonWithTitle:@"取消"];
    [alert.window setInitialFirstResponder:urlField];

    NSModalResponse resp = [alert runModal];
    if (resp == NSAlertFirstButtonReturn) {
        NSString *url = [urlField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (url.length == 0) {
            NSAlert *warn = [[NSAlert alloc] init];
            warn.messageText = @"网址不能为空";
            [warn runModal];
            return;
        }

        // 验证URL格式
        if (![url hasPrefix:@"http://"] && ![url hasPrefix:@"https://"]) {
            // 自动添加https://前缀
            url = [NSString stringWithFormat:@"https://%@", url];
        }

        // 清除首次封装网站的缓存
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults removeObjectForKey:@"UserCustomSiteURL"];
        [defaults synchronize];

        // 清除WebView缓存
        [[NSNotificationCenter defaultCenter] postNotificationName:@"CustomSitesDidChangeNotification" object:nil];

        // 设置新的URL并重新封装
        [defaults setObject:url forKey:@"UserCustomSiteURL"];
        [defaults synchronize];

        // 通知主界面加载新网址
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ChangeUserCustomSiteURLNotification" object:url];

        // 显示成功提示
        NSAlert *successAlert = [[NSAlert alloc] init];
        successAlert.messageText = @"重新封装成功！";
        successAlert.informativeText = @"已清除缓存并重新加载新网址";
        [successAlert runModal];
    }
}

// 修改openBuiltInSite，Emby优先用自定义设置
- (void)openBuiltInSite:(id)sender {
    NSString *title = ((NSMenuItem *)sender).title;
    NSString *url = ((NSMenuItem *)sender).representedObject;
    if ([title isEqualToString:@"Emby"]) {
        NSString *customUrl = [[NSUserDefaults standardUserDefaults] stringForKey:@"EmbyCustomURL"];
        if (customUrl.length > 0) {
            url = customUrl;
        }
    }
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
        [self openURLWithProxyFallback:url];
    }
}

// 新增：带代理回退的URL打开方法
- (void)openURLWithProxyFallback:(NSString *)url {
    [self openURLWithProxyFallback:url retryLevel:0];
}

- (void)openURLWithProxyFallback:(NSString *)url retryLevel:(NSInteger)retryLevel {
    NSString *testURL = url;

    // 根据重试级别选择URL
    if (retryLevel == 1) {
        testURL = [NSString stringWithFormat:@"https://gh-proxy.com/%@", url];
    } else if (retryLevel == 2) {
        testURL = [NSString stringWithFormat:@"https://ghfast.top/%@", url];
    }

    NSURL *urlToTest = [NSURL URLWithString:testURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:urlToTest];
    request.timeoutInterval = 6.0;

    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error && error.code == NSURLErrorTimedOut && retryLevel < 2) {
            // 超时且还有代理可用，尝试下一个代理
            dispatch_async(dispatch_get_main_queue(), ^{
                [self openURLWithProxyFallback:url retryLevel:retryLevel + 1];
            });
            return;
        }

        // 成功或所有代理都失败，打开URL
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:testURL]];
        });
    }];
    [task resume];
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
        // 通知WebView更新红色按钮JavaScript
        [[NSNotificationCenter defaultCenter] postNotificationName:@"CustomSitesDidChangeNotification" object:nil];

        // 添加成功弹窗提示
        NSAlert *successAlert = [[NSAlert alloc] init];
        successAlert.messageText = [NSString stringWithFormat:@"自定义站点『%@』添加成功！", name];
        [successAlert runModal];
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
    NSMenuItem *autoOpenLastSiteItem2 = [[NSMenuItem alloc] initWithTitle:@"记录当前站点" action:@selector(toggleAutoOpenLastSite:) keyEquivalent:@""];
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
        // 通知WebView更新红色按钮JavaScript
        [[NSNotificationCenter defaultCenter] postNotificationName:@"CustomSitesDidChangeNotification" object:nil];

        // 添加删除成功弹窗提示
        NSAlert *successAlert = [[NSAlert alloc] init];
        successAlert.messageText = [NSString stringWithFormat:@"自定义站点『%@』删除成功！", name];
        [successAlert runModal];
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
        // 通知WebView更新红色按钮JavaScript
        [[NSNotificationCenter defaultCenter] postNotificationName:@"CustomSitesDidChangeNotification" object:nil];

        // 添加成功弹窗提示
        NSAlert *successAlert = [[NSAlert alloc] init];
        successAlert.messageText = [NSString stringWithFormat:@"自定义站点『%@』编辑成功！", name];
        [successAlert runModal];
    }
}

#pragma mark - 优选影视相关方法

- (void)showWebsiteMonitor:(id)sender {
    // 在后台线程生成HTML，避免阻塞主线程
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self generateMonitorHTML];

        // 回到主线程更新UI
        dispatch_async(dispatch_get_main_queue(), ^{
            // 获取主界面控制器
            NSWindow *mainWindow = [NSApplication sharedApplication].mainWindow;
            NSViewController *vc = mainWindow.contentViewController;
            if ([vc isKindOfClass:NSClassFromString(@"HLHomeViewController")]) {
                [(id)vc showLocalMonitorHTML];
            } else if ([vc respondsToSelector:@selector(childViewControllers)]) {
                for (NSViewController *child in vc.childViewControllers) {
                    if ([child isKindOfClass:NSClassFromString(@"HLHomeViewController")]) {
                        [(id)child showLocalMonitorHTML];
                        break;
                    }
                }
            }
        });
    });
}



- (void)checkWebsiteStatus:(id)sender {
    HLWebsiteMonitor *monitor = [HLWebsiteMonitor sharedInstance];

    if (monitor.isChecking) {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"正在检查中";
        alert.informativeText = @"网站状态检查正在进行中，请稍候...";
        [alert runModal];
        return;
    }

    // 先同步所有站点
    NSInteger oldCount = monitor.getAllWebsites.count;
    [monitor syncAllSites];
    NSInteger newCount = monitor.getAllWebsites.count;

    if (newCount == 0) {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"没有可检查的网站";
        alert.informativeText = @"当前没有内置站点或自定义站点需要检查";
        [alert runModal];
        return;
    }

    // 开始检查
    [monitor checkAllWebsitesNow];

    // 显示检查开始的提示
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"开始检查网站状态";

    if (newCount > oldCount) {
        alert.informativeText = [NSString stringWithFormat:@"已同步 %ld 个新站点，正在检查 %ld 个网站的状态...", newCount - oldCount, newCount];
    } else {
        alert.informativeText = [NSString stringWithFormat:@"正在检查 %ld 个网站的状态...", newCount];
    }

    [alert addButtonWithTitle:@"确定"];

    [alert runModal];
}

- (void)toggleAutoOpenFastestSite:(id)sender {
    // 如果sender是按钮，获取状态；否则直接切换当前设置
    BOOL newState;
    if ([sender isKindOfClass:[NSButton class]]) {
        NSButton *button = (NSButton *)sender;
        newState = button.state == NSControlStateValueOn;
    } else {
        // 来自HTML页面的调用，切换当前状态
        BOOL currentState = [[NSUserDefaults standardUserDefaults] boolForKey:@"AutoOpenFastestSite"];
        newState = !currentState;
    }

    [[NSUserDefaults standardUserDefaults] setBool:newState forKey:@"AutoOpenFastestSite"];

    // 当启用优选网站时，自动取消记录当前站点
    if (newState) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"AutoOpenLastSite"];
        // 清除上次缓存
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"LastBuiltInSiteURL"];

        // 更新菜单中"记录当前站点"的状态
        NSMenu *mainMenu = [NSApp mainMenu];
        // 内置影视菜单
        NSInteger builtInIdx = [mainMenu indexOfItemWithTitle:@"内置影视"];
        if (builtInIdx != -1) {
            NSMenu *builtInMenu = [[mainMenu itemAtIndex:builtInIdx] submenu];
            for (NSMenuItem *item in builtInMenu.itemArray) {
                if ([item.title containsString:@"记录当前站点"]) {
                    item.state = NSControlStateValueOff;
                }
            }
        }
        // 自定义站菜单
        NSInteger customIdx = [mainMenu indexOfItemWithTitle:@"自定义站"];
        if (customIdx != -1) {
            NSMenu *customMenu = [[mainMenu itemAtIndex:customIdx] submenu];
            for (NSMenuItem *item in customMenu.itemArray) {
                if ([item.title containsString:@"记录当前站点"]) {
                    item.state = NSControlStateValueOff;
                }
            }
        }
    }

    [[NSUserDefaults standardUserDefaults] synchronize];

    NSAlert *alert = [[NSAlert alloc] init];
    if (newState) {
        alert.messageText = @"已启用下次启动自动打开优选网站";
        alert.informativeText = @"下次启动应用时，将自动打开响应速度最快的在线影视站点\n\n已自动取消\"记录当前站点\"功能";
    } else {
        alert.messageText = @"已禁用下次启动自动打开优选网站";
        alert.informativeText = @"下次启动应用时，将按正常流程启动";
    }
    [alert runModal];
}

- (void)openFastestSite {
    HLWebsiteMonitor *monitor = [HLWebsiteMonitor sharedInstance];
    NSArray<HLMonitoredWebsite *> *websites = [monitor getAllWebsites];

    // 找到响应时间最快的在线站点
    HLMonitoredWebsite *fastestSite = nil;
    NSTimeInterval fastestTime = MAXFLOAT;

    for (HLMonitoredWebsite *website in websites) {
        // 排除CCTV、Emby、抖音短剧和直播站点
        if ([website.name isEqualToString:@"CCTV"] ||
            [website.name isEqualToString:@"Emby"] ||
            [website.name isEqualToString:@"抖音短剧"] ||
            [website.name isEqualToString:@"直播"]) {
            continue;
        }

        if (website.status == HLWebsiteStatusOnline &&
            website.responseTime > 0 &&
            website.responseTime < fastestTime) {
            fastestTime = website.responseTime;
            fastestSite = website;
        }
    }

    if (fastestSite) {
        NSLog(@"自动打开最快站点: %@ (%.0fms)", fastestSite.name, fastestSite.responseTime);

        // 创建新窗口打开最快站点
        HLHomeWindowController *windowController = [[HLHomeWindowController alloc] initWithWindowNibName:@"HLHomeWindowController"];
        [self.windonwArray addObject:windowController];
        [windowController showWindow:nil];

        // 通过通知机制设置URL
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ChangeUserCustomSiteURLNotification"
                                                            object:fastestSite.url];

        // 显示通知
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"已自动打开最快站点";
        alert.informativeText = [NSString stringWithFormat:@"已打开 %@ (响应时间: %.0fms)", fastestSite.name, fastestSite.responseTime];

        // 3秒后自动关闭通知
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [alert.window close];
        });

        [alert runModal];
    } else {
        NSLog(@"没有找到可用的在线站点");
    }
}

- (void)handleWebsiteCheckCompleted:(NSNotification *)notification {
    // 检查是否启用了自动打开最快站点
    BOOL autoOpenEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"AutoOpenFastestSite"];

    if (autoOpenEnabled) {
        // 延迟2秒后打开最快站点，确保检查结果已保存
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self openFastestSite];
        });
    }

    // 移除监听器，避免重复触发
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"WebsiteCheckCompleted" object:nil];
}

- (void)handleCustomSitesDidChange:(NSNotification *)notification {
    // 当自定义站点发生变化时，重新同步监控站点
    HLWebsiteMonitor *monitor = [HLWebsiteMonitor sharedInstance];
    [monitor syncAllSites];
    NSLog(@"自定义站点变化，已重新同步监控站点，当前共 %ld 个站点", monitor.getAllWebsites.count);
}

#pragma mark - 启动计数和缓存管理

- (void)handleAppLaunchCountAndCacheCleanup {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger launchCount = [defaults integerForKey:@"AppLaunchCount"];
    launchCount++;
    [defaults setInteger:launchCount forKey:@"AppLaunchCount"];
    [defaults synchronize];

    NSLog(@"应用启动次数: %ld", launchCount);

    // 第三次启动时清理优选影视缓存
    if (launchCount >= 3) {
        NSLog(@"第三次启动，清理优选影视缓存以避免数据过多");
        HLWebsiteMonitor *monitor = [HLWebsiteMonitor sharedInstance];
        [monitor clearCache];

        // 重置计数器
        [defaults setInteger:0 forKey:@"AppLaunchCount"];
        [defaults synchronize];

        NSLog(@"优选影视缓存已清理，启动计数已重置");
    }
}

@end
