// LicenseManager.h
#pragma once
#import <Foundation/Foundation.h>

@interface LicenseManager : NSObject
@property (nonatomic, copy, readonly) NSString *currentKey;
@property (nonatomic, copy, readonly) NSString *packageName;
@property (nonatomic, copy, readonly) NSString *expiryDate;
@property (nonatomic, copy, readonly) NSString *deviceUUID;
@property (nonatomic, assign, readonly) BOOL isActivated;
@property (nonatomic, assign, readonly) BOOL isExpired;

+ (instancetype)sharedInstance;
- (BOOL)activateKey:(NSString *)key;
- (void)logout;
- (NSString *)statusText;
@end
