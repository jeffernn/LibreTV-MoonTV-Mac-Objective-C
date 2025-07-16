//Jeffern影视平台 ©Jeffern 2025/7/15

#import "HLHomeViewController.h"
#import "NSView+ZCAddition.h"
#import <WebKit/WebKit.h>
#import "NSString+HLAddition.h"
#import "HLCollectionViewItem.h"
#import "AppDelegate.h"
#import "HLRegexMatcher.h"

#pragma mark ----



#define NSCollectionViewWidth   75
#define NSCollectionViewHeight  50
#define NSTextViewTips @"[{}]"

typedef enum : NSUInteger {
    EditType_VIP,
    EditType_Platform,
} EditType;

#define ChromeUserAgent @"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36"

@interface HLHomeViewController()<WKNavigationDelegate, WKUIDelegate, NSCollectionViewDataSource, NSCollectionViewDelegate>{
    BOOL isLoading;
    BOOL isChanged;
    WKWebViewConfiguration *secondConfiguration;
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
    
    self.webView = [self createWebViewWithConfiguration:configuration];
    [self.view addSubview:self.webView];
    
    [self promptForCustomSiteURLAndLoadIfNeeded];
    [self showEmptyTipsIfNeeded];

    // 监听菜单切换内置影视等通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleChangeUserCustomSiteURLNotification:) name:@"ChangeUserCustomSiteURLNotification" object:nil];
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
    //如果是跳转一个新页面
    if (navigationAction.targetFrame == nil) {
        [webView loadRequest:navigationAction.request];
    }
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
        
        if([HLRegexMatcher isValidVideoUrl:requestUrl]) {
            self.currentUrl = navigationAction.request.URL.absoluteString;
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
    
    if([navigationAction.request.URL.absoluteString isEqualToString:@"about:blank"]) {
        return nil;
    }
    
    secondConfiguration = configuration;
    [self.secondWindow close];
    
    NSUInteger windowStyleMask = NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable | NSWindowStyleMaskTitled;
    NSWindow *keyWindow = NSApplication.sharedApplication.keyWindow;
    NSWindow *secondWindow = [[NSWindow alloc] initWithContentRect:keyWindow.frame styleMask:windowStyleMask backing:NSBackingStoreBuffered defer:NO];
    
    WKWebView *secondWebView = [self createWebViewWithConfiguration:configuration];
    [secondWindow setContentView:secondWebView];
    [secondWindow makeKeyAndOrderFront:self];

    AppDelegate *delegate = (id)[NSApplication sharedApplication].delegate;
    [delegate.windonwArray addObject:secondWindow];
    
    [secondWebView loadRequest:navigationAction.request];
    self.secondWebView = secondWebView;
    self.secondWindow = secondWindow;
    
    NSLog(@"navigationAction.request =%@",navigationAction.request);
    
    return secondWebView;
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation
{
    // 已通过WKUserScript全局注入隐藏滚动条，无需再手动注入
    if (self.loadingTipsLabel) {
        self.loadingTipsLabel.hidden = YES;
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
    WKUserContentController *userContentController = [[WKUserContentController alloc] init];
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

    // 只保留最右下角“+”按钮的注入，尺寸恢复为原来大小
    NSString *globalBtnJS = @"(function(){\
        var allowDomains = ['cupfox.love','yanetflix.com','gying.si','omofun2.xyz'];\
        var host = location.host;\
        var allow = false;\
        for(var i=0;i<allowDomains.length;i++){\
            if(host.indexOf(allowDomains[i])!==-1){ allow=true; break; }\
        }\
        if(!allow) return;\
        if(document.querySelector('.jeffern-global-fullscreen-btn')) return;\
        var btn = document.createElement('button');\
        btn.className = 'jeffern-global-fullscreen-btn';\
        btn.innerText = '+';\
        btn.style.position = 'fixed';\
        btn.style.right = '0px';\
        btn.style.bottom = '0px';\
        btn.style.zIndex = '2147483647';\
        btn.style.background = 'rgba(255,0,0,0.8)';\
        btn.style.color = 'white';\
        btn.style.border = 'none';\
        btn.style.padding = '520px 14px';\
        btn.style.borderRadius = '8px 0 0 0';\
        btn.style.cursor = 'pointer';\
        btn.style.fontSize = '20px';\
        btn.style.fontWeight = 'bold';\
        btn.style.boxShadow = '0 2px 8px rgba(0,0,0,0.2)';\
        btn.style.opacity = '1';\
        btn.style.pointerEvents = 'auto';\
        var hideTimer = null;\
        btn.onmouseenter = function(){\
            btn.style.opacity = '1';\
            if(hideTimer){ clearTimeout(hideTimer); hideTimer = null; }\
        };\
        btn.onmouseleave = function(){\
            if(hideTimer){ clearTimeout(hideTimer); }\
            hideTimer = setTimeout(function(){ btn.style.opacity = '0'; }, 2000);\
        };\
        btn.onclick = function(){\
            var iframes = Array.from(document.querySelectorAll('iframe'));\
            if(iframes.length===0){ alert('未找到iframe播放器'); return; }\
            var maxIframe = iframes[0];\
            var maxArea = 0;\
            for(var i=0;i<iframes.length;i++){\
                var rect = iframes[i].getBoundingClientRect();\
                var area = rect.width*rect.height;\
                if(area>maxArea){ maxArea=area; maxIframe=iframes[i]; }\
            }\
            var target = maxIframe;\
            if(!target._isFullscreen){\
                target._originParent = target.parentElement;\
                target._originNext = target.nextSibling;\
                target._originStyle = {\
                    position: target.style.position,\
                    zIndex: target.style.zIndex,\
                    left: target.style.left,\
                    top: target.style.top,\
                    width: target.style.width,\
                    height: target.style.height,\
                    background: target.style.background\
                };\
                document.body.appendChild(target);\
                target.style.position = 'fixed';\
                target.style.zIndex = '2147483646';\
                target.style.left = '0';\
                target.style.top = '0';\
                target.style.width = '100vw';\
                target.style.height = '100vh';\
                target.style.background = 'black';\
                target._isFullscreen = true;\
                btn.innerText = '+';\
                window.scrollTo(0,0);\
            }else{\
                if(target._originParent){\
                    if(target._originNext && target._originNext.parentElement===target._originParent){\
                        target._originParent.insertBefore(target, target._originNext);\
                    }else{\
                        target._originParent.appendChild(target);\
                    }\
                }\
                if(target._originStyle){\
                    target.style.position = target._originStyle.position;\
                    target.style.zIndex = target._originStyle.zIndex;\
                    target.style.left = target._originStyle.left;\
                    target.style.top = target._originStyle.top;\
                    target.style.width = target._originStyle.width;\
                    target.style.height = target._originStyle.height;\
                    target.style.background = target._originStyle.background;\
                }\
                target._isFullscreen = false;\
                btn.innerText = '+';\
            }\
        };\
        document.body.appendChild(btn);\
        setTimeout(function(){ btn.style.opacity = '0'; }, 3000);\
        document.addEventListener('keydown', function(ev){\
            var iframes = Array.from(document.querySelectorAll('iframe'));\
            var maxIframe = iframes[0];\
            var maxArea = 0;\
            for(var i=0;i<iframes.length;i++){\
                var rect = iframes[i].getBoundingClientRect();\
                var area = rect.width*rect.height;\
                if(area>maxArea){ maxArea=area; maxIframe=iframes[i]; }\
            }\
            var target = maxIframe;\
            if(ev.key==='Escape' && target && target._isFullscreen){\
                btn.onclick();\
            }\
        });\
    })();";
    WKUserScript *globalBtnScript = [[WKUserScript alloc] initWithSource:globalBtnJS injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:NO];
    [userContentController addUserScript:globalBtnScript];
    configuration.userContentController = userContentController;

    WKWebView *webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:configuration];
    webView.UIDelegate = self;
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
        alert.messageText = @"⬇网址格式如下⬇";
        alert.informativeText = @"https://www.xxx.com";
        NSTextField *input = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 300, 24)];
        [alert setAccessoryView:input];
        [alert addButtonWithTitle:@"✨✨✨"];
        [alert.window setInitialFirstResponder:input];
        __weak typeof(self) weakSelf = self;
        [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
            NSString *url = [input.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if (url.length > 0) {
                [[NSUserDefaults standardUserDefaults] setObject:url forKey:@"UserCustomSiteURL"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                [weakSelf loadUserCustomSiteURL:url];
            } else {
                [NSApp terminate:nil];
            }
            [weakSelf showEmptyTipsIfNeeded];
        }];
    } else {
        [self loadUserCustomSiteURL:cachedUrl];
        [self showEmptyTipsIfNeeded];
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
}

- (void)changeUserCustomSiteURL:(id)sender {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"UserCustomSiteURL"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self promptForCustomSiteURLAndLoadIfNeeded];
    [self showEmptyTipsIfNeeded];
}

- (void)showEmptyTipsIfNeeded {
    NSString *cachedUrl = [[NSUserDefaults standardUserDefaults] objectForKey:@"UserCustomSiteURL"];
    if (!cachedUrl || cachedUrl.length == 0) {
        if (!self.emptyTipsLabel) {
            NSTextField *label = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 400, 60)];
            label.stringValue = @"鼠标移动至状态栏依次点击 Jeffern观影平台->✨";
            label.alignment = NSTextAlignmentCenter;
            label.font = [NSFont boldSystemFontOfSize:18];
            label.textColor = [NSColor grayColor];
            label.backgroundColor = [NSColor clearColor];
            label.editable = NO;
            label.bezeled = NO;
            label.drawsBackground = NO;
            label.selectable = NO;
            label.translatesAutoresizingMaskIntoConstraints = NO;
            [self.view addSubview:label];
            [NSLayoutConstraint activateConstraints:@[
                [label.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
                [label.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor]
            ]];
            self.emptyTipsLabel = label;
        }
        self.emptyTipsLabel.hidden = NO;
    } else {
        if (self.emptyTipsLabel) {
            self.emptyTipsLabel.hidden = YES;
        }
    }
}


@end
