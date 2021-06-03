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


@implementation SEGKochavaIntegration

/**
 Constructor method
 @param settings NSDictionary integration settings provided by the segment server. Usually this is provided to this integration if the account owner has setup a "Kochava iOS" destination.
 @param tracker KVATracker object to be used in this integration, if an alternative tracker is desired instead of the default shared tracker.
 */
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
        
        // SKAd notification subscription
        if ([settings[SKConfigSubscribeToNotifications] boolValue]) {
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

/**
 Sends identifier properties to Kochava
 @param payload SEGIdentifyPayload identity payload to process and send to Kochava
 */
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

/**
 Sends the event to the current Kochava tracker
 @param event KVAEvent event to send to tracker
 */
- (void)sendEvent:(KVAEvent*)event {
    [event sendWithSenderArray:@[self.tracker]];
}

/**
 Sends the tracking payload to Kochava
 @param payload SEGTrackPayload payload to process and send to Kochava
 */
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
    
    [self sendEvent:event];
}

@end
