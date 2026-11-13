// MediaReplacerVC.m — Chạm Thay Media (ĐƠN GIẢN)
// Mở lên: auto scan lớp → bắt chọn ảnh → thay tất cả lớp → xong

#import "MediaReplacerVC.h"
#import "Theme.h"
#import "SVGIcons.h"
#import <Photos/Photos.h>
#import <PhotosUI/PhotosUI.h>

@interface MediaReplacerVC () <PHPickerViewControllerDelegate>
@property (nonatomic, strong) NSMutableArray *mediaLayers;
@property (nonatomic, strong) UILabel  *statusLabel;
@property (nonatomic, strong) UILabel  *countLabel;
@property (nonatomic, strong) UIButton *pickBtn;
@property (nonatomic, strong) UIProgressView *progressBar;
@property (nonatomic, strong) UILabel  *progressLabel;
@end

@implementation MediaReplacerVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.clearColor;
    self.mediaLayers = [NSMutableArray new];
    [self buildUI];
    // Auto scan ngay khi mở
    [self scanLayers];
}

- (void)buildUI {
    UIScrollView *scroll = [[UIScrollView alloc] init];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    scroll.showsVerticalScrollIndicator = NO;
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

    // ── Status card ───────────────────────────────────────
    UIView *card = [[UIView alloc] init];
    card.translatesAutoresizingMaskIntoConstraints = NO;
    card.backgroundColor = FVD_CARD;
    card.layer.cornerRadius = FVD_R_MD;
    card.layer.borderWidth = 1;
    card.layer.borderColor = FVD_BORDER.CGColor;

    UIImageView *ico = [[UIImageView alloc] initWithImage:FVDICON(FVDIconImage, 24, FVD_ACCENT)];
    ico.translatesAutoresizingMaskIntoConstraints = NO;
    ico.contentMode = UIViewContentModeScaleAspectFit;

    _statusLabel = [UILabel new];
    _statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _statusLabel.text = @"Đang scan lớp media...";
    _statusLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightBold];
    _statusLabel.textColor = FVD_TEXT;

    _countLabel = [UILabel new];
    _countLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _countLabel.text = @"";
    _countLabel.font = [UIFont systemFontOfSize:13];
    _countLabel.textColor = FVD_SUBTEXT;
    _countLabel.numberOfLines = 0;

    [card addSubview:ico];
    [card addSubview:_statusLabel];
    [card addSubview:_countLabel];
    [NSLayoutConstraint activateConstraints:@[
        [ico.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],
        [ico.topAnchor constraintEqualToAnchor:card.topAnchor constant:16],
        [ico.widthAnchor constraintEqualToConstant:24],
        [ico.heightAnchor constraintEqualToConstant:24],
        [_statusLabel.leadingAnchor constraintEqualToAnchor:ico.trailingAnchor constant:10],
        [_statusLabel.centerYAnchor constraintEqualToAnchor:ico.centerYAnchor],
        [_statusLabel.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16],
        [_countLabel.topAnchor constraintEqualToAnchor:ico.bottomAnchor constant:10],
        [_countLabel.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],
        [_countLabel.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16],
        [_countLabel.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-14],
    ]];

    // ── Chọn ảnh button ───────────────────────────────────
    _pickBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    _pickBtn.translatesAutoresizingMaskIntoConstraints = NO;
    _pickBtn.layer.cornerRadius = FVD_R_MD;
    _pickBtn.alpha = 0.4;
    _pickBtn.enabled = NO;

    CAGradientLayer *g = FVDMakeGradient(FVD_ACCENT, FVD_ACCENT2, 90);
    g.cornerRadius = FVD_R_MD;
    g.frame = CGRectMake(0,0,10,10);
    [_pickBtn.layer insertSublayer:g atIndex:0];

    [_pickBtn setTitle:@"Chọn Ảnh & Thay Tất Cả Lớp" forState:UIControlStateNormal];
    [_pickBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    _pickBtn.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightBold];
    [_pickBtn addTarget:self action:@selector(pickImage) forControlEvents:UIControlEventTouchUpInside];
    _pickBtn.heightAnchor.constraintEqualToConstant(54).active = YES;

    // ── Progress ──────────────────────────────────────────
    _progressBar = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    _progressBar.translatesAutoresizingMaskIntoConstraints = NO;
    _progressBar.progressTintColor = FVD_ACCENT;
    _progressBar.trackTintColor = FVD_BG;
    _progressBar.layer.cornerRadius = 3;
    _progressBar.clipsToBounds = YES;
    _progressBar.hidden = YES;

    _progressLabel = [UILabel new];
    _progressLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _progressLabel.font = [UIFont systemFontOfSize:12];
    _progressLabel.textColor = FVD_SUBTEXT;
    _progressLabel.textAlignment = NSTextAlignmentCenter;
    _progressLabel.hidden = YES;

    // ── Rescan button ─────────────────────────────────────
    UIButton *rescanBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    rescanBtn.translatesAutoresizingMaskIntoConstraints = NO;
    rescanBtn.backgroundColor = FVD_CARD;
    rescanBtn.layer.cornerRadius = FVD_R_SM;
    rescanBtn.layer.borderWidth = 1;
    rescanBtn.layer.borderColor = FVD_BORDER.CGColor;
    [rescanBtn setTitle:@"Scan lại" forState:UIControlStateNormal];
    [rescanBtn setTitleColor:FVD_SUBTEXT forState:UIControlStateNormal];
    rescanBtn.titleLabel.font = [UIFont systemFontOfSize:12];
    [rescanBtn addTarget:self action:@selector(scanLayers) forControlEvents:UIControlEventTouchUpInside];
    rescanBtn.heightAnchor.constraintEqualToConstant(32).active = YES;

    // ── Layout ────────────────────────────────────────────
    for (UIView *v in @[card, _pickBtn, _progressBar, _progressLabel, rescanBtn]) {
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
        [_progressBar.heightAnchor constraintEqualToConstant:6],
        [rescanBtn.topAnchor constraintEqualToAnchor:_progressBar.bottomAnchor constant:14],
        [rescanBtn.bottomAnchor constraintEqualToAnchor:cont.bottomAnchor constant:-20],
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

// ── MARK: Scan ────────────────────────────────────────────────────────────────
- (void)scanLayers {
    _statusLabel.text = @"Đang scan lớp media...";
    _countLabel.text  = @"";
    _pickBtn.enabled  = NO;
    _pickBtn.alpha    = 0.4;
    _progressBar.hidden = YES;
    _progressLabel.hidden = YES;
    [self.mediaLayers removeAllObjects];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSMutableArray *found = [NSMutableArray new];

        // ── Method 1: VSProjectController ────────────────
        Class ctrl = NSClassFromString(@"VSProjectController");
        if (ctrl && [ctrl respondsToSelector:@selector(sharedController)]) {
            id shared = [ctrl performSelector:@selector(sharedController)];
            id project = nil;
            if ([shared respondsToSelector:@selector(currentProject)])
                project = [shared performSelector:@selector(currentProject)];
            if (project) {
                for (NSString *s in @[@"layers", @"allLayers", @"videoLayers", @"imageLayers", @"clips"]) {
                    SEL sel = NSSelectorFromString(s);
                    if ([project respondsToSelector:sel]) {
                        id obj = [project performSelector:sel];
                        if ([obj isKindOfClass:[NSArray class]] && [(NSArray*)obj count] > 0) {
                            [found addObjectsFromArray:(NSArray*)obj]; break;
                        }
                    }
                }
            }
        }

        // ── Method 2: scan UIImageViews in window ─────────
        if (found.count == 0) {
            dispatch_semaphore_t sem = dispatch_semaphore_create(0);
            dispatch_async(dispatch_get_main_queue(), ^{
                for (UIWindowScene *sc in [UIApplication sharedApplication].connectedScenes) {
                    if (![sc isKindOfClass:[UIWindowScene class]]) continue;
                    for (UIWindow *win in sc.windows) {
                        [self collectFrom:win into:found];
                    }
                }
                dispatch_semaphore_signal(sem);
            });
            dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 3*NSEC_PER_SEC));
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.mediaLayers addObjectsFromArray:found];
            if (found.count > 0) {
                self.statusLabel.text = [NSString stringWithFormat:@"Tìm thấy %ld lớp media", (long)found.count];
                self.statusLabel.textColor = FVD_GREEN;
                self.countLabel.text = @"Nhấn nút bên dưới để chọn ảnh thay thế.";
                self.pickBtn.enabled = YES;
                [UIView animateWithDuration:0.25 animations:^{ self.pickBtn.alpha = 1.0; }];
            } else {
                self.statusLabel.text = @"Không tìm thấy lớp media";
                self.statusLabel.textColor = FVD_RED;
                self.countLabel.text = @"Hãy mở một project trong VideoStar rồi nhấn \"Scan lại\".";
            }
        });
    });
}

- (void)collectFrom:(UIView *)view into:(NSMutableArray *)arr {
    NSString *cls = NSStringFromClass([view class]);
    if ([cls containsString:@"FVD"] || [cls containsString:@"FallVds"]) return;
    if ([view isKindOfClass:[UIImageView class]] && ((UIImageView*)view).image) [arr addObject:view];
    else if ([view respondsToSelector:@selector(setSourceImage:)]) [arr addObject:view];
    else if ([view respondsToSelector:@selector(setVideoURL:)]) [arr addObject:view];
    for (UIView *sub in view.subviews) [self collectFrom:sub into:arr];
}

// ── MARK: Pick Image ──────────────────────────────────────────────────────────
- (void)pickImage {
    PHPickerConfiguration *cfg = [[PHPickerConfiguration alloc] init];
    cfg.selectionLimit = 1;
    cfg.filter = [PHPickerFilter imagesFilter];
    PHPickerViewController *picker = [[PHPickerViewController alloc] initWithConfiguration:cfg];
    picker.delegate = self;
    UIViewController *root = self;
    while (root.presentingViewController) root = root.presentingViewController;
    [root presentViewController:picker animated:YES completion:nil];
}

- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results {
    [picker dismissViewControllerAnimated:YES completion:nil];
    if (!results.count) return;
    [[results.firstObject itemProvider] loadObjectOfClass:[UIImage class] completionHandler:^(UIImage *img, NSError *e) {
        if (!img) return;
        dispatch_async(dispatch_get_main_queue(), ^{ [self applyImage:img]; });
    }];
}

// ── MARK: Apply ───────────────────────────────────────────────────────────────
- (void)applyImage:(UIImage *)img {
    _pickBtn.enabled = NO;
    _progressBar.progress = 0;
    _progressBar.hidden = NO;
    _progressLabel.hidden = NO;
    _progressLabel.text = @"Đang thay...";

    NSData *data = UIImageJPEGRepresentation(img, 0.95) ?: UIImagePNGRepresentation(img);
    NSArray *layers = [self.mediaLayers copy];
    NSInteger total = layers.count;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        for (NSInteger i = 0; i < total; i++) {
            [self replaceLayer:layers[i] data:data image:img];
            CGFloat p = (float)(i+1)/total;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.progressBar setProgress:p animated:YES];
                self.progressLabel.text = [NSString stringWithFormat:@"%ld/%ld lớp", (long)(i+1), (long)total];
            });
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            self.progressLabel.text = [NSString stringWithFormat:@"✅ Đã thay %ld lớp!", (long)total];
            self.pickBtn.enabled = YES;
            [UIView animateWithDuration:0.25 animations:^{ self.pickBtn.alpha = 1.0; }];
        });
    });
}

- (void)replaceLayer:(id)layer data:(NSData *)data image:(UIImage *)img {
    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            if ([layer isKindOfClass:[UIImageView class]]) ((UIImageView*)layer).image = img;
            if ([layer respondsToSelector:@selector(setImage:)]) [layer performSelector:@selector(setImage:) withObject:img];
            if ([layer respondsToSelector:@selector(setSourceImage:)]) [layer performSelector:@selector(setSourceImage:) withObject:img];
            if ([layer respondsToSelector:@selector(setVideoURL:)]) {
                NSString *p = [NSTemporaryDirectory() stringByAppendingPathComponent:@"fvd_rep.jpg"];
                if ([data writeToFile:p atomically:YES])
                    [layer performSelector:@selector(setVideoURL:) withObject:[NSURL fileURLWithPath:p]];
            }
            if ([layer respondsToSelector:@selector(setNeedsDisplay)]) [layer performSelector:@selector(setNeedsDisplay)];
        } @catch (...) {}
    });
}

@end
