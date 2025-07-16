//Jeffern影视平台 ©Jeffern 2025/7/15

#import "AppDelegate.h"
#import "HLHomeWindowController.h"
#import "HLHomeViewController.h"

@interface HLHomeWindowController ()<NSWindowDelegate>

@end

@implementation HLHomeWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    self.window.delegate = self;
    
    //让显示的位置居于屏幕的中心
    [[self window] center];
    // 启动时全屏显示
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.window toggleFullScreen:nil];
    });
}

- (void)windowWillClose:(NSNotification *)notification {
    // whichever operations are needed when the
    
}

- (void)windowWillExitFullScreen:(NSNotification *)notification {
    HLHomeViewController *vipVC = (id)self.contentViewController;
    vipVC.isFullScreen = NO;
}

- (void)windowWillEnterFullScreen:(NSNotification *)notification {
    HLHomeViewController *vipVC = (id)self.contentViewController;
    vipVC.isFullScreen = YES;
}

- (BOOL)windowShouldClose:(NSWindow *)sender{
    [self.window orderOut:nil];
    
   AppDelegate *delegate = (AppDelegate *)[NSApplication sharedApplication].delegate;
    if ([delegate.windonwArray containsObject:self]) {
        // 点击关闭按钮时，销毁，同时去除数据中引用。避免内存泄漏
        [delegate.windonwArray removeObject:self];
        return YES;
    }
    else {
        return NO;
    }
}

@end
