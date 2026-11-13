// LicenseManager.m
// Beta: hardcoded key = "MinhTienVds"
// Future: replace with real API endpoint

#import "LicenseManager.h"
#import <UIKit/UIKit.h>

static NSString *const kKeyStored   = @"fvd_license_key";
static NSString *const kKeyExpiry   = @"fvd_license_expiry";
static NSString *const kKeyPackage  = @"fvd_license_package";
static NSString *const kBetaKey     = @"MinhTienVds";

@implementation LicenseManager

+ (instancetype)sharedInstance {
    static LicenseManager *s;
    static dispatch_once_t t;
    dispatch_once(&t, ^{ s = [self new]; });
    return s;
}

- (instancetype)init {
    self = [super init];
    if (!self) return nil;
    // Load persisted key
    NSString *saved = [[NSUserDefaults standardUserDefaults] stringForKey:kKeyStored];
    if (saved) [self activateKey:saved];
    return self;
}

- (BOOL)activateKey:(NSString *)key {
    key = [key stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([key isEqualToString:kBetaKey]) {
        _currentKey    = key;
        _packageName   = @"Beta Access";
        _expiryDate    = @"31/12/2025";
        _isActivated   = YES;
        _isExpired     = NO;
        [[NSUserDefaults standardUserDefaults] setObject:key forKey:kKeyStored];
        [[NSUserDefaults standardUserDefaults] synchronize];
        return YES;
    }
    // TODO: real server validation
    return NO;
}

- (void)logout {
    _currentKey  = nil;
    _packageName = nil;
    _expiryDate  = nil;
    _isActivated = NO;
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kKeyStored];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)deviceUUID {
    // UIDevice.identifierForVendor — best available without entitlement
    NSString *uuid = [[UIDevice currentDevice].identifierForVendor UUIDString];
    return uuid ?: @"UNKNOWN";
}

- (BOOL)isExpired { return NO; }

- (NSString *)statusText {
    if (!_isActivated) return @"Chưa kích hoạt";
    if (_isExpired)    return @"Đã hết hạn";
    return @"Đang hoạt động";
}

@end
