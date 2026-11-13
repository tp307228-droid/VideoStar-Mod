// Tweak.m — FallVds Tool (Pure Objective-C Runtime)
// 100% Standalone — NO CydiaSubstrate dependency — Zero crash on launch
// Injected into VideoStar for unjailbroken sideloading (eSign / TrollStore)

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "FallVdsTool/FallVdsToolUI.h"
#import "FallVdsTool/FloatingButton.h"
#import "FallVdsTool/HideStream.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Swizzle UIWindow makeKeyAndVisible
// ─────────────────────────────────────────────────────────────────────────────

@implementation UIWindow (FallVdsTool)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class cls = [UIWindow class];
        SEL origSel = @selector(makeKeyAndVisible);
        SEL swizSel = @selector(fvd_makeKeyAndVisible);

        Method origMethod = class_getInstanceMethod(cls, origSel);
        Method swizMethod = class_getInstanceMethod(cls, swizSel);

        BOOL didAddMethod = class_addMethod(cls, origSel,
                                            method_getImplementation(swizMethod),
                                            method_getTypeEncoding(swizMethod));
        if (didAddMethod) {
            class_replaceMethod(cls, swizSel,
                                method_getImplementation(origMethod),
                                method_getTypeEncoding(origMethod));
        } else {
            method_exchangeImplementations(origMethod, swizMethod);
        }
    });
}

- (void)fvd_makeKeyAndVisible {
    [self fvd_makeKeyAndVisible]; // Call original

    static dispatch_once_t launchOnce;
    dispatch_once(&launchOnce, ^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            @try {
                [[FallVdsToolUI sharedInstance] launch];
            } @catch (NSException *e) {
                NSLog(@"[FallVdsTool] Launch exception: %@", e);
            }
        });
    });
}

@end

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Screen Capture & Recording Observers (HideStream)
// ─────────────────────────────────────────────────────────────────────────────

static void setupScreenCaptureObservers(void) {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

    // Screen recording / mirroring state changed
    if (@available(iOS 11.0, *)) {
        [nc addObserverForName:UIScreenCapturedDidChangeNotification
                        object:nil
                         queue:[NSOperationQueue mainQueue]
                    usingBlock:^(NSNotification *n) {
            BOOL captured = [UIScreen mainScreen].isCaptured;
            [[HideStream sharedInstance] handleCaptureStateChange:captured];
            if ([HideStream sharedInstance].enabled) {
                if (captured) {
                    [[FloatingButton sharedInstance] hide];
                } else {
                    [[FloatingButton sharedInstance] show];
                }
            }
        }];
    }

    // Screenshot taken
    [nc addObserverForName:UIApplicationUserDidTakeScreenshotNotification
                    object:nil
                     queue:[NSOperationQueue mainQueue]
                usingBlock:^(NSNotification *n) {
        if ([HideStream sharedInstance].enabled) {
            [[FloatingButton sharedInstance] hide];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[FloatingButton sharedInstance] show];
            });
        }
    }];
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Constructor Entry Point (Loaded automatically by dyld)
// ─────────────────────────────────────────────────────────────────────────────

__attribute__((constructor))
static void FallVdsToolInit(void) {
    @autoreleasepool {
        [[HideStream sharedInstance] startObserving];
        setupScreenCaptureObservers();
    }
}

#pragma clang diagnostic pop
