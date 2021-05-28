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

NSString *const SK_Config_EnforceATT = @"enforceAtt";
NSString *const SK_Config_CustomPromptLength = @"customPromptLength";
NSString *const SK_Config_ApiKey = @"apiKey";
NSString *const SK_Config_SubscribeToNotifications = @"subscribeToNotifications";
NSString *const SK_Identify_UserId = @"User ID";
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

        // SKAd notification subscription
        if ([settings[SK_Config_SubscribeToNotifications] isEqual:@YES]) {
            KVAAdNetworkConversionDidUpdateValueBlock conversionDidUpdateValueBlock = ^(KVAAdNetworkConversion *_Nonnull conversion, KVAAdNetworkConversionResult *_Nonnull result) {
                NSLog(@"updateConversionValue() called with a value of %@", @(result.valueInt));
            };
            self.tracker.adNetwork.conversion.didUpdateValueBlock = conversionDidUpdateValueBlock;
            
            KVAAdNetworkDidRegisterAppForAttributionBlock didRegisterAppForAttributionBlock = ^(KVAAdNetwork *_Nonnull adNetwork) {
                NSLog(@"registerAppForAdNetworkAttribution() called");
            };
            self.tracker.adNetwork.didRegisterAppForAttributionBlock = didRegisterAppForAttributionBlock;
        }
        
        // App tracking transparency
        if (settings[SK_Config_EnforceATT] != nil) {
            self.tracker.appTrackingTransparency.enabledBool = settings[SK_Config_EnforceATT];
        }
        if (settings[SK_Config_CustomPromptLength] != nil) {
            self.tracker.appTrackingTransparency.authorizationStatusWaitTimeInterval = [settings[SK_Config_CustomPromptLength] doubleValue];
        }
        
        // if the API key isn't given, can't start the tracker.
        if (settings[SK_Config_ApiKey] != nil) {
            [self.tracker startWithAppGUIDString:settings[SK_Config_ApiKey]];
        }
        else {
            NSLog(@"Unable to start Kochava iOS tracker, API key not provided.");
        }
    }
    return self;
}

-(void)identify:(SEGIdentifyPayload *)payload {
    [self.tracker.identityLink registerWithNameString:@"User ID" identifierString:payload.anonymousId];
    [self.tracker.identityLink registerWithNameString:@"Login" identifierString:payload.userId];
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
