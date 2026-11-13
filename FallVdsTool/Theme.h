// Theme.h — FallVds Tool Design System
#pragma once
#import <UIKit/UIKit.h>

// ── Colors ──────────────────────────────────────────────
#define FVD_BG          [UIColor colorWithRed:0.06 green:0.06 blue:0.09 alpha:1.0]
#define FVD_CARD        [UIColor colorWithRed:0.10 green:0.10 blue:0.15 alpha:1.0]
#define FVD_CARD2       [UIColor colorWithRed:0.13 green:0.13 blue:0.19 alpha:1.0]
#define FVD_ACCENT      [UIColor colorWithRed:0.55 green:0.25 blue:1.00 alpha:1.0]
#define FVD_ACCENT2     [UIColor colorWithRed:0.90 green:0.30 blue:0.70 alpha:1.0]
#define FVD_GREEN       [UIColor colorWithRed:0.20 green:0.90 blue:0.55 alpha:1.0]
#define FVD_RED         [UIColor colorWithRed:1.00 green:0.30 blue:0.35 alpha:1.0]
#define FVD_TEXT        [UIColor colorWithWhite:1.00 alpha:1.00]
#define FVD_SUBTEXT     [UIColor colorWithWhite:0.65 alpha:1.00]
#define FVD_BORDER      [UIColor colorWithWhite:1.00 alpha:0.08]
#define FVD_SEP         [UIColor colorWithWhite:1.00 alpha:0.07]

// ── Gradient helper ──────────────────────────────────────
static inline CAGradientLayer *FVDMakeGradient(UIColor *c1, UIColor *c2, CGFloat angle) {
    CAGradientLayer *g = [CAGradientLayer layer];
    g.colors = @[(id)c1.CGColor, (id)c2.CGColor];
    CGFloat rad = angle * M_PI / 180.0;
    g.startPoint = CGPointMake(0.5 - cos(rad)/2, 0.5 - sin(rad)/2);
    g.endPoint   = CGPointMake(0.5 + cos(rad)/2, 0.5 + sin(rad)/2);
    return g;
}

// ── Corner radius ────────────────────────────────────────
#define FVD_R_SM   8.0
#define FVD_R_MD  14.0
#define FVD_R_LG  20.0
#define FVD_R_XL  28.0

// ── Blur helper ──────────────────────────────────────────
static inline UIVisualEffectView *FVDBlurView(UIBlurEffectStyle style) {
    UIBlurEffect *e = [UIBlurEffect effectWithStyle:style];
    UIVisualEffectView *v = [[UIVisualEffectView alloc] initWithEffect:e];
    v.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    return v;
}
