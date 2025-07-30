//Jeffern影视平台 ©Jeffern 2025/7/15

#import "HLHomeViewController.h"
#import "NSView+ZCAddition.h"
#import <WebKit/WebKit.h>
#import "NSString+HLAddition.h"
#import "HLCollectionViewItem.h"
#import "AppDelegate.h"
#import "HLWebsiteMonitor.h"
#import <Foundation/Foundation.h>
#import <IOKit/pwr_mgt/IOPMLib.h>

#define HISTORY_PATH [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/JeffernMovie/history.json"]
#define SESSION_STATE_KEY @"HLHomeViewController_LastSessionURL"

#pragma mark ----



#define NSCollectionViewWidth   75
#define NSCollectionViewHeight  50
#define NSTextViewTips @"[{}]"

typedef enum : NSUInteger {
    EditType_VIP,
    EditType_Platform,
} EditType;

#define ChromeUserAgent @"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36"

@interface HLHomeViewController()<WKNavigationDelegate, WKUIDelegate, NSCollectionViewDataSource, NSCollectionViewDelegate, WKScriptMessageHandler>{
    BOOL isLoading;
    BOOL isChanged;
    WKWebViewConfiguration *secondConfiguration;
    IOPMAssertionID _assertionID;
}

@property (nonatomic, strong) WKWebView         *webView;
@property (nonatomic, strong) NSMutableArray    *modelsArray;
@property (nonatomic, strong) NSMutableArray    *buttonsArray;
@property (nonatomic, strong) NSString          *currentUrl;
@property (nonatomic, strong) NSCollectionView  *collectionView;
@property (nonatomic, strong) NSScrollView      *scrollView;
@property (nonatomic, strong) NSWindow          *secondWindow; // 第二弹窗
@property (nonatomic, strong) WKWebView         *secondWebView;// 第二个弹窗的webview
@property (nonatomic, strong) NSTextField *emptyTipsLabel;
@property (nonatomic, strong) NSTextField *loadingTipsLabel; // 新增：加载提示标签

@end;

@implementation HLHomeViewController

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self disablePreventSleep];
}

- (void)viewDidLayout{
    [super viewDidLayout];
    self.webView.frame = self.view.bounds; // 让webview全屏
}

- (void)setIsFullScreen:(BOOL)isFullScreen{
    _isFullScreen = isFullScreen;
    
    [self.view setNeedsLayout:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
   
    self.view.layer.backgroundColor = NSColor.lightGrayColor.CGColor;
    [self.view setNeedsDisplay:YES];
    
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    configuration.preferences.plugInsEnabled = YES;
    configuration.preferences.javaEnabled = YES;
    if (@available(macOS 10.12, *)) {
        configuration.userInterfaceDirectionPolicy = WKUserInterfaceDirectionPolicySystem;
    }
    if (@available(macOS 10.11, *)) {
        configuration.allowsAirPlayForMediaPlayback = YES;
    }
    configuration.preferences.javaScriptCanOpenWindowsAutomatically = YES;
    configuration.applicationNameForUserAgent = ChromeUserAgent;
    
    // 新增：添加JS消息处理
    WKUserContentController *userContentController = [[WKUserContentController alloc] init];
    [userContentController addScriptMessageHandler:self name:@"clearHistory"];
    [userContentController addScriptMessageHandler:self name:@"checkWebsites"];
    [userContentController addScriptMessageHandler:self name:@"toggleAutoOpen"];
    configuration.userContentController = userContentController;
    
    self.webView = [self createWebViewWithConfiguration:configuration];
    [self.view addSubview:self.webView];
    
    [self showEmptyTipsIfNeeded];

    // 监听菜单切换内置影视等通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleChangeUserCustomSiteURLNotification:) name:@"ChangeUserCustomSiteURLNotification" object:nil];
    // 监听自定义站点变化通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleCustomSitesDidChangeNotification:) name:@"CustomSitesDidChangeNotification" object:nil];

    // 智能预加载常用站点
    [self preloadFrequentlyUsedSites];
    // 启用防止休眠/锁屏
    [self enablePreventSleep];
    // 恢复上次会话
    [self restoreSessionState];
}

// 新增，确保弹窗在主窗口显示后弹出
- (void)viewDidAppear {
    [super viewDidAppear];
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            BOOL autoOpenLast = [[NSUserDefaults standardUserDefaults] boolForKey:@"AutoOpenLastSite"];
            NSString *lastUrl = [[NSUserDefaults standardUserDefaults] objectForKey:@"LastBuiltInSiteURL"];
            NSString *customUrl = [[NSUserDefaults standardUserDefaults] objectForKey:@"UserCustomSiteURL"];
            if (autoOpenLast && lastUrl.length > 0) {
                [self loadUserCustomSiteURL:lastUrl];
            } else if (customUrl.length > 0) {
                [self loadUserCustomSiteURL:customUrl];
            } else {
                [self promptForCustomSiteURLAndLoadIfNeeded];
            }
        });
    });
}

- (void)handleChangeUserCustomSiteURLNotification:(NSNotification *)notification {
    NSString *url = notification.object;
    if (url && [url isKindOfClass:[NSString class]]) {
        [self loadUserCustomSiteURL:url];
        [self showEmptyTipsIfNeeded];
    } else {
        // object为nil时，弹出填写窗口
        [self changeUserCustomSiteURL:nil];
    }
}

- (WKWebView *)currentWebView {
    if (self.secondWindow.isVisible) {
        return self.secondWebView;
    } else {
        return self.webView;
    }
}

- (void)configurationDefaultData{
  
}

- (void)createButtonsForData{
    // 不添加任何按钮
    [self.modelsArray removeAllObjects];
    [self.collectionView reloadData];
    for (NSButton *button in self.buttonsArray) {
        [button removeFromSuperview];
    }
    [self.buttonsArray removeAllObjects];
    [self.view setNeedsLayout:YES];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSString *requestUrl = navigationAction.request.URL.absoluteString;
    NSString *currentUrl = webView.URL.absoluteString;
    // 只在观影记录页面跳转到http/https时显示“正在加载中”
    if ([currentUrl containsString:@"history_rendered.html"] &&
        ([requestUrl hasPrefix:@"http://"] || [requestUrl hasPrefix:@"https://"])) {
        if (!self.loadingTipsLabel) {
            NSTextField *label = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 400, 40)];
            label.stringValue = @"正在加载中...";
            label.alignment = NSTextAlignmentCenter;
            label.font = [NSFont boldSystemFontOfSize:28];
            label.textColor = [NSColor whiteColor];
            label.backgroundColor = [[NSColor blackColor] colorWithAlphaComponent:0.7];
            label.editable = NO;
            label.bezeled = NO;
            label.drawsBackground = YES;
            label.selectable = NO;
            label.wantsLayer = YES;
            label.layer.cornerRadius = 16;
            label.layer.masksToBounds = YES;
            label.translatesAutoresizingMaskIntoConstraints = NO;
            [self.view addSubview:label];
            [NSLayoutConstraint activateConstraints:@[
                [label.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
                [label.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
                [label.widthAnchor constraintEqualToConstant:400],
                [label.heightAnchor constraintEqualToConstant:40]
            ]];
            self.loadingTipsLabel = label;
        }
        self.loadingTipsLabel.hidden = NO;
    }
    // 其它逻辑不变
    if (navigationAction.request.URL.absoluteString.length > 0) {
        
        // 拦截广告
        if ([requestUrl containsString:@"ynjczy.net"] ||
            [requestUrl containsString:@"ylbdtg.com"] ||
            [requestUrl containsString:@"662820.com"] ||
            [requestUrl containsString:@"api.vparse.org"] ||
            [requestUrl containsString:@"hyysvip.duapp.com"] ||
            [requestUrl containsString:@"f.qcwzx.net.cn"] ||
            [requestUrl containsString:@"adx.dlads.cn"] ||
            [requestUrl containsString:@"dlads.cn"] ||
            [requestUrl containsString:@"wuo.8h2x.com"]||
            [requestUrl containsString:@"strip.alicdn.com"]
            ) {
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        }

        if ([requestUrl hasSuffix:@".m3u8"]) {
           
        }
        else {
       
        }
        
        NSLog(@"request.URL.absoluteString = %@",requestUrl);
        
        if ([requestUrl hasPrefix:@"https://aweme.snssdk.co"] || [requestUrl hasPrefix:@"http://aweme.snssdk.co"]) {
            decisionHandler(WKNavigationActionPolicyCancel);
         
            return;
        }
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures{
    NSString *fromUrl = webView.URL.absoluteString;
    NSString *toUrl = navigationAction.request.URL.absoluteString;

    NSLog(@"createWebViewWithConfiguration called - from: %@, to: %@", fromUrl, toUrl);

    // 确保所有导航都在同一个容器中显示，不创建新窗口
    // 直接在当前WebView中加载请求
    if (![toUrl isEqualToString:@"about:blank"] && toUrl.length > 0) {
        [webView loadRequest:navigationAction.request];
    }

    // 返回nil表示不创建新的WebView
    return nil;
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation
{
    NSLog(@"=== didFinishNavigation called for URL: %@", webView.URL.absoluteString);
    // 已通过WKUserScript全局注入隐藏滚动条，无需再手动注入
    if (self.loadingTipsLabel) {
        self.loadingTipsLabel.hidden = YES;
    }
    // 获取当前URL，统一使用一个变量
    NSString *currentUrl = webView.URL.absoluteString;

    // 自动登录Emby
    if ([currentUrl hasPrefix:@"https://dongman.theluyuan.com"]) {
        // 动态获取账号密码，未设置时用默认
        NSString *embyUser = [[NSUserDefaults standardUserDefaults] stringForKey:@"EmbyCustomUser"];
        NSString *embyPass = [[NSUserDefaults standardUserDefaults] stringForKey:@"EmbyCustomPass"];
        if (!embyUser || embyUser.length == 0) {
            embyUser = @"stop";
        }
        if (!embyPass || embyPass.length == 0) {
            embyPass = @"123";
        }
        NSString *js = [NSString stringWithFormat:@"var tryCount=0;var timer=setInterval(function(){\n"
            "var userInput = document.querySelector('input[type=\\\"text\\\"],input[name*=\\\"user\\\"],input[placeholder*=\\\"用\\\"]');\n"
            "var passInput = document.querySelector('input[type=\\\"password\\\"],input[name*=\\\"pass\\\"],input[placeholder*=\\\"密\\\"]');\n"
            "var form = userInput ? userInput.form : null;\n"
            "if(userInput&&passInput){\n"
            "userInput.focus();\n"
            "userInput.value='%@';\n"
            "userInput.dispatchEvent(new Event('input', {bubbles:true}));\n"
            "userInput.dispatchEvent(new Event('change', {bubbles:true}));\n"
            "passInput.focus();\n"
            "passInput.value='%@';\n"
            "passInput.dispatchEvent(new Event('input', {bubbles:true}));\n"
            "passInput.dispatchEvent(new Event('change', {bubbles:true}));\n"
            "passInput.blur();\n"
            "}\n"
            "if(form&&userInput&&passInput){\n"
            "try{\n"
            "form.dispatchEvent(new Event('submit', {bubbles:true,cancelable:true}));\n"
            "form.requestSubmit ? form.requestSubmit() : form.submit();\n"
            "}catch(e){form.submit();}\n"
            "clearInterval(timer);\n"
            "}\n"
            "if(++tryCount>60)clearInterval(timer);\n"
            "}, 100);", embyUser, embyPass];
        [webView evaluateJavaScript:js completionHandler:^(id _Nullable result, NSError * _Nullable error) {
            if (error) {
                NSLog(@"自动登录Emby注入JS出错: %@", error);
            }
        }];
    }

    // 获取网页标题并存入观影记录
    [webView evaluateJavaScript:@"document.title" completionHandler:^(id _Nullable title, NSError * _Nullable error) {
        if (currentUrl.length > 0) {
            NSString *titleToUse = nil;
            if ([title isKindOfClass:[NSString class]] && [[title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] > 0) {
                titleToUse = title;
            } else {
                titleToUse = currentUrl;  // 如果标题为空或只有空白字符，使用URL
            }
            NSLog(@"[页面加载] 准备记录历史 - title: %@, url: %@", titleToUse, currentUrl);
            [self addHistoryWithName:titleToUse url:currentUrl];
        }
    }];

    // 检查当前页面是否为优选网站页面或观影记录页面
    BOOL isMonitorPage = [currentUrl containsString:@"monitor_rendered.html"];
    BOOL isHistoryPage = [currentUrl containsString:@"history_rendered.html"];

    // 只有在非优选网站页面和非观影记录页面时才注入红色按钮
    if (!isMonitorPage && !isHistoryPage) {
        // 页面加载完成后手动注入红色按钮JavaScript
        NSString *globalBtnJS = [self generateRedButtonJavaScript];
        [webView evaluateJavaScript:globalBtnJS completionHandler:^(id result, NSError *error) {
            if (error) {
                NSLog(@"Red button JavaScript injection error: %@", error.localizedDescription);
            } else {
                NSLog(@"Red button JavaScript injection successful");
            }
        }];
    } else {
        NSLog(@"Skipping red button injection for monitor/history page: %@", currentUrl);
    }
}

- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error
{
    if (self.loadingTipsLabel) {
        self.loadingTipsLabel.hidden = YES;
    }
}


- (void)jeffernMovieCurrentApiDidChange:(NSNotification *)notification{
    [self.currentWebView evaluateJavaScript:@"document.location.href" completionHandler:^(NSString * _Nullable url, NSError * _Nullable error) {
        if (self.currentUrl == nil) {
            self.currentUrl = url;
        }
     
    }];
}


- (void)jeffernMovieDidCopyCurrentURL:(NSNotification *)notification{
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard clearContents];
    [pasteboard setString:self.currentWebView.URL.absoluteString forType:NSPasteboardTypeString];
}

- (void)jeffernMovieGoBackCurrentURL:(NSNotification *)notification{
    if ([self.currentWebView canGoBack]) {
        [self.currentWebView goBack];
    }
}

- (void)jeffernMovieGoForwardCurrentURL:(NSNotification *)notification{
    if ([self.currentWebView canGoForward]) {
        [self.currentWebView goForward];
    }
}

#pragma mark - Create

- (WKWebView *)createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration {
    // 使用传入的configuration中的userContentController，不要重新创建
    WKUserContentController *userContentController = configuration.userContentController;
    if (!userContentController) {
        userContentController = [[WKUserContentController alloc] init];
        configuration.userContentController = userContentController;
    }

    // 注入隐藏滚动条的JS
    NSString *js = @"(function hideScrollbarsAllFrames(){\
        function injectStyle(doc){\
            if(!doc) return;\
            var style = doc.getElementById('hide-scrollbar-style');\
            if(!style){\
                style = doc.createElement('style');\
                style.id = 'hide-scrollbar-style';\
                style.innerHTML = '::-webkit-scrollbar{display:none !important;}';\
                doc.head.appendChild(style);\
            }\
        }\
        function injectAllFrames(win){\
            try{\
                injectStyle(win.document);\
            }catch(e){}\
            if(win.frames){\
                for(var i=0;i<win.frames.length;i++){\
                    try{\
                        injectAllFrames(win.frames[i]);\
                    }catch(e){}\
                }\
            }\
        }\
        injectAllFrames(window);\
        var observer = new MutationObserver(function(){\
            injectAllFrames(window);\
        });\
        observer.observe(document, {childList:true, subtree:true});\
    })();";
    WKUserScript *userScript = [[WKUserScript alloc] initWithSource:js injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:NO];
    [userContentController addUserScript:userScript];



    // 只保留最右下角“+”按钮的注入，支持动态获取自定义站点
    // 恢复使用红色按钮JavaScript，但先不注入，等页面加载完成后手动注入
    // NSString *globalBtnJS = [self generateRedButtonJavaScript];
    // WKUserScript *globalBtnScript = [[WKUserScript alloc] initWithSource:globalBtnJS injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:NO];
    // [userContentController addUserScript:globalBtnScript];

    WKWebView *webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:configuration];
    webView.UIDelegate = self;
    webView.navigationDelegate = self;  // 添加导航代理
    webView.allowsBackForwardNavigationGestures = YES;
    webView.navigationDelegate = self;
    [webView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];

    return webView;
}

- (void)creatgeCollectionView{
    CGRect frame = CGRectMake(0, CGRectGetHeight(self.view.bounds)-50, CGRectGetWidth(self.view.bounds), NSCollectionViewHeight);
    CGRect bound = CGRectZero;;

    NSCollectionView *collectionView = [[NSCollectionView alloc] initWithFrame:bound];
    NSCollectionViewFlowLayout *layout = [[NSCollectionViewFlowLayout alloc] init];
    layout.minimumLineSpacing = 0;
    layout.minimumInteritemSpacing = 0;
    layout.scrollDirection = NSCollectionViewScrollDirectionHorizontal;
    layout.itemSize = CGSizeMake(NSCollectionViewWidth, NSCollectionViewHeight);
    collectionView.collectionViewLayout = layout;
    collectionView.dataSource = self;
    collectionView.delegate = self;
    [collectionView registerClass:[HLCollectionViewItem class] forItemWithIdentifier:@"HLCollectionViewItemID"];
    
    NSClipView *clip = [[NSClipView alloc] initWithFrame:bound];
    clip.documentView = collectionView;
    
    NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:frame];
    scrollView.autohidesScrollers = YES; // 自动隐藏滚动条
    scrollView.hasVerticalScroller = NO; // 强制隐藏垂直滚动条
    scrollView.hasHorizontalScroller = NO; // 强制隐藏水平滚动条
    scrollView.contentView = clip;

    [self.view addSubview:scrollView];

    self.scrollView = scrollView;
    self.collectionView = collectionView;

    // 强制隐藏所有NSScroller子视图
    for (NSView *subview in scrollView.subviews) {
        if ([subview isKindOfClass:[NSScroller class]]) {
            subview.hidden = YES;
        }
    }
}

#pragma mark - Notification



- (void)jeffernMovieRequestSuccess:(NSNotification *)notification{
    

    
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"UserCustomSiteURL"]) {
    
    }
}

#pragma mark - history

- (NSMutableArray *)loadHistoryArray {
    NSData *data = [NSData dataWithContentsOfFile:HISTORY_PATH];
    if (!data) return [NSMutableArray array];
    NSArray *arr = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    if ([arr isKindOfClass:[NSArray class]]) {
        return [arr mutableCopy];
    }
    return [NSMutableArray array];
}

- (void)saveHistoryArray:(NSArray *)array {
    NSData *data = [NSJSONSerialization dataWithJSONObject:array options:0 error:nil];
    NSString *dir = [HISTORY_PATH stringByDeletingLastPathComponent];
    [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    [data writeToFile:HISTORY_PATH atomically:YES];
}

- (void)addHistoryWithName:(NSString *)name url:(NSString *)url {
    NSLog(@"[历史记录] 尝试添加历史记录 - name: %@, url: %@", name, url);

    if (!url.length) {
        NSLog(@"[历史记录] 跳过：URL为空");
        return;
    }
    if ([url containsString:@"history_rendered.html"]) {
        NSLog(@"[历史记录] 跳过：历史记录页面");
        return;
    }
    if ([url containsString:@"monitor_rendered.html"]) {
        NSLog(@"[历史记录] 跳过：监控页面");
        return;
    }

    // 注释掉优选网站过滤逻辑，现在所有网站都记录
    // if ([self isPreferredWebsite:url]) {
    //     NSLog(@"[历史记录] 跳过优选网站的历史记录: %@", url);
    //     return;
    // }

    // name为nil或空时使用URL作为名称
    if (!name || [[name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0) {
        name = url;
        NSLog(@"[历史记录] name为空，使用URL作为名称: %@", name);
    }

    // 判断是否为网址格式的标题（所有这些情况都应该显示为"观影记录 N"）
    NSString *trimmed = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^https?://.+" options:NSRegularExpressionCaseInsensitive error:nil];
    NSUInteger matches = [regex numberOfMatchesInString:trimmed options:0 range:NSMakeRange(0, trimmed.length)];

    // 判断是否为网站记录的条件：
    // 1. 标题是网址格式 (http://...)
    // 2. 标题等于URL
    // 3. 标题为空或只有空白字符（已经被设置为URL）
    BOOL isWebsiteTitle = (matches > 0) || [name isEqualToString:url] || [trimmed length] == 0;

    NSLog(@"[历史记录] 正在保存历史记录 - name: %@, url: %@, 是否为网站: %@", name, url, isWebsiteTitle ? @"是" : @"否");
    NSMutableArray *history = [self loadHistoryArray];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *now = [formatter stringFromDate:[NSDate date]];

    // 创建历史记录项，标记是否为网站标题
    NSDictionary *item = @{
        @"name": name,
        @"url": url,
        @"time": now,
        @"isWebsite": @(isWebsiteTitle)  // 标记是否为网站（用于显示时过滤）
    };

    [history insertObject:item atIndex:0];
    while (history.count > 50) {  // 增加历史记录容量，因为现在包含网站记录
        [history removeLastObject];
    }
    [self saveHistoryArray:history];
    NSLog(@"[历史记录] 历史记录保存成功，当前历史记录数量: %lu", (unsigned long)history.count);
}

// 注意：已移除isPreferredWebsite方法，现在所有外部网站都会被记录

- (void)clearHistory {
    NSLog(@"Clearing history at path: %@", HISTORY_PATH);
    NSError *error = nil;
    BOOL success = [[NSFileManager defaultManager] removeItemAtPath:HISTORY_PATH error:&error];
    if (success) {
        NSLog(@"History file deleted successfully");
    } else {
        NSLog(@"Failed to delete history file: %@", error.localizedDescription);
    }
}

#pragma mark - CollectionView
- (NSInteger)collectionView:(NSCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.modelsArray.count;
}

- (NSCollectionViewItem *)collectionView:(NSCollectionView *)collectionView itemForRepresentedObjectAtIndexPath:(NSIndexPath *)indexPath {
    HLCollectionViewItem *item = [collectionView makeItemWithIdentifier:@"HLCollectionViewItemID" forIndexPath:indexPath];

    return item;
}



#pragma mark - Custom Site URL

- (void)promptForCustomSiteURLAndLoadIfNeeded {
    NSString *cachedUrl = [[NSUserDefaults standardUserDefaults] objectForKey:@"UserCustomSiteURL"];
    if (!cachedUrl || cachedUrl.length == 0) {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"⬇封装网址格式如下⬇";
        alert.informativeText = @"https://www.xxx.com";
        NSTextField *input = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 300, 24)];
        [alert setAccessoryView:input];
        [alert addButtonWithTitle:@"✨✨✨"];
        [alert addButtonWithTitle:@"使用内置影视"];
        [alert.window setInitialFirstResponder:input];
        __weak typeof(self) weakSelf = self;
        NSWindow *mainWindow = [NSApplication sharedApplication].mainWindow ?: self.view.window;
        if (mainWindow) {
            [alert beginSheetModalForWindow:mainWindow completionHandler:^(NSModalResponse returnCode) {
                if (returnCode == NSAlertFirstButtonReturn) {
                    NSString *url = [input.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    if (url.length > 0) {
                        [[NSUserDefaults standardUserDefaults] setObject:url forKey:@"UserCustomSiteURL"];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                        // 通知监控系统重新同步站点
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"CustomSitesDidChangeNotification" object:nil];
                        [weakSelf loadUserCustomSiteURL:url];
                    } else {
                        [NSApp terminate:nil];
                    }
                } else if (returnCode == NSAlertSecondButtonReturn) {
                    // 弹窗选择内置影视站点
                    NSArray *siteNames = [HLHomeViewController getBuiltInSiteNames];
                    NSArray *siteURLs = [HLHomeViewController getBuiltInSiteURLs];
                    NSAlert *siteAlert = [[NSAlert alloc] init];
                    siteAlert.messageText = @"请选择内置影视站点";
                    for (NSString *name in siteNames) {
                        [siteAlert addButtonWithTitle:name];
                    }
                    NSWindow *mainWindow = [NSApplication sharedApplication].mainWindow ?: self.view.window;
                    [siteAlert beginSheetModalForWindow:mainWindow completionHandler:^(NSModalResponse siteCode) {
                        NSInteger idx = siteCode - NSAlertFirstButtonReturn;
                        if (idx >= 0 && idx < siteURLs.count) {
                            NSString *url = siteURLs[idx];
                            [weakSelf loadUserCustomSiteURL:url];
                        }
                        // 取消不做任何事
                    }];
                }
            }];
        } else {
            // 兜底：直接阻塞弹窗
            NSModalResponse returnCode = [alert runModal];
            if (returnCode == NSAlertFirstButtonReturn) {
                NSString *url = [input.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                if (url.length > 0) {
                    [[NSUserDefaults standardUserDefaults] setObject:url forKey:@"UserCustomSiteURL"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    // 通知监控系统重新同步站点
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"CustomSitesDidChangeNotification" object:nil];
                    [self loadUserCustomSiteURL:url];
                } else {
                    [NSApp terminate:nil];
                }
            } else if (returnCode == NSAlertSecondButtonReturn) {
                NSArray *siteNames = [HLHomeViewController getBuiltInSiteNames];
                NSArray *siteURLs = [HLHomeViewController getBuiltInSiteURLs];
                NSAlert *siteAlert = [[NSAlert alloc] init];
                siteAlert.messageText = @"请选择内置影视站点";
                for (NSString *name in siteNames) {
                    [siteAlert addButtonWithTitle:name];
                }
                NSModalResponse siteCode = [siteAlert runModal];
                NSInteger idx = siteCode - NSAlertFirstButtonReturn;
                if (idx >= 0 && idx < siteURLs.count) {
                    NSString *url = siteURLs[idx];
                    [self loadUserCustomSiteURL:url];
                }
                // 取消不做任何事
            }
        }
    } else {
        [self loadUserCustomSiteURL:cachedUrl];
    }
}

- (void)loadUserCustomSiteURL:(NSString *)urlString {
    if (!urlString || urlString.length == 0) return;
    // 显示“正在加载中”提示（更明显，垂直居中）
    if (!self.loadingTipsLabel) {
        NSTextField *label = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 400, 40)];
        label.stringValue = @"正在加载中...";
        label.alignment = NSTextAlignmentCenter;
        label.font = [NSFont boldSystemFontOfSize:28];
        label.textColor = [NSColor whiteColor];
        label.backgroundColor = [[NSColor blackColor] colorWithAlphaComponent:0.7];
        label.editable = NO;
        label.bezeled = NO;
        label.drawsBackground = YES;
        label.selectable = NO;
        label.wantsLayer = YES;
        label.layer.cornerRadius = 16;
        label.layer.masksToBounds = YES;
        label.translatesAutoresizingMaskIntoConstraints = NO;
        [self.view addSubview:label];
        [NSLayoutConstraint activateConstraints:@[
            [label.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
            [label.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
            [label.widthAnchor constraintEqualToConstant:400],
            [label.heightAnchor constraintEqualToConstant:40]
        ]];
        self.loadingTipsLabel = label;
    }
    self.loadingTipsLabel.hidden = NO;
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) return;
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:request];
    // 新增：记录观影
    [self addHistoryWithName:nil url:urlString];
}

- (void)changeUserCustomSiteURL:(id)sender {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"UserCustomSiteURL"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    // 通知监控系统重新同步站点（移除✨✨✨监控）
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CustomSitesDidChangeNotification" object:nil];
    [self promptForCustomSiteURLAndLoadIfNeeded];
    [self showEmptyTipsIfNeeded];
}

- (void)showEmptyTipsIfNeeded {
    // 已去除全局浮动提示，不再显示 label。
}

- (void)showLocalHistoryHTML {
    NSString *htmlPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"history_rendered.html"];
    NSURL *url = [NSURL fileURLWithPath:htmlPath];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:request];
}

- (void)showLocalMonitorHTML {
    NSString *htmlPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"monitor_rendered.html"];
    NSURL *url = [NSURL fileURLWithPath:htmlPath];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:request];
}

// 新增：生成红色按钮JavaScript代码的方法
- (NSString *)generateRedButtonJavaScript {
    NSLog(@"generateRedButtonJavaScript called");
    // 获取自定义站点域名列表
    NSArray *customSites = [[NSUserDefaults standardUserDefaults] arrayForKey:@"CustomSites"] ?: @[];
    NSLog(@"Custom sites count: %lu", (unsigned long)customSites.count);
    NSMutableArray *customDomains = [NSMutableArray array];
    for (NSDictionary *site in customSites) {
        NSString *url = site[@"url"];
        if (url && url.length > 0) {
            NSURL *siteURL = [NSURL URLWithString:url];
            if (siteURL && siteURL.host) {
                [customDomains addObject:siteURL.host];
            }
        }
    }

    // 构建包含内置域名和自定义域名的JavaScript数组
    NSMutableArray *allDomains = [NSMutableArray arrayWithArray:@[@"yanetflix.com",@"omofun2.xyz",@"ddys.pro",@"duonaovod.com",@"kuaizi.cc",@"honghuli.com",@"jagcys.com",@"v.luttt.com",@"jinlidj.com",@"dandantu.cc"]];
    [allDomains addObjectsFromArray:customDomains];

    // 将域名数组转换为JavaScript数组字符串
    NSMutableString *domainsJS = [NSMutableString stringWithString:@"["];
    for (NSInteger i = 0; i < allDomains.count; i++) {
        [domainsJS appendFormat:@"'%@'", allDomains[i]];
        if (i < allDomains.count - 1) {
            [domainsJS appendString:@","];
        }
    }
    [domainsJS appendString:@"]"];

    // 生成完整的JavaScript代码
    NSString *globalBtnJS = [NSString stringWithFormat:@""
        "(function(){"
            "var allowDomains = %@;"
            "var host = location.host;"
            "console.log('Red button script loaded. Host:', host, 'Allowed domains:', allowDomains);"
            "var allow = false;"
            "if (!host || host === '') {"
                "console.log('No host found, allowing for local files');"
                "allow = true;"
            "} else {"
                "for(var i=0;i<allowDomains.length;i++){"
                    "if(host.indexOf(allowDomains[i])!==-1){"
                        "console.log('Found matching domain:', allowDomains[i]);"
                        "allow=true; break;"
                    "}"
                "}"
            "}"
            "if(!allow) {"
                "console.log('Domain not allowed, skipping red button creation');"
                "return;"
            "}"
            "console.log('Domain allowed, creating red button...');"
            "if(document.querySelector('.jeffern-global-fullscreen-btn')) return;"
            "var btn = document.createElement('button');"
            "btn.className = 'jeffern-global-fullscreen-btn';"
            "btn.innerText = '+';"
            "btn.style.position = 'fixed';"
            "btn.style.right = '0px';"
            "btn.style.bottom = '0px';"
            "btn.style.zIndex = '2147483647';"
            "btn.style.background = 'rgba(255,0,0,0.8)';"
            "btn.style.color = 'white';"
            "btn.style.border = 'none';"
            "btn.style.padding = '520px 3px';"
            "btn.style.borderRadius = '8px 0 0 0';"
            "btn.style.cursor = 'pointer';"
            "btn.style.fontSize = '20px';"
            "btn.style.fontWeight = 'bold';"
            "btn.style.boxShadow = '0 2px 8px rgba(0,0,0,0.2)';"
            "btn.style.opacity = '0';"
            "btn.style.pointerEvents = 'auto';"
            "var hideTimer = null;"
            "var autoHideTimer = null;"
            "function showBtn(){"
                "btn.style.opacity = '1';"
                "if(hideTimer){ clearTimeout(hideTimer); hideTimer = null; }"
                "if(autoHideTimer){ clearTimeout(autoHideTimer); autoHideTimer = null; }"
                "autoHideTimer = setTimeout(function(){ btn.style.opacity = '0'; }, 1000);"
            "}"
            "function hideBtn(){"
                "btn.style.opacity = '0';"
                "if(autoHideTimer){ clearTimeout(autoHideTimer); autoHideTimer = null; }"
            "}"
            "btn.onmouseenter = function(){"
                "showBtn();"
            "};"
            "btn.onmouseleave = function(){"
                "if(autoHideTimer){ clearTimeout(autoHideTimer); autoHideTimer = null; }"
                "autoHideTimer = setTimeout(function(){ btn.style.opacity = '0'; }, 1000);"
            "};"
            "document.addEventListener('mousemove', function(e){"
                "var winWidth = window.innerWidth;"
                "if(winWidth - e.clientX <= 20){"
                    "showBtn();"
                "}"
            "});"
            "btn.onclick = function(){"
                "var iframes = Array.from(document.querySelectorAll('iframe'));"
                "if(iframes.length===0){ alert('未找到iframe播放器'); return; }"
                "var maxIframe = iframes[0];"
                "var maxArea = 0;"
                "for(var i=0;i<iframes.length;i++){"
                    "var rect = iframes[i].getBoundingClientRect();"
                    "var area = rect.width*rect.height;"
                    "if(area>maxArea){ maxArea=area; maxIframe=iframes[i]; }"
                "}"
                "var target = maxIframe;"
                "if(!target._isFullscreen){"
                    "target._originParent = target.parentElement;"
                    "target._originNext = target.nextSibling;"
                    "target._originStyle = {"
                        "position: target.style.position,"
                        "zIndex: target.style.zIndex,"
                        "left: target.style.left,"
                        "top: target.style.top,"
                        "width: target.style.width,"
                        "height: target.style.height,"
                        "background: target.style.background"
                    "};"
                    "document.body.appendChild(target);"
                    "target.style.position = 'fixed';"
                    "target.style.zIndex = '2147483646';"
                    "target.style.left = '0';"
                    "target.style.top = '0';"
                    "target.style.width = '100vw';"
                    "target.style.height = '100vh';"
                    "target.style.background = 'black';"
                    "target._isFullscreen = true;"
                    "btn.innerText = '+';"
                    "window.scrollTo(0,0);"
                "}else{"
                    "if(target._originParent){"
                        "if(target._originNext && target._originNext.parentElement===target._originParent){"
                            "target._originParent.insertBefore(target, target._originNext);"
                        "}else{"
                            "target._originParent.appendChild(target);"
                        "}"
                    "}"
                    "if(target._originStyle){"
                        "target.style.position = target._originStyle.position;"
                        "target.style.zIndex = target._originStyle.zIndex;"
                        "target.style.left = target._originStyle.left;"
                        "target.style.top = target._originStyle.top;"
                        "target.style.width = target._originStyle.width;"
                        "target.style.height = target._originStyle.height;"
                        "target.style.background = target._originStyle.background;"
                    "}"
                    "target._isFullscreen = false;"
                    "btn.innerText = '+';"
                "}"
            "};"
            "document.body.appendChild(btn);"
            "document.addEventListener('keydown', function(ev){"
                "var iframes = Array.from(document.querySelectorAll('iframe'));"
                "var maxIframe = iframes[0];"
                "var maxArea = 0;"
                "for(var i=0;i<iframes.length;i++){"
                    "var rect = iframes[i].getBoundingClientRect();"
                    "var area = rect.width*rect.height;"
                    "if(area>maxArea){ maxArea=area; maxIframe=iframes[i]; }"
                "}"
                "var target = maxIframe;"
                "if(ev.key==='Escape' && target && target._isFullscreen){"
                    "btn.onclick();"
                "}"
            "});"
        "})();", domainsJS];

    return globalBtnJS;
}

// 新增：处理自定义站点变化通知
- (void)handleCustomSitesDidChangeNotification:(NSNotification *)notification {
    // 重新注入红色按钮JavaScript
    [self reinjectRedButtonJavaScript];
}

// 新增：重新注入红色按钮JavaScript
- (void)reinjectRedButtonJavaScript {
    if (!self.webView) return;

    // 检查当前页面是否为优选网站页面或观影记录页面
    NSString *currentUrl = self.webView.URL.absoluteString;
    BOOL isMonitorPage = [currentUrl containsString:@"monitor_rendered.html"];
    BOOL isHistoryPage = [currentUrl containsString:@"history_rendered.html"];

    // 先移除现有的红色按钮
    NSString *removeJS = @"var existingBtn = document.querySelector('.jeffern-global-fullscreen-btn'); if(existingBtn) existingBtn.remove();";
    [self.webView evaluateJavaScript:removeJS completionHandler:nil];

    // 只有在非优选网站页面和非观影记录页面时才重新注入红色按钮
    if (!isMonitorPage && !isHistoryPage) {
        // 重新注入新的红色按钮JavaScript
        NSString *newJS = [self generateRedButtonJavaScript];
        [self.webView evaluateJavaScript:newJS completionHandler:nil];
    } else {
        NSLog(@"Skipping red button reinjection for monitor/history page: %@", currentUrl);
    }
}



#pragma mark - WKScriptMessageHandler
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    NSLog(@"Received script message: %@", message.name);
    if ([message.name isEqualToString:@"clearHistory"]) {
        NSLog(@"Processing clearHistory message");
        // 在后台线程处理清除历史记录
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self clearHistory];
            // 重新生成HTML
            AppDelegate *delegate = (AppDelegate *)[NSApplication sharedApplication].delegate;
            [delegate generateHistoryHTML];

            // 回到主线程刷新页面
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showLocalHistoryHTML];
                NSLog(@"History cleared and page refreshed");
            });
        });
    } else if ([message.name isEqualToString:@"checkWebsites"]) {
        NSLog(@"Processing checkWebsites message");
        AppDelegate *delegate = (AppDelegate *)[NSApplication sharedApplication].delegate;
        [delegate checkWebsiteStatus:nil];
        // 延迟3秒后在后台线程刷新页面
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [delegate generateMonitorHTML];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showLocalMonitorHTML];
            });
        });
    } else if ([message.name isEqualToString:@"toggleAutoOpen"]) {
        NSLog(@"Processing toggleAutoOpen message");
        AppDelegate *delegate = (AppDelegate *)[NSApplication sharedApplication].delegate;
        [delegate toggleAutoOpenFastestSite:nil];
        // 在后台线程刷新页面显示新状态
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [delegate generateMonitorHTML];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showLocalMonitorHTML];
            });
        });
    }
}

#pragma mark - 智能预加载常用站点
- (void)preloadFrequentlyUsedSites {
    NSMutableArray *history = [self loadHistoryArray];
    if (history.count == 0) return;
    // 统计域名出现频率
    NSMutableDictionary *hostCount = [NSMutableDictionary dictionary];
    for (NSDictionary *item in history) {
        NSString *urlStr = item[@"url"];
        NSURL *url = [NSURL URLWithString:urlStr];
        if (!url.host) continue;
        NSString *host = url.host;
        NSNumber *count = hostCount[host];
        hostCount[host] = @(count ? count.integerValue + 1 : 1);
    }
    // 按频率排序，取前3
    NSArray *sortedHosts = [hostCount keysSortedByValueUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [obj2 compare:obj1];
    }];
    NSInteger preloadCount = MIN(3, sortedHosts.count);
    for (NSInteger i = 0; i < preloadCount; i++) {
        NSString *host = sortedHosts[i];
        // 找到观影记录中第一个该host的完整url
        NSString *preloadUrl = nil;
        for (NSDictionary *item in history) {
            NSString *urlStr = item[@"url"];
            NSURL *url = [NSURL URLWithString:urlStr];
            if ([url.host isEqualToString:host]) {
                preloadUrl = urlStr;
                break;
            }
        }
        if (preloadUrl) {
            NSURL *url = [NSURL URLWithString:preloadUrl];
            NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30];
            NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request];
            [task resume];
        }
    }
}

#pragma mark - 防止休眠/锁屏
- (void)enablePreventSleep {
    if (self.isPreventingSleep) return;
    IOReturn success = IOPMAssertionCreateWithName(kIOPMAssertionTypeNoDisplaySleep,
                                                   kIOPMAssertionLevelOn,
                                                   CFSTR("JeffernMovie防止休眠/锁屏"),
                                                   &_assertionID);
    if (success == kIOReturnSuccess) {
        self.isPreventingSleep = YES;
    }
}

- (void)disablePreventSleep {
    if (!self.isPreventingSleep) return;
    IOPMAssertionRelease(_assertionID);
    self.isPreventingSleep = NO;
}

#pragma mark - 会话恢复
- (void)saveSessionState {
    NSString *currentUrl = self.currentWebView.URL.absoluteString;
    if (currentUrl.length > 0) {
        [[NSUserDefaults standardUserDefaults] setObject:currentUrl forKey:SESSION_STATE_KEY];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)restoreSessionState {
    NSString *lastUrl = [[NSUserDefaults standardUserDefaults] objectForKey:SESSION_STATE_KEY];
    if (lastUrl.length > 0) {
        NSURL *url = [NSURL URLWithString:lastUrl];
        if (url) {
            NSURLRequest *request = [NSURLRequest requestWithURL:url];
            [self.webView loadRequest:request];
        }
    }
}


#pragma mark - 内置站点信息

+ (NSArray *)getBuiltInSitesInfo {
    // 统一的内置站点定义，所有地方都从这里获取
    static NSArray *builtInSites = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        builtInSites = @[
            @{@"name": @"Emby", @"url": @"https://dongman.theluyuan.com/"},
            @{@"name": @"可可影视", @"url": @"https://www.keke1.app/"},
            @{@"name": @"奈飞工厂", @"url": @"https://yanetflix.com/"},
            @{@"name": @"omofun动漫", @"url": @"https://www.omofun2.xyz/"},
            @{@"name": @"北觅影视", @"url": @"https://v.luttt.com/"},
            @{@"name": @"gimy", @"url": @"https://www.jagcys.com/"},
            @{@"name": @"蛋蛋兔", @"url": @"https://www.dandantu.cc/"},
            @{@"name": @"人人影视", @"url": @"https://kuaizi.cc/"},
            @{@"name": @"红狐狸影视", @"url": @"https://honghuli.com/"},
            @{@"name": @"低端影视", @"url": @"https://ddys.pro/"},
            @{@"name": @"多瑙影视", @"url": @"https://www.duonaovod.com/"},
            @{@"name": @"CCTV", @"url": @"https://tv.cctv.com/live/"},
            @{@"name": @"直播", @"url": @"https://live.wxhbts.com/"},
            @{@"name": @"抖音短剧", @"url": @"https://www.jinlidj.com/"}
        ];
    });
    return builtInSites;
}

+ (NSArray *)getBuiltInSiteNames {
    NSArray *sites = [self getBuiltInSitesInfo];
    NSMutableArray *names = [NSMutableArray array];
    for (NSDictionary *site in sites) {
        [names addObject:site[@"name"]];
    }
    return [names copy];
}

+ (NSArray *)getBuiltInSiteURLs {
    NSArray *sites = [self getBuiltInSitesInfo];
    NSMutableArray *urls = [NSMutableArray array];
    for (NSDictionary *site in sites) {
        [urls addObject:site[@"url"]];
    }
    return [urls copy];
}

@end
