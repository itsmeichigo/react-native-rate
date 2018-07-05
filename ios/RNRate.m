#import "RNRate.h"

@implementation RNRate
RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(openAppStore:(NSDictionary *)options : (RCTResponseSenderBlock) callback) {
    NSString *AppleAppID = [RCTConvert NSString:options[@"AppleAppID"]];
    NSString *AppleNativePrefix = [RCTConvert NSString:options[@"AppleNativePrefix"]];
    
    NSString *url = [NSString stringWithFormat:@"%@%@", AppleNativePrefix, AppleAppID];
    [self openAppStoreAndRate:url];
}

RCT_EXPORT_METHOD(rate: (NSDictionary *)options : (RCTResponseSenderBlock) callback) {
    NSString *AppleAppID = [RCTConvert NSString:options[@"AppleAppID"]];
    NSString *AppleNativePrefix = [RCTConvert NSString:options[@"AppleNativePrefix"]];
    BOOL preferInApp = [RCTConvert BOOL:options[@"preferInApp"]];
    float inAppDelay = [RCTConvert float:options[@"inAppDelay"]];
    
    
    NSString *suffix = @"?action=write-review";
    
    NSString *url = [NSString stringWithFormat:@"%@%@%@", AppleNativePrefix, AppleAppID, suffix];
    
    if (preferInApp) {
        if ([SKStoreReviewController class]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSUInteger windowCount = [[[UIApplication sharedApplication] windows] count];
                [SKStoreReviewController requestReview];
                
                float checkTime = 0.1;
                int iterations = (int)(inAppDelay / checkTime);
                
                [self waitForInAppRatingModal:windowCount callback:callback checkTime:checkTime iterations:iterations];
            });
        }
    } else {
        [self openAppStoreAndRate:url];
        callback(@[[NSNumber numberWithBool:YES]]);
    }
}

- (void)waitForInAppRatingModal:(NSUInteger)originalWindowCount callback:(RCTResponseSenderBlock)callback checkTime:(float)checkTime iterations:(int)iterations {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(checkTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSUInteger newWindowCount = [[[UIApplication sharedApplication] windows] count];
        
        if (newWindowCount > originalWindowCount) {
            callback(@[[NSNumber numberWithBool:YES]]);
        } else if (newWindowCount < originalWindowCount) {
            callback(@[[NSNumber numberWithBool:NO]]);
        } else {
            int newInterations = iterations - 1;
            if (newInterations > 0) {
                [self waitForInAppRatingModal:originalWindowCount callback:callback checkTime:checkTime iterations:newInterations];
            } else {
                callback(@[[NSNumber numberWithBool:NO]]);
            }
        }
    });
}

- (void)openAppStoreAndRate:(NSString *)url {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
    });
    
}



@end
