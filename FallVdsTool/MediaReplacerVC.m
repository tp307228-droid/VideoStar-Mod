// MediaReplacerVC.m
// Scan DATA từ VideoStar project model (tất cả lớp dù không hiển thị trên màn hình)
// Flow: mở tab → auto scan project data → hiện số lớp → chọn ảnh → thay ALL → xong

#import "MediaReplacerVC.h"
#import "Theme.h"
#import "SVGIcons.h"
#import <Photos/Photos.h>
#import <PhotosUI/PhotosUI.h>
#import <objc/runtime.h>

// Suppress ARC performSelector leak warnings — we use @try/@catch for safety
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

@interface MediaReplacerVC () <PHPickerViewControllerDelegate>
@property (nonatomic, strong) NSMutableArray *dataLayers;  // layer objects từ project model
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
    self.dataLayers = [NSMutableArray new];
    [self buildUI];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self scanProjectData];
}

// ════════════════════════════════════════════════════════
// MARK: - UI
// ════════════════════════════════════════════════════════
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

    // ── Info card ─────────────────────────────────────────
    UIView *card = [self makeCard];

    UIImageView *ico = [[UIImageView alloc] initWithImage:FVDICON(FVDIconImage, 22, FVD_ACCENT)];
    ico.translatesAutoresizingMaskIntoConstraints = NO;
    ico.contentMode = UIViewContentModeScaleAspectFit;

    _countLabel = [UILabel new];
    _countLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _countLabel.text = @"Đang scan dữ liệu project...";
    _countLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightBold];
    _countLabel.textColor = FVD_TEXT;

    _statusLabel = [UILabel new];
    _statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _statusLabel.text = @"Đang đọc tất cả lớp media từ project VideoStar";
    _statusLabel.font = [UIFont systemFontOfSize:12];
    _statusLabel.textColor = FVD_SUBTEXT;
    _statusLabel.numberOfLines = 0;

    UIButton *rescan = [UIButton buttonWithType:UIButtonTypeSystem];
    rescan.translatesAutoresizingMaskIntoConstraints = NO;
    [rescan setTitle:@"Scan lại" forState:UIControlStateNormal];
    [rescan setTitleColor:FVD_ACCENT forState:UIControlStateNormal];
    rescan.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    [rescan addTarget:self action:@selector(scanProjectData)
     forControlEvents:UIControlEventTouchUpInside];

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
        [rescan.topAnchor constraintEqualToAnchor:_statusLabel.bottomAnchor constant:6],
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
    [_pickBtn.heightAnchor constraintEqualToConstant:52].active = YES;

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
    [_progressBar.heightAnchor constraintEqualToConstant:6].active = YES;

    // layout
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

- (UIView *)makeCard {
    UIView *v = [[UIView alloc] init];
    v.translatesAutoresizingMaskIntoConstraints = NO;
    v.backgroundColor = FVD_CARD;
    v.layer.cornerRadius = FVD_R_MD;
    v.layer.borderWidth = 1;
    v.layer.borderColor = FVD_BORDER.CGColor;
    return v;
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
// MARK: - Scan Project DATA (không phải UIView)
// ════════════════════════════════════════════════════════
- (void)scanProjectData {
    _countLabel.text = @"Đang scan dữ liệu project...";
    _countLabel.textColor = FVD_SUBTEXT;
    _statusLabel.text = @"Đọc tất cả lớp media từ model...";
    _pickBtn.enabled = NO;
    _pickBtn.alpha = 0.4;
    _progressLabel.hidden = YES;
    _progressBar.hidden = YES;
    [self.dataLayers removeAllObjects];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSMutableArray *found = [NSMutableArray new];
        [self collectFromProjectModel:found];

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.dataLayers addObjectsFromArray:found];

            if (found.count > 0) {
                self.countLabel.text = [NSString stringWithFormat:
                    @"Tìm thấy %ld lớp media", (long)found.count];
                self.countLabel.textColor = FVD_GREEN;
                self.statusLabel.text = [NSString stringWithFormat:
                    @"Sẵn sàng thay ảnh vào tất cả %ld lớp.", (long)found.count];
                self.pickBtn.enabled = YES;
                [UIView animateWithDuration:0.2 animations:^{
                    self.pickBtn.alpha = 1.0;
                }];
            } else {
                self.countLabel.text = @"Không tìm thấy lớp media";
                self.countLabel.textColor = FVD_RED;
                self.statusLabel.text = @"Hãy mở một project trong VideoStar rồi nhấn Scan lại.";
            }
        });
    });
}

// Scan DATA từ VideoStar project model — TẤT CẢ lớp dù không hiển thị
- (void)collectFromProjectModel:(NSMutableArray *)result {

    // ── Các selectors phổ biến để lấy layers từ project ──
    NSArray *layerSelectors = @[
        @"layers", @"allLayers", @"clips", @"videoClips",
        @"mediaLayers", @"imageLayers", @"videoLayers",
        @"segments", @"tracks", @"items"
    ];

    // ── Các class VS có thể chứa project/layers ──
    NSArray *controllerClasses = @[
        @"VSProjectController",
        @"VSDocumentController",
        @"VSCompositionController",
        @"VSTimeline",
        @"VSProject",
        @"VSDocument",
        @"VSComposition",
    ];

    for (NSString *clsName in controllerClasses) {
        Class cls = NSClassFromString(clsName);
        if (!cls) continue;

        // Lấy shared instance
        id shared = nil;
        for (NSString *s in @[@"sharedController", @"sharedInstance",
                               @"defaultController", @"sharedDocumentController"]) {
            SEL sel = NSSelectorFromString(s);
            if ([cls respondsToSelector:sel]) {
                @try { shared = [cls performSelector:sel]; } @catch (...) {}
                if (shared) break;
            }
        }
        if (!shared) continue;

        // Lấy currentProject / currentDocument
        id project = nil;
        for (NSString *s in @[@"currentProject", @"currentDocument",
                               @"activeProject", @"document", @"composition"]) {
            SEL sel = NSSelectorFromString(s);
            if ([shared respondsToSelector:sel]) {
                @try { project = [shared performSelector:sel]; } @catch (...) {}
                if (project) break;
            }
        }

        // Thử lấy layers trực tiếp từ shared nếu không có project
        for (id source in @[project ?: [NSNull null], shared]) {
            if ([source isKindOfClass:[NSNull class]]) continue;

            for (NSString *selName in layerSelectors) {
                SEL sel = NSSelectorFromString(selName);
                if (![source respondsToSelector:sel]) continue;

                @try {
                    id obj = [source performSelector:sel];
                    if ([obj isKindOfClass:[NSArray class]] && [(NSArray *)obj count] > 0) {
                        // Lấy từng layer, kiểm tra xem có thể thay media không
                        for (id layer in (NSArray *)obj) {
                            if ([self isMediaLayer:layer]) {
                                if (![result containsObject:layer])
                                    [result addObject:layer];
                            }
                        }
                    }
                } @catch (...) {}
            }

            if (result.count > 0) return; // Đã có layers, dừng scan
        }
    }

    // ── Nếu không tìm được qua controller, dùng runtime scan ──
    if (result.count == 0) {
        [self runtimeScanForLayers:result];
    }
}

// Kiểm tra xem một object có phải là media layer không
- (BOOL)isMediaLayer:(id)layer {
    if (!layer) return NO;
    // Có các method liên quan đến image/video → là media layer
    return [layer respondsToSelector:@selector(setImage:)]
        || [layer respondsToSelector:@selector(setSourceImage:)]
        || [layer respondsToSelector:@selector(setVideoURL:)]
        || [layer respondsToSelector:@selector(setMediaURL:)]
        || [layer respondsToSelector:@selector(setAsset:)]
        || [layer respondsToSelector:@selector(setAVAsset:)];
}

// Runtime scan: tìm tất cả instance của VS layer classes đang tồn tại
- (void)runtimeScanForLayers:(NSMutableArray *)result {
    // Scan tất cả loaded classes tìm VS layer/clip class
    unsigned int count;
    Class *classes = objc_copyClassList(&count);

    NSMutableArray *layerClasses = [NSMutableArray new];
    for (unsigned int i = 0; i < count; i++) {
        NSString *name = NSStringFromClass(classes[i]);
        if (!([name hasPrefix:@"VS"] || [name containsString:@"VideoStar"])) continue;

        BOOL isLayerClass =
            [name containsString:@"Layer"] ||
            [name containsString:@"Clip"]  ||
            [name containsString:@"Track"] ||
            [name containsString:@"Media"] ||
            [name containsString:@"Asset"] ||
            [name containsString:@"Segment"];

        if (isLayerClass) [layerClasses addObject:classes[i]];
    }
    free(classes);

    // Với mỗi class, thử lấy instances từ window subviews
    // (VideoStar thường giữ reference qua view tags hoặc associated objects)
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    dispatch_async(dispatch_get_main_queue(), ^{
        for (UIWindowScene *sc in [UIApplication sharedApplication].connectedScenes) {
            if (![sc isKindOfClass:[UIWindowScene class]]) continue;
            for (UIWindow *win in sc.windows) {
                [self scanViewForLayerObjects:win into:result];
            }
        }
        dispatch_semaphore_signal(sem);
    });
    dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC));
}

- (void)scanViewForLayerObjects:(UIView *)view into:(NSMutableArray *)result {
    // Kiểm tra associated objects trên view — VideoStar thường attach layer model vào view
    static const char *kLayerKey = "vsLayerModel";
    id model = objc_getAssociatedObject(view, kLayerKey);
    if (model && [self isMediaLayer:model] && ![result containsObject:model])
        [result addObject:model];

    // Kiểm tra chính view nếu nó là layer object (hybrid view-model)
    if ([self isMediaLayer:view] && ![result containsObject:view])
        [result addObject:view];

    for (UIView *sub in view.subviews) {
        [self scanViewForLayerObjects:sub into:result];
    }
}

// ════════════════════════════════════════════════════════
// MARK: - Pick Image
// ════════════════════════════════════════════════════════
- (void)pickImage {
    PHPickerConfiguration *cfg = [[PHPickerConfiguration alloc] init];
    cfg.selectionLimit = 1;
    cfg.filter = [PHPickerFilter imagesFilter];

    PHPickerViewController *picker = [[PHPickerViewController alloc]
        initWithConfiguration:cfg];
    picker.delegate = self;
    picker.modalPresentationStyle = UIModalPresentationFormSheet;

    UIViewController *root = self;
    while (root.presentingViewController) root = root.presentingViewController;
    [root presentViewController:picker animated:YES completion:nil];
}

- (void)picker:(PHPickerViewController *)picker
didFinishPicking:(NSArray<PHPickerResult *> *)results {
    [picker dismissViewControllerAnimated:YES completion:nil];
    if (!results.count) return;

    [[results.firstObject itemProvider]
        loadObjectOfClass:[UIImage class]
        completionHandler:^(UIImage *img, NSError *e) {
            if (!img) return;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self applyImage:img];
            });
        }];
}

// ════════════════════════════════════════════════════════
// MARK: - Apply to ALL layers
// ════════════════════════════════════════════════════════
- (void)applyImage:(UIImage *)img {
    NSArray *layers = [self.dataLayers copy];
    NSInteger total = layers.count;
    if (!total) return;

    _pickBtn.enabled = NO;
    _progressLabel.hidden = NO;
    _progressBar.hidden = NO;
    _progressBar.progress = 0;
    _progressLabel.text = [NSString stringWithFormat:@"Đang thay 0/%ld lớp...", (long)total];

    NSData *jpegData = UIImageJPEGRepresentation(img, 0.95)
                    ?: UIImagePNGRepresentation(img);

    // Lưu temp file cho video layers
    NSString *tmpPath = [NSTemporaryDirectory()
        stringByAppendingPathComponent:@"fvd_replace_media.jpg"];
    [jpegData writeToFile:tmpPath atomically:YES];
    NSURL *tmpURL = [NSURL fileURLWithPath:tmpPath];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        for (NSInteger i = 0; i < total; i++) {
            id layer = layers[i];

            dispatch_async(dispatch_get_main_queue(), ^{
                @try {
                    // setImage:
                    if ([layer respondsToSelector:@selector(setImage:)])
                        [layer performSelector:@selector(setImage:) withObject:img];

                    // setSourceImage:
                    if ([layer respondsToSelector:@selector(setSourceImage:)])
                        [layer performSelector:@selector(setSourceImage:) withObject:img];

                    // setVideoURL: / setMediaURL:
                    if ([layer respondsToSelector:@selector(setVideoURL:)])
                        [layer performSelector:@selector(setVideoURL:) withObject:tmpURL];
                    if ([layer respondsToSelector:@selector(setMediaURL:)])
                        [layer performSelector:@selector(setMediaURL:) withObject:tmpURL];

                    // setAsset: (AVAsset)
                    if ([layer respondsToSelector:@selector(setAsset:)]) {
                        Class avAsset = NSClassFromString(@"AVURLAsset");
                        if (avAsset) {
                            id asset = [[avAsset alloc] initWithURL:tmpURL options:nil];
                            [layer performSelector:@selector(setAsset:) withObject:asset];
                        }
                    }

                    // Notify layer to redraw/refresh
                    if ([layer respondsToSelector:@selector(setNeedsDisplay)])
                        [layer performSelector:@selector(setNeedsDisplay)];
                    if ([layer respondsToSelector:@selector(reload)])
                        [layer performSelector:@selector(reload)];
                    if ([layer respondsToSelector:@selector(refresh)])
                        [layer performSelector:@selector(refresh)];
                    if ([layer respondsToSelector:@selector(update)])
                        [layer performSelector:@selector(update)];

                    // If UIImageView
                    if ([layer isKindOfClass:[UIImageView class]])
                        ((UIImageView *)layer).image = img;

                } @catch (...) {}
            });

            CGFloat prog = (float)(i + 1) / (float)total;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.progressBar setProgress:prog animated:YES];
                self.progressLabel.text = [NSString stringWithFormat:
                    @"Đang thay %ld/%ld lớp...", (long)(i+1), (long)total];
            });

            [NSThread sleepForTimeInterval:0.01];
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            self.progressLabel.text = [NSString stringWithFormat:
                @"✅ Đã thay %ld lớp thành công!", (long)total];
            self.progressLabel.textColor = FVD_GREEN;
            self.countLabel.text = [NSString stringWithFormat:
                @"✅ Xong — %ld lớp đã cập nhật", (long)total];
            self.countLabel.textColor = FVD_GREEN;
            self.pickBtn.enabled = YES;
            [UIView animateWithDuration:0.2 animations:^{
                self.pickBtn.alpha = 1.0;
            }];
        });
    });
}

@end
