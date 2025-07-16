//Jeffern影视平台 ©Jeffern 2025/7/15
#import <Cocoa/Cocoa.h>

@interface NSVideoButton:NSButton
@end

NS_ASSUME_NONNULL_BEGIN

@interface HLCollectionViewItem : NSCollectionViewItem

@property (weak) IBOutlet NSTextField *textLabel;
@property (nonatomic, strong) NSVideoButton *button;
@property (nonatomic, strong) NSIndexPath *indexPath;

@end

NS_ASSUME_NONNULL_END
