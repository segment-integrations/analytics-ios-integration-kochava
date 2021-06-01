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
    return [[SEGKochavaIntegration alloc] initWithSettings:settings andKochavaTracker:nil];
}

- (nonnull NSString *)key {
    return @"Kochava iOS";
}

@end


