// MediaReplacerVC.m
// Flow:
//   User đang ở màn hình nhập nhiều lớp trong VideoStar
//   Mở tab này → auto scan màn hình HIỆN TẠI đang hiển thị → tìm tất cả lớp media
//   Hiện picker ảnh → chọn xong → thay ALL lớp tìm được → xong

#import "MediaReplacerVC.h"
#import "Theme.h"
#import "SVGIcons.h"
#import <Photos/Photos.h>
#import <PhotosUI/PhotosUI.h>

@interface MediaReplacerVC () <PHPickerViewControllerDelegate>
@property (nonatomic, strong) NSMutableArray *foundLayers;   // các lớp media tìm thấy trên màn hình VS
@property (nonatomic, strong) UILabel        *countLabel;
@property (nonatomic, strong) UILabel        *statusLabel;
@property (nonatomic, strong) UIButton       *pickBtn;
@property (nonatomic, strong) UIProgressView *progressBar;
@property (nonatomic, strong) UILabel        *progressLabel;
@end

@implementation MediaReplacerVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.clearColor;
    self.foundLayers = [NSMutableArray new];
    [self buildUI];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // Auto scan ngay khi mở tab
    [self scanCurrentScreen];
}

// ════════════════════════════════════════════════════════
// MARK: - UI
// ════════════════════════════════════════════════════════
- (void)buildUI {
    UIScrollView *scroll = [[UIScrollView alloc] init];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:scroll];

    UIView *cont = [[UIView alloc] init];
    cont.translatesAutoresizingMaskIntoConstraints = NO;
    [scroll addSubview:cont];

    [NSLayoutConstraint activateConstraints:@[
        [scroll.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [scroll.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [scroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [scroll.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [cont.topAnchor constraintEqualToAnchor:scroll.topAnchor],
        [cont.leadingAnchor constraintEqualToAnchor:scroll.leadingAnchor],
        [cont.trailingAnchor constraintEqualToAnchor:scroll.trailingAnchor],
        [cont.bottomAnchor constraintEqualToAnchor:scroll.bottomAnchor],
        [cont.widthAnchor constraintEqualToAnchor:scroll.widthAnchor],
    ]];

    // ── Scan result card ──────────────────────────────────
    UIView *card = [[UIView alloc] init];
    card.translatesAutoresizingMaskIntoConstraints = NO;
    card.backgroundColor = FVD_CARD;
    card.layer.cornerRadius = FVD_R_MD;
    card.layer.borderWidth = 1;
    card.layer.borderColor = FVD_BORDER.CGColor;

    UIImageView *ico = [[UIImageView alloc] initWithImage:FVDICON(FVDIconImage, 22, FVD_ACCENT)];
    ico.translatesAutoresizingMaskIntoConstraints = NO;
    ico.contentMode = UIViewContentModeScaleAspectFit;

    _countLabel = [UILabel new];
    _countLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _countLabel.text = @"Đang scan màn hình...";
    _countLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightBold];
    _countLabel.textColor = FVD_TEXT;

    _statusLabel = [UILabel new];
    _statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _statusLabel.text = @"Hãy mở màn hình nhập nhiều lớp trong VideoStar";
    _statusLabel.font = [UIFont systemFontOfSize:12];
    _statusLabel.textColor = FVD_SUBTEXT;
    _statusLabel.numberOfLines = 0;

    // Rescan button
    UIButton *rescan = [UIButton buttonWithType:UIButtonTypeSystem];
    rescan.translatesAutoresizingMaskIntoConstraints = NO;
    [rescan setTitle:@"Scan lại" forState:UIControlStateNormal];
    [rescan setTitleColor:FVD_ACCENT forState:UIControlStateNormal];
    rescan.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    [rescan addTarget:self action:@selector(scanCurrentScreen) forControlEvents:UIControlEventTouchUpInside];

    [card addSubview:ico];
    [card addSubview:_countLabel];
    [card addSubview:_statusLabel];
    [card addSubview:rescan];
    [NSLayoutConstraint activateConstraints:@[
        [ico.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:14],
        [ico.topAnchor constraintEqualToAnchor:card.topAnchor constant:14],
        [ico.widthAnchor constraintEqualToConstant:22],
        [ico.heightAnchor constraintEqualToConstant:22],
        [_countLabel.leadingAnchor constraintEqualToAnchor:ico.trailingAnchor constant:10],
        [_countLabel.centerYAnchor constraintEqualToAnchor:ico.centerYAnchor],
        [_countLabel.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-14],
        [_statusLabel.topAnchor constraintEqualToAnchor:ico.bottomAnchor constant:8],
        [_statusLabel.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:14],
        [_statusLabel.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-14],
        [rescan.topAnchor constraintEqualToAnchor:_statusLabel.bottomAnchor constant:8],
        [rescan.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:14],
        [rescan.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-10],
    ]];

    // ── Pick button ───────────────────────────────────────
    _pickBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    _pickBtn.translatesAutoresizingMaskIntoConstraints = NO;
    _pickBtn.layer.cornerRadius = FVD_R_MD;
    _pickBtn.alpha = 0.4;
    _pickBtn.enabled = NO;

    CAGradientLayer *g = FVDMakeGradient(FVD_ACCENT, FVD_ACCENT2, 90);
    g.cornerRadius = FVD_R_MD;
    g.frame = CGRectMake(0, 0, 10, 10);
    [_pickBtn.layer insertSublayer:g atIndex:0];

    [_pickBtn setTitle:@"Chọn Ảnh Thay Thế" forState:UIControlStateNormal];
    [_pickBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    _pickBtn.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightBold];
    [_pickBtn addTarget:self action:@selector(pickImage) forControlEvents:UIControlEventTouchUpInside];
    _pickBtn.heightAnchor.constraintEqualToConstant(52).active = YES;

    // ── Progress ──────────────────────────────────────────
    _progressLabel = [UILabel new];
    _progressLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _progressLabel.font = [UIFont systemFontOfSize:12];
    _progressLabel.textColor = FVD_SUBTEXT;
    _progressLabel.textAlignment = NSTextAlignmentCenter;
    _progressLabel.hidden = YES;

    _progressBar = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    _progressBar.translatesAutoresizingMaskIntoConstraints = NO;
    _progressBar.progressTintColor = FVD_ACCENT;
    _progressBar.trackTintColor = FVD_BG;
    _progressBar.layer.cornerRadius = 3;
    _progressBar.clipsToBounds = YES;
    _progressBar.hidden = YES;
    _progressBar.heightAnchor.constraintEqualToConstant(6).active = YES;

    // Layout
    for (UIView *v in @[card, _pickBtn, _progressLabel, _progressBar]) {
        [cont addSubview:v];
        [NSLayoutConstraint activateConstraints:@[
            [v.leadingAnchor constraintEqualToAnchor:cont.leadingAnchor constant:14],
            [v.trailingAnchor constraintEqualToAnchor:cont.trailingAnchor constant:-14],
        ]];
    }
    [NSLayoutConstraint activateConstraints:@[
        [card.topAnchor constraintEqualToAnchor:cont.topAnchor constant:14],
        [_pickBtn.topAnchor constraintEqualToAnchor:card.bottomAnchor constant:14],
        [_progressLabel.topAnchor constraintEqualToAnchor:_pickBtn.bottomAnchor constant:10],
        [_progressBar.topAnchor constraintEqualToAnchor:_progressLabel.bottomAnchor constant:6],
        [_progressBar.bottomAnchor constraintEqualToAnchor:cont.bottomAnchor constant:-20],
    ]];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    for (CALayer *l in _pickBtn.layer.sublayers) {
        if ([l isKindOfClass:[CAGradientLayer class]]) {
            l.frame = _pickBtn.bounds;
            l.cornerRadius = _pickBtn.layer.cornerRadius;
        }
    }
}

// ════════════════════════════════════════════════════════
// MARK: - Scan màn hình hiện tại của VideoStar
// ════════════════════════════════════════════════════════
- (void)scanCurrentScreen {
    _countLabel.text = @"Đang scan...";
    _countLabel.textColor = FVD_SUBTEXT;
    _statusLabel.text = @"";
    _pickBtn.enabled = NO;
    _pickBtn.alpha = 0.4;
    _progressLabel.hidden = YES;
    _progressBar.hidden = YES;
    [self.foundLayers removeAllObjects];

    // Scan trên main thread vì cần truy cập UIView hierarchy
    dispatch_async(dispatch_get_main_queue(), ^{
        // Tìm VideoStar VC đang hiển thị (không phải FVD overlay)
        UIViewController *vsVC = [self findCurrentVideoStarVC];
        UIView *scanRoot = vsVC ? vsVC.view : nil;

        // Nếu không tìm được VC cụ thể, scan toàn window nhưng bỏ qua FVD views
        if (!scanRoot) {
            for (UIWindowScene *sc in [UIApplication sharedApplication].connectedScenes) {
                if (![sc isKindOfClass:[UIWindowScene class]]) continue;
                for (UIWindow *win in sc.windows) {
                    NSString *cls = NSStringFromClass([win class]);
                    if ([cls containsString:@"FVD"] || [cls containsString:@"FallVds"]) continue;
                    scanRoot = win;
                    break;
                }
                if (scanRoot) break;
            }
        }

        NSMutableArray *found = [NSMutableArray new];
        if (scanRoot) [self collectMediaViews:scanRoot into:found];

        [self.foundLayers addObjectsFromArray:found];

        if (found.count > 0) {
            self.countLabel.text = [NSString stringWithFormat:@"Tìm thấy %ld lớp media", (long)found.count];
            self.countLabel.textColor = FVD_GREEN;
            self.statusLabel.text = @"Chọn ảnh để thay tất cả lớp bên dưới.";
            self.pickBtn.enabled = YES;
            [UIView animateWithDuration:0.2 animations:^{ self.pickBtn.alpha = 1.0; }];
        } else {
            self.countLabel.text = @"Không tìm thấy lớp media";
            self.countLabel.textColor = FVD_RED;
            self.statusLabel.text = @"Vào màn hình nhập nhiều lớp trong VideoStar rồi nhấn Scan lại.";
        }
    });
}

// Tìm VC VideoStar đang hiển thị (top-most VC không phải FVD)
- (UIViewController *)findCurrentVideoStarVC {
    UIViewController *top = nil;

    for (UIWindowScene *sc in [UIApplication sharedApplication].connectedScenes) {
        if (![sc isKindOfClass:[UIWindowScene class]]) continue;
        for (UIWindow *win in sc.windows) {
            NSString *winCls = NSStringFromClass([win class]);
            if ([winCls containsString:@"FVD"] || [winCls containsString:@"FallVds"]) continue;
            top = win.rootViewController;
            break;
        }
        if (top) break;
    }

    if (!top) return nil;

    // Đi xuống đến topmost VC
    while (top.presentedViewController) top = top.presentedViewController;
    if ([top isKindOfClass:[UINavigationController class]])
        top = [(UINavigationController *)top topViewController];
    if ([top isKindOfClass:[UITabBarController class]])
        top = [(UITabBarController *)top selectedViewController];

    // Bỏ qua FVD VC
    NSString *cls = NSStringFromClass([top class]);
    if ([cls containsString:@"FVD"] || [cls containsString:@"FallVds"]) return nil;

    return top;
}

// Quét UIView hierarchy tìm các lớp media có thể thay
- (void)collectMediaViews:(UIView *)view into:(NSMutableArray *)arr {
    // Bỏ qua toàn bộ FVD overlay
    NSString *cls = NSStringFromClass([view class]);
    if ([cls containsString:@"FVD"] || [cls containsString:@"FallVds"]) return;

    // Lớp UIImageView có ảnh thực → đây là media layer
    if ([view isKindOfClass:[UIImageView class]]) {
        UIImageView *iv = (UIImageView *)view;
        // Chỉ lấy các ImageView có size đáng kể (loại icon nhỏ)
        BOOL bigEnough = iv.frame.size.width > 40 && iv.frame.size.height > 40;
        if (iv.image && bigEnough && ![arr containsObject:iv]) {
            [arr addObject:iv];
        }
    }

    // VS-specific layer objects (nếu có)
    if ([view respondsToSelector:@selector(setSourceImage:)] && ![arr containsObject:view])
        [arr addObject:view];
    if ([view respondsToSelector:@selector(setVideoURL:)] && ![arr containsObject:view])
        [arr addObject:view];

    for (UIView *sub in view.subviews) {
        [self collectMediaViews:sub into:arr];
    }
}

// ════════════════════════════════════════════════════════
// MARK: - Pick Image
// ════════════════════════════════════════════════════════
- (void)pickImage {
    PHPickerConfiguration *cfg = [[PHPickerConfiguration alloc] init];
    cfg.selectionLimit = 1;
    cfg.filter = [PHPickerFilter imagesFilter];

    PHPickerViewController *picker = [[PHPickerViewController alloc] initWithConfiguration:cfg];
    picker.delegate = self;
    picker.modalPresentationStyle = UIModalPresentationFormSheet;

    UIViewController *root = self;
    while (root.presentingViewController) root = root.presentingViewController;
    [root presentViewController:picker animated:YES completion:nil];
}

- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results {
    [picker dismissViewControllerAnimated:YES completion:nil];
    if (!results.count) return;

    [[results.firstObject itemProvider] loadObjectOfClass:[UIImage class]
                                       completionHandler:^(UIImage *img, NSError *e) {
        if (!img) return;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self applyImage:img];
        });
    }];
}

// ════════════════════════════════════════════════════════
// MARK: - Apply to All Layers
// ════════════════════════════════════════════════════════
- (void)applyImage:(UIImage *)img {
    NSArray *layers = [self.foundLayers copy];
    NSInteger total = layers.count;
    if (!total) return;

    _pickBtn.enabled = NO;
    _progressLabel.hidden = NO;
    _progressBar.hidden = NO;
    _progressBar.progress = 0;
    _progressLabel.text = [NSString stringWithFormat:@"Đang thay 0/%ld lớp...", (long)total];

    NSData *data = UIImageJPEGRepresentation(img, 0.95) ?: UIImagePNGRepresentation(img);

    for (NSInteger i = 0; i < total; i++) {
        id layer = layers[i];
        @try {
            if ([layer isKindOfClass:[UIImageView class]])
                ((UIImageView *)layer).image = img;
            if ([layer respondsToSelector:@selector(setImage:)])
                [layer performSelector:@selector(setImage:) withObject:img];
            if ([layer respondsToSelector:@selector(setSourceImage:)])
                [layer performSelector:@selector(setSourceImage:) withObject:img];
            if ([layer respondsToSelector:@selector(setVideoURL:)]) {
                NSString *p = [NSTemporaryDirectory() stringByAppendingPathComponent:@"fvd_rep.jpg"];
                if ([data writeToFile:p atomically:YES])
                    [layer performSelector:@selector(setVideoURL:) withObject:[NSURL fileURLWithPath:p]];
            }
            if ([layer respondsToSelector:@selector(setNeedsDisplay)])
                [layer performSelector:@selector(setNeedsDisplay)];
        } @catch (...) {}

        CGFloat prog = (float)(i + 1) / total;
        [_progressBar setProgress:prog animated:YES];
        _progressLabel.text = [NSString stringWithFormat:@"Đang thay %ld/%ld lớp...", (long)(i+1), (long)total];
    }

    _progressLabel.text = [NSString stringWithFormat:@"✅ Đã thay %ld lớp!", (long)total];
    _progressLabel.textColor = FVD_GREEN;
    _countLabel.text = [NSString stringWithFormat:@"✅ Xong — %ld lớp đã thay", (long)total];
    _countLabel.textColor = FVD_GREEN;
    _pickBtn.enabled = YES;
    [UIView animateWithDuration:0.2 animations:^{ self.pickBtn.alpha = 1.0; }];
}

@end
