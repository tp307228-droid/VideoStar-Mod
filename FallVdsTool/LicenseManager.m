// LicenseManager.m
#import "LicenseManager.h"
#import <UIKit/UIKit.h>

static NSString *const kKeyStored  = @"fvd_license_key";
static NSString *const kBetaKey    = @"MinhTienVds";

@interface LicenseManager ()
// Redeclare readonly as readwrite internally
@property (nonatomic, copy)   NSString *currentKey;
@property (nonatomic, copy)   NSString *packageName;
@property (nonatomic, copy)   NSString *expiryDate;
@property (nonatomic, assign) BOOL      isActivated;
@end

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
    NSString *saved = [[NSUserDefaults standardUserDefaults] stringForKey:kKeyStored];
    if (saved.length) [self activateKey:saved];
    return self;
}

- (BOOL)activateKey:(NSString *)key {
    key = [key stringByTrimmingCharactersInSet:
           [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([key isEqualToString:kBetaKey]) {
        self.currentKey  = key;
        self.packageName = @"Beta Access";
        self.expiryDate  = @"31/12/2025";
        self.isActivated = YES;
        [[NSUserDefaults standardUserDefaults] setObject:key forKey:kKeyStored];
        [[NSUserDefaults standardUserDefaults] synchronize];
        return YES;
    }
    return NO;
}

- (void)logout {
    self.currentKey  = nil;
    self.packageName = nil;
    self.expiryDate  = nil;
    self.isActivated = NO;
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kKeyStored];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)deviceUUID {
    NSString *uuid = [[UIDevice currentDevice].identifierForVendor UUIDString];
    return uuid ?: @"UNKNOWN";
}

- (BOOL)isExpired {
    return NO; // Beta: không có expiry
}

- (NSString *)statusText {
    if (!self.isActivated) return @"Chưa kích hoạt";
    if (self.isExpired)    return @"Đã hết hạn";
    return @"Đang hoạt động";
}

@end
