// HideStream.m
// Hides the tool overlay from screenshots, screen recording, and live streams.
// Technique: embed the tool inside a UITextField's private layer which iOS
// automatically excludes from screen captures (same method used by banking apps).

#import "HideStream.h"
#import <UIKit/UIKit.h>

@interface HideStream ()
@property (nonatomic, strong) UITextField *secureField;
@property (nonatomic, strong) NSMutableArray<UIView *> *protectedViews;
@end

@implementation HideStream

+ (instancetype)sharedInstance {
    static HideStream *s;
    static dispatch_once_t t;
    dispatch_once(&t, ^{ s = [self new]; });
    return s;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _protectedViews = [NSMutableArray new];
        _enabled = YES;
    }
    return self;
}

- (void)startObserving {
    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(captureDidChange:)
        name:UIScreenCapturedDidChangeNotification
        object:nil];

    // Also observe AVCapture / ReplayKit broadcast
    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(captureDidChange:)
        name:@"RPBroadcastStarted"
        object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(captureDidChange:)
        name:@"RPBroadcastFinished"
        object:nil];
}

- (void)captureDidChange:(NSNotification *)n {
    BOOL capturing = [UIScreen mainScreen].isCaptured;
    [self handleCaptureStateChange:capturing];
}

- (void)handleCaptureStateChange:(BOOL)captured {
    // Handled by the hook in Tweak.x; no extra action needed here.
}

// ── Core Technique ──────────────────────────────────────────────────────────
// UITextField has an internal _secureContainerView whose layer is marked as
// secured and is excluded from iOS capture pipeline automatically.
// We reparent our tool view INTO that private subview.

- (void)applyToView:(UIView *)view {
    if (!view || [_protectedViews containsObject:view]) return;
    [_protectedViews addObject:view];

    if (!_secureField) {
        _secureField = [[UITextField alloc] initWithFrame:view.bounds];
        _secureField.secureTextEntry = YES;
        _secureField.userInteractionEnabled = NO;
        _secureField.alpha = 0.0001; // almost invisible container
    }

    // Find the private secured layer subview
    UIView *secureContainer = nil;
    for (UIView *sub in _secureField.subviews) {
        // The class name contains "ContentBackdrop" or starts with "UITextField"
        if ([NSStringFromClass(sub.class) containsString:@"TextField"] ||
            [NSStringFromClass(sub.class) containsString:@"Backdrop"] ||
            [NSStringFromClass(sub.class) containsString:@"Content"]) {
            secureContainer = sub;
            break;
        }
    }

    if (secureContainer) {
        [secureContainer addSubview:view];
        view.frame = secureContainer.bounds;
        view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
}

- (void)removeFromView:(UIView *)view {
    [_protectedViews removeObject:view];
    if (view.superview == _secureField || [_secureField.subviews containsObject:view.superview]) {
        [view removeFromSuperview];
    }
}

@end
