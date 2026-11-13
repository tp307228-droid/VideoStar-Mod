// FloatingButton.m
#import "FloatingButton.h"
#import "Theme.h"
#import "SVGIcons.h"

static const CGFloat kBtnSize = 54.0;

@interface FloatingButton ()
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) CAGradientLayer *gradLayer;
@property (nonatomic, strong) UIView *pulseRing;
@property (nonatomic, assign) CGPoint lastPos;
@property (nonatomic, assign) BOOL isDragging;
@end

@implementation FloatingButton

+ (instancetype)sharedInstance {
    static FloatingButton *s;
    static dispatch_once_t t;
    dispatch_once(&t, ^{ s = [[FloatingButton alloc] initWithFrame:CGRectMake(20, 100, kBtnSize, kBtnSize)]; });
    return s;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;
    self.layer.cornerRadius = kBtnSize / 2;
    self.clipsToBounds = NO;

    // Pulse ring
    _pulseRing = [[UIView alloc] initWithFrame:CGRectMake(-8, -8, kBtnSize+16, kBtnSize+16)];
    _pulseRing.layer.cornerRadius = (kBtnSize+16)/2;
    _pulseRing.layer.borderWidth = 2;
    _pulseRing.layer.borderColor = FVD_ACCENT.CGColor;
    _pulseRing.alpha = 0;
    [self addSubview:_pulseRing];

    // Gradient background
    _gradLayer = FVDMakeGradient(FVD_ACCENT, FVD_ACCENT2, 135);
    _gradLayer.frame = CGRectMake(0,0,kBtnSize,kBtnSize);
    _gradLayer.cornerRadius = kBtnSize/2;
    [self.layer addSublayer:_gradLayer];

    // Shadow
    self.layer.shadowColor = FVD_ACCENT.CGColor;
    self.layer.shadowOffset = CGSizeZero;
    self.layer.shadowRadius = 12;
    self.layer.shadowOpacity = 0.6;

    // Icon
    UIImage *icon = FVDICON(FVDIconStar, 24, [UIColor whiteColor]);
    _iconView = [[UIImageView alloc] initWithImage:icon];
    _iconView.frame = CGRectMake(15, 15, 24, 24);
    [self addSubview:_iconView];

    // Gestures
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap)];
    [self addGestureRecognizer:pan];
    [self addGestureRecognizer:tap];
    [tap requireGestureRecognizerToFail:pan];

    [self startPulse];
    return self;
}

- (void)showInWindow:(UIWindow *)window {
    if (self.superview) return;
    CGFloat x = window.bounds.size.width - kBtnSize - 20;
    CGFloat y = window.bounds.size.height * 0.35;
    self.frame = CGRectMake(x, y, kBtnSize, kBtnSize);
    [window addSubview:self];
    self.alpha = 0;
    self.transform = CGAffineTransformMakeScale(0.5, 0.5);
    [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:0.8 options:0 animations:^{
        self.alpha = 1;
        self.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)hide {
    [UIView animateWithDuration:0.25 animations:^{ self.alpha = 0; self.transform = CGAffineTransformMakeScale(0.5,0.5); }
        completion:^(BOOL done){ self.hidden = YES; }];
}

- (void)show {
    self.hidden = NO;
    [UIView animateWithDuration:0.35 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:0 options:0 animations:^{
        self.alpha = 1;
        self.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)handleTap {
    [UIView animateWithDuration:0.1 animations:^{ self.transform = CGAffineTransformMakeScale(0.88, 0.88); }
        completion:^(BOOL d){
            [UIView animateWithDuration:0.2 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0 options:0 animations:^{
                self.transform = CGAffineTransformIdentity;
            } completion:nil];
            if ([self.delegate respondsToSelector:@selector(floatingButtonTapped)]) {
                [self.delegate floatingButtonTapped];
            }
        }];
}

- (void)handlePan:(UIPanGestureRecognizer *)g {
    UIView *sv = self.superview;
    if (!sv) return;
    CGPoint translation = [g translationInView:sv];
    CGPoint center = CGPointMake(self.center.x + translation.x, self.center.y + translation.y);

    // Clamp to screen
    CGFloat half = kBtnSize / 2;
    center.x = MAX(half + 8, MIN(sv.bounds.size.width - half - 8, center.x));
    center.y = MAX(half + 44, MIN(sv.bounds.size.height - half - 34, center.y));
    self.center = center;
    [g setTranslation:CGPointZero inView:sv];

    if (g.state == UIGestureRecognizerStateEnded) {
        // Snap to nearest edge
        BOOL snapLeft = (center.x < sv.bounds.size.width / 2);
        CGFloat targetX = snapLeft ? (half + 8) : (sv.bounds.size.width - half - 8);
        [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0 options:0 animations:^{
            self.center = CGPointMake(targetX, self.center.y);
        } completion:nil];
    }
}

- (void)startPulse {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.8 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.pulseRing.transform = CGAffineTransformMakeScale(1.6, 1.6);
            self.pulseRing.alpha = 0.6;
        } completion:^(BOOL d){
            [UIView animateWithDuration:0.8 animations:^{
                self.pulseRing.alpha = 0;
                self.pulseRing.transform = CGAffineTransformIdentity;
            } completion:^(BOOL d2){
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self startPulse];
                });
            }];
        }];
    });
}

@end
