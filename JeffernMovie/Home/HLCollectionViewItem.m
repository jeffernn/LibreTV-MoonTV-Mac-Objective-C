//Jeffern影视平台 ©Jeffern 2025/7/15

#import "HLCollectionViewItem.h"

@implementation NSVideoButton

@end


@interface HLCollectionViewItem ()

@end

@implementation HLCollectionViewItem
@dynamic selected;

- (void)viewDidLayout{
    [super viewDidLayout];
    self.button.frame = CGRectMake(5, 5, CGRectGetWidth(self.view.bounds)-5, CGRectGetHeight(self.view.bounds)-5);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
    if (self.button == nil) {
        self.button = [[NSVideoButton alloc] init];
        [self.button setBezelStyle:NSBezelStyleRegularSquare];
        self.button.layer.cornerRadius = 5;
        self.button.target = self;
        self.button.wantsLayer = YES;
        
        [self.view addSubview:self.button];
    }
}


@end
