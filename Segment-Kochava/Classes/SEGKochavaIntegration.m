//
// SEGKochavaIntegration.m
// Pods
//

#import "SEGKochavaIntegration.h"
#import <KochavaCore.h>
#import <KochavaTracker.h>
#import <KochavaAdNetwork.h>

#if defined(__has_include) && __has_include(<Analytics/SEGAnalytics.h>)
#import <Analytics/SEGAnalyticsUtils.h>
#else
#import <Segment/SEGAnalyticsUtils.h>
#endif

NSString *const SK_EnforceATT = @"enforceAtt";
NSString *const SK_CustomPromptLength = @"customPromptLength";
NSString *const SK_ApiKey = @"apiKey";
NSString *const SK_SubscribeToNotifications = @"subscribeToNotifications";
NSString *const SK_UserId = @"User ID";
NSString *const SK_Track_DeepLinkOpened = @"Deep Link Opened";

@interface KochavaEventManager()

@property (atomic, strong) KVATracker *tracker;

@end


@implementation KochavaEventManager

static	 KochavaEventManager *sharedInstance = nil;

+ (KochavaEventManager*)shared {
    @synchronized(self) {
        if (sharedInstance == nil) {
            sharedInstance = [[KochavaEventManager alloc] init];
        }
        return sharedInstance;
    }
}

+ (void)setShared:(KochavaEventManager *)shared {
    @synchronized(self) {
        sharedInstance = shared;
        
    }
}

- (void)sendEvent:(KVAEvent*)event {
    [event sendWithSenderArray:@[self.tracker]];
}

- (int)sendTest:(int)val {
    return val * 2;
}

@end


@implementation SEGKochavaIntegration

- (instancetype)initWithSettings:(NSDictionary*)settings andKochavaTracker:(id)tracker {
    if (self = [super init]) {
        // support for SKAdNetwork
        [KVAAdNetworkProduct.shared register];

        if (tracker != nil) {
            self.tracker = tracker;
        }
        else {
            self.tracker = KVATracker.shared;
        }
        
        KochavaEventManager.shared.tracker = self.tracker;
        
        // tracking setup
        if (settings[SK_EnforceATT]) {
            self.tracker.appTrackingTransparency.enabledBool = settings[SK_EnforceATT];
        }
        
        if (settings[SK_CustomPromptLength] && ([settings[SK_CustomPromptLength] isKindOfClass:NSNumber.class])) {
            NSNumber *customPromptLength = settings[SK_CustomPromptLength];
            self.tracker.appTrackingTransparency.authorizationStatusWaitTimeInterval = customPromptLength.doubleValue;
        }
        
        [self.tracker startWithAppGUIDString:settings[SK_ApiKey]];
    }
    return self;
}

-(void)identify:(SEGIdentifyPayload *)payload {
    [self.tracker.identityLink registerWithNameString:@"User ID" identifierString:payload.userId];
}

-(void)track:(SEGTrackPayload*)payload {
    KVAEvent *event = nil;
    if ([payload.event isEqualToString: SK_Track_DeepLinkOpened]) {
        event = [KVAEvent eventWithType:KVAEventType.deeplink];
        event.customEventNameString = SK_Track_DeepLinkOpened;
        event.uriString = @"https://www.xoom.com/documents";
        event.infoDictionary = payload.properties;
    }
    else {
        event = [KVAEvent customEventWithNameString:payload.event];
        event.infoDictionary = payload.properties;
    }
    
    [KochavaEventManager.shared sendEvent:event];
}

@end
