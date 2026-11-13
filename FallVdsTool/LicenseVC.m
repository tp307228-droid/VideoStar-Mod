// LicenseVC.m
#import "LicenseVC.h"
#import "LicenseManager.h"
#import "Theme.h"
#import "SVGIcons.h"

// ── Helper: rounded card view ────────────────────────────
@interface FVDCard : UIView
@end
@implementation FVDCard
- (instancetype)init {
    self = [super init];
    self.backgroundColor = FVD_CARD;
    self.layer.cornerRadius = FVD_R_MD;
    self.layer.borderWidth = 1;
    self.layer.borderColor = FVD_BORDER.CGColor;
    self.translatesAutoresizingMaskIntoConstraints = NO;
    return self;
}
@end

// ── Info row ──────────────────────────────────────────────
@interface FVDInfoRow : UIView
- (instancetype)initWithIcon:(FVDIcon)icon label:(NSString *)label value:(NSString *)value;
@property (nonatomic, strong) UILabel *valueLabel;
@end
@implementation FVDInfoRow
- (instancetype)initWithIcon:(FVDIcon)icon label:(NSString *)label value:(NSString *)value {
    self = [super init];
    self.translatesAutoresizingMaskIntoConstraints = NO;

    UIImageView *iv = [[UIImageView alloc] initWithImage:FVDICON(icon, 18, FVD_SUBTEXT)];
    iv.translatesAutoresizingMaskIntoConstraints = NO;
    iv.contentMode = UIViewContentModeScaleAspectFit;

    UILabel *lbl = [UILabel new];
    lbl.translatesAutoresizingMaskIntoConstraints = NO;
    lbl.text = label;
    lbl.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    lbl.textColor = FVD_SUBTEXT;

    _valueLabel = [UILabel new];
    _valueLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _valueLabel.text = value;
    _valueLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    _valueLabel.textColor = FVD_TEXT;
    _valueLabel.textAlignment = NSTextAlignmentRight;
    _valueLabel.numberOfLines = 1;
    _valueLabel.adjustsFontSizeToFitWidth = YES;

    [self addSubview:iv];
    [self addSubview:lbl];
    [self addSubview:_valueLabel];

    [NSLayoutConstraint activateConstraints:@[
        [iv.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [iv.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [iv.widthAnchor constraintEqualToConstant:18],
        [iv.heightAnchor constraintEqualToConstant:18],

        [lbl.leadingAnchor constraintEqualToAnchor:iv.trailingAnchor constant:8],
        [lbl.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],

        [_valueLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [_valueLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [_valueLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:lbl.trailingAnchor constant:8],

        [self.heightAnchor constraintEqualToConstant:36],
    ]];
    return self;
}
@end

// ════════════════════════════════════════════════════════
// MARK: - LicenseVC
// ════════════════════════════════════════════════════════
@interface LicenseVC ()
@property (nonatomic, strong) UIScrollView *scroll;
@property (nonatomic, strong) UIView *content;
@property (nonatomic, strong) FVDInfoRow *rowKey;
@property (nonatomic, strong) FVDInfoRow *rowExpiry;
@property (nonatomic, strong) FVDInfoRow *rowDevice;
@property (nonatomic, strong) FVDInfoRow *rowPkg;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIView *statusDot;
@property (nonatomic, strong) UITextField *keyField;
@end

@implementation LicenseVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.clearColor;
    [self buildUI];
    [self refresh];
}

- (void)buildUI {
    _scroll = [[UIScrollView alloc] init];
    _scroll.translatesAutoresizingMaskIntoConstraints = NO;
    _scroll.showsVerticalScrollIndicator = NO;
    [self.view addSubview:_scroll];

    _content = [[UIView alloc] init];
    _content.translatesAutoresizingMaskIntoConstraints = NO;
    [_scroll addSubview:_content];

    [NSLayoutConstraint activateConstraints:@[
        [_scroll.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [_scroll.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_scroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_scroll.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [_content.topAnchor constraintEqualToAnchor:_scroll.topAnchor],
        [_content.leadingAnchor constraintEqualToAnchor:_scroll.leadingAnchor],
        [_content.trailingAnchor constraintEqualToAnchor:_scroll.trailingAnchor],
        [_content.bottomAnchor constraintEqualToAnchor:_scroll.bottomAnchor],
        [_content.widthAnchor constraintEqualToAnchor:_scroll.widthAnchor],
    ]];

    // ── Status Hero Card ──────────────────────────────────
    FVDCard *heroCard = [FVDCard new];
    CAGradientLayer *heroGrad = FVDMakeGradient(
        [UIColor colorWithRed:0.3 green:0.1 blue:0.6 alpha:0.5],
        [UIColor colorWithRed:0.5 green:0.1 blue:0.4 alpha:0.4], 135);
    heroGrad.frame = CGRectMake(0,0,10,10); // will resize in layoutSubviews
    heroGrad.cornerRadius = FVD_R_MD;
    [heroCard.layer insertSublayer:heroGrad atIndex:0];

    // Shield icon
    UIImageView *shieldIcon = [[UIImageView alloc] initWithImage:FVDICON(FVDIconShield, 48, FVD_ACCENT)];
    shieldIcon.translatesAutoresizingMaskIntoConstraints = NO;
    shieldIcon.contentMode = UIViewContentModeScaleAspectFit;
    [heroCard addSubview:shieldIcon];

    UILabel *heroTitle = [UILabel new];
    heroTitle.translatesAutoresizingMaskIntoConstraints = NO;
    heroTitle.text = @"Trạng Thái Bản Quyền";
    heroTitle.font = [UIFont systemFontOfSize:17 weight:UIFontWeightBold];
    heroTitle.textColor = FVD_TEXT;
    [heroCard addSubview:heroTitle];

    _statusDot = [[UIView alloc] init];
    _statusDot.translatesAutoresizingMaskIntoConstraints = NO;
    _statusDot.layer.cornerRadius = 4;
    [heroCard addSubview:_statusDot];

    _statusLabel = [UILabel new];
    _statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _statusLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    _statusLabel.textColor = FVD_SUBTEXT;
    [heroCard addSubview:_statusLabel];

    [NSLayoutConstraint activateConstraints:@[
        [shieldIcon.topAnchor constraintEqualToAnchor:heroCard.topAnchor constant:18],
        [shieldIcon.centerXAnchor constraintEqualToAnchor:heroCard.centerXAnchor],
        [shieldIcon.widthAnchor constraintEqualToConstant:48],
        [shieldIcon.heightAnchor constraintEqualToConstant:48],

        [heroTitle.topAnchor constraintEqualToAnchor:shieldIcon.bottomAnchor constant:10],
        [heroTitle.centerXAnchor constraintEqualToAnchor:heroCard.centerXAnchor],

        [_statusDot.topAnchor constraintEqualToAnchor:heroTitle.bottomAnchor constant:8],
        [_statusDot.trailingAnchor constraintEqualToAnchor:_statusLabel.leadingAnchor constant:-6],
        [_statusDot.centerYAnchor constraintEqualToAnchor:_statusLabel.centerYAnchor],
        [_statusDot.widthAnchor constraintEqualToConstant:8],
        [_statusDot.heightAnchor constraintEqualToConstant:8],

        [_statusLabel.centerXAnchor constraintEqualToAnchor:heroCard.centerXAnchor constant:7],
        [_statusLabel.bottomAnchor constraintEqualToAnchor:heroCard.bottomAnchor constant:-18],
    ]];

    // ── Info Card ─────────────────────────────────────────
    FVDCard *infoCard = [FVDCard new];
    UILabel *infoTitle = [UILabel new];
    infoTitle.translatesAutoresizingMaskIntoConstraints = NO;
    infoTitle.text = @"Thông Tin Gói";
    infoTitle.font = [UIFont systemFontOfSize:14 weight:UIFontWeightBold];
    infoTitle.textColor = FVD_TEXT;
    [infoCard addSubview:infoTitle];

    _rowPkg    = [[FVDInfoRow alloc] initWithIcon:FVDIconPkg      label:@"Gói Đăng Ký"   value:@"—"];
    _rowKey    = [[FVDInfoRow alloc] initWithIcon:FVDIconKey      label:@"Mã Key"         value:@"—"];
    _rowExpiry = [[FVDInfoRow alloc] initWithIcon:FVDIconCalendar label:@"Hạn Dùng"       value:@"—"];
    _rowDevice = [[FVDInfoRow alloc] initWithIcon:FVDIconDevice   label:@"Thiết Bị (UUID)" value:@"—"];

    UIView *sep1 = [UIView new]; sep1.translatesAutoresizingMaskIntoConstraints = NO;
    sep1.backgroundColor = FVD_SEP;
    UIView *sep2 = [UIView new]; sep2.translatesAutoresizingMaskIntoConstraints = NO;
    sep2.backgroundColor = FVD_SEP;
    UIView *sep3 = [UIView new]; sep3.translatesAutoresizingMaskIntoConstraints = NO;
    sep3.backgroundColor = FVD_SEP;

    for (UIView *v in @[infoTitle, _rowPkg, sep1, _rowKey, sep2, _rowExpiry, sep3, _rowDevice]) {
        [infoCard addSubview:v];
    }

    [NSLayoutConstraint activateConstraints:@[
        [infoTitle.topAnchor constraintEqualToAnchor:infoCard.topAnchor constant:14],
        [infoTitle.leadingAnchor constraintEqualToAnchor:infoCard.leadingAnchor constant:14],
        [_rowPkg.topAnchor constraintEqualToAnchor:infoTitle.bottomAnchor constant:10],
        [_rowPkg.leadingAnchor constraintEqualToAnchor:infoCard.leadingAnchor constant:14],
        [_rowPkg.trailingAnchor constraintEqualToAnchor:infoCard.trailingAnchor constant:-14],
        [sep1.topAnchor constraintEqualToAnchor:_rowPkg.bottomAnchor],
        [sep1.leadingAnchor constraintEqualToAnchor:infoCard.leadingAnchor constant:14],
        [sep1.trailingAnchor constraintEqualToAnchor:infoCard.trailingAnchor constant:-14],
        [sep1.heightAnchor constraintEqualToConstant:1],
        [_rowKey.topAnchor constraintEqualToAnchor:sep1.bottomAnchor],
        [_rowKey.leadingAnchor constraintEqualToAnchor:infoCard.leadingAnchor constant:14],
        [_rowKey.trailingAnchor constraintEqualToAnchor:infoCard.trailingAnchor constant:-14],
        [sep2.topAnchor constraintEqualToAnchor:_rowKey.bottomAnchor],
        [sep2.leadingAnchor constraintEqualToAnchor:infoCard.leadingAnchor constant:14],
        [sep2.trailingAnchor constraintEqualToAnchor:infoCard.trailingAnchor constant:-14],
        [sep2.heightAnchor constraintEqualToConstant:1],
        [_rowExpiry.topAnchor constraintEqualToAnchor:sep2.bottomAnchor],
        [_rowExpiry.leadingAnchor constraintEqualToAnchor:infoCard.leadingAnchor constant:14],
        [_rowExpiry.trailingAnchor constraintEqualToAnchor:infoCard.trailingAnchor constant:-14],
        [sep3.topAnchor constraintEqualToAnchor:_rowExpiry.bottomAnchor],
        [sep3.leadingAnchor constraintEqualToAnchor:infoCard.leadingAnchor constant:14],
        [sep3.trailingAnchor constraintEqualToAnchor:infoCard.trailingAnchor constant:-14],
        [sep3.heightAnchor constraintEqualToConstant:1],
        [_rowDevice.topAnchor constraintEqualToAnchor:sep3.bottomAnchor],
        [_rowDevice.leadingAnchor constraintEqualToAnchor:infoCard.leadingAnchor constant:14],
        [_rowDevice.trailingAnchor constraintEqualToAnchor:infoCard.trailingAnchor constant:-14],
        [_rowDevice.bottomAnchor constraintEqualToAnchor:infoCard.bottomAnchor constant:-14],
    ]];

    // ── Key Input Card ────────────────────────────────────
    FVDCard *keyCard = [FVDCard new];
    UILabel *keyTitle = [UILabel new];
    keyTitle.translatesAutoresizingMaskIntoConstraints = NO;
    keyTitle.text = @"Nhập Mã Key";
    keyTitle.font = [UIFont systemFontOfSize:14 weight:UIFontWeightBold];
    keyTitle.textColor = FVD_TEXT;

    _keyField = [[UITextField alloc] init];
    _keyField.translatesAutoresizingMaskIntoConstraints = NO;
    _keyField.placeholder = @"Nhập key tại đây...";
    _keyField.attributedPlaceholder = [[NSAttributedString alloc]
        initWithString:@"Nhập key tại đây..." attributes:@{NSForegroundColorAttributeName: FVD_SUBTEXT}];
    _keyField.textColor = FVD_TEXT;
    _keyField.font = [UIFont monospacedSystemFontOfSize:14 weight:UIFontWeightMedium];
    _keyField.backgroundColor = FVD_BG;
    _keyField.layer.cornerRadius = FVD_R_SM;
    _keyField.layer.borderWidth = 1;
    _keyField.layer.borderColor = FVD_BORDER.CGColor;
    _keyField.autocorrectionType = UITextAutocorrectionTypeNo;
    _keyField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    UIView *lpad = [[UIView alloc] initWithFrame:CGRectMake(0,0,12,0)];
    _keyField.leftView = lpad;
    _keyField.leftViewMode = UITextFieldViewModeAlways;

    UIButton *activateBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    activateBtn.translatesAutoresizingMaskIntoConstraints = NO;
    activateBtn.backgroundColor = FVD_ACCENT;
    activateBtn.layer.cornerRadius = FVD_R_SM;
    [activateBtn setTitle:@"Kích Hoạt" forState:UIControlStateNormal];
    [activateBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    activateBtn.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightBold];
    [activateBtn addTarget:self action:@selector(activateTapped) forControlEvents:UIControlEventTouchUpInside];

    [keyCard addSubview:keyTitle];
    [keyCard addSubview:_keyField];
    [keyCard addSubview:activateBtn];

    [NSLayoutConstraint activateConstraints:@[
        [keyTitle.topAnchor constraintEqualToAnchor:keyCard.topAnchor constant:14],
        [keyTitle.leadingAnchor constraintEqualToAnchor:keyCard.leadingAnchor constant:14],
        [_keyField.topAnchor constraintEqualToAnchor:keyTitle.bottomAnchor constant:10],
        [_keyField.leadingAnchor constraintEqualToAnchor:keyCard.leadingAnchor constant:14],
        [_keyField.trailingAnchor constraintEqualToAnchor:keyCard.trailingAnchor constant:-14],
        [_keyField.heightAnchor constraintEqualToConstant:42],
        [activateBtn.topAnchor constraintEqualToAnchor:_keyField.bottomAnchor constant:10],
        [activateBtn.leadingAnchor constraintEqualToAnchor:keyCard.leadingAnchor constant:14],
        [activateBtn.trailingAnchor constraintEqualToAnchor:keyCard.trailingAnchor constant:-14],
        [activateBtn.heightAnchor constraintEqualToConstant:44],
        [activateBtn.bottomAnchor constraintEqualToAnchor:keyCard.bottomAnchor constant:-14],
    ]];

    // ── Logout Button ─────────────────────────────────────
    UIButton *logoutBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    logoutBtn.translatesAutoresizingMaskIntoConstraints = NO;
    logoutBtn.backgroundColor = [UIColor colorWithRed:0.5 green:0.05 blue:0.08 alpha:1.0];
    logoutBtn.layer.cornerRadius = FVD_R_MD;
    logoutBtn.layer.borderWidth = 1;
    logoutBtn.layer.borderColor = [UIColor colorWithRed:1 green:0.3 blue:0.35 alpha:0.4].CGColor;

    UIImageView *logoutIcon = [[UIImageView alloc] initWithImage:FVDICON(FVDIconLogout, 18, FVD_RED)];
    logoutIcon.translatesAutoresizingMaskIntoConstraints = NO;
    logoutIcon.contentMode = UIViewContentModeScaleAspectFit;
    UILabel *logoutLbl = [UILabel new];
    logoutLbl.translatesAutoresizingMaskIntoConstraints = NO;
    logoutLbl.text = @"Đăng Xuất Key Khỏi Thiết Bị";
    logoutLbl.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    logoutLbl.textColor = FVD_RED;

    [logoutBtn addSubview:logoutIcon];
    [logoutBtn addSubview:logoutLbl];
    [logoutBtn addTarget:self action:@selector(logoutTapped) forControlEvents:UIControlEventTouchUpInside];

    [NSLayoutConstraint activateConstraints:@[
        [logoutIcon.leadingAnchor constraintEqualToAnchor:logoutBtn.leadingAnchor constant:16],
        [logoutIcon.centerYAnchor constraintEqualToAnchor:logoutBtn.centerYAnchor],
        [logoutIcon.widthAnchor constraintEqualToConstant:18],
        [logoutIcon.heightAnchor constraintEqualToConstant:18],
        [logoutLbl.leadingAnchor constraintEqualToAnchor:logoutIcon.trailingAnchor constant:8],
        [logoutLbl.centerYAnchor constraintEqualToAnchor:logoutBtn.centerYAnchor],
        [logoutBtn.heightAnchor constraintEqualToConstant:50],
    ]];

    // ── Layout all into content ───────────────────────────
    for (UIView *v in @[heroCard, infoCard, keyCard, logoutBtn]) {
        v.translatesAutoresizingMaskIntoConstraints = NO;
        [_content addSubview:v];
    }
    [NSLayoutConstraint activateConstraints:@[
        [heroCard.topAnchor constraintEqualToAnchor:_content.topAnchor constant:12],
        [heroCard.leadingAnchor constraintEqualToAnchor:_content.leadingAnchor constant:14],
        [heroCard.trailingAnchor constraintEqualToAnchor:_content.trailingAnchor constant:-14],

        [infoCard.topAnchor constraintEqualToAnchor:heroCard.bottomAnchor constant:12],
        [infoCard.leadingAnchor constraintEqualToAnchor:_content.leadingAnchor constant:14],
        [infoCard.trailingAnchor constraintEqualToAnchor:_content.trailingAnchor constant:-14],

        [keyCard.topAnchor constraintEqualToAnchor:infoCard.bottomAnchor constant:12],
        [keyCard.leadingAnchor constraintEqualToAnchor:_content.leadingAnchor constant:14],
        [keyCard.trailingAnchor constraintEqualToAnchor:_content.trailingAnchor constant:-14],

        [logoutBtn.topAnchor constraintEqualToAnchor:keyCard.bottomAnchor constant:12],
        [logoutBtn.leadingAnchor constraintEqualToAnchor:_content.leadingAnchor constant:14],
        [logoutBtn.trailingAnchor constraintEqualToAnchor:_content.trailingAnchor constant:-14],
        [logoutBtn.bottomAnchor constraintEqualToAnchor:_content.bottomAnchor constant:-20],
    ]];
}

- (void)refresh {
    LicenseManager *lm = [LicenseManager sharedInstance];
    BOOL active = lm.isActivated;

    _statusLabel.text   = [lm statusText];
    _statusDot.backgroundColor = active ? FVD_GREEN : FVD_RED;
    _rowPkg.valueLabel.text    = lm.packageName  ?: @"—";
    _rowExpiry.valueLabel.text = lm.expiryDate   ?: @"—";
    _rowDevice.valueLabel.text = lm.deviceUUID   ?: @"—";

    if (lm.currentKey) {
        // Mask key: show first 4 chars + ****
        NSString *k = lm.currentKey;
        NSString *masked = k.length > 4
            ? [NSString stringWithFormat:@"%@****", [k substringToIndex:4]]
            : k;
        _rowKey.valueLabel.text = masked;
    } else {
        _rowKey.valueLabel.text = @"—";
    }
}

- (void)activateTapped {
    NSString *key = _keyField.text;
    [_keyField resignFirstResponder];
    if (!key.length) return;

    BOOL ok = [[LicenseManager sharedInstance] activateKey:key];
    if (ok) {
        [self refresh];
        [self showBanner:@"✅ Kích hoạt thành công!" success:YES];
    } else {
        [self showBanner:@"❌ Key không hợp lệ!" success:NO];
    }
}

- (void)logoutTapped {
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:@"Đăng Xuất"
        message:@"Bạn có chắc muốn đăng xuất key khỏi thiết bị này?"
        preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:@"Huỷ" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Đăng Xuất" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a) {
        [[LicenseManager sharedInstance] logout];
        [self refresh];
        [self showBanner:@"Đã đăng xuất!" success:NO];
    }]];

    UIViewController *root = self;
    while (root.presentingViewController) root = root.presentingViewController;
    [root presentViewController:alert animated:YES completion:nil];
}

- (void)showBanner:(NSString *)msg success:(BOOL)success {
    UIView *banner = [[UIView alloc] init];
    banner.backgroundColor = success ? FVD_GREEN : FVD_RED;
    banner.layer.cornerRadius = 10;
    banner.translatesAutoresizingMaskIntoConstraints = NO;
    UILabel *lbl = [UILabel new];
    lbl.translatesAutoresizingMaskIntoConstraints = NO;
    lbl.text = msg;
    lbl.textColor = UIColor.whiteColor;
    lbl.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    [banner addSubview:lbl];
    [self.view addSubview:banner];
    [NSLayoutConstraint activateConstraints:@[
        [lbl.centerXAnchor constraintEqualToAnchor:banner.centerXAnchor],
        [lbl.centerYAnchor constraintEqualToAnchor:banner.centerYAnchor],
        [banner.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [banner.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        [banner.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:10],
        [banner.heightAnchor constraintEqualToConstant:40],
    ]];
    banner.alpha = 0;
    banner.transform = CGAffineTransformMakeTranslation(0, -20);
    [UIView animateWithDuration:0.3 animations:^{ banner.alpha = 1; banner.transform = CGAffineTransformIdentity; }
        completion:^(BOOL d){
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:0.3 animations:^{ banner.alpha = 0; } completion:^(BOOL d){ [banner removeFromSuperview]; }];
            });
        }];
}

@end
