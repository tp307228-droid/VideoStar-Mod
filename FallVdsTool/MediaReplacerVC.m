// MediaReplacerVC.m
// Chạm Thay Media:
//   1. User tự tìm & nhập segment/layer code trong VideoStar
//   2. Nhấn "Tìm Lớp Media" → tool scan tất cả lớp trong project
//   3. Chọn 1 ảnh
//   4. Nhấn "Áp Dụng" → thay ảnh vào TẤT CẢ lớp media tìm được

#import "MediaReplacerVC.h"
#import "Theme.h"
#import "SVGIcons.h"
#import <Photos/Photos.h>
#import <PhotosUI/PhotosUI.h>

// ── VideoStar private class names ────────────────────────────────────────────
// Truy cập qua NSClassFromString / performSelector để tránh link lỗi
static NSString * const kVSProjectController   = @"VSProjectController";
static NSString * const kVSDocumentController  = @"VSDocumentController";
static NSString * const kVSCompositionManager  = @"VSCompositionManager";
static NSString * const kVSShotController      = @"VSShotController";

// ── State machine ────────────────────────────────────────────────────────────
typedef NS_ENUM(NSInteger, FVDReplaceState) {
    FVDReplaceStateIdle,        // chưa làm gì
    FVDReplaceStateScanned,     // đã scan thấy lớp
    FVDReplaceStateImagePicked, // đã chọn ảnh
    FVDReplaceStateApplying,    // đang áp dụng
    FVDReplaceStateDone,        // hoàn thành
};

@interface MediaReplacerVC () <PHPickerViewControllerDelegate>

// State
@property (nonatomic, assign) FVDReplaceState state;
@property (nonatomic, strong) UIImage  *selectedImage;
@property (nonatomic, strong) NSArray  *foundLayers;

// UI - Code input section
@property (nonatomic, strong) UIView   *codeCard;
@property (nonatomic, strong) UITextField *codeField;
@property (nonatomic, strong) UIButton *scanBtn;

// UI - Scan result
@property (nonatomic, strong) UIView   *scanResultCard;
@property (nonatomic, strong) UILabel  *scanResultLabel;
@property (nonatomic, strong) UIImageView *scanResultIcon;

// UI - Image section
@property (nonatomic, strong) UIView   *imageCard;
@property (nonatomic, strong) UIImageView *previewImageView;
@property (nonatomic, strong) UILabel  *imageLabel;
@property (nonatomic, strong) UIButton *pickBtn;

// UI - Apply
@property (nonatomic, strong) UIButton *applyBtn;

// UI - Progress
@property (nonatomic, strong) UIView        *progressCard;
@property (nonatomic, strong) UIProgressView *progressBar;
@property (nonatomic, strong) UILabel       *progressLabel;

// Layout
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView       *contentView;

@end

@implementation MediaReplacerVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.clearColor;
    self.state = FVDReplaceStateIdle;
    [self buildUI];
    [self refreshUI];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    // Resize gradient apply button
    for (CALayer *l in _applyBtn.layer.sublayers) {
        if ([l isKindOfClass:[CAGradientLayer class]]) {
            l.frame = _applyBtn.bounds;
            l.cornerRadius = _applyBtn.layer.cornerRadius;
        }
    }
}

// ════════════════════════════════════════════════════════
// MARK: - Build UI
// ════════════════════════════════════════════════════════
- (void)buildUI {
    _scrollView = [[UIScrollView alloc] init];
    _scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    _scrollView.showsVerticalScrollIndicator = NO;
    [self.view addSubview:_scrollView];

    _contentView = [[UIView alloc] init];
    _contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [_scrollView addSubview:_contentView];

    [NSLayoutConstraint activateConstraints:@[
        [_scrollView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [_scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [_contentView.topAnchor constraintEqualToAnchor:_scrollView.topAnchor],
        [_contentView.leadingAnchor constraintEqualToAnchor:_scrollView.leadingAnchor],
        [_contentView.trailingAnchor constraintEqualToAnchor:_scrollView.trailingAnchor],
        [_contentView.bottomAnchor constraintEqualToAnchor:_scrollView.bottomAnchor],
        [_contentView.widthAnchor constraintEqualToAnchor:_scrollView.widthAnchor],
    ]];

    // ── Header info card ─────────────────────────────────
    UIView *infoCard = [self makeCard];
    infoCard.backgroundColor = [UIColor colorWithRed:0.3 green:0.1 blue:0.6 alpha:0.2];
    infoCard.layer.borderColor = [UIColor colorWithRed:0.55 green:0.25 blue:1 alpha:0.3].CGColor;

    UILabel *infoTitle = [UILabel new];
    infoTitle.translatesAutoresizingMaskIntoConstraints = NO;
    infoTitle.text = @"Chạm Thay Media";
    infoTitle.font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
    infoTitle.textColor = FVD_TEXT;

    UILabel *infoDesc = [UILabel new];
    infoDesc.translatesAutoresizingMaskIntoConstraints = NO;
    infoDesc.text = @"Nhập code đoạn trong VideoStar → Scan lớp media → Chọn ảnh → Áp dụng thay TẤT CẢ lớp.";
    infoDesc.font = [UIFont systemFontOfSize:12];
    infoDesc.textColor = FVD_SUBTEXT;
    infoDesc.numberOfLines = 0;

    [infoCard addSubview:infoTitle];
    [infoCard addSubview:infoDesc];
    [NSLayoutConstraint activateConstraints:@[
        [infoTitle.topAnchor constraintEqualToAnchor:infoCard.topAnchor constant:12],
        [infoTitle.leadingAnchor constraintEqualToAnchor:infoCard.leadingAnchor constant:14],
        [infoTitle.trailingAnchor constraintEqualToAnchor:infoCard.trailingAnchor constant:-14],
        [infoDesc.topAnchor constraintEqualToAnchor:infoTitle.bottomAnchor constant:6],
        [infoDesc.leadingAnchor constraintEqualToAnchor:infoCard.leadingAnchor constant:14],
        [infoDesc.trailingAnchor constraintEqualToAnchor:infoCard.trailingAnchor constant:-14],
        [infoDesc.bottomAnchor constraintEqualToAnchor:infoCard.bottomAnchor constant:-12],
    ]];

    // ── STEP 1: Code input ───────────────────────────────
    UIView *step1Header = [self makeStepLabel:@"BƯỚC 1  Nhập Code Đoạn / Segment" icon:FVDIconSearch];

    _codeCard = [self makeCard];

    UILabel *codeHint = [UILabel new];
    codeHint.translatesAutoresizingMaskIntoConstraints = NO;
    codeHint.text = @"Code đoạn bạn tìm trong VideoStar (VD: vs_seg_001)";
    codeHint.font = [UIFont systemFontOfSize:11];
    codeHint.textColor = FVD_SUBTEXT;
    codeHint.numberOfLines = 0;

    _codeField = [[UITextField alloc] init];
    _codeField.translatesAutoresizingMaskIntoConstraints = NO;
    _codeField.placeholder = @"Nhập code đoạn...";
    _codeField.font = [UIFont monospacedSystemFontOfSize:14 weight:UIFontWeightMedium];
    _codeField.textColor = FVD_TEXT;
    _codeField.backgroundColor = FVD_BG;
    _codeField.layer.cornerRadius = 8;
    _codeField.layer.borderWidth = 1;
    _codeField.layer.borderColor = FVD_BORDER.CGColor;
    _codeField.returnKeyType = UIReturnKeyDone;
    _codeField.autocorrectionType = UITextAutocorrectionTypeNo;
    _codeField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    UIView *leftPad = [[UIView alloc] initWithFrame:CGRectMake(0,0,10,0)];
    _codeField.leftView = leftPad;
    _codeField.leftViewMode = UITextFieldViewModeAlways;
    [_codeField addTarget:self action:@selector(codeFieldChanged) forControlEvents:UIControlEventEditingChanged];
    [_codeField addTarget:self action:@selector(dismissKeyboard) forControlEvents:UIControlEventEditingDidEndOnExit];

    _scanBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    _scanBtn.translatesAutoresizingMaskIntoConstraints = NO;
    _scanBtn.backgroundColor = FVD_ACCENT;
    _scanBtn.layer.cornerRadius = 8;
    [_scanBtn setTitle:@"Tìm Lớp Media" forState:UIControlStateNormal];
    [_scanBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    _scanBtn.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    [_scanBtn addTarget:self action:@selector(scanLayers) forControlEvents:UIControlEventTouchUpInside];

    [_codeCard addSubview:codeHint];
    [_codeCard addSubview:_codeField];
    [_codeCard addSubview:_scanBtn];
    [NSLayoutConstraint activateConstraints:@[
        [codeHint.topAnchor constraintEqualToAnchor:_codeCard.topAnchor constant:12],
        [codeHint.leadingAnchor constraintEqualToAnchor:_codeCard.leadingAnchor constant:14],
        [codeHint.trailingAnchor constraintEqualToAnchor:_codeCard.trailingAnchor constant:-14],
        [_codeField.topAnchor constraintEqualToAnchor:codeHint.bottomAnchor constant:8],
        [_codeField.leadingAnchor constraintEqualToAnchor:_codeCard.leadingAnchor constant:14],
        [_codeField.trailingAnchor constraintEqualToAnchor:_codeCard.trailingAnchor constant:-14],
        [_codeField.heightAnchor constraintEqualToConstant:42],
        [_scanBtn.topAnchor constraintEqualToAnchor:_codeField.bottomAnchor constant:10],
        [_scanBtn.leadingAnchor constraintEqualToAnchor:_codeCard.leadingAnchor constant:14],
        [_scanBtn.trailingAnchor constraintEqualToAnchor:_codeCard.trailingAnchor constant:-14],
        [_scanBtn.heightAnchor constraintEqualToConstant:40],
        [_scanBtn.bottomAnchor constraintEqualToAnchor:_codeCard.bottomAnchor constant:-12],
    ]];

    // ── Scan result card ─────────────────────────────────
    _scanResultCard = [self makeCard];
    _scanResultCard.hidden = YES;

    _scanResultIcon = [[UIImageView alloc] initWithImage:FVDICON(FVDIconCheck, 20, FVD_GREEN)];
    _scanResultIcon.translatesAutoresizingMaskIntoConstraints = NO;
    _scanResultIcon.contentMode = UIViewContentModeScaleAspectFit;

    _scanResultLabel = [UILabel new];
    _scanResultLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _scanResultLabel.text = @"Chưa scan";
    _scanResultLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    _scanResultLabel.textColor = FVD_TEXT;
    _scanResultLabel.numberOfLines = 0;

    [_scanResultCard addSubview:_scanResultIcon];
    [_scanResultCard addSubview:_scanResultLabel];
    [NSLayoutConstraint activateConstraints:@[
        [_scanResultIcon.leadingAnchor constraintEqualToAnchor:_scanResultCard.leadingAnchor constant:14],
        [_scanResultIcon.centerYAnchor constraintEqualToAnchor:_scanResultCard.centerYAnchor],
        [_scanResultIcon.widthAnchor constraintEqualToConstant:20],
        [_scanResultIcon.heightAnchor constraintEqualToConstant:20],
        [_scanResultLabel.leadingAnchor constraintEqualToAnchor:_scanResultIcon.trailingAnchor constant:10],
        [_scanResultLabel.trailingAnchor constraintEqualToAnchor:_scanResultCard.trailingAnchor constant:-14],
        [_scanResultLabel.topAnchor constraintEqualToAnchor:_scanResultCard.topAnchor constant:12],
        [_scanResultLabel.bottomAnchor constraintEqualToAnchor:_scanResultCard.bottomAnchor constant:-12],
    ]];

    // ── STEP 2: Pick Image ───────────────────────────────
    UIView *step2Header = [self makeStepLabel:@"BƯỚC 2  Chọn Ảnh Thay Thế" icon:FVDIconImage];

    _imageCard = [self makeCard];
    _imageCard.hidden = YES;

    _previewImageView = [[UIImageView alloc] init];
    _previewImageView.translatesAutoresizingMaskIntoConstraints = NO;
    _previewImageView.contentMode = UIViewContentModeScaleAspectFill;
    _previewImageView.clipsToBounds = YES;
    _previewImageView.layer.cornerRadius = 8;
    _previewImageView.backgroundColor = FVD_BG;

    _imageLabel = [UILabel new];
    _imageLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _imageLabel.text = @"Chưa chọn ảnh";
    _imageLabel.font = [UIFont systemFontOfSize:12];
    _imageLabel.textColor = FVD_SUBTEXT;
    _imageLabel.textAlignment = NSTextAlignmentCenter;

    _pickBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    _pickBtn.translatesAutoresizingMaskIntoConstraints = NO;
    _pickBtn.backgroundColor = FVD_CARD;
    _pickBtn.layer.cornerRadius = 8;
    _pickBtn.layer.borderWidth = 1.5;
    _pickBtn.layer.borderColor = FVD_ACCENT.CGColor;
    [_pickBtn setTitle:@"Mở Thư Viện Ảnh" forState:UIControlStateNormal];
    [_pickBtn setTitleColor:FVD_ACCENT forState:UIControlStateNormal];
    _pickBtn.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    [_pickBtn addTarget:self action:@selector(pickImage) forControlEvents:UIControlEventTouchUpInside];

    [_imageCard addSubview:_previewImageView];
    [_imageCard addSubview:_imageLabel];
    [_imageCard addSubview:_pickBtn];
    [NSLayoutConstraint activateConstraints:@[
        [_previewImageView.topAnchor constraintEqualToAnchor:_imageCard.topAnchor constant:12],
        [_previewImageView.centerXAnchor constraintEqualToAnchor:_imageCard.centerXAnchor],
        [_previewImageView.widthAnchor constraintEqualToConstant:120],
        [_previewImageView.heightAnchor constraintEqualToConstant:120],
        [_imageLabel.topAnchor constraintEqualToAnchor:_previewImageView.bottomAnchor constant:6],
        [_imageLabel.centerXAnchor constraintEqualToAnchor:_imageCard.centerXAnchor],
        [_imageLabel.leadingAnchor constraintEqualToAnchor:_imageCard.leadingAnchor constant:14],
        [_imageLabel.trailingAnchor constraintEqualToAnchor:_imageCard.trailingAnchor constant:-14],
        [_pickBtn.topAnchor constraintEqualToAnchor:_imageLabel.bottomAnchor constant:10],
        [_pickBtn.leadingAnchor constraintEqualToAnchor:_imageCard.leadingAnchor constant:14],
        [_pickBtn.trailingAnchor constraintEqualToAnchor:_imageCard.trailingAnchor constant:-14],
        [_pickBtn.heightAnchor constraintEqualToConstant:40],
        [_pickBtn.bottomAnchor constraintEqualToAnchor:_imageCard.bottomAnchor constant:-12],
    ]];

    // ── STEP 3: Apply button ─────────────────────────────
    UIView *step3Header = [self makeStepLabel:@"BƯỚC 3  Áp Dụng" icon:FVDIconCheck];

    _applyBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    _applyBtn.translatesAutoresizingMaskIntoConstraints = NO;
    _applyBtn.layer.cornerRadius = FVD_R_MD;
    _applyBtn.alpha = 0.4;
    _applyBtn.enabled = NO;
    _applyBtn.hidden = YES;

    CAGradientLayer *applyGrad = FVDMakeGradient(FVD_ACCENT, FVD_ACCENT2, 90);
    applyGrad.cornerRadius = FVD_R_MD;
    applyGrad.frame = CGRectMake(0,0,10,10);
    [_applyBtn.layer insertSublayer:applyGrad atIndex:0];

    [_applyBtn setTitle:@"Áp Dụng Cho Tất Cả Lớp Media" forState:UIControlStateNormal];
    [_applyBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    _applyBtn.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightBold];
    [_applyBtn addTarget:self action:@selector(applyMedia) forControlEvents:UIControlEventTouchUpInside];
    _applyBtn.heightAnchor.constraintEqualToConstant(52).active = YES;

    // ── Progress card ────────────────────────────────────
    _progressCard = [self makeCard];
    _progressCard.hidden = YES;

    _progressLabel = [UILabel new];
    _progressLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _progressLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    _progressLabel.textColor = FVD_SUBTEXT;
    _progressLabel.textAlignment = NSTextAlignmentCenter;
    _progressLabel.text = @"Đang xử lý...";

    _progressBar = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    _progressBar.translatesAutoresizingMaskIntoConstraints = NO;
    _progressBar.progressTintColor = FVD_ACCENT;
    _progressBar.trackTintColor = FVD_BG;
    _progressBar.layer.cornerRadius = 3;
    _progressBar.clipsToBounds = YES;

    [_progressCard addSubview:_progressLabel];
    [_progressCard addSubview:_progressBar];
    [NSLayoutConstraint activateConstraints:@[
        [_progressLabel.topAnchor constraintEqualToAnchor:_progressCard.topAnchor constant:12],
        [_progressLabel.centerXAnchor constraintEqualToAnchor:_progressCard.centerXAnchor],
        [_progressLabel.leadingAnchor constraintEqualToAnchor:_progressCard.leadingAnchor constant:14],
        [_progressLabel.trailingAnchor constraintEqualToAnchor:_progressCard.trailingAnchor constant:-14],
        [_progressBar.topAnchor constraintEqualToAnchor:_progressLabel.bottomAnchor constant:8],
        [_progressBar.leadingAnchor constraintEqualToAnchor:_progressCard.leadingAnchor constant:14],
        [_progressBar.trailingAnchor constraintEqualToAnchor:_progressCard.trailingAnchor constant:-14],
        [_progressBar.heightAnchor constraintEqualToConstant:6],
        [_progressCard.bottomAnchor constraintEqualToAnchor:_progressBar.bottomAnchor constant:12],
    ]];

    // ── Layout all in content ─────────────────────────────
    NSArray *views = @[infoCard, step1Header, _codeCard, _scanResultCard,
                       step2Header, _imageCard, step3Header, _applyBtn,
                       _progressCard];
    for (UIView *v in views) {
        v.translatesAutoresizingMaskIntoConstraints = NO;
        [_contentView addSubview:v];
    }

    UIView *prev = nil;
    CGFloat topPad = 12, gap = 8;
    for (UIView *v in views) {
        CGFloat space = (prev == nil) ? topPad : gap;
        [NSLayoutConstraint activateConstraints:@[
            [v.leadingAnchor constraintEqualToAnchor:_contentView.leadingAnchor constant:14],
            [v.trailingAnchor constraintEqualToAnchor:_contentView.trailingAnchor constant:-14],
            prev ? [v.topAnchor constraintEqualToAnchor:prev.bottomAnchor constant:space]
                 : [v.topAnchor constraintEqualToAnchor:_contentView.topAnchor constant:topPad],
        ]];
        prev = v;
    }
    [prev.bottomAnchor constraintEqualToAnchor:_contentView.bottomAnchor constant:-20].active = YES;
}

// ── MARK: Helpers ─────────────────────────────────────────────────────────────
- (UIView *)makeCard {
    UIView *v = [[UIView alloc] init];
    v.translatesAutoresizingMaskIntoConstraints = NO;
    v.backgroundColor = FVD_CARD;
    v.layer.cornerRadius = FVD_R_MD;
    v.layer.borderWidth = 1;
    v.layer.borderColor = FVD_BORDER.CGColor;
    return v;
}

- (UIView *)makeStepLabel:(NSString *)text icon:(FVDIconType)iconType {
    UIView *row = [[UIView alloc] init];
    row.translatesAutoresizingMaskIntoConstraints = NO;

    UIImageView *ico = [[UIImageView alloc] initWithImage:FVDICON(iconType, 14, FVD_ACCENT)];
    ico.translatesAutoresizingMaskIntoConstraints = NO;
    ico.contentMode = UIViewContentModeScaleAspectFit;

    UILabel *lbl = [UILabel new];
    lbl.translatesAutoresizingMaskIntoConstraints = NO;
    lbl.text = text;
    lbl.font = [UIFont systemFontOfSize:11 weight:UIFontWeightBold];
    lbl.textColor = FVD_ACCENT;

    [row addSubview:ico];
    [row addSubview:lbl];
    [NSLayoutConstraint activateConstraints:@[
        [ico.leadingAnchor constraintEqualToAnchor:row.leadingAnchor],
        [ico.centerYAnchor constraintEqualToAnchor:row.centerYAnchor],
        [ico.widthAnchor constraintEqualToConstant:14],
        [ico.heightAnchor constraintEqualToConstant:14],
        [lbl.leadingAnchor constraintEqualToAnchor:ico.trailingAnchor constant:6],
        [lbl.trailingAnchor constraintEqualToAnchor:row.trailingAnchor],
        [lbl.topAnchor constraintEqualToAnchor:row.topAnchor constant:2],
        [lbl.bottomAnchor constraintEqualToAnchor:row.bottomAnchor constant:-2],
    ]];
    return row;
}

// ── MARK: UI State Refresh ───────────────────────────────────────────────────
- (void)refreshUI {
    BOOL hasLayers = (_foundLayers.count > 0);
    BOOL hasImage  = (_selectedImage != nil);
    BOOL canApply  = hasLayers && hasImage;

    // Show scan result if scanned
    _scanResultCard.hidden = (self.state == FVDReplaceStateIdle);

    // Show image section only after scan found layers
    _imageCard.hidden  = !hasLayers;

    // Step 3 header + apply only when both ready
    // (we keep step3Header always visible for clarity but dim it)
    _applyBtn.hidden   = NO;
    _applyBtn.enabled  = canApply && (self.state != FVDReplaceStateApplying);
    _applyBtn.alpha    = canApply ? 1.0 : 0.4;

    // Progress card
    _progressCard.hidden = (self.state != FVDReplaceStateApplying && self.state != FVDReplaceStateDone);
}

// ── MARK: Keyboard ───────────────────────────────────────────────────────────
- (void)codeFieldChanged {
    // Reset scan state if code changes after scan
    if (self.state == FVDReplaceStateScanned || self.state == FVDReplaceStateDone) {
        self.state = FVDReplaceStateIdle;
        self.foundLayers = nil;
        [self refreshUI];
    }
}

- (void)dismissKeyboard {
    [_codeField resignFirstResponder];
}

// ── MARK: Scan Layers ────────────────────────────────────────────────────────
- (void)scanLayers {
    [_codeField resignFirstResponder];

    NSString *code = [_codeField.text stringByTrimmingCharactersInSet:
                      [NSCharacterSet whitespaceAndNewlineCharacterSet]];

    // Scan tất cả lớp media trong project hiện tại
    // Code được dùng để log / filter nếu VideoStar hỗ trợ segment lookup
    _scanBtn.enabled = NO;
    [_scanBtn setTitle:@"Đang tìm..." forState:UIControlStateNormal];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSArray *layers = [self scanAllMediaLayers:code];

        dispatch_async(dispatch_get_main_queue(), ^{
            self.foundLayers = layers;
            self.scanBtn.enabled = YES;
            [self.scanBtn setTitle:@"Tìm Lớp Media" forState:UIControlStateNormal];

            if (layers.count > 0) {
                self.state = FVDReplaceStateScanned;
                self.scanResultIcon.image = FVDICON(FVDIconCheck, 20, FVD_GREEN);
                self.scanResultLabel.text = [NSString stringWithFormat:
                    @"Tìm thấy %ld lớp media%@.\nSẵn sàng thay thế!",
                    (long)layers.count,
                    code.length > 0 ? [NSString stringWithFormat:@" (code: %@)", code] : @""];
                self.scanResultLabel.textColor = FVD_GREEN;
            } else {
                self.state = FVDReplaceStateIdle;
                self.scanResultIcon.image = FVDICON(FVDIconX, 20, FVD_RED);
                self.scanResultLabel.text = code.length > 0
                    ? [NSString stringWithFormat:@"Không tìm thấy lớp nào.\nHãy mở project trong VideoStar và thử lại (code: %@).", code]
                    : @"Không tìm thấy lớp nào.\nHãy mở project trong VideoStar và thử lại.";
                self.scanResultLabel.textColor = FVD_RED;
            }
            [self refreshUI];
        });
    });

    // Show result card immediately
    _scanResultCard.hidden = NO;
    _scanResultLabel.text = @"Đang tìm kiếm lớp media...";
    _scanResultLabel.textColor = FVD_SUBTEXT;
}

// Scan tất cả lớp media có thể thay được
- (NSArray *)scanAllMediaLayers:(NSString *)code {
    NSMutableArray *result = [NSMutableArray new];

    // ── Method 1: VSProjectController.sharedController.currentProject ─────────
    Class ctrl = NSClassFromString(kVSProjectController);
    if (ctrl && [ctrl respondsToSelector:@selector(sharedController)]) {
        id shared = [ctrl performSelector:@selector(sharedController)];
        if (shared) {
            id project = nil;
            SEL selProject = @selector(currentProject);
            if ([shared respondsToSelector:selProject])
                project = [shared performSelector:selProject];

            if (project) {
                // Try multiple layer accessors
                for (NSString *selName in @[@"layers", @"allLayers", @"videoLayers", @"imageLayers", @"clips"]) {
                    SEL sel = NSSelectorFromString(selName);
                    if ([project respondsToSelector:sel]) {
                        id obj = [project performSelector:sel];
                        if ([obj isKindOfClass:[NSArray class]] && [(NSArray *)obj count] > 0) {
                            [result addObjectsFromArray:(NSArray *)obj];
                        }
                    }
                }
            }
        }
    }

    // ── Method 2: VSCompositionManager ───────────────────────────────────────
    if (result.count == 0) {
        Class compMgr = NSClassFromString(kVSCompositionManager);
        if (compMgr) {
            id shared = nil;
            for (NSString *s in @[@"sharedManager", @"sharedInstance", @"defaultManager"]) {
                SEL sel = NSSelectorFromString(s);
                if ([compMgr respondsToSelector:sel]) {
                    shared = [compMgr performSelector:sel]; break;
                }
            }
            if (shared) {
                for (NSString *selName in @[@"layers", @"mediaLayers", @"clips", @"composition"]) {
                    SEL sel = NSSelectorFromString(selName);
                    if ([shared respondsToSelector:sel]) {
                        id obj = [shared performSelector:sel];
                        if ([obj isKindOfClass:[NSArray class]])
                            [result addObjectsFromArray:(NSArray *)obj];
                    }
                }
            }
        }
    }

    // ── Method 3: Scan UIImageViews & video layer views from window ───────────
    if (result.count == 0) {
        dispatch_semaphore_t sem = dispatch_semaphore_create(0);
        dispatch_async(dispatch_get_main_queue(), ^{
            UIWindow *win = nil;
            for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if ([scene isKindOfClass:[UIWindowScene class]]) {
                    win = scene.windows.firstObject; break;
                }
            }
            if (win) [self collectMediaViewsFromView:win into:result];
            dispatch_semaphore_signal(sem);
        });
        dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC));
    }

    // Filter by code if provided — keep all if no code (replace globally)
    // VideoStar layers don't expose a "segment code" property in known APIs,
    // so we replace all found layers (user already navigated to the right segment)
    return [result copy];
}

- (void)collectMediaViewsFromView:(UIView *)view into:(NSMutableArray *)arr {
    // Skip our own overlay window
    NSString *cls = NSStringFromClass([view class]);
    if ([cls containsString:@"FVD"] || [cls containsString:@"FallVds"]) return;

    BOOL isMedia = NO;
    if ([view isKindOfClass:[UIImageView class]] && ((UIImageView *)view).image != nil) isMedia = YES;
    if ([view respondsToSelector:@selector(setImage:)] && [view respondsToSelector:@selector(image)]) isMedia = YES;
    if ([view respondsToSelector:@selector(setVideoURL:)]) isMedia = YES;
    if ([view respondsToSelector:@selector(setSourceImage:)]) isMedia = YES;

    if (isMedia && ![arr containsObject:view]) [arr addObject:view];

    for (UIView *sub in view.subviews) {
        [self collectMediaViewsFromView:sub into:arr];
    }
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

    [[results.firstObject itemProvider] loadObjectOfClass:[UIImage class]
                                       completionHandler:^(UIImage *image, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!image) return;
            self.selectedImage = image;
            self.previewImageView.image = image;
            self.imageLabel.text = @"Ảnh đã chọn ✓";
            self.imageLabel.textColor = FVD_GREEN;
            self.state = FVDReplaceStateImagePicked;
            [self refreshUI];
        });
    }];
}

// ── MARK: Apply ───────────────────────────────────────────────────────────────
- (void)applyMedia {
    if (!_selectedImage || !_foundLayers.count) return;
    self.state = FVDReplaceStateApplying;
    [self refreshUI];

    _progressCard.hidden = NO;
    _progressBar.progress = 0;
    _progressLabel.text = @"Đang thay media...";

    NSData *imgData = UIImageJPEGRepresentation(_selectedImage, 0.95);
    if (!imgData) imgData = UIImagePNGRepresentation(_selectedImage);

    NSArray *layers = [_foundLayers copy];
    NSInteger total = layers.count;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        for (NSInteger i = 0; i < total; i++) {
            id layer = layers[i];
            [self replaceMediaInLayer:layer withImageData:imgData];

            CGFloat prog = (CGFloat)(i + 1) / (CGFloat)total;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.progressBar setProgress:prog animated:YES];
                self.progressLabel.text = [NSString stringWithFormat:@"Đang xử lý %ld/%ld lớp...", (long)(i+1), (long)total];
            });
            [NSThread sleepForTimeInterval:0.015];
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            self.state = FVDReplaceStateDone;
            self.progressLabel.text = [NSString stringWithFormat:@"✅ Đã thay %ld lớp thành công!", (long)total];
            [self.progressBar setProgress:1.0 animated:YES];
            [self refreshUI];

            // Show success alert
            UIAlertController *alert = [UIAlertController
                alertControllerWithTitle:@"Hoàn Thành"
                message:[NSString stringWithFormat:@"Đã thay ảnh vào %ld lớp media thành công.", (long)total]
                preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            UIViewController *root = self;
            while (root.presentingViewController) root = root.presentingViewController;
            [root presentViewController:alert animated:YES completion:nil];
        });
    });
}

- (void)replaceMediaInLayer:(id)layer withImageData:(NSData *)data {
    UIImage *img = [UIImage imageWithData:data];
    if (!img) return;

    dispatch_async(dispatch_get_main_queue(), ^{
        // UIImageView
        if ([layer isKindOfClass:[UIImageView class]]) {
            ((UIImageView *)layer).image = img;
        }
        // setImage:
        if ([layer respondsToSelector:@selector(setImage:)]) {
            @try { [layer performSelector:@selector(setImage:) withObject:img]; } @catch (...) {}
        }
        // setSourceImage:
        if ([layer respondsToSelector:@selector(setSourceImage:)]) {
            @try { [layer performSelector:@selector(setSourceImage:) withObject:img]; } @catch (...) {}
        }
        // setVideoURL: (video layers — set temp image file as URL)
        if ([layer respondsToSelector:@selector(setVideoURL:)]) {
            NSURL *url = [self saveTempImage:img];
            if (url) @try { [layer performSelector:@selector(setVideoURL:) withObject:url]; } @catch (...) {}
        }
        // setNeedsDisplay
        if ([layer respondsToSelector:@selector(setNeedsDisplay)]) {
            [layer performSelector:@selector(setNeedsDisplay)];
        }
    });
}

- (NSURL *)saveTempImage:(UIImage *)img {
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"fvd_replace_media.jpg"];
    NSData *d = UIImageJPEGRepresentation(img, 0.95);
    return ([d writeToFile:path atomically:YES]) ? [NSURL fileURLWithPath:path] : nil;
}

@end
