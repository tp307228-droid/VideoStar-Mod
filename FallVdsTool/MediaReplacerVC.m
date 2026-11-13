// MediaReplacerVC.m
// "Chạm Thay Media" — select one image, auto-replace ALL image/video layers in VideoStar

#import "MediaReplacerVC.h"
#import "Theme.h"
#import "SVGIcons.h"
#import <Photos/Photos.h>
#import <PhotosUI/PhotosUI.h>

// ── VideoStar private class declarations (linked at runtime) ─────────────────
// We use NSClassFromString / performSelector to avoid link-time issues
// These match VideoStar 15.x internal architecture
#define VS_CLIP_CLASS    @"VideoClip"
#define VS_PROJECT_CLASS @"VSProject"
#define VS_LAYER_IMAGE   @"VSImageLayer"
#define VS_LAYER_VIDEO   @"VSVideoLayer"

// ── Helper: shimmer loading view ─────────────────────────────────────────────
@interface FVDShimmerView : UIView
- (void)startShimmer;
- (void)stopShimmer;
@end
@implementation FVDShimmerView {
    CAGradientLayer *_shimmer;
}
- (void)startShimmer {
    _shimmer = [CAGradientLayer layer];
    _shimmer.colors = @[(id)[UIColor colorWithWhite:1 alpha:0.05].CGColor,
                        (id)[UIColor colorWithWhite:1 alpha:0.15].CGColor,
                        (id)[UIColor colorWithWhite:1 alpha:0.05].CGColor];
    _shimmer.startPoint = CGPointMake(0, 0.5);
    _shimmer.endPoint   = CGPointMake(1, 0.5);
    _shimmer.frame = self.bounds;
    [self.layer addSublayer:_shimmer];

    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"transform.translation.x"];
    anim.fromValue = @(-self.bounds.size.width);
    anim.toValue   = @(self.bounds.size.width);
    anim.duration  = 1.4;
    anim.repeatCount = HUGE_VALF;
    [_shimmer addAnimation:anim forKey:@"shimmer"];
}
- (void)stopShimmer { [_shimmer removeFromSuperlayer]; _shimmer = nil; }
@end

// ════════════════════════════════════════════════════════
// MARK: - MediaReplacerVC
// ════════════════════════════════════════════════════════
@interface MediaReplacerVC () <PHPickerViewControllerDelegate>
@property (nonatomic, strong) UIImage *selectedImage;
@property (nonatomic, strong) UIView  *previewCard;
@property (nonatomic, strong) UIImageView *previewImageView;
@property (nonatomic, strong) UILabel *previewLabel;
@property (nonatomic, strong) UIButton *pickBtn;
@property (nonatomic, strong) UIButton *applyBtn;
@property (nonatomic, strong) UIView  *progressContainer;
@property (nonatomic, strong) UIProgressView *progressBar;
@property (nonatomic, strong) UILabel *progressLabel;
@property (nonatomic, strong) UILabel *layerCountLabel;
@end

@implementation MediaReplacerVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.clearColor;
    [self buildUI];
}

- (void)buildUI {
    UIScrollView *scroll = [[UIScrollView alloc] init];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    scroll.showsVerticalScrollIndicator = NO;
    [self.view addSubview:scroll];

    UIView *content = [[UIView alloc] init];
    content.translatesAutoresizingMaskIntoConstraints = NO;
    [scroll addSubview:content];

    [NSLayoutConstraint activateConstraints:@[
        [scroll.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [scroll.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [scroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [scroll.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [content.topAnchor constraintEqualToAnchor:scroll.topAnchor],
        [content.leadingAnchor constraintEqualToAnchor:scroll.leadingAnchor],
        [content.trailingAnchor constraintEqualToAnchor:scroll.trailingAnchor],
        [content.bottomAnchor constraintEqualToAnchor:scroll.bottomAnchor],
        [content.widthAnchor constraintEqualToAnchor:scroll.widthAnchor],
    ]];

    // ── Description Card ─────────────────────────────────
    UIView *descCard = [[UIView alloc] init];
    descCard.translatesAutoresizingMaskIntoConstraints = NO;
    descCard.backgroundColor = [UIColor colorWithRed:0.3 green:0.1 blue:0.6 alpha:0.2];
    descCard.layer.cornerRadius = FVD_R_MD;
    descCard.layer.borderWidth  = 1;
    descCard.layer.borderColor  = [UIColor colorWithRed:0.55 green:0.25 blue:1 alpha:0.3].CGColor;

    UIImageView *descIcon = [[UIImageView alloc] initWithImage:FVDICON(FVDIconImage, 20, FVD_ACCENT)];
    descIcon.translatesAutoresizingMaskIntoConstraints = NO;
    descIcon.contentMode = UIViewContentModeScaleAspectFit;

    UILabel *descTitle = [UILabel new];
    descTitle.translatesAutoresizingMaskIntoConstraints = NO;
    descTitle.text = @"Chạm Thay Media";
    descTitle.font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
    descTitle.textColor = FVD_TEXT;

    UILabel *descText = [UILabel new];
    descText.translatesAutoresizingMaskIntoConstraints = NO;
    descText.text = @"Chọn 1 ảnh, tool sẽ tự động thay vào TẤT CẢ lớp ảnh & video trong dự án VideoStar hiện tại.";
    descText.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    descText.textColor = FVD_SUBTEXT;
    descText.numberOfLines = 0;

    [descCard addSubview:descIcon];
    [descCard addSubview:descTitle];
    [descCard addSubview:descText];

    [NSLayoutConstraint activateConstraints:@[
        [descIcon.leadingAnchor constraintEqualToAnchor:descCard.leadingAnchor constant:14],
        [descIcon.topAnchor constraintEqualToAnchor:descCard.topAnchor constant:14],
        [descIcon.widthAnchor constraintEqualToConstant:20],
        [descIcon.heightAnchor constraintEqualToConstant:20],
        [descTitle.leadingAnchor constraintEqualToAnchor:descIcon.trailingAnchor constant:8],
        [descTitle.centerYAnchor constraintEqualToAnchor:descIcon.centerYAnchor],
        [descText.topAnchor constraintEqualToAnchor:descIcon.bottomAnchor constant:8],
        [descText.leadingAnchor constraintEqualToAnchor:descCard.leadingAnchor constant:14],
        [descText.trailingAnchor constraintEqualToAnchor:descCard.trailingAnchor constant:-14],
        [descText.bottomAnchor constraintEqualToAnchor:descCard.bottomAnchor constant:-14],
    ]];

    // ── Layer count badge ─────────────────────────────────
    UIView *badgeCard = [[UIView alloc] init];
    badgeCard.translatesAutoresizingMaskIntoConstraints = NO;
    badgeCard.backgroundColor = FVD_CARD;
    badgeCard.layer.cornerRadius = FVD_R_SM;

    _layerCountLabel = [UILabel new];
    _layerCountLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _layerCountLabel.text = @"Phát hiện: — lớp media";
    _layerCountLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    _layerCountLabel.textColor = FVD_SUBTEXT;
    _layerCountLabel.textAlignment = NSTextAlignmentCenter;
    [badgeCard addSubview:_layerCountLabel];
    [NSLayoutConstraint activateConstraints:@[
        [_layerCountLabel.topAnchor constraintEqualToAnchor:badgeCard.topAnchor constant:8],
        [_layerCountLabel.leadingAnchor constraintEqualToAnchor:badgeCard.leadingAnchor constant:14],
        [_layerCountLabel.trailingAnchor constraintEqualToAnchor:badgeCard.trailingAnchor constant:-14],
        [_layerCountLabel.bottomAnchor constraintEqualToAnchor:badgeCard.bottomAnchor constant:-8],
    ]];

    // ── Preview Card ──────────────────────────────────────
    _previewCard = [[UIView alloc] init];
    _previewCard.translatesAutoresizingMaskIntoConstraints = NO;
    _previewCard.backgroundColor = FVD_CARD;
    _previewCard.layer.cornerRadius = FVD_R_MD;
    _previewCard.layer.borderWidth  = 1;
    _previewCard.layer.borderColor  = FVD_BORDER.CGColor;

    _previewImageView = [[UIImageView alloc] init];
    _previewImageView.translatesAutoresizingMaskIntoConstraints = NO;
    _previewImageView.contentMode = UIViewContentModeScaleAspectFill;
    _previewImageView.clipsToBounds = YES;
    _previewImageView.layer.cornerRadius = FVD_R_SM;
    _previewImageView.backgroundColor = FVD_BG;

    _previewLabel = [UILabel new];
    _previewLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _previewLabel.text = @"Chưa chọn ảnh";
    _previewLabel.font = [UIFont systemFontOfSize:12];
    _previewLabel.textColor = FVD_SUBTEXT;
    _previewLabel.textAlignment = NSTextAlignmentCenter;

    UILabel *previewTitle = [UILabel new];
    previewTitle.translatesAutoresizingMaskIntoConstraints = NO;
    previewTitle.text = @"Ảnh Đã Chọn";
    previewTitle.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    previewTitle.textColor = FVD_TEXT;

    [_previewCard addSubview:previewTitle];
    [_previewCard addSubview:_previewImageView];
    [_previewCard addSubview:_previewLabel];

    [NSLayoutConstraint activateConstraints:@[
        [previewTitle.topAnchor constraintEqualToAnchor:_previewCard.topAnchor constant:12],
        [previewTitle.leadingAnchor constraintEqualToAnchor:_previewCard.leadingAnchor constant:14],
        [_previewImageView.topAnchor constraintEqualToAnchor:previewTitle.bottomAnchor constant:10],
        [_previewImageView.centerXAnchor constraintEqualToAnchor:_previewCard.centerXAnchor],
        [_previewImageView.widthAnchor constraintEqualToConstant:140],
        [_previewImageView.heightAnchor constraintEqualToConstant:140],
        [_previewLabel.topAnchor constraintEqualToAnchor:_previewImageView.bottomAnchor constant:8],
        [_previewLabel.centerXAnchor constraintEqualToAnchor:_previewCard.centerXAnchor],
        [_previewLabel.bottomAnchor constraintEqualToAnchor:_previewCard.bottomAnchor constant:-12],
    ]];

    // ── Pick button ───────────────────────────────────────
    _pickBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    _pickBtn.translatesAutoresizingMaskIntoConstraints = NO;
    _pickBtn.backgroundColor = FVD_CARD;
    _pickBtn.layer.cornerRadius = FVD_R_MD;
    _pickBtn.layer.borderWidth  = 1.5;
    _pickBtn.layer.borderColor  = FVD_ACCENT.CGColor;

    UIImageView *pickIcon = [[UIImageView alloc] initWithImage:FVDICON(FVDIconImage, 20, FVD_ACCENT)];
    pickIcon.translatesAutoresizingMaskIntoConstraints = NO;
    pickIcon.contentMode = UIViewContentModeScaleAspectFit;
    UILabel *pickLbl = [UILabel new];
    pickLbl.translatesAutoresizingMaskIntoConstraints = NO;
    pickLbl.text = @"Chọn Ảnh Thay Thế";
    pickLbl.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    pickLbl.textColor = FVD_ACCENT;
    [_pickBtn addSubview:pickIcon];
    [_pickBtn addSubview:pickLbl];
    [_pickBtn addTarget:self action:@selector(pickImage) forControlEvents:UIControlEventTouchUpInside];
    [NSLayoutConstraint activateConstraints:@[
        [pickIcon.leadingAnchor constraintEqualToAnchor:_pickBtn.leadingAnchor constant:16],
        [pickIcon.centerYAnchor constraintEqualToAnchor:_pickBtn.centerYAnchor],
        [pickIcon.widthAnchor constraintEqualToConstant:20],
        [pickIcon.heightAnchor constraintEqualToConstant:20],
        [pickLbl.leadingAnchor constraintEqualToAnchor:pickIcon.trailingAnchor constant:10],
        [pickLbl.centerYAnchor constraintEqualToAnchor:_pickBtn.centerYAnchor],
        [_pickBtn.heightAnchor constraintEqualToConstant:50],
    ]];

    // ── Apply button ──────────────────────────────────────
    _applyBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    _applyBtn.translatesAutoresizingMaskIntoConstraints = NO;
    _applyBtn.layer.cornerRadius = FVD_R_MD;
    _applyBtn.alpha = 0.5;
    _applyBtn.enabled = NO;

    CAGradientLayer *applyGrad = FVDMakeGradient(FVD_ACCENT, FVD_ACCENT2, 90);
    applyGrad.cornerRadius = FVD_R_MD;
    applyGrad.frame = CGRectMake(0,0,10,10);
    [_applyBtn.layer insertSublayer:applyGrad atIndex:0];

    UIImageView *applyIcon = [[UIImageView alloc] initWithImage:FVDICON(FVDIconCheck, 20, UIColor.whiteColor)];
    applyIcon.translatesAutoresizingMaskIntoConstraints = NO;
    applyIcon.contentMode = UIViewContentModeScaleAspectFit;
    UILabel *applyLbl = [UILabel new];
    applyLbl.translatesAutoresizingMaskIntoConstraints = NO;
    applyLbl.text = @"Áp Dụng Cho Tất Cả Lớp";
    applyLbl.font = [UIFont systemFontOfSize:15 weight:UIFontWeightBold];
    applyLbl.textColor = UIColor.whiteColor;
    [_applyBtn addSubview:applyIcon];
    [_applyBtn addSubview:applyLbl];
    [_applyBtn addTarget:self action:@selector(applyMedia) forControlEvents:UIControlEventTouchUpInside];
    [NSLayoutConstraint activateConstraints:@[
        [applyIcon.leadingAnchor constraintEqualToAnchor:_applyBtn.leadingAnchor constant:16],
        [applyIcon.centerYAnchor constraintEqualToAnchor:_applyBtn.centerYAnchor],
        [applyIcon.widthAnchor constraintEqualToConstant:20],
        [applyIcon.heightAnchor constraintEqualToConstant:20],
        [applyLbl.leadingAnchor constraintEqualToAnchor:applyIcon.trailingAnchor constant:10],
        [applyLbl.centerYAnchor constraintEqualToAnchor:_applyBtn.centerYAnchor],
        [_applyBtn.heightAnchor constraintEqualToConstant:52],
    ]];

    // ── Progress container ────────────────────────────────
    _progressContainer = [[UIView alloc] init];
    _progressContainer.translatesAutoresizingMaskIntoConstraints = NO;
    _progressContainer.backgroundColor = FVD_CARD;
    _progressContainer.layer.cornerRadius = FVD_R_MD;
    _progressContainer.hidden = YES;

    _progressBar = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    _progressBar.translatesAutoresizingMaskIntoConstraints = NO;
    _progressBar.progressTintColor  = FVD_ACCENT;
    _progressBar.trackTintColor     = FVD_BG;
    _progressBar.layer.cornerRadius = 3;
    _progressBar.clipsToBounds = YES;

    _progressLabel = [UILabel new];
    _progressLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _progressLabel.text = @"Đang xử lý...";
    _progressLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    _progressLabel.textColor = FVD_SUBTEXT;
    _progressLabel.textAlignment = NSTextAlignmentCenter;

    [_progressContainer addSubview:_progressBar];
    [_progressContainer addSubview:_progressLabel];
    [NSLayoutConstraint activateConstraints:@[
        [_progressLabel.topAnchor constraintEqualToAnchor:_progressContainer.topAnchor constant:12],
        [_progressLabel.centerXAnchor constraintEqualToAnchor:_progressContainer.centerXAnchor],
        [_progressBar.topAnchor constraintEqualToAnchor:_progressLabel.bottomAnchor constant:8],
        [_progressBar.leadingAnchor constraintEqualToAnchor:_progressContainer.leadingAnchor constant:14],
        [_progressBar.trailingAnchor constraintEqualToAnchor:_progressContainer.trailingAnchor constant:-14],
        [_progressBar.heightAnchor constraintEqualToConstant:6],
        [_progressContainer.bottomAnchor constraintEqualToAnchor:_progressBar.bottomAnchor constant:12],
    ]];

    // ── Add to content ────────────────────────────────────
    for (UIView *v in @[descCard, badgeCard, _previewCard, _pickBtn, _applyBtn, _progressContainer]) {
        [content addSubview:v];
    }
    [NSLayoutConstraint activateConstraints:@[
        [descCard.topAnchor constraintEqualToAnchor:content.topAnchor constant:12],
        [descCard.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:14],
        [descCard.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-14],

        [badgeCard.topAnchor constraintEqualToAnchor:descCard.bottomAnchor constant:10],
        [badgeCard.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:14],
        [badgeCard.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-14],

        [_previewCard.topAnchor constraintEqualToAnchor:badgeCard.bottomAnchor constant:12],
        [_previewCard.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:14],
        [_previewCard.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-14],

        [_pickBtn.topAnchor constraintEqualToAnchor:_previewCard.bottomAnchor constant:12],
        [_pickBtn.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:14],
        [_pickBtn.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-14],

        [_applyBtn.topAnchor constraintEqualToAnchor:_pickBtn.bottomAnchor constant:10],
        [_applyBtn.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:14],
        [_applyBtn.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-14],

        [_progressContainer.topAnchor constraintEqualToAnchor:_applyBtn.bottomAnchor constant:10],
        [_progressContainer.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:14],
        [_progressContainer.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-14],
        [_progressContainer.bottomAnchor constraintEqualToAnchor:content.bottomAnchor constant:-20],
    ]];

    // Detect layer count
    dispatch_async(dispatch_get_main_queue(), ^{
        NSInteger count = [self detectLayerCount];
        self.layerCountLabel.text = count > 0
            ? [NSString stringWithFormat:@"Phát hiện: %ld lớp media", (long)count]
            : @"Không tìm thấy lớp media — mở project trước";
        self.layerCountLabel.textColor = count > 0 ? FVD_GREEN : FVD_RED;
    });
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    // Resize gradient layers
    for (UIView *v in @[_applyBtn]) {
        for (CALayer *l in v.layer.sublayers) {
            if ([l isKindOfClass:[CAGradientLayer class]]) {
                l.frame = v.bounds;
                l.cornerRadius = v.layer.cornerRadius;
            }
        }
    }
}

// ── MARK: Layer Detection ─────────────────────────────────────────────────────
- (NSInteger)detectLayerCount {
    // Try to reach VideoStar's project model via known class names
    NSInteger count = 0;

    // Pattern 1: VSProjectController.sharedController.currentProject.layers
    Class ctrl = NSClassFromString(@"VSProjectController");
    if (ctrl) {
        id shared = [ctrl performSelector:@selector(sharedController) withObject:nil];
        if (shared) {
            id project = [shared performSelector:@selector(currentProject) withObject:nil];
            if (project) {
                NSArray *layers = [project performSelector:@selector(layers) withObject:nil];
                count = layers.count;
            }
        }
    }

    // Pattern 2: VSDocumentController
    if (count == 0) {
        Class docCtrl = NSClassFromString(@"VSDocumentController");
        if (docCtrl) {
            id shared = [docCtrl performSelector:@selector(sharedDocumentController) withObject:nil];
            if (shared) {
                NSArray *docs = [shared performSelector:@selector(documents) withObject:nil];
                if (docs.count) {
                    id doc = docs.firstObject;
                    NSArray *layers = [doc performSelector:@selector(allLayers) withObject:nil];
                    count = layers.count;
                }
            }
        }
    }

    return count;
}

// ── MARK: Pick Image ──────────────────────────────────────────────────────────
- (void)pickImage {
    PHPickerConfiguration *config = [[PHPickerConfiguration alloc] init];
    config.selectionLimit = 1;
    config.filter = [PHPickerFilter imagesFilter];

    PHPickerViewController *picker = [[PHPickerViewController alloc] initWithConfiguration:config];
    picker.delegate = self;

    UIViewController *root = self;
    while (root.presentingViewController) root = root.presentingViewController;
    [root presentViewController:picker animated:YES completion:nil];
}

- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results {
    [picker dismissViewControllerAnimated:YES completion:nil];
    if (!results.count) return;

    PHPickerResult *result = results.firstObject;
    [result.itemProvider loadObjectOfClass:[UIImage class] completionHandler:^(UIImage *image, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (image) {
                self.selectedImage = image;
                self.previewImageView.image = image;
                self.previewLabel.text = @"Ảnh đã chọn ✓";
                self.previewLabel.textColor = FVD_GREEN;
                self.applyBtn.enabled = YES;
                [UIView animateWithDuration:0.3 animations:^{ self.applyBtn.alpha = 1.0; }];
            }
        });
    }];
}

// ── MARK: Apply Media ─────────────────────────────────────────────────────────
- (void)applyMedia {
    if (!_selectedImage) return;

    _progressContainer.hidden = NO;
    _applyBtn.enabled = NO;
    _pickBtn.enabled  = NO;
    _progressBar.progress = 0;
    _progressLabel.text = @"Đang tìm lớp media...";

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSArray *layers = [self getAllMediaLayers];
        NSInteger total = layers.count;

        if (total == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.progressLabel.text = @"Không tìm thấy lớp nào.";
                [self finishApply:NO];
            });
            return;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            self.progressLabel.text = [NSString stringWithFormat:@"Đang thay %ld lớp...", (long)total];
        });

        // Convert image to data once
        NSData *imgData = UIImageJPEGRepresentation(self->_selectedImage, 0.95);
        if (!imgData) imgData = UIImagePNGRepresentation(self->_selectedImage);

        for (NSInteger i = 0; i < total; i++) {
            id layer = layers[i];
            [self replaceMediaInLayer:layer withImageData:imgData];

            CGFloat progress = (CGFloat)(i + 1) / (CGFloat)total;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.progressBar setProgress:progress animated:YES];
                self.progressLabel.text = [NSString stringWithFormat:@"Đang xử lý %ld/%ld...", (long)(i+1), (long)total];
            });
            [NSThread sleepForTimeInterval:0.02]; // small delay for UI update
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            self.progressLabel.text = [NSString stringWithFormat:@"✅ Đã thay %ld lớp!", (long)total];
            [self finishApply:YES];
        });
    });
}

- (NSArray *)getAllMediaLayers {
    NSMutableArray *result = [NSMutableArray new];

    // Try multiple access patterns
    SEL selectors[] = {
        @selector(layers),
        @selector(allLayers),
        @selector(videoLayers),
    };

    // Pattern 1: VSProjectController
    Class ctrl = NSClassFromString(@"VSProjectController");
    if (ctrl) {
        id shared = [ctrl performSelector:@selector(sharedController)];
        if (shared) {
            id project = [shared performSelector:@selector(currentProject)];
            if (project) {
                for (int i = 0; i < 3; i++) {
                    if ([project respondsToSelector:selectors[i]]) {
                        NSArray *ls = [project performSelector:selectors[i]];
                        if (ls.count) { [result addObjectsFromArray:ls]; break; }
                    }
                }
            }
        }
    }

    // If nothing found, walk the view hierarchy for video/image layer objects
    if (result.count == 0) {
        UIWindow *win = nil;
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                win = scene.windows.firstObject;
                break;
            }
        }
        if (win) [self collectLayerObjectsFromView:win into:result];
    }

    return result;
}

- (void)collectLayerObjectsFromView:(UIView *)view into:(NSMutableArray *)arr {
    // Check if this view responds to media replacement selectors
    if ([view respondsToSelector:@selector(setImage:)] &&
        [view respondsToSelector:@selector(image)]) {
        [arr addObject:view];
    }
    if ([view respondsToSelector:@selector(setVideoURL:)]) {
        [arr addObject:view];
    }
    for (UIView *sub in view.subviews) {
        [self collectLayerObjectsFromView:sub into:arr];
    }
}

- (void)replaceMediaInLayer:(id)layer withImageData:(NSData *)data {
    UIImage *img = [UIImage imageWithData:data];
    if (!img) return;

    // Try setting image directly
    if ([layer respondsToSelector:@selector(setImage:)]) {
        [layer performSelector:@selector(setImage:) withObject:img];
    }
    // Try setSourceImage
    if ([layer respondsToSelector:@selector(setSourceImage:)]) {
        [layer performSelector:@selector(setSourceImage:) withObject:img];
    }
    // For video layers: write image as temp file and set URL
    if ([layer respondsToSelector:@selector(setVideoURL:)]) {
        NSURL *tmpURL = [self saveTempImage:img];
        if (tmpURL) [layer performSelector:@selector(setVideoURL:) withObject:tmpURL];
    }
    // If it's a UIImageView
    if ([layer isKindOfClass:[UIImageView class]]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            ((UIImageView *)layer).image = img;
        });
    }
    // Trigger refresh if available
    if ([layer respondsToSelector:@selector(setNeedsDisplay)]) {
        dispatch_async(dispatch_get_main_queue(), ^{ [layer setNeedsDisplay]; });
    }
}

- (NSURL *)saveTempImage:(UIImage *)img {
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"fvd_replace.jpg"];
    NSData *data = UIImageJPEGRepresentation(img, 0.95);
    if ([data writeToFile:path atomically:YES]) {
        return [NSURL fileURLWithPath:path];
    }
    return nil;
}

- (void)finishApply:(BOOL)success {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.applyBtn.enabled = YES;
        self.pickBtn.enabled  = YES;
        if (!success) {
            self.progressContainer.hidden = YES;
        }
    });
}

@end
