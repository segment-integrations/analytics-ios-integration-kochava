//
//  SEGKochavaIntegration.h
//  Pods
//

#import <Foundation/Foundation.h>
#import <KochavaTracker.h>

#if defined(__has_include) && __has_include(<Analytics/SEGAnalytics.h>)
#import <Analytics/SEGIntegration.h>
#else
#import <Segment/SEGIntegration.h>
#endif

FOUNDATION_EXPORT NSString *const SKConfigEnforceATT;
FOUNDATION_EXPORT NSString *const SKConfigCustomPromptLength;
FOUNDATION_EXPORT NSString *const SKConfigApiKey;
FOUNDATION_EXPORT NSString *const SKConfigSubscribeToNotifications;
FOUNDATION_EXPORT NSString *const SKIdentifyUserId;
FOUNDATION_EXPORT NSString *const SKTrackDeepLinkOpened;

@interface KochavaEventManager:NSObject

+ (KochavaEventManager*)shared;
+ (void)setShared:(KochavaEventManager*)shared;

- (void)setTracker:(KVATracker*)tracker;
- (void)sendEvent:(KVAEvent*)event;
- (int)sendTest:(int)val;

@end

@interface SEGKochavaIntegration:NSObject<SEGIntegration>

@property (atomic, strong) NSDictionary *settings;
@property (atomic, strong) KVATracker *tracker;

- (instancetype)initWithSettings:(NSDictionary*)settings andKochavaTracker:(id)kochava;

@end
