// Tweak.x — FallVds Tool
// Inject into VideoStar (com.frontierdesign.VideoStar)
// Author: FallVds Team | Brand: FallVds Tool

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "FallVdsTool/FallVdsToolUI.h"
#import "FallVdsTool/FloatingButton.h"
#import "FallVdsTool/HideStream.h"

// ─────────────────────────────────────────────────────────
// Filter: only run inside VideoStar
// ─────────────────────────────────────────────────────────
%filter(applications, com.frontierdesign.VideoStar);

// ─────────────────────────────────────────────────────────
// Hook UIWindow to inject our floating button on first launch
// ─────────────────────────────────────────────────────────
%hook UIWindow

- (void)makeKeyAndVisible {
    %orig;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[FallVdsToolUI sharedInstance] launch];
        });
    });
}

%end

// ─────────────────────────────────────────────────────────
// Hook UIScreen to handle screen capture / recording events
// UIScreen.isCaptured becomes true during screen recording & mirroring
// ─────────────────────────────────────────────────────────
%hook UIScreen

- (void)setIsCaptured:(BOOL)captured {
    %orig;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[HideStream sharedInstance] handleCaptureStateChange:captured];
        // If Hide of Stream is ON, hide the floating button during capture
        if ([HideStream sharedInstance].enabled) {
            if (captured) {
                [[FloatingButton sharedInstance] hide];
            } else {
                [[FloatingButton sharedInstance] show];
            }
        }
    });
}

%end

// ─────────────────────────────────────────────────────────
// Hook RPBroadcastSampleHandler for ReplayKit live streaming
// ─────────────────────────────────────────────────────────
%hook RPBroadcastSampleHandler

- (void)broadcastStartedWithSetupInfo:(NSDictionary<NSString *,NSObject *> *)setupInfo {
    %orig;
    if ([HideStream sharedInstance].enabled) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[FloatingButton sharedInstance] hide];
        });
    }
}

- (void)broadcastFinished {
    %orig;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[FloatingButton sharedInstance] show];
    });
}

%end

// ─────────────────────────────────────────────────────────
// Hook UIApplication to intercept screenshot notifications
// (Prevents tool window from appearing in screenshots when HideStream is ON)
// ─────────────────────────────────────────────────────────
%hook UIApplication

- (void)applicationDidBecomeActive:(UIApplication *)application {
    %orig;
}

%end

// ─────────────────────────────────────────────────────────
// Constructor: initialise HideStream observers at dylib load time
// ─────────────────────────────────────────────────────────
%ctor {
    @autoreleasepool {
        [[HideStream sharedInstance] startObserving];

        // Observe screenshot notification to hide floating button
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationUserDidTakeScreenshotNotification
            object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *n) {
                // Screenshot taken — if HideStream is enabled the secure window
                // already prevents the tool from appearing; this is a fallback.
                if ([HideStream sharedInstance].enabled) {
                    [[FloatingButton sharedInstance] hide];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                        dispatch_get_main_queue(), ^{
                        [[FloatingButton sharedInstance] show];
                    });
                }
            }];
    }
}
