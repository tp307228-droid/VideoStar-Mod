// MediaReplacerVC.m
// Flow: tap tab → auto mở VideoStar's own media picker (cái bình thường khi bấm thay media)
//       chọn xong → auto thay TẤT CẢ lớp → không bấm gì thêm

#import "MediaReplacerVC.h"
#import "Theme.h"
#import "SVGIcons.h"
#import <objc/runtime.h>
#import <Photos/Photos.h>
#import <PhotosUI/PhotosUI.h>

// ════════════════════════════════════════════════════════
// MARK: - MediaReplacerVC
// ════════════════════════════════════════════════════════
@interface MediaReplacerVC () <PHPickerViewControllerDelegate>
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, assign) BOOL didOpenPicker;
@end

@implementation MediaReplacerVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.clearColor;
    [self buildMinimalUI];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!self.didOpenPicker) {
        self.didOpenPicker = YES;
        [self openVSMediaPicker];
    }
}

- (void)buildMinimalUI {
    _spinner = [[UIActivityIndicatorView alloc]
        initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    _spinner.translatesAutoresizingMaskIntoConstraints = NO;
    _spinner.color = FVD_ACCENT;
    [_spinner startAnimating];

    _statusLabel = [UILabel new];
    _statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _statusLabel.text = @"Đang mở chọn ảnh...";
    _statusLabel.font = [UIFont systemFontOfSize:13];
    _statusLabel.textColor = FVD_SUBTEXT;
    _statusLabel.textAlignment = NSTextAlignmentCenter;
    _statusLabel.numberOfLines = 0;

    [self.view addSubview:_spinner];
    [self.view addSubview:_statusLabel];
    [NSLayoutConstraint activateConstraints:@[
        [_spinner.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [_spinner.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor constant:-16],
        [_statusLabel.topAnchor constraintEqualToAnchor:_spinner.bottomAnchor constant:10],
        [_statusLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [_statusLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [_statusLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
    ]];
}

// ════════════════════════════════════════════════════════
// MARK: - Open VideoStar's Own Media Picker
// ════════════════════════════════════════════════════════
- (void)openVSMediaPicker {
    // ── Step 1: Try to trigger VideoStar's native "replace media" flow ──────
    // VideoStar's picker shows their asset library (3D text, overlays, etc.) + photos.
    // We find it by scanning all loaded VC classes for known VS patterns,
    // OR by calling the replace selector on the current selected layer.

    // Try direct "replace" on current layer first
    if ([self triggerNativeReplaceOnCurrentLayer]) return;

    // Try to find and present VS media picker class
    if ([self presentVSMediaPickerClass]) return;

    // Fallback: PHPicker (at least works)
    [self presentFallbackPicker];
}

// ── Method 1: Trigger VideoStar's own replace flow on selected layer ──────────
- (BOOL)triggerNativeReplaceOnCurrentLayer {
    // Find selected layer / clip in VideoStar's project controller
    id selectedLayer = nil;

    Class ctrl = NSClassFromString(@"VSProjectController");
    if (ctrl && [ctrl respondsToSelector:@selector(sharedController)]) {
        id shared = [ctrl performSelector:@selector(sharedController)];
        // Try selectedLayer, selectedClip, currentLayer, etc.
        for (NSString *s in @[@"selectedLayer",@"selectedClip",@"currentLayer",@"currentClip",@"activeLayer"]) {
            SEL sel = NSSelectorFromString(s);
            if ([shared respondsToSelector:sel]) {
                selectedLayer = [shared performSelector:sel];
                if (selectedLayer) break;
            }
        }
        // Also try from currentProject
        if (!selectedLayer) {
            id project = [shared respondsToSelector:@selector(currentProject)]
                ? [shared performSelector:@selector(currentProject)] : nil;
            for (NSString *s in @[@"selectedLayer",@"selectedClip",@"currentLayer"]) {
                SEL sel = NSSelectorFromString(s);
                if ([project respondsToSelector:sel]) {
                    selectedLayer = [project performSelector:sel];
                    if (selectedLayer) break;
                }
            }
        }
    }

    if (!selectedLayer) return NO;

    // Try to call replace/changeMedia on the layer
    // This will trigger VideoStar's own picker natively
    for (NSString *s in @[@"replaceMedia", @"changeMedia", @"replaceClip",
                          @"showMediaPicker", @"pickReplacementMedia"]) {
        SEL sel = NSSelectorFromString(s);
        if ([selectedLayer respondsToSelector:sel]) {
            [selectedLayer performSelector:sel withObject:nil afterDelay:0];
            // Swizzle result to apply to all layers after user picks
            [self hookVSPickerCompletion];
            return YES;
        }
    }
    return NO;
}

// ── Method 2: Find VideoStar's media picker VC class by runtime scan ──────────
- (BOOL)presentVSMediaPickerClass {
    // Keywords that VS commonly uses for their asset/media picker
    NSArray *patterns = @[
        @"VSMediaLibraryViewController",
        @"VSAssetPickerViewController",
        @"VSMediaPickerViewController",
        @"VSStockMediaViewController",
        @"VSContentPickerViewController",
        @"VideoStarMediaPicker",
        @"VSLibraryViewController",
        @"VSAssetLibraryViewController",
    ];

    // First try known names directly
    for (NSString *name in patterns) {
        Class cls = NSClassFromString(name);
        if (cls && [cls isSubclassOfClass:[UIViewController class]]) {
            return [self instantiateAndPresent:cls];
        }
    }

    // Runtime scan for any VS*ViewController that deals with media/assets
    unsigned int count;
    Class *classes = objc_copyClassList(&count);
    Class found = Nil;

    for (unsigned int i = 0; i < count; i++) {
        NSString *name = NSStringFromClass(classes[i]);
        if (![name hasPrefix:@"VS"]) continue;
        if (![classes[i] isSubclassOfClass:[UIViewController class]]) continue;

        BOOL hasMedia = [name containsString:@"Media"] || [name containsString:@"Asset"]
                     || [name containsString:@"Library"] || [name containsString:@"Stock"]
                     || [name containsString:@"Content"] || [name containsString:@"Picker"];
        if (hasMedia) {
            found = classes[i];
            break;
        }
    }
    free(classes);

    if (found) return [self instantiateAndPresent:found];
    return NO;
}

- (BOOL)instantiateAndPresent:(Class)cls {
    @try {
        UIViewController *vc = [[cls alloc] init];
        if (!vc) return NO;

        // Try to set a completion/delegate that we intercept
        // Set ourselves as delegate if the picker uses a delegate pattern
        for (NSString *s in @[@"setDelegate:",@"setPickerDelegate:",@"setCompletionBlock:"]) {
            SEL sel = NSSelectorFromString(s);
            if ([vc respondsToSelector:sel]) {
                // We'll hook after presentation via observation
                break;
            }
        }

        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        nav.modalPresentationStyle = UIModalPresentationFormSheet;

        UIViewController *root = self;
        while (root.presentingViewController) root = root.presentingViewController;
        [root presentViewController:nav animated:YES completion:nil];

        // After picker presented, hook dismiss to capture selection
        [self hookVSPickerCompletion];
        [self updateStatus:@"Chọn ảnh từ thư viện VideoStar..."];
        return YES;
    } @catch (...) {
        return NO;
    }
}

// ── Method 3: Fallback PHPicker ───────────────────────────────────────────────
- (void)presentFallbackPicker {
    PHPickerConfiguration *cfg = [[PHPickerConfiguration alloc] init];
    cfg.selectionLimit = 1;
    cfg.filter = [PHPickerFilter imagesFilter];

    PHPickerViewController *picker = [[PHPickerViewController alloc] initWithConfiguration:cfg];
    picker.delegate = self;
    picker.modalPresentationStyle = UIModalPresentationFormSheet;

    UIViewController *root = self;
    while (root.presentingViewController) root = root.presentingViewController;
    [root presentViewController:picker animated:YES completion:nil];
    [self updateStatus:@"Chọn ảnh để thay..."];
}

// PHPicker delegate (fallback)
- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results {
    [picker dismissViewControllerAnimated:YES completion:nil];
    if (!results.count) {
        [self updateStatus:@"Đã huỷ."];
        return;
    }
    [[results.firstObject itemProvider] loadObjectOfClass:[UIImage class]
                                       completionHandler:^(UIImage *img, NSError *e) {
        if (!img) return;
        dispatch_async(dispatch_get_main_queue(), ^{ [self applyImageToAllLayers:img]; });
    }];
}

// ── Hook VideoStar picker completion ─────────────────────────────────────────
// When VideoStar's picker dismisses, check if any layer's media changed and
// propagate that change to ALL other layers.
- (void)hookVSPickerCompletion {
    // Store snapshot of current layer media state before picker
    // After picker dismisses, diff the state and copy the changed media to all layers
    __weak typeof(self) weak = self;
    NSArray *layers = [self getAllLayers];
    NSMutableArray *beforeSnapshots = [NSMutableArray new];
    for (id layer in layers) {
        id img = nil;
        @try {
            if ([layer respondsToSelector:@selector(image)]) img = [layer performSelector:@selector(image)];
            else if ([layer respondsToSelector:@selector(sourceImage)]) img = [layer performSelector:@selector(sourceImage)];
        } @catch (...) {}
        [beforeSnapshots addObject:img ?: [NSNull null]];
    }

    // Poll after picker expected to close (simple approach)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weak pollForChangedLayer:layers beforeSnapshots:beforeSnapshots attempts:20];
    });
}

- (void)pollForChangedLayer:(NSArray *)layers beforeSnapshots:(NSArray *)before attempts:(int)left {
    if (left <= 0) return;

    // Check if any layer's image changed
    UIImage *changedImg = nil;
    for (NSInteger i = 0; i < layers.count; i++) {
        id layer = layers[i];
        id nowImg = nil;
        @try {
            if ([layer respondsToSelector:@selector(image)]) nowImg = [layer performSelector:@selector(image)];
            else if ([layer respondsToSelector:@selector(sourceImage)]) nowImg = [layer performSelector:@selector(sourceImage)];
        } @catch (...) {}

        id wasImg = before[i];
        BOOL changed = (nowImg != nil && nowImg != [NSNull null])
                    && (wasImg == [NSNull null] || nowImg != wasImg);
        if (changed && [nowImg isKindOfClass:[UIImage class]]) {
            changedImg = (UIImage *)nowImg;
            break;
        }
    }

    if (changedImg) {
        [self applyImageToAllLayers:changedImg];
        return;
    }

    // Keep polling
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self pollForChangedLayer:layers beforeSnapshots:before attempts:left - 1];
    });
}

// ════════════════════════════════════════════════════════
// MARK: - Apply to All Layers
// ════════════════════════════════════════════════════════
- (void)applyImageToAllLayers:(UIImage *)img {
    [self updateStatus:@"Đang thay tất cả lớp..."];

    NSData *data = UIImageJPEGRepresentation(img, 0.95) ?: UIImagePNGRepresentation(img);
    NSArray *layers = [self getAllLayers];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        for (id layer in layers) {
            dispatch_async(dispatch_get_main_queue(), ^{
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
                            [layer performSelector:@selector(setVideoURL:)
                                       withObject:[NSURL fileURLWithPath:p]];
                    }
                    if ([layer respondsToSelector:@selector(setNeedsDisplay)])
                        [layer performSelector:@selector(setNeedsDisplay)];
                } @catch (...) {}
            });
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.spinner stopAnimating];
            self.spinner.hidden = YES;
            if (layers.count > 0) {
                [self updateStatus:[NSString stringWithFormat:@"✅ Đã thay %ld lớp!", (long)layers.count]];
                self.statusLabel.textColor = FVD_GREEN;
            } else {
                [self updateStatus:@"Không tìm thấy lớp.\nMở project VideoStar rồi thử lại."];
                self.statusLabel.textColor = FVD_RED;
            }
        });
    });
}

// ════════════════════════════════════════════════════════
// MARK: - Helpers
// ════════════════════════════════════════════════════════
- (NSArray *)getAllLayers {
    NSMutableArray *result = [NSMutableArray new];

    Class ctrl = NSClassFromString(@"VSProjectController");
    if (ctrl && [ctrl respondsToSelector:@selector(sharedController)]) {
        id shared = [ctrl performSelector:@selector(sharedController)];
        id project = [shared respondsToSelector:@selector(currentProject)]
            ? [shared performSelector:@selector(currentProject)] : nil;
        if (project) {
            for (NSString *s in @[@"layers",@"allLayers",@"videoLayers",@"imageLayers",@"clips"]) {
                SEL sel = NSSelectorFromString(s);
                if ([project respondsToSelector:sel]) {
                    id obj = [project performSelector:sel];
                    if ([obj isKindOfClass:[NSArray class]] && [(NSArray*)obj count]) {
                        [result addObjectsFromArray:(NSArray*)obj]; break;
                    }
                }
            }
        }
    }

    if (!result.count) {
        // Fallback: scan UIImageViews from window hierarchy
        for (UIWindowScene *sc in [UIApplication sharedApplication].connectedScenes) {
            if (![sc isKindOfClass:[UIWindowScene class]]) continue;
            for (UIWindow *win in sc.windows) {
                [self collectViews:win into:result];
            }
        }
    }
    return result;
}

- (void)collectViews:(UIView *)v into:(NSMutableArray *)arr {
    NSString *cls = NSStringFromClass([v class]);
    if ([cls containsString:@"FVD"] || [cls containsString:@"FallVds"]) return;
    if ([v isKindOfClass:[UIImageView class]] && ((UIImageView*)v).image) [arr addObject:v];
    else if ([v respondsToSelector:@selector(setSourceImage:)]) [arr addObject:v];
    else if ([v respondsToSelector:@selector(setVideoURL:)])    [arr addObject:v];
    for (UIView *sub in v.subviews) [self collectViews:sub into:arr];
}

- (void)updateStatus:(NSString *)text {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.statusLabel.text = text;
        self.statusLabel.textColor = FVD_SUBTEXT;
    });
}

@end
