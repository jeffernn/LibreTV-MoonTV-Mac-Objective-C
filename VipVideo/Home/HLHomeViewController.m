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
            NSArray *urls = [requestUrl componentsSeparatedByString:@"url="];
           
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
}

- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error
{
  
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
        alert.messageText = @"⬇影视站格式⬇";
        alert.informativeText = @"https://www.xxx.com";
        NSTextField *input = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 300, 24)];
        [alert setAccessoryView:input];
        [alert addButtonWithTitle:@"🚀🚀🚀"];
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
        }];
    } else {
        [self loadUserCustomSiteURL:cachedUrl];
    }
}

- (void)loadUserCustomSiteURL:(NSString *)urlString {
    if (!urlString || urlString.length == 0) return;
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) return;
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:request];
}

- (void)changeUserCustomSiteURL:(id)sender {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"UserCustomSiteURL"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self promptForCustomSiteURLAndLoadIfNeeded];
}


@end
