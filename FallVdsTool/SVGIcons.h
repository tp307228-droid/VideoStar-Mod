// SVGIcons.h — Pure UIBezierPath SVG-style icons (no emoji, no SF Symbols needed)
#pragma once
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, FVDIcon) {
    FVDIconImage,
    FVDIconQR,
    FVDIconShield,
    FVDIconKey,
    FVDIconDevice,
    FVDIconCalendar,
    FVDIconLogout,
    FVDIconClose,
    FVDIconMenu,
    FVDIconCheck,
    FVDIconStar,
    FVDIconEye,
    FVDIconEyeOff,
    FVDIconChevronRight,
    FVDIconPlus,
    FVDIconTrash,
    FVDIconDiscord,
    FVDIconPkg,
};

// Returns a UIImage drawn with UIBezierPath at given size/color
static UIImage *FVDIconImage_(FVDIcon icon, CGFloat size, UIColor *color) {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(size, size), NO, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [color setFill];
    [color setStroke];
    CGContextSetLineWidth(ctx, size * 0.075);
    CGContextSetLineCap(ctx, kCGLineCapRound);
    CGContextSetLineJoin(ctx, kCGLineJoinRound);

    // Normalize to 24×24 grid then scale
    CGFloat s = size / 24.0;
    CGContextScaleCTM(ctx, s, s);

    switch (icon) {

    case FVDIconImage: {
        // Frame
        UIBezierPath *p = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(2,2,20,20) cornerRadius:3];
        [p stroke];
        // Mountain
        UIBezierPath *m = [UIBezierPath bezierPath];
        [m moveToPoint:CGPointMake(2, 18)];
        [m addLineToPoint:CGPointMake(8, 11)];
        [m addLineToPoint:CGPointMake(13, 16)];
        [m addLineToPoint:CGPointMake(16, 13)];
        [m addLineToPoint:CGPointMake(22, 18)];
        [m stroke];
        // Sun
        UIBezierPath *circle = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(14.5, 5.5, 4, 4)];
        [circle fill];
        break;
    }
    case FVDIconQR: {
        // Top-left cell
        UIBezierPath *p1 = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(2,2,8,8) cornerRadius:1.5];
        [p1 stroke];
        UIBezierPath *p1i = [UIBezierPath bezierPathWithRect:CGRectMake(4,4,4,4)];
        [p1i fill];
        // Top-right cell
        UIBezierPath *p2 = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(14,2,8,8) cornerRadius:1.5];
        [p2 stroke];
        UIBezierPath *p2i = [UIBezierPath bezierPathWithRect:CGRectMake(16,4,4,4)];
        [p2i fill];
        // Bottom-left cell
        UIBezierPath *p3 = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(2,14,8,8) cornerRadius:1.5];
        [p3 stroke];
        UIBezierPath *p3i = [UIBezierPath bezierPathWithRect:CGRectMake(4,16,4,4)];
        [p3i fill];
        // Bottom-right dots
        for (int r = 0; r < 2; r++) for (int c = 0; c < 2; c++) {
            if (r==1&&c==0) continue;
            UIBezierPath *dot = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(14+c*5, 14+r*5, 3, 3)];
            [dot fill];
        }
        break;
    }
    case FVDIconShield: {
        UIBezierPath *p = [UIBezierPath bezierPath];
        [p moveToPoint:CGPointMake(12, 2)];
        [p addLineToPoint:CGPointMake(20, 5)];
        [p addLineToPoint:CGPointMake(20, 11)];
        [p addCurveToPoint:CGPointMake(12, 22) controlPoint1:CGPointMake(20,17) controlPoint2:CGPointMake(16,20)];
        [p addCurveToPoint:CGPointMake(4, 11) controlPoint1:CGPointMake(8,20) controlPoint2:CGPointMake(4,17)];
        [p addLineToPoint:CGPointMake(4, 5)];
        [p closePath];
        [p stroke];
        // Check inside
        UIBezierPath *ck = [UIBezierPath bezierPath];
        [ck moveToPoint:CGPointMake(8.5, 12)];
        [ck addLineToPoint:CGPointMake(10.5, 14.5)];
        [ck addLineToPoint:CGPointMake(15.5, 9.5)];
        [ck stroke];
        break;
    }
    case FVDIconKey: {
        UIBezierPath *p = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(2,2,10,10)];
        [p stroke];
        UIBezierPath *stem = [UIBezierPath bezierPath];
        [stem moveToPoint:CGPointMake(11,11)];
        [stem addLineToPoint:CGPointMake(21,21)];
        [stem moveToPoint:CGPointMake(17,17)];
        [stem addLineToPoint:CGPointMake(17,20)];
        [stem moveToPoint:CGPointMake(20,17)];
        [stem addLineToPoint:CGPointMake(20,20)];
        [stem stroke];
        break;
    }
    case FVDIconDevice: {
        UIBezierPath *p = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(5,2,14,20) cornerRadius:3];
        [p stroke];
        UIBezierPath *btn = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(10.5,18,3,3)];
        [btn fill];
        UIBezierPath *line = [UIBezierPath bezierPath];
        [line moveToPoint:CGPointMake(5,16)]; [line addLineToPoint:CGPointMake(19,16)];
        [line stroke];
        break;
    }
    case FVDIconCalendar: {
        UIBezierPath *p = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(2,4,20,18) cornerRadius:3];
        [p stroke];
        UIBezierPath *line = [UIBezierPath bezierPath];
        [line moveToPoint:CGPointMake(2,10)]; [line addLineToPoint:CGPointMake(22,10)];
        [line moveToPoint:CGPointMake(7,2)]; [line addLineToPoint:CGPointMake(7,6)];
        [line moveToPoint:CGPointMake(17,2)]; [line addLineToPoint:CGPointMake(17,6)];
        [line stroke];
        // Dots
        for (int r=0;r<2;r++) for (int c=0;c<3;c++) {
            UIBezierPath *d = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(6+c*5, 13+r*4, 2.5, 2.5)];
            [d fill];
        }
        break;
    }
    case FVDIconLogout: {
        UIBezierPath *p = [UIBezierPath bezierPath];
        [p moveToPoint:CGPointMake(9,21)];
        [p addLineToPoint:CGPointMake(4,21)];
        [p addLineToPoint:CGPointMake(4,3)];
        [p addLineToPoint:CGPointMake(9,3)];
        [p stroke];
        UIBezierPath *arrow = [UIBezierPath bezierPath];
        [arrow moveToPoint:CGPointMake(16,7)];
        [arrow addLineToPoint:CGPointMake(21,12)];
        [arrow addLineToPoint:CGPointMake(16,17)];
        [arrow moveToPoint:CGPointMake(21,12)];
        [arrow addLineToPoint:CGPointMake(9,12)];
        [arrow stroke];
        break;
    }
    case FVDIconClose: {
        UIBezierPath *p = [UIBezierPath bezierPath];
        [p moveToPoint:CGPointMake(4,4)]; [p addLineToPoint:CGPointMake(20,20)];
        [p moveToPoint:CGPointMake(20,4)]; [p addLineToPoint:CGPointMake(4,20)];
        [p stroke];
        break;
    }
    case FVDIconMenu: {
        for (int i=0;i<3;i++) {
            UIBezierPath *p = [UIBezierPath bezierPath];
            [p moveToPoint:CGPointMake(3, 6+i*6)];
            [p addLineToPoint:CGPointMake(21, 6+i*6)];
            [p stroke];
        }
        break;
    }
    case FVDIconCheck: {
        UIBezierPath *p = [UIBezierPath bezierPath];
        [p moveToPoint:CGPointMake(4,12)];
        [p addLineToPoint:CGPointMake(9,17)];
        [p addLineToPoint:CGPointMake(20,6)];
        [p stroke];
        break;
    }
    case FVDIconStar: {
        CGPoint pts[] = {
            CGPointMake(12,2),CGPointMake(15.09,8.26),CGPointMake(22,9.27),
            CGPointMake(17,14.14),CGPointMake(18.18,21.02),CGPointMake(12,17.77),
            CGPointMake(5.82,21.02),CGPointMake(7,14.14),CGPointMake(2,9.27),
            CGPointMake(8.91,8.26)
        };
        UIBezierPath *p = [UIBezierPath bezierPath];
        [p moveToPoint:pts[0]];
        for (int i=1;i<10;i++) [p addLineToPoint:pts[i]];
        [p closePath];
        [p fill];
        break;
    }
    case FVDIconEye: {
        UIBezierPath *p = [UIBezierPath bezierPath];
        [p moveToPoint:CGPointMake(1,12)];
        [p addCurveToPoint:CGPointMake(23,12) controlPoint1:CGPointMake(5,5) controlPoint2:CGPointMake(19,5)];
        [p addCurveToPoint:CGPointMake(1,12) controlPoint1:CGPointMake(19,19) controlPoint2:CGPointMake(5,19)];
        [p stroke];
        UIBezierPath *circle = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(9,9,6,6)];
        [circle stroke];
        break;
    }
    case FVDIconEyeOff: {
        UIBezierPath *p = [UIBezierPath bezierPath];
        [p moveToPoint:CGPointMake(2,2)]; [p addLineToPoint:CGPointMake(22,22)];
        [p moveToPoint:CGPointMake(6.71,6.71)];
        [p addCurveToPoint:CGPointMake(1,12) controlPoint1:CGPointMake(3.5,9) controlPoint2:CGPointMake(1,12)];
        [p addCurveToPoint:CGPointMake(12,19) controlPoint1:CGPointMake(1,12) controlPoint2:CGPointMake(5,19)];
        [p moveToPoint:CGPointMake(17.29,17.29)];
        [p addCurveToPoint:CGPointMake(23,12) controlPoint1:CGPointMake(20,15.5) controlPoint2:CGPointMake(23,12)];
        [p addCurveToPoint:CGPointMake(12,5) controlPoint1:CGPointMake(23,12) controlPoint2:CGPointMake(19,5)];
        [p stroke];
        break;
    }
    case FVDIconChevronRight: {
        UIBezierPath *p = [UIBezierPath bezierPath];
        [p moveToPoint:CGPointMake(9,6)]; [p addLineToPoint:CGPointMake(15,12)]; [p addLineToPoint:CGPointMake(9,18)];
        [p stroke];
        break;
    }
    case FVDIconPlus: {
        UIBezierPath *p = [UIBezierPath bezierPath];
        [p moveToPoint:CGPointMake(12,4)]; [p addLineToPoint:CGPointMake(12,20)];
        [p moveToPoint:CGPointMake(4,12)]; [p addLineToPoint:CGPointMake(20,12)];
        [p stroke];
        break;
    }
    case FVDIconTrash: {
        UIBezierPath *p = [UIBezierPath bezierPath];
        [p moveToPoint:CGPointMake(3,6)]; [p addLineToPoint:CGPointMake(21,6)];
        [p moveToPoint:CGPointMake(8,6)]; [p addLineToPoint:CGPointMake(8,4)];
        [p addLineToPoint:CGPointMake(16,4)]; [p addLineToPoint:CGPointMake(16,6)];
        UIBezierPath *box = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(5,6,14,15) cornerRadius:2];
        [box stroke];
        for (int i=0;i<3;i++) {
            UIBezierPath *l = [UIBezierPath bezierPath];
            [l moveToPoint:CGPointMake(9+i*2.5, 10)]; [l addLineToPoint:CGPointMake(9+i*2.5, 17)];
            [l stroke];
        }
        [p stroke];
        break;
    }
    case FVDIconDiscord: {
        // Discord Clyde simplified
        UIBezierPath *p = [UIBezierPath bezierPath];
        [p moveToPoint:CGPointMake(20.317,4.37)];
        [p addCurveToPoint:CGPointMake(16.148,3) controlPoint1:CGPointMake(18.845,3.76) controlPoint2:CGPointMake(17.526,3.26)];
        [p addCurveToPoint:CGPointMake(15.818,3.634) controlPoint1:CGPointMake(16.054,3.112) controlPoint2:CGPointMake(15.918,3.389)];
        [p addCurveToPoint:CGPointMake(12,3.312) controlPoint1:CGPointMake(14.73,3.148) controlPoint2:CGPointMake(13.37,3.138)];
        [p addCurveToPoint:CGPointMake(8.182,3.634) controlPoint1:CGPointMake(10.63,3.138) controlPoint2:CGPointMake(9.27,3.148)];
        [p addCurveToPoint:CGPointMake(7.852,3) controlPoint1:CGPointMake(8.082,3.389) controlPoint2:CGPointMake(7.946,3.112)];
        [p addCurveToPoint:CGPointMake(3.683,4.37) controlPoint1:CGPointMake(6.474,3.26) controlPoint2:CGPointMake(5.155,3.76)];
        [p addCurveToPoint:CGPointMake(2,19.11) controlPoint1:CGPointMake(2.631,8.44) controlPoint2:CGPointMake(2.058,15.17)];
        [p addCurveToPoint:CGPointMake(5.945,21) controlPoint1:CGPointMake(3.117,20.14) controlPoint2:CGPointMake(4.483,20.65)];
        [p addCurveToPoint:CGPointMake(7.019,18.95) controlPoint1:CGPointMake(6.407,20.42) controlPoint2:CGPointMake(6.775,19.75)];
        [p addCurveToPoint:CGPointMake(4.961,17.95) controlPoint1:CGPointMake(6.213,18.56) controlPoint2:CGPointMake(5.556,18.23)];
        [p addCurveToPoint:CGPointMake(5.272,17.73) controlPoint1:CGPointMake(5.015,17.9) controlPoint2:CGPointMake(5.144,17.81)];
        [p addCurveToPoint:CGPointMake(12,19.44) controlPoint1:CGPointMake(7.125,18.67) controlPoint2:CGPointMake(9.496,19.44)];
        [p addCurveToPoint:CGPointMake(18.728,17.73) controlPoint1:CGPointMake(14.504,19.44) controlPoint2:CGPointMake(16.875,18.67)];
        [p addCurveToPoint:CGPointMake(19.039,17.95) controlPoint1:CGPointMake(18.856,17.81) controlPoint2:CGPointMake(18.985,17.9)];
        [p addCurveToPoint:CGPointMake(16.981,18.95) controlPoint1:CGPointMake(18.444,18.23) controlPoint2:CGPointMake(17.787,18.56)];
        [p addCurveToPoint:CGPointMake(18.055,21) controlPoint1:CGPointMake(17.225,19.75) controlPoint2:CGPointMake(17.593,20.42)];
        [p addCurveToPoint:CGPointMake(22,19.11) controlPoint1:CGPointMake(19.517,20.65) controlPoint2:CGPointMake(20.883,20.14)];
        [p addCurveToPoint:CGPointMake(20.317,4.37) controlPoint1:CGPointMake(21.942,15.17) controlPoint2:CGPointMake(21.369,8.44)];
        [p closePath];
        [p fill];
        // Eyes
        UIBezierPath *eye1 = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(8.5,10.5,3,3.5)];
        UIBezierPath *eye2 = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(12.5,10.5,3,3.5)];
        [[UIColor whiteColor] setFill];
        [eye1 fill]; [eye2 fill];
        break;
    }
    case FVDIconPkg: {
        UIBezierPath *p = [UIBezierPath bezierPath];
        [p moveToPoint:CGPointMake(12,2)];
        [p addLineToPoint:CGPointMake(21,7)];
        [p addLineToPoint:CGPointMake(21,17)];
        [p addLineToPoint:CGPointMake(12,22)];
        [p addLineToPoint:CGPointMake(3,17)];
        [p addLineToPoint:CGPointMake(3,7)];
        [p closePath];
        [p stroke];
        UIBezierPath *mid = [UIBezierPath bezierPath];
        [mid moveToPoint:CGPointMake(12,22)]; [mid addLineToPoint:CGPointMake(12,12)];
        [mid moveToPoint:CGPointMake(3,7)]; [mid addLineToPoint:CGPointMake(12,12)];
        [mid moveToPoint:CGPointMake(21,7)]; [mid addLineToPoint:CGPointMake(12,12)];
        [mid stroke];
        break;
    }
    }

    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

#define FVDICON(icon, size, color) FVDIconImage_((icon), (size), (color))
