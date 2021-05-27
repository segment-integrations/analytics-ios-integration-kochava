#include "SEGKochavaIntegrationFactory.h"
#include "SEGKochavaIntegration.h"

@implementation SEGKochavaIntegrationFactory

+(instancetype)instance
{
    static dispatch_once_t once;
    static SEGKochavaIntegrationFactory *sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

-(instancetype)init
{
    self = [super init];
    return self;
}

-(id<SEGIntegration>)createWithSettings:(NSDictionary *)settings forAnalytics:(SEGAnalytics *)analytics
{
    // KVATracker *tracker = [KVATracker tracker];
    // [tracker startWithAppGUIDString:@"kosegment-ios-sdk-test-doq96088y"];
    
    // NSMutableDictionary *newSettings = [[NSMutableDictionary alloc] initWithDictionary:settings];
    // newSettings[ksApplicationGuid] = @"kosegment-ios-sdk-test-doq96088y";
    
    return [[SEGKochavaIntegration alloc] initWithSettings:settings andKochavaTracker:nil];
    // return [[SEGKochavaIntegration alloc] initWithSettings:newSettings andKochavaTracker:tracker];
}

- (nonnull NSString *)key {
    return @"Kochava iOS";
}

@end


