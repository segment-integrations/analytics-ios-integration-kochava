//
//  SEGKochavaIntegration.h
//  Pods
//

#import <Foundation/Foundation.h>
#import <KochavaTrackeriOS/KochavaTracker.h>

#if defined(__has_include) && __has_include(<Analytics/SEGAnalytics.h>)
#import <Analytics/SEGIntegration.h>
#else
#import <Segment/SEGIntegration.h>
#endif

#if defined(TEST)
FOUNDATION_EXPORT NSString *const SKConfigEnforceATT;
FOUNDATION_EXPORT NSString *const SKConfigCustomPromptLength;
FOUNDATION_EXPORT NSString *const SKConfigApiKey;
FOUNDATION_EXPORT NSString *const SKConfigSubscribeToNotifications;
FOUNDATION_EXPORT NSString *const SKIdentifyUserId;
#endif

FOUNDATION_EXPORT NSString *const SKTrackDeepLinkOpened;

@interface KochavaEventManager:NSObject

+ (KochavaEventManager*)shared;

- (void)sendEvent:(KVAEvent*)event;

@end

@interface SEGKochavaIntegration:NSObject<SEGIntegration>

@property (atomic, strong) NSDictionary *settings;
@property (atomic, strong) KVATracker *tracker;

- (instancetype)initWithSettings:(NSDictionary*)settings andKochavaTracker:(id)kochava;

@end
