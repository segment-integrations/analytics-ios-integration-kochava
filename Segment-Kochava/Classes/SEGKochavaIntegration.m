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

NSString *const SKConfigEnforceATT = @"enforceAtt";
NSString *const SKConfigCustomPromptLength = @"customPromptLength";
NSString *const SKConfigApiKey = @"apiKey";
NSString *const SKConfigSubscribeToNotifications = @"subscribeToNotifications";
NSString *const SKIdentifyUserId = @"User ID";
NSString *const SKTrackDeepLinkOpened = @"Deep Link Opened";
NSString *const SKKochavaIntegrationName = @"Kochava iOS";

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

- (void)sendEvent:(KVAEvent*)event {
    [event sendWithSenderArray:@[self.tracker]];
}

@end


@implementation SEGKochavaIntegration

- (instancetype)initWithSettings:(NSDictionary*)settings andKochavaTracker:(id)tracker {
    if (self = [super init]) {
        self.settings = settings;
        
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
        if ([settings[SKConfigSubscribeToNotifications] boolValue]) {
            KVAAdNetworkConversionDidUpdateValueBlock conversionDidUpdateValueBlock = ^(KVAAdNetworkConversion *_Nonnull conversion, KVAAdNetworkConversionResult *_Nonnull result) {
                NSLog(@"SKAd Notification: updateConversionValue() called with a value of %@", @(result.valueInt));
            };
            self.tracker.adNetwork.conversion.didUpdateValueBlock = conversionDidUpdateValueBlock;
            
            KVAAdNetworkDidRegisterAppForAttributionBlock didRegisterAppForAttributionBlock = ^(KVAAdNetwork *_Nonnull adNetwork) {
                NSLog(@"SKAd Notification: registerAppForAdNetworkAttribution() called");
            };
            self.tracker.adNetwork.didRegisterAppForAttributionBlock = didRegisterAppForAttributionBlock;
        }
        
        // App tracking transparency
        if (settings[SKConfigEnforceATT] != nil) {
            self.tracker.appTrackingTransparency.enabledBool = [settings[SKConfigEnforceATT] boolValue];
        }
        if (settings[SKConfigCustomPromptLength] != nil) {
            self.tracker.appTrackingTransparency.authorizationStatusWaitTimeInterval = [settings[SKConfigCustomPromptLength] doubleValue];
        }
        
        // if the API key isn't given, can't start the tracker.
        if (settings[SKConfigApiKey] != nil) {
            [self.tracker startWithAppGUIDString:settings[SKConfigApiKey]];
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
    
    NSDictionary *integration = payload.integrations[SKKochavaIntegrationName];
    if (integration) {
        for (NSString *key in integration.allKeys) {
            [self.tracker.identityLink registerWithNameString:key identifierString:[integration[key] stringValue]];
        }
    }
}

-(void)track:(SEGTrackPayload*)payload {
    NSMutableDictionary *props = [[NSMutableDictionary alloc] initWithDictionary:payload.properties];
    if (payload.integrations[SKKochavaIntegrationName]) {
        [props addEntriesFromDictionary:payload.integrations[SKKochavaIntegrationName]];
    }
    
    KVAEvent *event = nil;
    if ([payload.event isEqualToString: SKTrackDeepLinkOpened]) {
        event = [KVAEvent eventWithType:KVAEventType.deeplink];
        event.customEventNameString = SKTrackDeepLinkOpened;
        event.uriString = @"https://www.xoom.com/documents";
        event.infoDictionary = props;
    }
    else {
        event = [KVAEvent customEventWithNameString:payload.event];
        event.infoDictionary = props;
    }
    
    [KochavaEventManager.shared sendEvent:event];
}

@end
