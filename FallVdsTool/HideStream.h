// HideStream.h
#pragma once
#import <UIKit/UIKit.h>

@interface HideStream : NSObject
@property (nonatomic, assign) BOOL enabled;
+ (instancetype)sharedInstance;
- (void)startObserving;
- (void)handleCaptureStateChange:(BOOL)captured;
- (void)applyToView:(UIView *)view;
- (void)removeFromView:(UIView *)view;
@end
