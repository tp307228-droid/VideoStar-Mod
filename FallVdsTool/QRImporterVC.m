// QRImporterVC.m — Nhập QR Hàng Loạt
// Flow:
//   Step 1 → Chọn range (từ đoạn X → đoạn Y)
//   Step 2 → Chọn loại QR (1 loại cho cả session)
//   Step 3 → Nhập code cho từng đoạn (code 1, code 2...)
//   Step 4 → Bấm nút → chọn ảnh 1 lần → auto thay ALL lớp media + set code
//   Step 5 → Kết quả + "Phiên Mới" để reset

#import "QRImporterVC.h"
#import "Theme.h"
#import "SVGIcons.h"
#import <Photos/Photos.h>
#import <PhotosUI/PhotosUI.h>
#import <objc/runtime.h>

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - QR Types
// ─────────────────────────────────────────────────────────────────────────────
static NSArray<NSString *> *FVDQRTypes(void) {
    return @[
        @"QR Code",
        @"Barcode EAN-13",
        @"Code-128",
        @"Data Matrix",
        @"PDF417",
        @"Aztec Code",
        @"Micro QR",
    ];
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Code Input Cell
// ─────────────────────────────────────────────────────────────────────────────
@interface FVDCodeCell : UIView
@property (nonatomic, strong) UILabel     *numLabel;
@property (nonatomic, strong) UITextField *codeField;
@property (nonatomic, assign) NSInteger    segmentIndex;
- (instancetype)initWithSegment:(NSInteger)seg;
@end

@implementation FVDCodeCell

- (instancetype)initWithSegment:(NSInteger)seg {
    self = [super init];
    self.segmentIndex = seg;
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.backgroundColor = FVD_CARD;
    self.layer.cornerRadius = FVD_R_SM;
    self.layer.borderWidth  = 1;
    self.layer.borderColor  = FVD_BORDER.CGColor;

    // Badge circle
    UIView *badge = [[UIView alloc] init];
    badge.translatesAutoresizingMaskIntoConstraints = NO;
    badge.layer.cornerRadius = 14;

    // Color rotate
    NSArray<UIColor *> *cols = @[
        FVD_ACCENT,
        [UIColor colorWithRed:0.9 green:0.3 blue:0.7 alpha:1],
        FVD_GREEN,
        [UIColor colorWithRed:1 green:0.6 blue:0.1 alpha:1],
        [UIColor colorWithRed:0.3 green:0.8 blue:1 alpha:1],
        [UIColor colorWithRed:1 green:0.4 blue:0.4 alpha:1],
        [UIColor colorWithRed:0.7 green:0.9 blue:0.3 alpha:1],
    ];
    badge.backgroundColor = cols[(seg - 1) % cols.count];
    badge.layer.shadowColor   = badge.backgroundColor.CGColor;
    badge.layer.shadowRadius  = 6;
    badge.layer.shadowOpacity = 0.4;
    badge.layer.shadowOffset  = CGSizeZero;

    _numLabel = [UILabel new];
    _numLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _numLabel.text = [NSString stringWithFormat:@"%ld", (long)seg];
    _numLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightBold];
    _numLabel.textColor = UIColor.whiteColor;
    _numLabel.textAlignment = NSTextAlignmentCenter;
    [badge addSubview:_numLabel];

    // "Đoạn N" label
    UILabel *segLbl = [UILabel new];
    segLbl.translatesAutoresizingMaskIntoConstraints = NO;
    segLbl.text = [NSString stringWithFormat:@"Đoạn %ld", (long)seg];
    segLbl.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
    segLbl.textColor = FVD_SUBTEXT;

    // Text field
    _codeField = [[UITextField alloc] init];
    _codeField.translatesAutoresizingMaskIntoConstraints = NO;
    _codeField.backgroundColor = FVD_BG;
    _codeField.textColor       = FVD_TEXT;
    _codeField.font = [UIFont monospacedSystemFontOfSize:13 weight:UIFontWeightRegular];
    _codeField.layer.cornerRadius = 6;
    _codeField.layer.borderWidth  = 1;
    _codeField.layer.borderColor  = FVD_BORDER.CGColor;
    _codeField.returnKeyType = UIReturnKeyNext;
    _codeField.autocorrectionType    = UITextAutocorrectionTypeNo;
    _codeField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _codeField.attributedPlaceholder = [[NSAttributedString alloc]
        initWithString:[NSString stringWithFormat:@"Code cho đoạn %ld...", (long)seg]
        attributes:@{NSForegroundColorAttributeName: FVD_SUBTEXT}];
    UIView *lp = [[UIView alloc] initWithFrame:CGRectMake(0,0,10,0)];
    _codeField.leftView = lp;
    _codeField.leftViewMode = UITextFieldViewModeAlways;

    for (UIView *v in @[badge, segLbl, _codeField]) [self addSubview:v];
    [NSLayoutConstraint activateConstraints:@[
        [_numLabel.centerXAnchor constraintEqualToAnchor:badge.centerXAnchor],
        [_numLabel.centerYAnchor constraintEqualToAnchor:badge.centerYAnchor],
        [badge.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:12],
        [badge.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [badge.widthAnchor constraintEqualToConstant:28],
        [badge.heightAnchor constraintEqualToConstant:28],
        [segLbl.leadingAnchor constraintEqualToAnchor:badge.trailingAnchor constant:8],
        [segLbl.topAnchor constraintEqualToAnchor:self.topAnchor constant:10],
        [_codeField.leadingAnchor constraintEqualToAnchor:badge.trailingAnchor constant:8],
        [_codeField.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-12],
        [_codeField.topAnchor constraintEqualToAnchor:segLbl.bottomAnchor constant:4],
        [_codeField.heightAnchor constraintEqualToConstant:34],
        [_codeField.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-10],
    ]];
    return self;
}
@end

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - QRImporterVC
// ─────────────────────────────────────────────────────────────────────────────
@interface QRImporterVC () <PHPickerViewControllerDelegate>

// Session state
@property (nonatomic, assign) NSInteger  fromSeg;
@property (nonatomic, assign) NSInteger  toSeg;
@property (nonatomic, copy)   NSString  *selectedQRType;
@property (nonatomic, strong) UIImage   *selectedMedia;   // ảnh media dùng chung
@property (nonatomic, strong) NSMutableArray<FVDCodeCell *> *codeCells;

// Steps (all inside 1 scroll view, shown/hidden by step)
@property (nonatomic, strong) UIScrollView *mainScroll;
@property (nonatomic, strong) UIView       *stepRange;    // step 1
@property (nonatomic, strong) UIView       *stepQRType;   // step 2
@property (nonatomic, strong) UIView       *stepCodes;    // step 3
@property (nonatomic, strong) UIView       *stepPickImg;  // step 4
@property (nonatomic, strong) UIView       *stepResult;   // step 5

// Step 1 refs
@property (nonatomic, strong) UIStepper   *fromStepper;
@property (nonatomic, strong) UIStepper   *toStepper;
@property (nonatomic, strong) UILabel     *fromValLbl;
@property (nonatomic, strong) UILabel     *toValLbl;
@property (nonatomic, strong) UILabel     *rangeSummaryLbl;

// Step 2 refs
@property (nonatomic, strong) UIView      *qrTypeContainer;
@property (nonatomic, strong) UILabel     *selectedTypeLabel;

// Step 3 refs
@property (nonatomic, strong) UIView      *codesContainer;
@property (nonatomic, strong) UILabel     *codesTitle;

// Step 4 refs
@property (nonatomic, strong) UIView      *imgPreviewCard;
@property (nonatomic, strong) UIImageView *imgPreview;
@property (nonatomic, strong) UILabel     *imgStatusLbl;
@property (nonatomic, strong) UIButton    *applyBtn;
@property (nonatomic, strong) UILabel     *applyBtnLbl;
@property (nonatomic, strong) CAGradientLayer *applyGrad;

// Step 5 refs
@property (nonatomic, strong) UILabel     *resultTitleLbl;
@property (nonatomic, strong) UILabel     *resultSubLbl;

// Progress overlay
@property (nonatomic, strong) UIView        *progressOverlay;
@property (nonatomic, strong) UIProgressView *progressBar;
@property (nonatomic, strong) UILabel       *progressLbl;
@property (nonatomic, strong) UILabel       *progressDetail;

@end

@implementation QRImporterVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.clearColor;
    _fromSeg = 1;
    _toSeg   = 5;
    _selectedQRType = FVDQRTypes().firstObject;
    _codeCells = [NSMutableArray new];
    [self buildUI];
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Build UI
// ─────────────────────────────────────────────────────────────────────────────
- (void)buildUI {
    _mainScroll = [[UIScrollView alloc] init];
    _mainScroll.translatesAutoresizingMaskIntoConstraints = NO;
    _mainScroll.showsVerticalScrollIndicator = NO;
    [self.view addSubview:_mainScroll];

    UIView *content = [[UIView alloc] init];
    content.translatesAutoresizingMaskIntoConstraints = NO;
    [_mainScroll addSubview:content];

    [NSLayoutConstraint activateConstraints:@[
        [_mainScroll.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [_mainScroll.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_mainScroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_mainScroll.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [content.topAnchor constraintEqualToAnchor:_mainScroll.topAnchor],
        [content.leadingAnchor constraintEqualToAnchor:_mainScroll.leadingAnchor],
        [content.trailingAnchor constraintEqualToAnchor:_mainScroll.trailingAnchor],
        [content.bottomAnchor constraintEqualToAnchor:_mainScroll.bottomAnchor],
        [content.widthAnchor constraintEqualToAnchor:_mainScroll.widthAnchor],
    ]];

    // Build all steps
    _stepRange   = [self buildStepRange];
    _stepQRType  = [self buildStepQRType];
    _stepCodes   = [self buildStepCodes];
    _stepPickImg = [self buildStepPickImg];
    _stepResult  = [self buildStepResult];

    NSArray<UIView *> *steps = @[_stepRange, _stepQRType, _stepCodes, _stepPickImg, _stepResult];
    UIView *prev = nil;
    for (UIView *step in steps) {
        step.translatesAutoresizingMaskIntoConstraints = NO;
        [content addSubview:step];
        [NSLayoutConstraint activateConstraints:@[
            [step.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:14],
            [step.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-14],
        ]];
        if (prev) {
            [step.topAnchor constraintEqualToAnchor:prev.bottomAnchor constant:10].active = YES;
        } else {
            [step.topAnchor constraintEqualToAnchor:content.topAnchor constant:10].active = YES;
        }
        prev = step;
    }
    [prev.bottomAnchor constraintEqualToAnchor:content.bottomAnchor constant:-20].active = YES;

    // Initial: show only step 1
    _stepQRType.hidden  = YES;
    _stepCodes.hidden   = YES;
    _stepPickImg.hidden = YES;
    _stepResult.hidden  = YES;
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Step 1: Range
// ─────────────────────────────────────────────────────────────────────────────
- (UIView *)buildStepRange {
    UIView *card = [self makeCard];

    UILabel *stepTag = [self makeStepTag:@"1" text:@"Chọn Phạm Vi Đoạn"];

    UILabel *fromLbl = [UILabel new]; fromLbl.translatesAutoresizingMaskIntoConstraints = NO;
    fromLbl.text = @"Từ Đoạn"; fromLbl.font = [UIFont systemFontOfSize:13]; fromLbl.textColor = FVD_SUBTEXT;

    _fromValLbl = [UILabel new]; _fromValLbl.translatesAutoresizingMaskIntoConstraints = NO;
    _fromValLbl.font = [UIFont systemFontOfSize:24 weight:UIFontWeightBold];
    _fromValLbl.textColor = FVD_ACCENT; _fromValLbl.textAlignment = NSTextAlignmentCenter;

    _fromStepper = [[UIStepper alloc] init]; _fromStepper.translatesAutoresizingMaskIntoConstraints = NO;
    _fromStepper.minimumValue = 1; _fromStepper.maximumValue = 999;
    _fromStepper.stepValue = 1; _fromStepper.value = _fromSeg; _fromStepper.tintColor = FVD_ACCENT;
    [_fromStepper addTarget:self action:@selector(stepperChanged) forControlEvents:UIControlEventValueChanged];

    UILabel *toLbl = [UILabel new]; toLbl.translatesAutoresizingMaskIntoConstraints = NO;
    toLbl.text = @"Đến Đoạn"; toLbl.font = [UIFont systemFontOfSize:13]; toLbl.textColor = FVD_SUBTEXT;

    _toValLbl = [UILabel new]; _toValLbl.translatesAutoresizingMaskIntoConstraints = NO;
    _toValLbl.font = [UIFont systemFontOfSize:24 weight:UIFontWeightBold];
    _toValLbl.textColor = FVD_ACCENT2; _toValLbl.textAlignment = NSTextAlignmentCenter;

    _toStepper = [[UIStepper alloc] init]; _toStepper.translatesAutoresizingMaskIntoConstraints = NO;
    _toStepper.minimumValue = 1; _toStepper.maximumValue = 999;
    _toStepper.stepValue = 1; _toStepper.value = _toSeg; _toStepper.tintColor = FVD_ACCENT2;
    [_toStepper addTarget:self action:@selector(stepperChanged) forControlEvents:UIControlEventValueChanged];

    UIView *sep = [UIView new]; sep.translatesAutoresizingMaskIntoConstraints = NO;
    sep.backgroundColor = FVD_SEP;

    _rangeSummaryLbl = [UILabel new]; _rangeSummaryLbl.translatesAutoresizingMaskIntoConstraints = NO;
    _rangeSummaryLbl.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    _rangeSummaryLbl.textColor = FVD_ACCENT; _rangeSummaryLbl.textAlignment = NSTextAlignmentCenter;
    _rangeSummaryLbl.numberOfLines = 0;

    UIButton *nextBtn = [self makePrimaryButton:@"Tiếp Theo →" icon:FVDIconChevronRight
        action:@selector(rangeConfirmed)];

    for (UIView *v in @[stepTag, fromLbl, _fromValLbl, _fromStepper,
                        sep, toLbl, _toValLbl, _toStepper, _rangeSummaryLbl, nextBtn])
        [card addSubview:v];

    [NSLayoutConstraint activateConstraints:@[
        [stepTag.topAnchor constraintEqualToAnchor:card.topAnchor constant:14],
        [stepTag.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:14],

        [fromLbl.topAnchor constraintEqualToAnchor:stepTag.bottomAnchor constant:14],
        [fromLbl.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:14],
        [fromLbl.centerYAnchor constraintEqualToAnchor:_fromStepper.centerYAnchor],
        [_fromValLbl.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],
        [_fromValLbl.centerYAnchor constraintEqualToAnchor:_fromStepper.centerYAnchor],
        [_fromStepper.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-14],
        [_fromStepper.topAnchor constraintEqualToAnchor:stepTag.bottomAnchor constant:12],

        [sep.topAnchor constraintEqualToAnchor:_fromStepper.bottomAnchor constant:12],
        [sep.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:14],
        [sep.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-14],
        [sep.heightAnchor constraintEqualToConstant:1],

        [toLbl.topAnchor constraintEqualToAnchor:sep.bottomAnchor constant:12],
        [toLbl.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:14],
        [toLbl.centerYAnchor constraintEqualToAnchor:_toStepper.centerYAnchor],
        [_toValLbl.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],
        [_toValLbl.centerYAnchor constraintEqualToAnchor:_toStepper.centerYAnchor],
        [_toStepper.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-14],
        [_toStepper.topAnchor constraintEqualToAnchor:sep.bottomAnchor constant:10],

        [_rangeSummaryLbl.topAnchor constraintEqualToAnchor:_toStepper.bottomAnchor constant:12],
        [_rangeSummaryLbl.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:14],
        [_rangeSummaryLbl.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-14],

        [nextBtn.topAnchor constraintEqualToAnchor:_rangeSummaryLbl.bottomAnchor constant:14],
        [nextBtn.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:14],
        [nextBtn.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-14],
        [nextBtn.heightAnchor constraintEqualToConstant:48],
        [nextBtn.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-14],
    ]];
    [self updateRangeSummary];
    return card;
}

- (void)stepperChanged {
    _fromSeg = (NSInteger)_fromStepper.value;
    _toSeg   = (NSInteger)_toStepper.value;
    if (_fromSeg > _toSeg) { _toSeg = _fromSeg; _toStepper.value = _fromSeg; }
    [self updateRangeSummary];
}

- (void)updateRangeSummary {
    _fromValLbl.text = [NSString stringWithFormat:@"%ld", (long)_fromSeg];
    _toValLbl.text   = [NSString stringWithFormat:@"%ld", (long)_toSeg];
    NSInteger n = _toSeg - _fromSeg + 1;
    _rangeSummaryLbl.text = [NSString stringWithFormat:
        @"📋 %ld đoạn • Đoạn %ld → Đoạn %ld", (long)n, (long)_fromSeg, (long)_toSeg];
}

- (void)rangeConfirmed {
    [self animateShow:_stepQRType];
    [self scrollToView:_stepQRType];
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Step 2: QR Type (1 loại cho cả session)
// ─────────────────────────────────────────────────────────────────────────────
- (UIView *)buildStepQRType {
    UIView *card = [self makeCard];

    UILabel *stepTag = [self makeStepTag:@"2" text:@"Chọn Loại QR Code"];
    UILabel *hint = [UILabel new]; hint.translatesAutoresizingMaskIntoConstraints = NO;
    hint.text = @"Áp dụng cho tất cả đoạn trong session này";
    hint.font = [UIFont systemFontOfSize:11]; hint.textColor = FVD_SUBTEXT;

    // Type chips grid
    _qrTypeContainer = [[UIView alloc] init];
    _qrTypeContainer.translatesAutoresizingMaskIntoConstraints = NO;

    // Current selected label
    _selectedTypeLabel = [UILabel new]; _selectedTypeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _selectedTypeLabel.text = [NSString stringWithFormat:@"Đã chọn: %@", _selectedQRType];
    _selectedTypeLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    _selectedTypeLabel.textColor = FVD_ACCENT;
    _selectedTypeLabel.textAlignment = NSTextAlignmentCenter;

    // Build chips
    NSArray<NSString *> *types = FVDQRTypes();
    UIView *row1 = [self makeChipRow:[types subarrayWithRange:NSMakeRange(0, MIN(3, types.count))]];
    UIView *row2 = [self makeChipRow:[types subarrayWithRange:NSMakeRange(3, MAX(0, types.count - 3))]];

    for (UIView *v in @[row1, row2]) {
        v.translatesAutoresizingMaskIntoConstraints = NO;
        [_qrTypeContainer addSubview:v];
    }
    [NSLayoutConstraint activateConstraints:@[
        [row1.topAnchor constraintEqualToAnchor:_qrTypeContainer.topAnchor],
        [row1.leadingAnchor constraintEqualToAnchor:_qrTypeContainer.leadingAnchor],
        [row1.trailingAnchor constraintEqualToAnchor:_qrTypeContainer.trailingAnchor],
        [row2.topAnchor constraintEqualToAnchor:row1.bottomAnchor constant:6],
        [row2.leadingAnchor constraintEqualToAnchor:_qrTypeContainer.leadingAnchor],
        [row2.trailingAnchor constraintEqualToAnchor:_qrTypeContainer.trailingAnchor],
        [row2.bottomAnchor constraintEqualToAnchor:_qrTypeContainer.bottomAnchor],
    ]];

    UIButton *nextBtn = [self makePrimaryButton:@"Tiếp Theo →" icon:FVDIconChevronRight
        action:@selector(qrTypeConfirmed)];

    for (UIView *v in @[stepTag, hint, _qrTypeContainer, _selectedTypeLabel, nextBtn])
        [card addSubview:v];

    [NSLayoutConstraint activateConstraints:@[
        [stepTag.topAnchor constraintEqualToAnchor:card.topAnchor constant:14],
        [stepTag.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:14],
        [hint.topAnchor constraintEqualToAnchor:stepTag.bottomAnchor constant:4],
        [hint.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:14],
        [_qrTypeContainer.topAnchor constraintEqualToAnchor:hint.bottomAnchor constant:12],
        [_qrTypeContainer.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:14],
        [_qrTypeContainer.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-14],
        [_selectedTypeLabel.topAnchor constraintEqualToAnchor:_qrTypeContainer.bottomAnchor constant:10],
        [_selectedTypeLabel.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],
        [nextBtn.topAnchor constraintEqualToAnchor:_selectedTypeLabel.bottomAnchor constant:14],
        [nextBtn.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:14],
        [nextBtn.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-14],
        [nextBtn.heightAnchor constraintEqualToConstant:48],
        [nextBtn.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-14],
    ]];
    return card;
}

- (UIView *)makeChipRow:(NSArray<NSString *> *)types {
    UIView *row = [[UIView alloc] init];
    row.translatesAutoresizingMaskIntoConstraints = NO;
    UIView *prev = nil;
    for (NSString *type in types) {
        UIButton *chip = [UIButton buttonWithType:UIButtonTypeSystem];
        chip.translatesAutoresizingMaskIntoConstraints = NO;
        [chip setTitle:type forState:UIControlStateNormal];
        chip.titleLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
        chip.layer.cornerRadius = 12;
        chip.layer.borderWidth  = 1.5;
        BOOL selected = [type isEqualToString:_selectedQRType];
        [self styleChip:chip selected:selected];
        [chip addTarget:self action:@selector(chipTapped:) forControlEvents:UIControlEventTouchUpInside];
        [row addSubview:chip];
        [NSLayoutConstraint activateConstraints:@[
            [chip.topAnchor constraintEqualToAnchor:row.topAnchor],
            [chip.bottomAnchor constraintEqualToAnchor:row.bottomAnchor],
            [chip.heightAnchor constraintEqualToConstant:30],
        ]];
        if (prev) {
            [chip.leadingAnchor constraintEqualToAnchor:prev.trailingAnchor constant:6].active = YES;
        } else {
            [chip.leadingAnchor constraintEqualToAnchor:row.leadingAnchor].active = YES;
        }
        prev = chip;
    }
    if (prev) [prev.trailingAnchor constraintLessThanOrEqualToAnchor:row.trailingAnchor].active = YES;
    [row.heightAnchor constraintEqualToConstant:30].active = YES;
    return row;
}

- (void)styleChip:(UIButton *)chip selected:(BOOL)sel {
    if (sel) {
        chip.backgroundColor = FVD_ACCENT;
        chip.layer.borderColor = FVD_ACCENT.CGColor;
        [chip setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    } else {
        chip.backgroundColor = FVD_CARD2;
        chip.layer.borderColor = FVD_BORDER.CGColor;
        [chip setTitleColor:FVD_SUBTEXT forState:UIControlStateNormal];
    }
    chip.contentEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 10);
}

- (void)chipTapped:(UIButton *)sender {
    _selectedQRType = sender.currentTitle;
    _selectedTypeLabel.text = [NSString stringWithFormat:@"✓ Đã chọn: %@", _selectedQRType];

    // Update all chips in container
    [self updateChipStyles];

    // Haptic
    UIImpactFeedbackGenerator *haptic = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
    [haptic impactOccurred];
}

- (void)updateChipStyles {
    for (UIView *row in _qrTypeContainer.subviews) {
        for (UIButton *chip in row.subviews) {
            if ([chip isKindOfClass:[UIButton class]]) {
                BOOL sel = [chip.currentTitle isEqualToString:_selectedQRType];
                [UIView animateWithDuration:0.2 animations:^{ [self styleChip:chip selected:sel]; }];
            }
        }
    }
}

- (void)qrTypeConfirmed {
    [self rebuildCodeCells];
    [self animateShow:_stepCodes];
    [self scrollToView:_stepCodes];
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Step 3: Nhập code cho từng đoạn
// ─────────────────────────────────────────────────────────────────────────────
- (UIView *)buildStepCodes {
    UIView *card = [self makeCard];

    _codesTitle = [UILabel new]; _codesTitle.translatesAutoresizingMaskIntoConstraints = NO;
    // Will be updated in rebuildCodeCells

    UIView *stepTag = [self makeStepTag:@"3" text:@"Nhập Code Cho Từng Đoạn"];

    UILabel *hint = [UILabel new]; hint.translatesAutoresizingMaskIntoConstraints = NO;
    hint.text = @"Mỗi đoạn 1 code riêng. Nhập xong → chọn ảnh media.";
    hint.font = [UIFont systemFontOfSize:11]; hint.textColor = FVD_SUBTEXT;
    hint.numberOfLines = 0;

    _codesContainer = [[UIView alloc] init];
    _codesContainer.translatesAutoresizingMaskIntoConstraints = NO;

    UIButton *nextBtn = [self makePrimaryButton:@"Chọn Ảnh Media →" icon:FVDIconImage
        action:@selector(codesConfirmed)];

    for (UIView *v in @[stepTag, hint, _codesContainer, nextBtn]) [card addSubview:v];
    [NSLayoutConstraint activateConstraints:@[
        [stepTag.topAnchor constraintEqualToAnchor:card.topAnchor constant:14],
        [stepTag.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:14],
        [hint.topAnchor constraintEqualToAnchor:stepTag.bottomAnchor constant:4],
        [hint.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:14],
        [hint.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-14],
        [_codesContainer.topAnchor constraintEqualToAnchor:hint.bottomAnchor constant:12],
        [_codesContainer.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:14],
        [_codesContainer.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-14],
        [nextBtn.topAnchor constraintEqualToAnchor:_codesContainer.bottomAnchor constant:14],
        [nextBtn.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:14],
        [nextBtn.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-14],
        [nextBtn.heightAnchor constraintEqualToConstant:48],
        [nextBtn.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-14],
    ]];
    return card;
}

- (void)rebuildCodeCells {
    for (UIView *v in _codesContainer.subviews) [v removeFromSuperview];
    [_codeCells removeAllObjects];

    UIView *prev = nil;
    for (NSInteger seg = _fromSeg; seg <= _toSeg; seg++) {
        FVDCodeCell *cell = [[FVDCodeCell alloc] initWithSegment:seg];
        [_codesContainer addSubview:cell];
        [_codeCells addObject:cell];
        [NSLayoutConstraint activateConstraints:@[
            [cell.leadingAnchor constraintEqualToAnchor:_codesContainer.leadingAnchor],
            [cell.trailingAnchor constraintEqualToAnchor:_codesContainer.trailingAnchor],
        ]];
        if (prev) {
            [cell.topAnchor constraintEqualToAnchor:prev.bottomAnchor constant:6].active = YES;
        } else {
            [cell.topAnchor constraintEqualToAnchor:_codesContainer.topAnchor].active = YES;
        }
        prev = cell;
    }
    if (prev) [prev.bottomAnchor constraintEqualToAnchor:_codesContainer.bottomAnchor].active = YES;
}

- (void)codesConfirmed {
    // Dismiss keyboard
    [self.view endEditing:YES];
    [self animateShow:_stepPickImg];
    [self scrollToView:_stepPickImg];
    [self triggerImagePick];
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Step 4: Chọn ảnh + Apply
// ─────────────────────────────────────────────────────────────────────────────
- (UIView *)buildStepPickImg {
    UIView *card = [self makeCard];

    UILabel *stepTag = [self makeStepTag:@"4" text:@"Chọn Ảnh Media & Áp Dụng"];

    UILabel *hint = [UILabel new]; hint.translatesAutoresizingMaskIntoConstraints = NO;
    hint.text = @"1 ảnh dùng chung cho tất cả đoạn — sẽ thay vào ALL lớp media";
    hint.font = [UIFont systemFontOfSize:11]; hint.textColor = FVD_SUBTEXT;
    hint.numberOfLines = 0;

    // Preview card
    _imgPreviewCard = [[UIView alloc] init];
    _imgPreviewCard.translatesAutoresizingMaskIntoConstraints = NO;
    _imgPreviewCard.backgroundColor = FVD_BG;
    _imgPreviewCard.layer.cornerRadius = FVD_R_SM;
    _imgPreviewCard.layer.borderWidth  = 1.5;
    _imgPreviewCard.layer.borderColor  = [UIColor colorWithWhite:1 alpha:0.08].CGColor;

    _imgPreview = [[UIImageView alloc] init];
    _imgPreview.translatesAutoresizingMaskIntoConstraints = NO;
    _imgPreview.contentMode = UIViewContentModeScaleAspectFit;
    _imgPreview.clipsToBounds = YES;
    _imgPreview.layer.cornerRadius = FVD_R_SM - 2;

    UIImageView *placeholder = [[UIImageView alloc] initWithImage:FVDICON(FVDIconImage, 28, FVD_SUBTEXT)];
    placeholder.translatesAutoresizingMaskIntoConstraints = NO;
    placeholder.contentMode = UIViewContentModeScaleAspectFit;
    placeholder.tag = 500;
    [_imgPreviewCard addSubview:placeholder];
    [_imgPreviewCard addSubview:_imgPreview];

    _imgStatusLbl = [UILabel new]; _imgStatusLbl.translatesAutoresizingMaskIntoConstraints = NO;
    _imgStatusLbl.text = @"Chưa chọn ảnh";
    _imgStatusLbl.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
    _imgStatusLbl.textColor = FVD_SUBTEXT; _imgStatusLbl.textAlignment = NSTextAlignmentCenter;
    [_imgPreviewCard addSubview:_imgStatusLbl];

    [NSLayoutConstraint activateConstraints:@[
        [_imgPreview.topAnchor constraintEqualToAnchor:_imgPreviewCard.topAnchor constant:8],
        [_imgPreview.leadingAnchor constraintEqualToAnchor:_imgPreviewCard.leadingAnchor constant:8],
        [_imgPreview.trailingAnchor constraintEqualToAnchor:_imgPreviewCard.trailingAnchor constant:-8],
        [_imgPreview.heightAnchor constraintEqualToConstant:110],
        [placeholder.centerXAnchor constraintEqualToAnchor:_imgPreviewCard.centerXAnchor],
        [placeholder.centerYAnchor constraintEqualToAnchor:_imgPreview.centerYAnchor],
        [placeholder.widthAnchor constraintEqualToConstant:28],[placeholder.heightAnchor constraintEqualToConstant:28],
        [_imgStatusLbl.topAnchor constraintEqualToAnchor:_imgPreview.bottomAnchor constant:6],
        [_imgStatusLbl.centerXAnchor constraintEqualToAnchor:_imgPreviewCard.centerXAnchor],
        [_imgStatusLbl.bottomAnchor constraintEqualToAnchor:_imgPreviewCard.bottomAnchor constant:-8],
    ]];

    // Pick again button
    UIButton *pickAgainBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    pickAgainBtn.translatesAutoresizingMaskIntoConstraints = NO;
    pickAgainBtn.backgroundColor = FVD_CARD2;
    pickAgainBtn.layer.cornerRadius = FVD_R_SM;
    pickAgainBtn.layer.borderWidth  = 1; pickAgainBtn.layer.borderColor = FVD_BORDER.CGColor;
    UIImageView *pickIcon = [[UIImageView alloc] initWithImage:FVDICON(FVDIconImage, 14, FVD_SUBTEXT)];
    pickIcon.translatesAutoresizingMaskIntoConstraints = NO; pickIcon.contentMode = UIViewContentModeScaleAspectFit;
    UILabel *pickLbl = [UILabel new]; pickLbl.translatesAutoresizingMaskIntoConstraints = NO;
    pickLbl.text = @"Đổi Ảnh"; pickLbl.font = [UIFont systemFontOfSize:12]; pickLbl.textColor = FVD_SUBTEXT;
    [pickAgainBtn addSubview:pickIcon]; [pickAgainBtn addSubview:pickLbl];
    [pickAgainBtn addTarget:self action:@selector(triggerImagePick) forControlEvents:UIControlEventTouchUpInside];
    [NSLayoutConstraint activateConstraints:@[
        [pickIcon.leadingAnchor constraintEqualToAnchor:pickAgainBtn.leadingAnchor constant:10],
        [pickIcon.centerYAnchor constraintEqualToAnchor:pickAgainBtn.centerYAnchor],
        [pickIcon.widthAnchor constraintEqualToConstant:14],[pickIcon.heightAnchor constraintEqualToConstant:14],
        [pickLbl.leadingAnchor constraintEqualToAnchor:pickIcon.trailingAnchor constant:6],
        [pickLbl.centerYAnchor constraintEqualToAnchor:pickAgainBtn.centerYAnchor],
        [pickAgainBtn.heightAnchor constraintEqualToConstant:34],
    ]];

    // Apply button
    _applyBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    _applyBtn.translatesAutoresizingMaskIntoConstraints = NO;
    _applyBtn.layer.cornerRadius = FVD_R_MD;
    _applyBtn.alpha = 0.5; _applyBtn.enabled = NO;

    _applyGrad = FVDMakeGradient(FVD_ACCENT, FVD_ACCENT2, 90);
    _applyGrad.cornerRadius = FVD_R_MD;
    _applyGrad.frame = CGRectMake(0,0,10,10);
    [_applyBtn.layer insertSublayer:_applyGrad atIndex:0];

    UIImageView *applyIcon = [[UIImageView alloc] initWithImage:FVDICON(FVDIconCheck, 20, UIColor.whiteColor)];
    applyIcon.translatesAutoresizingMaskIntoConstraints = NO; applyIcon.contentMode = UIViewContentModeScaleAspectFit;
    _applyBtnLbl = [UILabel new]; _applyBtnLbl.translatesAutoresizingMaskIntoConstraints = NO;
    _applyBtnLbl.textColor = UIColor.whiteColor;
    _applyBtnLbl.font = [UIFont systemFontOfSize:15 weight:UIFontWeightBold];
    [_applyBtn addSubview:applyIcon]; [_applyBtn addSubview:_applyBtnLbl];
    [_applyBtn addTarget:self action:@selector(applyAll) forControlEvents:UIControlEventTouchUpInside];
    [NSLayoutConstraint activateConstraints:@[
        [applyIcon.leadingAnchor constraintEqualToAnchor:_applyBtn.leadingAnchor constant:16],
        [applyIcon.centerYAnchor constraintEqualToAnchor:_applyBtn.centerYAnchor],
        [applyIcon.widthAnchor constraintEqualToConstant:20],[applyIcon.heightAnchor constraintEqualToConstant:20],
        [_applyBtnLbl.leadingAnchor constraintEqualToAnchor:applyIcon.trailingAnchor constant:10],
        [_applyBtnLbl.centerYAnchor constraintEqualToAnchor:_applyBtn.centerYAnchor],
        [_applyBtn.heightAnchor constraintEqualToConstant:52],
    ]];

    for (UIView *v in @[stepTag, hint, _imgPreviewCard, pickAgainBtn, _applyBtn]) [card addSubview:v];
    [NSLayoutConstraint activateConstraints:@[
        [stepTag.topAnchor constraintEqualToAnchor:card.topAnchor constant:14],
        [stepTag.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:14],
        [hint.topAnchor constraintEqualToAnchor:stepTag.bottomAnchor constant:4],
        [hint.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:14],
        [hint.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-14],
        [_imgPreviewCard.topAnchor constraintEqualToAnchor:hint.bottomAnchor constant:12],
        [_imgPreviewCard.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:14],
        [_imgPreviewCard.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-14],
        [pickAgainBtn.topAnchor constraintEqualToAnchor:_imgPreviewCard.bottomAnchor constant:8],
        [pickAgainBtn.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-14],
        [pickAgainBtn.widthAnchor constraintEqualToConstant:90],
        [_applyBtn.topAnchor constraintEqualToAnchor:pickAgainBtn.bottomAnchor constant:12],
        [_applyBtn.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:14],
        [_applyBtn.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-14],
        [_applyBtn.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-14],
    ]];
    return card;
}

- (void)triggerImagePick {
    PHPickerConfiguration *cfg = [[PHPickerConfiguration alloc] initWithPhotoLibrary:[PHPhotoLibrary sharedPhotoLibrary]];
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
    [results.firstObject.itemProvider loadObjectOfClass:[UIImage class]
        completionHandler:^(UIImage *img, NSError *err) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!img) return;
                self.selectedMedia = img;
                self.imgPreview.image = img;
                [self.imgPreviewCard viewWithTag:500].hidden = YES;
                self.imgStatusLbl.text = @"✅ Ảnh đã chọn";
                self.imgStatusLbl.textColor = FVD_GREEN;
                self.imgPreviewCard.layer.borderColor = [FVD_GREEN colorWithAlphaComponent:0.4].CGColor;

                NSInteger n = self.toSeg - self.fromSeg + 1;
                self.applyBtnLbl.text = [NSString stringWithFormat:
                    @"Thay Ảnh + Nhập QR — %ld Đoạn", (long)n];
                self.applyBtn.enabled = YES;
                [UIView animateWithDuration:0.3 animations:^{ self.applyBtn.alpha = 1.0; }];
            });
        }];
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Step 5: Result
// ─────────────────────────────────────────────────────────────────────────────
- (UIView *)buildStepResult {
    UIView *card = [self makeCard];
    card.backgroundColor = [UIColor colorWithRed:0.05 green:0.15 blue:0.08 alpha:1];
    card.layer.borderColor = [FVD_GREEN colorWithAlphaComponent:0.3].CGColor;

    UIImageView *icon = [[UIImageView alloc] initWithImage:FVDICON(FVDIconCheck, 40, FVD_GREEN)];
    icon.translatesAutoresizingMaskIntoConstraints = NO; icon.contentMode = UIViewContentModeScaleAspectFit;

    _resultTitleLbl = [UILabel new]; _resultTitleLbl.translatesAutoresizingMaskIntoConstraints = NO;
    _resultTitleLbl.font = [UIFont systemFontOfSize:17 weight:UIFontWeightBold];
    _resultTitleLbl.textColor = FVD_TEXT; _resultTitleLbl.textAlignment = NSTextAlignmentCenter;

    _resultSubLbl = [UILabel new]; _resultSubLbl.translatesAutoresizingMaskIntoConstraints = NO;
    _resultSubLbl.font = [UIFont systemFontOfSize:12]; _resultSubLbl.textColor = FVD_SUBTEXT;
    _resultSubLbl.textAlignment = NSTextAlignmentCenter; _resultSubLbl.numberOfLines = 0;

    UIButton *newSession = [UIButton buttonWithType:UIButtonTypeSystem];
    newSession.translatesAutoresizingMaskIntoConstraints = NO;
    newSession.backgroundColor = [UIColor colorWithWhite:1 alpha:0.07];
    newSession.layer.cornerRadius = FVD_R_SM;
    newSession.layer.borderWidth  = 1; newSession.layer.borderColor = FVD_BORDER.CGColor;
    [newSession setTitle:@"🔄  Phiên Mới" forState:UIControlStateNormal];
    [newSession setTitleColor:FVD_ACCENT forState:UIControlStateNormal];
    newSession.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    [newSession addTarget:self action:@selector(resetSession) forControlEvents:UIControlEventTouchUpInside];

    for (UIView *v in @[icon, _resultTitleLbl, _resultSubLbl, newSession]) [card addSubview:v];
    [NSLayoutConstraint activateConstraints:@[
        [icon.topAnchor constraintEqualToAnchor:card.topAnchor constant:24],
        [icon.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],
        [icon.widthAnchor constraintEqualToConstant:40],[icon.heightAnchor constraintEqualToConstant:40],
        [_resultTitleLbl.topAnchor constraintEqualToAnchor:icon.bottomAnchor constant:10],
        [_resultTitleLbl.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],
        [_resultSubLbl.topAnchor constraintEqualToAnchor:_resultTitleLbl.bottomAnchor constant:6],
        [_resultSubLbl.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:14],
        [_resultSubLbl.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-14],
        [newSession.topAnchor constraintEqualToAnchor:_resultSubLbl.bottomAnchor constant:18],
        [newSession.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],
        [newSession.widthAnchor constraintEqualToConstant:150],
        [newSession.heightAnchor constraintEqualToConstant:42],
        [newSession.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-20],
    ]];
    return card;
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Apply All
// ─────────────────────────────────────────────────────────────────────────────
- (void)applyAll {
    if (!_selectedMedia) return;
    [self.view endEditing:YES];

    // Collect codes
    NSMutableArray<NSString *> *codes = [NSMutableArray new];
    for (FVDCodeCell *cell in _codeCells) {
        [codes addObject:cell.codeField.text ?: @""];
    }

    NSInteger total = codes.count;
    [self showProgressOverlayWithTotal:total];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        for (NSInteger i = 0; i < total; i++) {
            NSInteger segIdx = self.fromSeg + i;
            NSString *code   = codes[i];

            dispatch_async(dispatch_get_main_queue(), ^{
                self.progressLbl.text = [NSString stringWithFormat:
                    @"Đang xử lý đoạn %ld/%ld...", (long)(i+1), (long)total];
                self.progressDetail.text = [NSString stringWithFormat:
                    @"Đoạn %ld • %@ • \"%@\"",
                    (long)segIdx, self.selectedQRType,
                    code.length > 20 ? [code substringToIndex:20] : code];
                [self.progressBar setProgress:(float)(i+1)/(float)total animated:YES];
            });

            [self injectSegment:segIdx code:code];
            [NSThread sleepForTimeInterval:0.05];
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [self hideProgressOverlay];
            [self showResult:total];
        });
    });
}

- (void)injectSegment:(NSInteger)segIdx code:(NSString *)code {
    // ── 1. Get VideoStar project ──────────────────────────
    Class ctrl = NSClassFromString(@"VSProjectController");
    if (!ctrl) { [self injectFallback:segIdx code:code]; return; }
    id shared = [ctrl performSelector:@selector(sharedController)];
    if (!shared) { [self injectFallback:segIdx code:code]; return; }
    id project = [shared performSelector:@selector(currentProject)];
    if (!project) { [self injectFallback:segIdx code:code]; return; }

    // ── 2. Get layers/segments array ──────────────────────
    NSArray *layers = nil;
    for (NSString *sel in @[@"segments", @"layers", @"allLayers", @"videoLayers", @"mediaLayers"]) {
        SEL s = NSSelectorFromString(sel);
        if ([project respondsToSelector:s]) {
            NSArray *arr = [project performSelector:s];
            if (arr.count > 0) { layers = arr; break; }
        }
    }
    if (!layers) { [self injectFallback:segIdx code:code]; return; }

    // ── 3. Replace ALL media layers with shared image ─────
    dispatch_async(dispatch_get_main_queue(), ^{
        for (id layer in layers) {
            // Set image to ALL layers
            for (NSString *sel in @[@"setImage:", @"setSourceImage:", @"setThumbnailImage:",
                                    @"setMediaImage:", @"setBackgroundImage:"]) {
                SEL s = NSSelectorFromString(sel);
                if ([layer respondsToSelector:s]) {
                    [layer performSelector:s withObject:self.selectedMedia];
                }
            }
            if ([layer isKindOfClass:[UIImageView class]]) {
                ((UIImageView *)layer).image = self.selectedMedia;
            }
        }
    });

    // ── 4. Set QR code for specific segment ──────────────
    NSInteger idx = segIdx - 1;
    if (idx >= 0 && idx < (NSInteger)layers.count) {
        id seg = layers[idx];
        if (code.length > 0) {
            for (NSString *sel in @[@"setQrContent:", @"setQrCode:", @"setQrText:",
                                    @"setQrData:", @"setCodeContent:", @"setQrString:"]) {
                SEL s = NSSelectorFromString(sel);
                if ([seg respondsToSelector:s]) [seg performSelector:s withObject:code];
            }
            for (NSString *sel in @[@"setQrType:", @"setQrCodeType:", @"setCodeType:"]) {
                SEL s = NSSelectorFromString(sel);
                if ([seg respondsToSelector:s]) [seg performSelector:s withObject:self.selectedQRType];
            }
        }
    }

    // ── 5. Notify project update ──────────────────────────
    dispatch_async(dispatch_get_main_queue(), ^{
        for (NSString *sel in @[@"notifyProjectChanged", @"refresh", @"setNeedsUpdate",
                                @"updateThumbnails", @"reloadProject"]) {
            SEL s = NSSelectorFromString(sel);
            if ([project respondsToSelector:s]) [project performSelector:s];
        }
    });
}

// Fallback: inject via UIImageView walk when VS classes not available
- (void)injectFallback:(NSInteger)segIdx code:(NSString *)code {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIApplication *app = [UIApplication sharedApplication];
        UIWindow *win = nil;
        for (UIWindowScene *sc in app.connectedScenes) {
            if ([sc isKindOfClass:[UIWindowScene class]])
                { win = sc.windows.firstObject; break; }
        }
        if (!win) return;

        NSMutableArray *imageViews = [NSMutableArray new];
        [self collectImageViews:win into:imageViews];
        for (UIImageView *iv in imageViews) {
            iv.image = self.selectedMedia;
        }
    });
}

- (void)collectImageViews:(UIView *)view into:(NSMutableArray *)arr {
    if ([view isKindOfClass:[UIImageView class]] && view.frame.size.width > 50) {
        [arr addObject:view];
    }
    for (UIView *sub in view.subviews) [self collectImageViews:sub into:arr];
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Progress Overlay
// ─────────────────────────────────────────────────────────────────────────────
- (void)showProgressOverlayWithTotal:(NSInteger)total {
    _progressOverlay = [[UIView alloc] init];
    _progressOverlay.translatesAutoresizingMaskIntoConstraints = NO;
    _progressOverlay.backgroundColor = [UIColor colorWithWhite:0 alpha:0.75];
    [self.view addSubview:_progressOverlay];

    UIView *card = [[UIView alloc] init]; card.translatesAutoresizingMaskIntoConstraints = NO;
    card.backgroundColor = FVD_CARD; card.layer.cornerRadius = FVD_R_LG;

    UIImageView *icon = [[UIImageView alloc] initWithImage:FVDICON(FVDIconQR, 36, FVD_ACCENT)];
    icon.translatesAutoresizingMaskIntoConstraints = NO; icon.contentMode = UIViewContentModeScaleAspectFit;

    UILabel *title = [UILabel new]; title.translatesAutoresizingMaskIntoConstraints = NO;
    title.text = [NSString stringWithFormat:@"Đang nhập %ld đoạn...", (long)total];
    title.font = [UIFont systemFontOfSize:15 weight:UIFontWeightBold]; title.textColor = FVD_TEXT;

    _progressBar = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    _progressBar.translatesAutoresizingMaskIntoConstraints = NO;
    _progressBar.progressTintColor = FVD_ACCENT; _progressBar.trackTintColor = FVD_BG;
    _progressBar.layer.cornerRadius = 3; _progressBar.clipsToBounds = YES;

    _progressLbl = [UILabel new]; _progressLbl.translatesAutoresizingMaskIntoConstraints = NO;
    _progressLbl.font = [UIFont systemFontOfSize:12]; _progressLbl.textColor = FVD_SUBTEXT;
    _progressLbl.textAlignment = NSTextAlignmentCenter;

    _progressDetail = [UILabel new]; _progressDetail.translatesAutoresizingMaskIntoConstraints = NO;
    _progressDetail.font = [UIFont systemFontOfSize:10]; _progressDetail.textColor = FVD_SUBTEXT;
    _progressDetail.textAlignment = NSTextAlignmentCenter; _progressDetail.numberOfLines = 2;
    _progressDetail.alpha = 0.7;

    for (UIView *v in @[icon, title, _progressBar, _progressLbl, _progressDetail]) [card addSubview:v];
    [_progressOverlay addSubview:card];

    [NSLayoutConstraint activateConstraints:@[
        [_progressOverlay.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [_progressOverlay.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_progressOverlay.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_progressOverlay.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [card.centerXAnchor constraintEqualToAnchor:_progressOverlay.centerXAnchor],
        [card.centerYAnchor constraintEqualToAnchor:_progressOverlay.centerYAnchor],
        [card.widthAnchor constraintEqualToAnchor:_progressOverlay.widthAnchor multiplier:0.8],
        [icon.topAnchor constraintEqualToAnchor:card.topAnchor constant:24],
        [icon.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],
        [icon.widthAnchor constraintEqualToConstant:36],[icon.heightAnchor constraintEqualToConstant:36],
        [title.topAnchor constraintEqualToAnchor:icon.bottomAnchor constant:12],
        [title.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],
        [_progressBar.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:16],
        [_progressBar.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:20],
        [_progressBar.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-20],
        [_progressBar.heightAnchor constraintEqualToConstant:6],
        [_progressLbl.topAnchor constraintEqualToAnchor:_progressBar.bottomAnchor constant:8],
        [_progressLbl.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],
        [_progressDetail.topAnchor constraintEqualToAnchor:_progressLbl.bottomAnchor constant:4],
        [_progressDetail.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:14],
        [_progressDetail.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-14],
        [_progressDetail.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-20],
    ]];

    _progressOverlay.alpha = 0;
    card.transform = CGAffineTransformMakeScale(0.88, 0.88);
    [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0 options:0 animations:^{
        self.progressOverlay.alpha = 1; card.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)hideProgressOverlay {
    [UIView animateWithDuration:0.25 animations:^{ self.progressOverlay.alpha = 0; }
        completion:^(BOOL d){ [self.progressOverlay removeFromSuperview]; self.progressOverlay = nil; }];
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Show Result + Reset Session
// ─────────────────────────────────────────────────────────────────────────────
- (void)showResult:(NSInteger)total {
    _resultTitleLbl.text = [NSString stringWithFormat:@"✅ Xong %ld Đoạn!", (long)total];
    _resultSubLbl.text   = [NSString stringWithFormat:
        @"Đoạn %ld → %ld\nLoại: %@\nĐã thay ảnh + nhập QR code vào VideoStar",
        (long)_fromSeg, (long)_toSeg, _selectedQRType];

    [self animateShow:_stepResult];
    [self scrollToView:_stepResult];
}

- (void)resetSession {
    // Clear state
    _selectedMedia = nil;
    _selectedQRType = FVDQRTypes().firstObject;
    _fromSeg = 1; _toSeg = 5;
    _fromStepper.value = 1; _toStepper.value = 5;
    [self updateRangeSummary];
    [self updateChipStyles];
    _selectedTypeLabel.text = [NSString stringWithFormat:@"Đã chọn: %@", _selectedQRType];

    // Reset image preview
    _imgPreview.image = nil;
    [_imgPreviewCard viewWithTag:500].hidden = NO;
    _imgStatusLbl.text = @"Chưa chọn ảnh"; _imgStatusLbl.textColor = FVD_SUBTEXT;
    _imgPreviewCard.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.08].CGColor;
    _applyBtn.enabled = NO; _applyBtn.alpha = 0.5;

    // Hide all except step 1
    _stepQRType.hidden = YES; _stepQRType.alpha = 0;
    _stepCodes.hidden  = YES; _stepCodes.alpha  = 0;
    _stepPickImg.hidden = YES; _stepPickImg.alpha = 0;

    [UIView transitionWithView:self.view duration:0.35
        options:UIViewAnimationOptionTransitionCrossDissolve
        animations:^{ self.stepResult.hidden = YES; }
        completion:^(BOOL d) {
            [self animateShow:self.stepRange];
            [self.mainScroll setContentOffset:CGPointZero animated:YES];
        }];
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Helpers
// ─────────────────────────────────────────────────────────────────────────────
- (UIView *)makeCard {
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = FVD_CARD;
    card.layer.cornerRadius = FVD_R_MD;
    card.layer.borderWidth  = 1;
    card.layer.borderColor  = FVD_BORDER.CGColor;
    return card;
}

- (UILabel *)makeStepTag:(NSString *)num text:(NSString *)text {
    UIView *tag = [[UIView alloc] init]; // ignored, we build inline
    UILabel *lbl = [UILabel new]; lbl.translatesAutoresizingMaskIntoConstraints = NO;
    lbl.text = [NSString stringWithFormat:@"⬡ %@", text];
    lbl.font = [UIFont systemFontOfSize:14 weight:UIFontWeightBold];
    lbl.textColor = FVD_TEXT;
    return lbl;
}

- (UIButton *)makePrimaryButton:(NSString *)title icon:(FVDIcon)icon action:(SEL)action {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    btn.layer.cornerRadius = FVD_R_SM;

    CAGradientLayer *g = FVDMakeGradient(FVD_ACCENT, FVD_ACCENT2, 90);
    g.cornerRadius = FVD_R_SM; g.frame = CGRectMake(0,0,10,10);
    [btn.layer insertSublayer:g atIndex:0];
    objc_setAssociatedObject(btn, "grad", g, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    UIImageView *iv = [[UIImageView alloc] initWithImage:FVDICON(icon, 16, UIColor.whiteColor)];
    iv.translatesAutoresizingMaskIntoConstraints = NO; iv.contentMode = UIViewContentModeScaleAspectFit;
    UILabel *lbl = [UILabel new]; lbl.translatesAutoresizingMaskIntoConstraints = NO;
    lbl.text = title; lbl.textColor = UIColor.whiteColor;
    lbl.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    [btn addSubview:iv]; [btn addSubview:lbl];
    [NSLayoutConstraint activateConstraints:@[
        [iv.leadingAnchor constraintEqualToAnchor:btn.leadingAnchor constant:14],
        [iv.centerYAnchor constraintEqualToAnchor:btn.centerYAnchor],
        [iv.widthAnchor constraintEqualToConstant:16],[iv.heightAnchor constraintEqualToConstant:16],
        [lbl.leadingAnchor constraintEqualToAnchor:iv.trailingAnchor constant:8],
        [lbl.centerYAnchor constraintEqualToAnchor:btn.centerYAnchor],
    ]];
    [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

- (void)animateShow:(UIView *)view {
    if (!view.hidden) return;
    view.alpha = 0;
    view.hidden = NO;
    view.transform = CGAffineTransformMakeTranslation(0, 16);
    [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.78 initialSpringVelocity:0 options:0 animations:^{
        view.alpha = 1; view.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)scrollToView:(UIView *)view {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        CGRect rect = [view convertRect:view.bounds toView:self.mainScroll];
        [self.mainScroll scrollRectToVisible:rect animated:YES];
    });
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (_applyGrad) _applyGrad.frame = _applyBtn.bounds;
    // Resize all primary button grads
    NSArray<UIView *> *steps = @[_stepRange, _stepQRType, _stepCodes, _stepPickImg];
    for (UIView *step in steps) {
        for (UIView *sub in step.subviews) {
            if ([sub isKindOfClass:[UIButton class]]) {
                CAGradientLayer *g = objc_getAssociatedObject(sub, "grad");
                if (g) g.frame = sub.bounds;
            }
        }
    }
}
@end
