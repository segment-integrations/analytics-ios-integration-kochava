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
    __block __strong KVATracker *mockTracker;
    __block __strong KVAIdentityLink *mockIdentityLink;

    beforeEach(^{
        mockTracker = mock(KVATracker.class);
        
        mockIdentityLink = mock(KVAIdentityLink.class);
        [given(mockTracker.identityLink) willReturn:mockIdentityLink];

        [KochavaEventManager setShared:mock(KochavaEventManager.class)];
    });

    describe(@"Configurations", ^{
        __block __strong id<KVAAdNetworkProtocol> mockAdNetwork;
        __block __strong KVAAdNetworkConversion *mockConversion;
        __block __strong KVAAppTrackingTransparency *mockAtt;

        beforeEach(^{
            mockAdNetwork = mockProtocol(@protocol(KVAAdNetworkProtocol));
            [given(mockTracker.adNetwork) willReturn:mockAdNetwork];
            
            mockConversion = mock(KVAAdNetworkConversion.class);
            [given(mockAdNetwork.conversion) willReturn:mockConversion];

            mockAtt = mock(KVAAppTrackingTransparency.class);
            [given(mockTracker.appTrackingTransparency) willReturn:mockAtt];
        });
        
        it(@"uses the default tracker", ^{
            integration = [[SEGKochavaIntegration alloc] initWithSettings: @{
                SKConfigApiKey: @"TEST_GUID"
            }
                                                        andKochavaTracker: nil];

            expect(integration.tracker).to.equal(KVATracker.shared);
        });

        it(@"uses a custom tracker", ^{
            integration = [[SEGKochavaIntegration alloc] initWithSettings: @{
                SKConfigApiKey: @"TEST_GUID"
            }
                                                        andKochavaTracker: mockTracker];

            expect(integration.tracker).to.equal(mockTracker);
            [verifyCount(mockAtt, never()) setEnabledBool:anything()];
            [[verifyCount(mockAtt, never()) withMatcher:anything()] setAuthorizationStatusWaitTimeInterval:0];
            [verifyCount(mockConversion, never()) setDidUpdateValueBlock:anything()];
            [verifyCount(mockAdNetwork, never()) setDidRegisterAppForAttributionBlock:anything()];
            [verify(mockTracker) startWithAppGUIDString: @"TEST_GUID"];
        });

        it(@"subscribes to notifications", ^{
            integration = [[SEGKochavaIntegration alloc] initWithSettings: @{
                SKConfigApiKey: @"TEST_GUID",
                SKConfigSubscribeToNotifications: @YES
            }
                                                        andKochavaTracker: mockTracker];

            [verify(mockConversion) setDidUpdateValueBlock:notNilValue()];
            [verify(mockAdNetwork) setDidRegisterAppForAttributionBlock:notNilValue()];
            [verify(mockTracker) startWithAppGUIDString: @"TEST_GUID"];
        });

        it(@"does not subscribe to notifications", ^{
            integration = [[SEGKochavaIntegration alloc] initWithSettings: @{
                SKConfigApiKey: @"TEST_GUID"
            }
                                                        andKochavaTracker: mockTracker];

            [verifyCount(mockConversion, never()) setDidUpdateValueBlock:anything()];
            [verifyCount(mockAdNetwork, never()) setDidRegisterAppForAttributionBlock:anything()];
            [verify(mockTracker) startWithAppGUIDString: @"TEST_GUID"];
        });

        it(@"enables application transparency ", ^{
            integration = [[SEGKochavaIntegration alloc] initWithSettings: @{
                SKConfigApiKey: @"TEST_GUID",
                SKConfigEnforceATT: @YES,
                SKConfigCustomPromptLength: @1000.0
            }
                                                        andKochavaTracker: mockTracker];

            [verify(mockAtt) setEnabledBool: YES];
            [verify(mockAtt) setAuthorizationStatusWaitTimeInterval: 1000.0];
            [verify(mockTracker) startWithAppGUIDString: @"TEST_GUID"];
        });
    });
    
    
    describe(@"Tracking", ^{
        beforeEach(^{
            integration = [[SEGKochavaIntegration alloc] initWithSettings:@{SKConfigApiKey:@"TEST_GUID"} andKochavaTracker:mockTracker];
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
        
        it(@"Tracks deep links", ^{
            SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:SKTrackDeepLinkOpened
                                                                   properties:@{
                                                                       @"linkType": @"External",
                                                                       @"url": @"https://www.someothersite.com/redirect"
                                                                   }
                                                                      context:@{}
                                                                 integrations:@{}];
            
            [givenVoid([KochavaEventManager.shared sendEvent:anything()]) willDo:^id(NSInvocation *invocation) {
                KVAEvent *event = [invocation mkt_arguments][0];
                expect(event.eventType.nameString.description).to.equal(KVAEventType.deeplink.nameString.description);
                expect(event.customEventNameString).to.equal(SKTrackDeepLinkOpened);
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
            integration = [[SEGKochavaIntegration alloc] initWithSettings:@{SKConfigApiKey:@"TEST_GUID"} andKochavaTracker:mockTracker];
        });

        it(@"initial identification", ^{
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

            [verify(mockIdentityLink) registerWithNameString:@"User ID" identifierString:@"dd7148953a72573614d38e4bbcb2a9a1"];
            [verify(mockIdentityLink) registerWithNameString:@"Login" identifierString:@"roger2031"];
        });
    });

});

SpecEnd

SpecBegin(SegmentKochavaIntegrationFactory)

describe(@"SegmentKochavaIntegrationFactory", ^{
    __block __strong Class mockIntegrationClass;
    __block __strong SEGAnalytics *mockAnalytics;

    beforeEach(^{
        mockIntegrationClass = mockClass(SEGKochavaIntegration.class);
        mockAnalytics = mock(SEGAnalytics.class);
    });
    
    afterEach(^{
        mockIntegrationClass = nil;
        mockAnalytics = nil;
    });
    
    it(@"creates an integration instance", ^{
        NSDictionary *settings = @{
            SKConfigApiKey: @"TEST_GUID",
            SKConfigEnforceATT: @YES,
            SKConfigCustomPromptLength: @1000.0
        };
        
        SEGKochavaIntegrationFactory *factory = [[SEGKochavaIntegrationFactory alloc] init];
        SEGKochavaIntegration *integration = [factory createWithSettings:settings forAnalytics:mockAnalytics];
        
        expect(integration.tracker).toNot.beNil();
        expect(integration.settings).to.equal(settings);
        
    });
});


SpecEnd
