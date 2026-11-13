// FloatingButton.h
#pragma once
#import <UIKit/UIKit.h>

@protocol FloatingButtonDelegate <NSObject>
- (void)floatingButtonTapped;
@end

@interface FloatingButton : UIView
@property (nonatomic, weak) id<FloatingButtonDelegate> delegate;
+ (instancetype)sharedInstance;
- (void)showInWindow:(UIWindow *)window;
- (void)hide;
- (void)show;
@end
