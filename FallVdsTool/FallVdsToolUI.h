// FallVdsToolUI.h
#pragma once
#import <UIKit/UIKit.h>

@interface FallVdsToolUI : NSObject
+ (instancetype)sharedInstance;
- (void)launch;
- (void)showMenu;
- (void)hideMenu;
@end
