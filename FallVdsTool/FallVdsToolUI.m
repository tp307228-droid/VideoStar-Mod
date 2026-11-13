// FallVdsToolUI.m
// Main controller: floating button → full-screen overlay menu
// Tabs: Tính Năng | Bản Quyền
// Features: MediaReplacer, QRImporter, HideStream toggle

#import "FallVdsToolUI.h"
#import "FloatingButton.h"
#import "HideStream.h"
#import "LicenseVC.h"
#import "MediaReplacerVC.h"
#import "QRImporterVC.h"
#import "LicenseManager.h"
#import "Theme.h"
#import "SVGIcons.h"
#import <objc/runtime.h>

// ════════════════════════════════════════════════════════
// MARK: - Overlay Window (above all)
// ════════════════════════════════════════════════════════
@interface FVDOverlayWindow : UIWindow
@end
@implementation FVDOverlayWindow
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    // Pass touches through when menu is hidden (only hit the floating button)
    for (UIView *sub in self.subviews) {
        if (!sub.hidden && [sub pointInside:[self convertPoint:point toView:sub] withEvent:event]) {
            return YES;
        }
    }
    return NO;
}
@end

// ════════════════════════════════════════════════════════
// MARK: - Menu View Controller
// ════════════════════════════════════════════════════════
@interface FVDMenuVC : UIViewController <FloatingButtonDelegate>
@property (nonatomic, strong) UIView        *menuContainer;
@property (nonatomic, strong) UIView        *tabBar;
@property (nonatomic, strong) UIButton      *tabFeatures;
@property (nonatomic, strong) UIButton      *tabLicense;
@property (nonatomic, strong) UIView        *tabIndicator;
@property (nonatomic, strong) UIPageViewController *pageVC;
@property (nonatomic, strong) MediaReplacerVC *mediaVC;
@property (nonatomic, strong) QRImporterVC   *qrVC;
@property (nonatomic, strong) LicenseVC      *licenseVC;
@property (nonatomic, strong) UIView        *featurePager; // container for inner feature tabs
@property (nonatomic, strong) UIButton      *featTabMedia;
@property (nonatomic, strong) UIButton      *featTabQR;
@property (nonatomic, strong) UIButton      *featTabHide;
@property (nonatomic, strong) UIView        *featIndicator;
@property (nonatomic, assign) NSInteger      selectedMainTab;   // 0=features, 1=license
@property (nonatomic, assign) NSInteger      selectedFeatTab;   // 0=media, 1=qr, 2=hide
@property (nonatomic, weak)   FallVdsToolUI  *owner;
@end

@implementation FVDMenuVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.clearColor;
    [self buildMenu];
}

- (void)buildMenu {
    // ── Backdrop blur ─────────────────────────────────────
    UIView *backdrop = [[UIView alloc] initWithFrame:self.view.bounds];
    backdrop.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
    backdrop.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    UITapGestureRecognizer *tapClose = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeMenu)];
    [backdrop addGestureRecognizer:tapClose];
    [self.view addSubview:backdrop];

    // ── Menu Container ────────────────────────────────────
    _menuContainer = [[UIView alloc] init];
    _menuContainer.translatesAutoresizingMaskIntoConstraints = NO;
    _menuContainer.backgroundColor   = FVD_BG;
    _menuContainer.layer.cornerRadius = FVD_R_XL;
    _menuContainer.clipsToBounds      = YES;
    _menuContainer.layer.shadowColor  = UIColor.blackColor.CGColor;
    _menuContainer.layer.shadowRadius = 24;
    _menuContainer.layer.shadowOpacity = 0.5;
    _menuContainer.layer.shadowOffset  = CGSizeZero;
    [self.view addSubview:_menuContainer];

    // ── Gradient top bar ──────────────────────────────────
    UIView *topBar = [[UIView alloc] init];
    topBar.translatesAutoresizingMaskIntoConstraints = NO;

    CAGradientLayer *topGrad = FVDMakeGradient(
        [UIColor colorWithRed:0.3 green:0.1 blue:0.6 alpha:1.0],
        FVD_BG, 180);
    topGrad.frame = CGRectMake(0,0,10,10);
    [topBar.layer addSublayer:topGrad];

    // Brand logo + title
    UIImageView *starIcon = [[UIImageView alloc] initWithImage:FVDICON(FVDIconStar, 20, [UIColor colorWithRed:1 green:0.85 blue:0.1 alpha:1])];
    starIcon.translatesAutoresizingMaskIntoConstraints = NO;
    starIcon.contentMode = UIViewContentModeScaleAspectFit;

    UILabel *brandTitle = [UILabel new];
    brandTitle.translatesAutoresizingMaskIntoConstraints = NO;
    brandTitle.text = @"FallVds Tool";
    brandTitle.font = [UIFont systemFontOfSize:17 weight:UIFontWeightBold];
    brandTitle.textColor = FVD_TEXT;

    UILabel *versionBadge = [UILabel new];
    versionBadge.translatesAutoresizingMaskIntoConstraints = NO;
    versionBadge.text = @"BETA";
    versionBadge.font = [UIFont systemFontOfSize:9 weight:UIFontWeightBold];
    versionBadge.textColor = FVD_ACCENT;
    versionBadge.backgroundColor = [UIColor colorWithRed:0.55 green:0.25 blue:1 alpha:0.2];
    versionBadge.layer.cornerRadius = 4;
    versionBadge.clipsToBounds = YES;
    UIView *vBadgePad = [[UIView alloc] init]; // padding wrapper
    vBadgePad.translatesAutoresizingMaskIntoConstraints = NO;

    // Close button
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    closeBtn.translatesAutoresizingMaskIntoConstraints = NO;
    closeBtn.backgroundColor = [UIColor colorWithWhite:1 alpha:0.08];
    closeBtn.layer.cornerRadius = 15;
    UIImageView *closeIcon = [[UIImageView alloc] initWithImage:FVDICON(FVDIconClose, 14, FVD_SUBTEXT)];
    closeIcon.translatesAutoresizingMaskIntoConstraints = NO;
    closeIcon.contentMode = UIViewContentModeScaleAspectFit;
    [closeBtn addSubview:closeIcon];
    [closeBtn addTarget:self action:@selector(closeMenu) forControlEvents:UIControlEventTouchUpInside];

    [NSLayoutConstraint activateConstraints:@[
        [closeIcon.centerXAnchor constraintEqualToAnchor:closeBtn.centerXAnchor],
        [closeIcon.centerYAnchor constraintEqualToAnchor:closeBtn.centerYAnchor],
        [closeIcon.widthAnchor constraintEqualToConstant:14],
        [closeIcon.heightAnchor constraintEqualToConstant:14],
        [closeBtn.widthAnchor constraintEqualToConstant:30],
        [closeBtn.heightAnchor constraintEqualToConstant:30],
    ]];

    [topBar addSubview:starIcon];
    [topBar addSubview:brandTitle];
    [topBar addSubview:versionBadge];
    [topBar addSubview:closeBtn];

    [NSLayoutConstraint activateConstraints:@[
        [starIcon.leadingAnchor constraintEqualToAnchor:topBar.leadingAnchor constant:16],
        [starIcon.centerYAnchor constraintEqualToAnchor:topBar.centerYAnchor],
        [starIcon.widthAnchor constraintEqualToConstant:20],
        [starIcon.heightAnchor constraintEqualToConstant:20],
        [brandTitle.leadingAnchor constraintEqualToAnchor:starIcon.trailingAnchor constant:8],
        [brandTitle.centerYAnchor constraintEqualToAnchor:topBar.centerYAnchor],
        [versionBadge.leadingAnchor constraintEqualToAnchor:brandTitle.trailingAnchor constant:6],
        [versionBadge.centerYAnchor constraintEqualToAnchor:topBar.centerYAnchor],
        [versionBadge.widthAnchor constraintEqualToConstant:36],
        [versionBadge.heightAnchor constraintEqualToConstant:16],
        [closeBtn.trailingAnchor constraintEqualToAnchor:topBar.trailingAnchor constant:-16],
        [closeBtn.centerYAnchor constraintEqualToAnchor:topBar.centerYAnchor],
        [topBar.heightAnchor constraintEqualToConstant:52],
    ]];

    // ── Main Tab Bar ──────────────────────────────────────
    _tabBar = [[UIView alloc] init];
    _tabBar.translatesAutoresizingMaskIntoConstraints = NO;
    _tabBar.backgroundColor = FVD_CARD;

    _tabFeatures = [self makeMainTabButton:@"Tính Năng" icon:FVDIconStar];
    _tabLicense  = [self makeMainTabButton:@"Bản Quyền" icon:FVDIconShield];
    [_tabFeatures addTarget:self action:@selector(selectFeaturesTab) forControlEvents:UIControlEventTouchUpInside];
    [_tabLicense  addTarget:self action:@selector(selectLicenseTab)  forControlEvents:UIControlEventTouchUpInside];

    _tabIndicator = [[UIView alloc] init];
    _tabIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    _tabIndicator.backgroundColor = FVD_ACCENT;
    _tabIndicator.layer.cornerRadius = 1.5;

    [_tabBar addSubview:_tabFeatures];
    [_tabBar addSubview:_tabLicense];
    [_tabBar addSubview:_tabIndicator];

    [NSLayoutConstraint activateConstraints:@[
        [_tabFeatures.leadingAnchor constraintEqualToAnchor:_tabBar.leadingAnchor],
        [_tabFeatures.topAnchor constraintEqualToAnchor:_tabBar.topAnchor],
        [_tabFeatures.bottomAnchor constraintEqualToAnchor:_tabBar.bottomAnchor constant:-3],
        [_tabFeatures.widthAnchor constraintEqualToAnchor:_tabBar.widthAnchor multiplier:0.5],

        [_tabLicense.trailingAnchor constraintEqualToAnchor:_tabBar.trailingAnchor],
        [_tabLicense.topAnchor constraintEqualToAnchor:_tabBar.topAnchor],
        [_tabLicense.bottomAnchor constraintEqualToAnchor:_tabBar.bottomAnchor constant:-3],
        [_tabLicense.widthAnchor constraintEqualToAnchor:_tabBar.widthAnchor multiplier:0.5],

        [_tabIndicator.bottomAnchor constraintEqualToAnchor:_tabBar.bottomAnchor],
        [_tabIndicator.heightAnchor constraintEqualToConstant:3],
        [_tabIndicator.widthAnchor constraintEqualToAnchor:_tabBar.widthAnchor multiplier:0.5],
        [_tabIndicator.leadingAnchor constraintEqualToAnchor:_tabBar.leadingAnchor],

        [_tabBar.heightAnchor constraintEqualToConstant:46],
    ]];

    // ── Feature Sub-Tab ───────────────────────────────────
    _featurePager = [[UIView alloc] init];
    _featurePager.translatesAutoresizingMaskIntoConstraints = NO;
    _featurePager.backgroundColor = FVD_BG;

    UIView *featTabBar = [[UIView alloc] init];
    featTabBar.translatesAutoresizingMaskIntoConstraints = NO;
    featTabBar.backgroundColor = FVD_CARD2;
    featTabBar.layer.cornerRadius = FVD_R_SM;

    _featTabMedia = [self makeFeatureTabButton:@"Thay Media" icon:FVDIconImage];
    _featTabQR    = [self makeFeatureTabButton:@"Nhập QR"    icon:FVDIconQR];
    _featTabHide  = [self makeFeatureTabButton:@"Ẩn Tool"    icon:FVDIconEyeOff];

    [_featTabMedia addTarget:self action:@selector(selectFeatMedia) forControlEvents:UIControlEventTouchUpInside];
    [_featTabQR    addTarget:self action:@selector(selectFeatQR)    forControlEvents:UIControlEventTouchUpInside];
    [_featTabHide  addTarget:self action:@selector(selectFeatHide)  forControlEvents:UIControlEventTouchUpInside];

    _featIndicator = [[UIView alloc] init];
    _featIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    _featIndicator.backgroundColor = FVD_ACCENT;
    _featIndicator.layer.cornerRadius = FVD_R_SM - 2;

    [featTabBar addSubview:_featIndicator];
    [featTabBar addSubview:_featTabMedia];
    [featTabBar addSubview:_featTabQR];
    [featTabBar addSubview:_featTabHide];

    [NSLayoutConstraint activateConstraints:@[
        [_featTabMedia.leadingAnchor constraintEqualToAnchor:featTabBar.leadingAnchor constant:4],
        [_featTabMedia.topAnchor constraintEqualToAnchor:featTabBar.topAnchor constant:4],
        [_featTabMedia.bottomAnchor constraintEqualToAnchor:featTabBar.bottomAnchor constant:-4],
        [_featTabMedia.widthAnchor constraintEqualToAnchor:featTabBar.widthAnchor multiplier:1.0/3.0 constant:-8.0/3.0],

        [_featTabQR.leadingAnchor constraintEqualToAnchor:_featTabMedia.trailingAnchor constant:2],
        [_featTabQR.topAnchor constraintEqualToAnchor:featTabBar.topAnchor constant:4],
        [_featTabQR.bottomAnchor constraintEqualToAnchor:featTabBar.bottomAnchor constant:-4],
        [_featTabQR.widthAnchor constraintEqualToAnchor:_featTabMedia.widthAnchor],

        [_featTabHide.trailingAnchor constraintEqualToAnchor:featTabBar.trailingAnchor constant:-4],
        [_featTabHide.topAnchor constraintEqualToAnchor:featTabBar.topAnchor constant:4],
        [_featTabHide.bottomAnchor constraintEqualToAnchor:featTabBar.bottomAnchor constant:-4],
        [_featTabHide.widthAnchor constraintEqualToAnchor:_featTabMedia.widthAnchor],

        [_featIndicator.topAnchor constraintEqualToAnchor:featTabBar.topAnchor constant:4],
        [_featIndicator.bottomAnchor constraintEqualToAnchor:featTabBar.bottomAnchor constant:-4],
        [_featIndicator.widthAnchor constraintEqualToAnchor:_featTabMedia.widthAnchor],
        [_featIndicator.leadingAnchor constraintEqualToAnchor:featTabBar.leadingAnchor constant:4],

        [featTabBar.heightAnchor constraintEqualToConstant:40],
    ]];

    // ── Embed child VCs ───────────────────────────────────
    _mediaVC   = [MediaReplacerVC new];
    _qrVC      = [QRImporterVC new];
    _licenseVC = [LicenseVC new];
    UIView *hideView = [self buildHideStreamView];

    [self addChildViewController:_mediaVC];
    [self addChildViewController:_qrVC];
    [self addChildViewController:_licenseVC];

    _mediaVC.view.translatesAutoresizingMaskIntoConstraints = NO;
    _qrVC.view.translatesAutoresizingMaskIntoConstraints    = NO;
    _licenseVC.view.translatesAutoresizingMaskIntoConstraints = NO;
    hideView.translatesAutoresizingMaskIntoConstraints = NO;

    [_featurePager addSubview:featTabBar];
    [_featurePager addSubview:_mediaVC.view];
    [_featurePager addSubview:_qrVC.view];
    [_featurePager addSubview:hideView];
    [_menuContainer addSubview:topBar];
    [_menuContainer addSubview:_tabBar];
    [_menuContainer addSubview:_featurePager];
    [_menuContainer addSubview:_licenseVC.view];

    [_mediaVC didMoveToParentViewController:self];
    [_qrVC didMoveToParentViewController:self];
    [_licenseVC didMoveToParentViewController:self];

    for (UIView *v in @[_mediaVC.view, _qrVC.view, hideView]) {
        [NSLayoutConstraint activateConstraints:@[
            [v.topAnchor constraintEqualToAnchor:featTabBar.bottomAnchor constant:8],
            [v.leadingAnchor constraintEqualToAnchor:_featurePager.leadingAnchor],
            [v.trailingAnchor constraintEqualToAnchor:_featurePager.trailingAnchor],
            [v.bottomAnchor constraintEqualToAnchor:_featurePager.bottomAnchor],
        ]];
    }

    [NSLayoutConstraint activateConstraints:@[
        [featTabBar.topAnchor constraintEqualToAnchor:_featurePager.topAnchor constant:8],
        [featTabBar.leadingAnchor constraintEqualToAnchor:_featurePager.leadingAnchor constant:14],
        [featTabBar.trailingAnchor constraintEqualToAnchor:_featurePager.trailingAnchor constant:-14],

        [_licenseVC.view.topAnchor constraintEqualToAnchor:_tabBar.bottomAnchor],
        [_licenseVC.view.leadingAnchor constraintEqualToAnchor:_menuContainer.leadingAnchor],
        [_licenseVC.view.trailingAnchor constraintEqualToAnchor:_menuContainer.trailingAnchor],
        [_licenseVC.view.bottomAnchor constraintEqualToAnchor:_menuContainer.bottomAnchor],
    ]];

    // ── Menu Container constraints ────────────────────────
    [NSLayoutConstraint activateConstraints:@[
        [topBar.topAnchor constraintEqualToAnchor:_menuContainer.topAnchor],
        [topBar.leadingAnchor constraintEqualToAnchor:_menuContainer.leadingAnchor],
        [topBar.trailingAnchor constraintEqualToAnchor:_menuContainer.trailingAnchor],

        [_tabBar.topAnchor constraintEqualToAnchor:topBar.bottomAnchor],
        [_tabBar.leadingAnchor constraintEqualToAnchor:_menuContainer.leadingAnchor],
        [_tabBar.trailingAnchor constraintEqualToAnchor:_menuContainer.trailingAnchor],

        [_featurePager.topAnchor constraintEqualToAnchor:_tabBar.bottomAnchor],
        [_featurePager.leadingAnchor constraintEqualToAnchor:_menuContainer.leadingAnchor],
        [_featurePager.trailingAnchor constraintEqualToAnchor:_menuContainer.trailingAnchor],
        [_featurePager.bottomAnchor constraintEqualToAnchor:_menuContainer.bottomAnchor],

        [_menuContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:14],
        [_menuContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-14],
        [_menuContainer.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-10],
        [_menuContainer.heightAnchor constraintEqualToAnchor:self.view.heightAnchor multiplier:0.78],
    ]];

    // Initial state
    _selectedMainTab = 0;
    _selectedFeatTab = 0;
    [self updateMainTabUI];
    [self updateFeatTabUI];

    // Top gradient resize in layoutSubviews
    objc_setAssociatedObject(topBar, "topGrad", topGrad, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    // Resize top gradient
    for (UIView *sub in _menuContainer.subviews) {
        CALayer *tg = objc_getAssociatedObject(sub, "topGrad");
        if (tg) tg.frame = sub.bounds;
    }
}

// ── MARK: Tab Buttons ─────────────────────────────────────────────────────────
- (UIButton *)makeMainTabButton:(NSString *)title icon:(FVDIcon)icon {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.translatesAutoresizingMaskIntoConstraints = NO;

    UIImageView *iv = [[UIImageView alloc] initWithImage:FVDICON(icon, 16, FVD_SUBTEXT)];
    iv.translatesAutoresizingMaskIntoConstraints = NO;
    iv.contentMode = UIViewContentModeScaleAspectFit;
    iv.tag = 101;

    UILabel *lbl = [UILabel new];
    lbl.translatesAutoresizingMaskIntoConstraints = NO;
    lbl.text = title;
    lbl.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    lbl.textColor = FVD_SUBTEXT;
    lbl.tag = 102;

    [btn addSubview:iv];
    [btn addSubview:lbl];
    [NSLayoutConstraint activateConstraints:@[
        [iv.centerYAnchor constraintEqualToAnchor:btn.centerYAnchor],
        [iv.trailingAnchor constraintEqualToAnchor:lbl.leadingAnchor constant:-5],
        [lbl.centerYAnchor constraintEqualToAnchor:btn.centerYAnchor],
        [lbl.centerXAnchor constraintEqualToAnchor:btn.centerXAnchor constant:10],
        [iv.widthAnchor constraintEqualToConstant:16],
        [iv.heightAnchor constraintEqualToConstant:16],
    ]];
    return btn;
}

- (UIButton *)makeFeatureTabButton:(NSString *)title icon:(FVDIcon)icon {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    btn.layer.cornerRadius = FVD_R_SM - 2;

    UIImageView *iv = [[UIImageView alloc] initWithImage:FVDICON(icon, 13, FVD_SUBTEXT)];
    iv.translatesAutoresizingMaskIntoConstraints = NO;
    iv.contentMode = UIViewContentModeScaleAspectFit;
    iv.tag = 101;

    UILabel *lbl = [UILabel new];
    lbl.translatesAutoresizingMaskIntoConstraints = NO;
    lbl.text = title;
    lbl.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
    lbl.textColor = FVD_SUBTEXT;
    lbl.adjustsFontSizeToFitWidth = YES;
    lbl.tag = 102;

    [btn addSubview:iv];
    [btn addSubview:lbl];
    [NSLayoutConstraint activateConstraints:@[
        [iv.centerYAnchor constraintEqualToAnchor:btn.centerYAnchor],
        [iv.leadingAnchor constraintEqualToAnchor:btn.leadingAnchor constant:6],
        [iv.widthAnchor constraintEqualToConstant:13],
        [iv.heightAnchor constraintEqualToConstant:13],
        [lbl.centerYAnchor constraintEqualToAnchor:btn.centerYAnchor],
        [lbl.leadingAnchor constraintEqualToAnchor:iv.trailingAnchor constant:4],
        [lbl.trailingAnchor constraintEqualToAnchor:btn.trailingAnchor constant:-4],
    ]];
    return btn;
}

// ── MARK: Tab Selection ───────────────────────────────────────────────────────
- (void)selectFeaturesTab {
    _selectedMainTab = 0;
    [self updateMainTabUI];
}
- (void)selectLicenseTab {
    _selectedMainTab = 1;
    [self updateMainTabUI];
}

- (void)updateMainTabUI {
    BOOL features = (_selectedMainTab == 0);
    _featurePager.hidden  = !features;
    _licenseVC.view.hidden = features;

    UIColor *activeColor = FVD_ACCENT;
    UIColor *inactiveColor = FVD_SUBTEXT;

    for (UIView *sub in _tabFeatures.subviews) {
        if (sub.tag == 102) ((UILabel *)sub).textColor = features ? activeColor : inactiveColor;
        if (sub.tag == 101) ((UIImageView *)sub).image = FVDICON(FVDIconStar, 16, features ? activeColor : inactiveColor);
    }
    for (UIView *sub in _tabLicense.subviews) {
        if (sub.tag == 102) ((UILabel *)sub).textColor = !features ? activeColor : inactiveColor;
        if (sub.tag == 101) ((UIImageView *)sub).image = FVDICON(FVDIconShield, 16, !features ? activeColor : inactiveColor);
    }

    // Slide indicator
    [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0 options:0 animations:^{
        CGFloat x = features ? 0 : self.tabBar.bounds.size.width / 2;
        self.tabIndicator.transform = CGAffineTransformMakeTranslation(x, 0);
    } completion:nil];
}

- (void)selectFeatMedia { _selectedFeatTab = 0; [self updateFeatTabUI]; }
- (void)selectFeatQR    { _selectedFeatTab = 1; [self updateFeatTabUI]; }
- (void)selectFeatHide  { _selectedFeatTab = 2; [self updateFeatTabUI]; }

- (void)updateFeatTabUI {
    NSArray<UIButton *> *tabs = @[_featTabMedia, _featTabQR, _featTabHide];

    for (NSInteger i = 0; i < 3; i++) {
        BOOL active = (i == _selectedFeatTab);
        UIButton *btn = tabs[i];
        for (UIView *sub in btn.subviews) {
            if (sub.tag == 102) ((UILabel *)sub).textColor = active ? FVD_TEXT : FVD_SUBTEXT;
        }
    }
    _mediaVC.view.hidden = (_selectedFeatTab != 0);
    _qrVC.view.hidden    = (_selectedFeatTab != 1);
    UIView *hideV = [_featurePager viewWithTag:777];
    if (hideV) hideV.hidden = (_selectedFeatTab != 2);

    // Slide feat indicator
    NSArray<UIButton *> *btns = @[_featTabMedia, _featTabQR, _featTabHide];
    UIButton *target = btns[_selectedFeatTab];
    [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0 options:0 animations:^{
        self.featIndicator.frame = CGRectMake(target.frame.origin.x - 4 + 4,
                                              self.featIndicator.frame.origin.y,
                                              target.frame.size.width,
                                              self.featIndicator.frame.size.height);
    } completion:nil];
}

// ── MARK: Hide Stream View ────────────────────────────────────────────────────
- (UIView *)buildHideStreamView {
    UIScrollView *scroll = [[UIScrollView alloc] init];
    scroll.tag = 777;
    scroll.showsVerticalScrollIndicator = NO;

    UIView *container = [[UIView alloc] init];
    container.translatesAutoresizingMaskIntoConstraints = NO;
    [scroll addSubview:container];

    // Header card
    UIView *card = [[UIView alloc] init];
    card.translatesAutoresizingMaskIntoConstraints = NO;
    card.backgroundColor = [UIColor colorWithRed:0.05 green:0.15 blue:0.1 alpha:1];
    card.layer.cornerRadius = FVD_R_MD;
    card.layer.borderWidth  = 1;
    card.layer.borderColor  = [UIColor colorWithRed:0.2 green:0.9 blue:0.55 alpha:0.3].CGColor;

    UIImageView *eyeIcon = [[UIImageView alloc] initWithImage:FVDICON(FVDIconEyeOff, 36, FVD_GREEN)];
    eyeIcon.translatesAutoresizingMaskIntoConstraints = NO;
    eyeIcon.contentMode = UIViewContentModeScaleAspectFit;

    UILabel *title = [UILabel new];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    title.text = @"Hide of Stream";
    title.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    title.textColor = FVD_TEXT;
    title.textAlignment = NSTextAlignmentCenter;

    UILabel *desc = [UILabel new];
    desc.translatesAutoresizingMaskIntoConstraints = NO;
    desc.text = @"Ẩn tool khỏi quay màn hình, chụp màn hình & live stream. Tool sẽ không xuất hiện trong video hoặc screenshot.";
    desc.font = [UIFont systemFontOfSize:12];
    desc.textColor = FVD_SUBTEXT;
    desc.numberOfLines = 0;
    desc.textAlignment = NSTextAlignmentCenter;

    UISwitch *toggle = [[UISwitch alloc] init];
    toggle.translatesAutoresizingMaskIntoConstraints = NO;
    toggle.onTintColor = FVD_GREEN;
    toggle.on = [HideStream sharedInstance].enabled;
    [toggle addTarget:self action:@selector(toggleHideStream:) forControlEvents:UIControlEventValueChanged];

    UILabel *toggleLabel = [UILabel new];
    toggleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    toggleLabel.text = @"Bật / Tắt";
    toggleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    toggleLabel.textColor = FVD_TEXT;

    // Status indicator
    UILabel *statusLabel = [UILabel new];
    statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    statusLabel.text = toggle.on ? @"🟢 Đang bảo vệ" : @"🔴 Đã tắt";
    statusLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    statusLabel.textColor = toggle.on ? FVD_GREEN : FVD_RED;
    statusLabel.textAlignment = NSTextAlignmentCenter;
    statusLabel.tag = 888;

    [card addSubview:eyeIcon];
    [card addSubview:title];
    [card addSubview:desc];
    [card addSubview:toggleLabel];
    [card addSubview:toggle];
    [card addSubview:statusLabel];

    [NSLayoutConstraint activateConstraints:@[
        [eyeIcon.topAnchor constraintEqualToAnchor:card.topAnchor constant:20],
        [eyeIcon.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],
        [eyeIcon.widthAnchor constraintEqualToConstant:36],
        [eyeIcon.heightAnchor constraintEqualToConstant:36],
        [title.topAnchor constraintEqualToAnchor:eyeIcon.bottomAnchor constant:10],
        [title.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],
        [desc.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:8],
        [desc.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],
        [desc.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16],
        [toggleLabel.topAnchor constraintEqualToAnchor:desc.bottomAnchor constant:16],
        [toggleLabel.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],
        [toggleLabel.centerYAnchor constraintEqualToAnchor:toggle.centerYAnchor],
        [toggle.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16],
        [toggle.topAnchor constraintEqualToAnchor:desc.bottomAnchor constant:14],
        [statusLabel.topAnchor constraintEqualToAnchor:toggle.bottomAnchor constant:12],
        [statusLabel.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],
        [statusLabel.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-16],
    ]];

    [container addSubview:card];
    [NSLayoutConstraint activateConstraints:@[
        [card.topAnchor constraintEqualToAnchor:container.topAnchor constant:12],
        [card.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:14],
        [card.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-14],
        [card.bottomAnchor constraintEqualToAnchor:container.bottomAnchor constant:-20],
        [container.widthAnchor constraintEqualToAnchor:scroll.widthAnchor],
    ]];

    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [container.topAnchor constraintEqualToAnchor:scroll.topAnchor],
        [container.bottomAnchor constraintEqualToAnchor:scroll.bottomAnchor],
    ]];

    return scroll;
}

- (void)toggleHideStream:(UISwitch *)sw {
    [HideStream sharedInstance].enabled = sw.on;
    // Update status label (find by tag)
    UIView *statusV = [_featurePager viewWithTag:888];
    if ([statusV isKindOfClass:[UILabel class]]) {
        UILabel *l = (UILabel *)statusV;
        l.text = sw.on ? @"🟢 Đang bảo vệ" : @"🔴 Đã tắt";
        l.textColor = sw.on ? FVD_GREEN : FVD_RED;
    }
}

// ── MARK: Close ───────────────────────────────────────────────────────────────
- (void)closeMenu {
    if ([_owner respondsToSelector:@selector(hideMenu)]) {
        [_owner hideMenu];
    }
}

- (void)floatingButtonTapped { [self closeMenu]; }

@end

// ════════════════════════════════════════════════════════
// MARK: - FallVdsToolUI (main controller)
// ════════════════════════════════════════════════════════
@interface FallVdsToolUI () <FloatingButtonDelegate>
@property (nonatomic, strong) FVDOverlayWindow *overlayWindow;
@property (nonatomic, strong) FVDMenuVC        *menuVC;
@property (nonatomic, assign) BOOL              menuVisible;
@end

@implementation FallVdsToolUI

+ (instancetype)sharedInstance {
    static FallVdsToolUI *s;
    static dispatch_once_t t;
    dispatch_once(&t, ^{ s = [self new]; });
    return s;
}

- (void)launch {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setupOverlayWindow];
        [self showProPopupIfNeeded];
    });
}

- (void)setupOverlayWindow {
    UIWindowScene *scene = nil;
    for (UIWindowScene *s in [UIApplication sharedApplication].connectedScenes) {
        if ([s isKindOfClass:[UIWindowScene class]] && s.activationState == UISceneActivationStateForegroundActive) {
            scene = s; break;
        }
    }

    _overlayWindow = [[FVDOverlayWindow alloc] initWithWindowScene:scene];
    _overlayWindow.windowLevel = UIWindowLevelStatusBar + 100;
    _overlayWindow.backgroundColor = UIColor.clearColor;
    _overlayWindow.hidden = NO;

    UIViewController *root = [[UIViewController alloc] init];
    root.view.backgroundColor = UIColor.clearColor;
    root.view.userInteractionEnabled = NO;
    _overlayWindow.rootViewController = root;

    // Add floating button
    FloatingButton *btn = [FloatingButton sharedInstance];
    btn.delegate = self;
    [btn showInWindow:_overlayWindow];
}

- (void)floatingButtonTapped {
    if (_menuVisible) {
        [self hideMenu];
    } else {
        [self showMenu];
    }
}

- (void)showMenu {
    if (_menuVisible) return;
    _menuVisible = YES;

    _menuVC = [FVDMenuVC new];
    _menuVC.owner = self;
    _menuVC.view.translatesAutoresizingMaskIntoConstraints = NO;
    _menuVC.view.alpha = 0;

    UIViewController *root = _overlayWindow.rootViewController;
    root.view.userInteractionEnabled = YES;
    [root addChildViewController:_menuVC];
    [root.view addSubview:_menuVC.view];
    [_menuVC didMoveToParentViewController:root];

    [NSLayoutConstraint activateConstraints:@[
        [_menuVC.view.topAnchor constraintEqualToAnchor:root.view.topAnchor],
        [_menuVC.view.leadingAnchor constraintEqualToAnchor:root.view.leadingAnchor],
        [_menuVC.view.trailingAnchor constraintEqualToAnchor:root.view.trailingAnchor],
        [_menuVC.view.bottomAnchor constraintEqualToAnchor:root.view.bottomAnchor],
    ]];

    _menuVC.menuContainer.transform = CGAffineTransformMakeTranslation(0, 80);
    [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.78 initialSpringVelocity:0.5 options:0 animations:^{
        self.menuVC.view.alpha = 1;
        self.menuVC.menuContainer.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)hideMenu {
    if (!_menuVisible) return;
    [UIView animateWithDuration:0.3 animations:^{
        self.menuVC.view.alpha = 0;
        self.menuVC.menuContainer.transform = CGAffineTransformMakeTranslation(0, 60);
    } completion:^(BOOL done){
        [self.menuVC willMoveToParentViewController:nil];
        [self.menuVC.view removeFromSuperview];
        [self.menuVC removeFromParentViewController];
        self.menuVC = nil;
        self.overlayWindow.rootViewController.view.userInteractionEnabled = NO;
        self.menuVisible = NO;
    }];
}

// ── MARK: Pro Popup ───────────────────────────────────────────────────────────
- (void)showProPopupIfNeeded {
    NSString *key = @"fvd_pro_popup_shown";
    if ([[NSUserDefaults standardUserDefaults] boolForKey:key]) return;
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:key];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self showProPopup];
    });
}

- (void)showProPopup {
    UIWindow *mainWin = nil;
    for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if ([scene isKindOfClass:[UIWindowScene class]]) {
            mainWin = scene.windows.firstObject; break;
        }
    }
    if (!mainWin) return;

    // Backdrop
    UIView *backdrop = [[UIView alloc] initWithFrame:mainWin.bounds];
    backdrop.backgroundColor = [UIColor colorWithWhite:0 alpha:0.65];
    backdrop.tag = 9999;
    [mainWin addSubview:backdrop];

    // Card
    UIView *card = [[UIView alloc] init];
    card.translatesAutoresizingMaskIntoConstraints = NO;
    card.backgroundColor   = [UIColor colorWithRed:0.08 green:0.08 blue:0.12 alpha:1];
    card.layer.cornerRadius = 20;
    card.clipsToBounds      = YES;
    [backdrop addSubview:card];

    // Top gradient
    CAGradientLayer *topG = FVDMakeGradient(FVD_ACCENT, FVD_ACCENT2, 135);
    topG.frame = CGRectMake(0,0,10,80);
    topG.cornerRadius = 20;
    [card.layer addSublayer:topG];

    // Party emoji
    UILabel *party = [UILabel new];
    party.translatesAutoresizingMaskIntoConstraints = NO;
    party.text = @"🎉";
    party.font = [UIFont systemFontOfSize:36];
    party.textAlignment = NSTextAlignmentCenter;

    UILabel *titleLbl = [UILabel new];
    titleLbl.translatesAutoresizingMaskIntoConstraints = NO;
    titleLbl.text = @"Video Star VIP Pro";
    titleLbl.font = [UIFont systemFontOfSize:19 weight:UIFontWeightBold];
    titleLbl.textColor = UIColor.whiteColor;
    titleLbl.textAlignment = NSTextAlignmentCenter;

    UILabel *bodyLbl = [UILabel new];
    bodyLbl.translatesAutoresizingMaskIntoConstraints = NO;
    bodyLbl.text = @"Chào mừng bạn đến với Video Star Pro!\n"
                   @"Hãy tham gia nhóm Discord để nhận cập nhật hiệu ứng mới, preset QR độc quyền và hỗ trợ kỹ thuật miễn phí.";
    bodyLbl.font = [UIFont systemFontOfSize:14];
    bodyLbl.textColor = [UIColor colorWithWhite:0.85 alpha:1];
    bodyLbl.numberOfLines = 0;
    bodyLbl.textAlignment = NSTextAlignmentCenter;

    // Separator
    UIView *sep = [[UIView alloc] init];
    sep.translatesAutoresizingMaskIntoConstraints = NO;
    sep.backgroundColor = [UIColor colorWithWhite:1 alpha:0.1];

    // Buttons row
    UIButton *laterBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    laterBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [laterBtn setTitle:@"Để Sau" forState:UIControlStateNormal];
    [laterBtn setTitleColor:[UIColor colorWithRed:0.9 green:0.3 blue:0.7 alpha:1] forState:UIControlStateNormal];
    laterBtn.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    [laterBtn addTarget:self action:@selector(closeProPopup:) forControlEvents:UIControlEventTouchUpInside];
    laterBtn.tag = 9998;

    UIButton *discordBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    discordBtn.translatesAutoresizingMaskIntoConstraints = NO;
    UIImageView *discordIcon = [[UIImageView alloc] initWithImage:FVDICON(FVDIconDiscord, 16, [UIColor colorWithRed:0.9 green:0.3 blue:0.7 alpha:1])];
    discordIcon.translatesAutoresizingMaskIntoConstraints = NO;
    discordIcon.contentMode = UIViewContentModeScaleAspectFit;
    UILabel *discordLbl = [UILabel new];
    discordLbl.translatesAutoresizingMaskIntoConstraints = NO;
    discordLbl.text = @"Tham Gia Discord";
    discordLbl.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    discordLbl.textColor = [UIColor colorWithRed:0.9 green:0.3 blue:0.7 alpha:1];
    [discordBtn addSubview:discordIcon];
    [discordBtn addSubview:discordLbl];
    [NSLayoutConstraint activateConstraints:@[
        [discordIcon.leadingAnchor constraintEqualToAnchor:discordBtn.leadingAnchor constant:8],
        [discordIcon.centerYAnchor constraintEqualToAnchor:discordBtn.centerYAnchor],
        [discordIcon.widthAnchor constraintEqualToConstant:16],
        [discordIcon.heightAnchor constraintEqualToConstant:16],
        [discordLbl.leadingAnchor constraintEqualToAnchor:discordIcon.trailingAnchor constant:6],
        [discordLbl.centerYAnchor constraintEqualToAnchor:discordBtn.centerYAnchor],
    ]];
    [discordBtn addTarget:self action:@selector(openDiscord:) forControlEvents:UIControlEventTouchUpInside];

    UIView *btnRow = [[UIView alloc] init];
    btnRow.translatesAutoresizingMaskIntoConstraints = NO;
    [btnRow addSubview:laterBtn];
    [btnRow addSubview:discordBtn];
    UIView *midSep = [[UIView alloc] init];
    midSep.translatesAutoresizingMaskIntoConstraints = NO;
    midSep.backgroundColor = [UIColor colorWithWhite:1 alpha:0.1];
    [btnRow addSubview:midSep];

    [NSLayoutConstraint activateConstraints:@[
        [laterBtn.leadingAnchor constraintEqualToAnchor:btnRow.leadingAnchor],
        [laterBtn.topAnchor constraintEqualToAnchor:btnRow.topAnchor],
        [laterBtn.bottomAnchor constraintEqualToAnchor:btnRow.bottomAnchor],
        [laterBtn.widthAnchor constraintEqualToAnchor:btnRow.widthAnchor multiplier:0.5],
        [laterBtn.heightAnchor constraintEqualToConstant:52],
        [midSep.centerXAnchor constraintEqualToAnchor:btnRow.centerXAnchor],
        [midSep.topAnchor constraintEqualToAnchor:btnRow.topAnchor constant:8],
        [midSep.bottomAnchor constraintEqualToAnchor:btnRow.bottomAnchor constant:-8],
        [midSep.widthAnchor constraintEqualToConstant:1],
        [discordBtn.trailingAnchor constraintEqualToAnchor:btnRow.trailingAnchor],
        [discordBtn.topAnchor constraintEqualToAnchor:btnRow.topAnchor],
        [discordBtn.bottomAnchor constraintEqualToAnchor:btnRow.bottomAnchor],
        [discordBtn.widthAnchor constraintEqualToAnchor:btnRow.widthAnchor multiplier:0.5],
    ]];

    [card addSubview:party];
    [card addSubview:titleLbl];
    [card addSubview:bodyLbl];
    [card addSubview:sep];
    [card addSubview:btnRow];

    [NSLayoutConstraint activateConstraints:@[
        [party.topAnchor constraintEqualToAnchor:card.topAnchor constant:24],
        [party.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],
        [titleLbl.topAnchor constraintEqualToAnchor:party.bottomAnchor constant:6],
        [titleLbl.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],
        [bodyLbl.topAnchor constraintEqualToAnchor:titleLbl.bottomAnchor constant:12],
        [bodyLbl.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:20],
        [bodyLbl.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-20],
        [sep.topAnchor constraintEqualToAnchor:bodyLbl.bottomAnchor constant:20],
        [sep.leadingAnchor constraintEqualToAnchor:card.leadingAnchor],
        [sep.trailingAnchor constraintEqualToAnchor:card.trailingAnchor],
        [sep.heightAnchor constraintEqualToConstant:1],
        [btnRow.topAnchor constraintEqualToAnchor:sep.bottomAnchor],
        [btnRow.leadingAnchor constraintEqualToAnchor:card.leadingAnchor],
        [btnRow.trailingAnchor constraintEqualToAnchor:card.trailingAnchor],
        [btnRow.bottomAnchor constraintEqualToAnchor:card.bottomAnchor],

        [card.centerXAnchor constraintEqualToAnchor:backdrop.centerXAnchor],
        [card.centerYAnchor constraintEqualToAnchor:backdrop.centerYAnchor],
        [card.widthAnchor constraintEqualToAnchor:backdrop.widthAnchor multiplier:0.85],
    ]];

    // Animate in
    card.transform = CGAffineTransformMakeScale(0.85, 0.85);
    backdrop.alpha = 0;
    [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.72 initialSpringVelocity:0.5 options:0 animations:^{
        backdrop.alpha = 1;
        card.transform = CGAffineTransformIdentity;
    } completion:nil];

    // Resize top gradient in layout
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        topG.frame = CGRectMake(0,0, card.bounds.size.width, 80);
    });
}

- (void)closeProPopup:(UIButton *)btn {
    UIView *backdrop = btn.superview.superview.superview;
    [UIView animateWithDuration:0.25 animations:^{ backdrop.alpha = 0; }
        completion:^(BOOL d){ [backdrop removeFromSuperview]; }];
}

- (void)openDiscord:(UIButton *)btn {
    NSURL *url = [NSURL URLWithString:@"https://discord.gg/swaggang"];
    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    [self closeProPopup:btn];
}

@end
