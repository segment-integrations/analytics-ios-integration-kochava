//
//  Segment_KochavaTests.m
//  Segment-KochavaTests
//
//  Created by Ian Mak on 5/4/21.
//  Copyright © 2021 Segment. All rights reserved.
//

#import <Segment-Kochava/SEGKochavaIntegrationFactory.h>
#import <Segment-Kochava/SEGKochavaIntegration.h>
#import <KochavaTrackeriOS/KochavaTracker.h>
#import <KochavaCoreiOS/KochavaCore.h>
#import <KochavaAdNetworkiOS/KochavaAdNetwork.h>


SpecBegin(SegmentKochavaIntegration)

describe(@"SegmentKochavaIntegration", ^{
    __block __strong SEGKochavaIntegration *integration;
    __block __strong KVATracker *tracker;
    __block __strong KVAIdentityLink *identityLink;

    beforeEach(^{
        tracker = mock(KVATracker.class);
        
        identityLink = mock(KVAIdentityLink.class);
        [given(tracker.identityLink) willReturn:identityLink];
        
        [KochavaEventManager setShared:mock(KochavaEventManager.class)];
    });

    describe(@"Configurations", ^{
        __block __strong id<KVAAdNetworkProtocol> adNetwork;
        __block __strong KVAAdNetworkConversion *conversion;
        __block __strong KVAAppTrackingTransparency *att;

        beforeEach(^{
            adNetwork = mockProtocol(@protocol(KVAAdNetworkProtocol));
            [given(tracker.adNetwork) willReturn:adNetwork];
            
            conversion = mock(KVAAdNetworkConversion.class);
            [given(adNetwork.conversion) willReturn:conversion];

            att = mock(KVAAppTrackingTransparency.class);
            [given(tracker.appTrackingTransparency) willReturn:att];
        });
        
        it(@"uses the default tracker", ^{
            integration = [[SEGKochavaIntegration alloc] initWithSettings: @{
                SK_Config_ApiKey: @"TEST_GUID"
            }
                                                        andKochavaTracker: nil];

            expect(integration.tracker).to.equal(KVATracker.shared);
        });

        it(@"uses a custom tracker", ^{
            integration = [[SEGKochavaIntegration alloc] initWithSettings: @{
                SK_Config_ApiKey: @"TEST_GUID"
            }
                                                        andKochavaTracker: tracker];

            expect(integration.tracker).to.equal(tracker);
            [verifyCount(att, never()) setEnabledBool:anything()];
            [[verifyCount(att, never()) withMatcher:anything()] setAuthorizationStatusWaitTimeInterval:0];
            [verifyCount(conversion, never()) setDidUpdateValueBlock:anything()];
            [verifyCount(adNetwork, never()) setDidRegisterAppForAttributionBlock:anything()];
            [verify(tracker) startWithAppGUIDString: @"TEST_GUID"];
        });

        it(@"subscribes to notifications", ^{
            integration = [[SEGKochavaIntegration alloc] initWithSettings: @{
                SK_Config_ApiKey: @"TEST_GUID",
                SK_Config_SubscribeToNotifications: @YES
            }
                                                        andKochavaTracker: tracker];

            [verify(conversion) setDidUpdateValueBlock:notNilValue()];
            [verify(adNetwork) setDidRegisterAppForAttributionBlock:notNilValue()];
            [verify(tracker) startWithAppGUIDString: @"TEST_GUID"];
        });

        it(@"does not subscribe to notifications", ^{
            integration = [[SEGKochavaIntegration alloc] initWithSettings: @{
                SK_Config_ApiKey: @"TEST_GUID"
            }
                                                        andKochavaTracker: tracker];

            [verifyCount(conversion, never()) setDidUpdateValueBlock:anything()];
            [verifyCount(adNetwork, never()) setDidRegisterAppForAttributionBlock:anything()];
            [verify(tracker) startWithAppGUIDString: @"TEST_GUID"];
        });

        it(@"enables application transparency ", ^{
            integration = [[SEGKochavaIntegration alloc] initWithSettings: @{
                SK_Config_ApiKey: @"TEST_GUID",
                SK_Config_EnforceATT: @YES,
                SK_Config_CustomPromptLength: @1000.0
            }
                                                        andKochavaTracker: tracker];

            [verify(att) setEnabledBool: YES];
            [verify(att) setAuthorizationStatusWaitTimeInterval: 1000.0];
            [verify(tracker) startWithAppGUIDString: @"TEST_GUID"];
        });
    });
    
    
    describe(@"Tracking", ^{
        beforeEach(^{
            integration = [[SEGKochavaIntegration alloc] initWithSettings:@{SK_Config_ApiKey:@"TEST_GUID"} andKochavaTracker:tracker];
        });

        it(@"tracks a normal event", ^{
            SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Some Test Event"
                                                                   properties:@{
                                                                       @"Event Property 1": @"Property value",
                                                                       @"Event Property 2": @"Some other value",
                                                                       @"Event Type": @"Some type"
                                                                   }
                                                                      context:@{}
                                                                 integrations:@{}];
            
            [givenVoid([KochavaEventManager.shared sendEvent:anything()]) willDo:^id(NSInvocation *invocation) {
                KVAEvent *event = [invocation mkt_arguments][0];
                expect(event.customEventNameString).to.equal(@"Some Test Event");
                expect(event.infoDictionary).to.equal(@{
                    @"Event Property 1": @"Property value",
                    @"Event Property 2": @"Some other value",
                    @"Event Type": @"Some type"
                });
                return nil;
            }];

            [integration track:payload];
        });
        
        it(@"tracks a deep link", ^{
            SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:SK_Track_DeepLinkOpened
                                                                   properties:@{
                                                                       @"linkType": @"External",
                                                                       @"url": @"https://www.someothersite.com/redirect"
                                                                   }
                                                                      context:@{}
                                                                 integrations:@{}];
            
            [givenVoid([KochavaEventManager.shared sendEvent:anything()]) willDo:^id(NSInvocation *invocation) {
                KVAEvent *event = [invocation mkt_arguments][0];
                expect(event.eventType.nameString.description).to.equal(KVAEventType.deeplink.nameString.description);
                expect(event.customEventNameString).to.equal(SK_Track_DeepLinkOpened);
                expect(event.uriString.description).to.equal(@"https://www.xoom.com/documents");
                expect(event.infoDictionary).to.equal(@{
                    @"linkType": @"External",
                    @"url": @"https://www.someothersite.com/redirect"
                });
                return nil;
            }];

            [integration track:payload];
        });
    });
    
    describe(@"Identification", ^{
        beforeEach(^{
            integration = [[SEGKochavaIntegration alloc] initWithSettings:@{SK_Config_ApiKey:@"TEST_GUID"} andKochavaTracker:tracker];
        });

        it(@"Initial identification", ^{
            SEGIdentifyPayload *payload = [[SEGIdentifyPayload alloc] initWithUserId:@"roger2031"
                                                                         anonymousId:@"dd7148953a72573614d38e4bbcb2a9a1"
                                                                              traits:@{
                                                                                  @"prop1": @"abc",
                                                                                  @"prop2": @"123"
                                                                              }
                                                                             context:@{
                                                                                 @"step": @"Creating New User"
                                                                             }
                                                                        integrations:@{
                                                                            @"Kochava": @{
                                                                                    @"a1": @"v2021"
                                                                            }
                                                                        }];

            [integration identify:payload];

            [verify(identityLink) registerWithNameString:@"User ID" identifierString:@"dd7148953a72573614d38e4bbcb2a9a1"];
            [verify(identityLink) registerWithNameString:@"Login" identifierString:@"roger2031"];
        });
    });

});

SpecEnd

