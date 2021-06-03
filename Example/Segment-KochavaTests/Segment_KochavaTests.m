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
    __block __strong KVATracker *mockCustomTracker;
    __block __strong KVAIdentityLink *mockIdentityLink;
    __block __strong id<KVAAdNetworkProtocol> mockAdNetwork;
    __block __strong KVAAdNetworkConversion *mockConversion;
    __block __strong KVAAppTrackingTransparency *mockAppTrackingTransparency;
    __block __strong Class mockNetworkProductClass;
    __block __strong KVAAdNetworkProduct *mockProduct;
    __block __strong Class mockSharedTrackerClass;
    __block __strong KVATracker *mockSharedTracker;
    __block __strong Class mockEventClass;

    beforeEach(^{
        mockCustomTracker = mock(KVATracker.class);
        
        mockIdentityLink = mock(KVAIdentityLink.class);
        [given(mockCustomTracker.identityLink) willReturn:mockIdentityLink];

        mockAdNetwork = mockProtocol(@protocol(KVAAdNetworkProtocol));
        [given(mockCustomTracker.adNetwork) willReturn:mockAdNetwork];
        
        mockConversion = mock(KVAAdNetworkConversion.class);
        [given(mockAdNetwork.conversion) willReturn:mockConversion];

        mockAppTrackingTransparency = mock(KVAAppTrackingTransparency.class);
        [given(mockCustomTracker.appTrackingTransparency) willReturn:mockAppTrackingTransparency];

        // mock KVAAdNetworkProduct.shared
        mockNetworkProductClass = mockClass(KVAAdNetworkProduct.class);
        mockProduct = mock(KVAAdNetworkProduct.class);
        
        stubSingleton(mockNetworkProductClass, shared);
        [given(KVAAdNetworkProduct.shared) willReturn:mockProduct];

        // mock KVATracker.shared
        mockSharedTrackerClass = mockClass(KVATracker.class);
        mockSharedTracker = mock(KVATracker.class);
        
        stubSingleton(mockSharedTrackerClass, shared);
        [given(KVATracker.shared) willReturn:mockSharedTracker];

        // mock KVAEvent
        mockEventClass = mockClass(KVAEvent.class);
    });
    
    afterEach(^{
        mockNetworkProductClass = nil;
        mockSharedTrackerClass = nil;
        mockEventClass = nil;
    });

    describe(@"Configurations", ^{
        it(@"uses the default tracker", ^{
            integration = [[SEGKochavaIntegration alloc] initWithSettings: @{
                SKConfigApiKey: @"TEST_GUID"
            }
                                                        andKochavaTracker: nil];

            expect(integration.tracker).to.equal(KVATracker.shared);
            expect(integration.tracker).to.equal(mockSharedTracker);
            expect(integration.tracker).toNot.equal(mockCustomTracker);

            [verify(mockProduct) register];
        });

        it(@"uses a custom tracker", ^{
            integration = [[SEGKochavaIntegration alloc] initWithSettings: @{
                SKConfigApiKey: @"TEST_GUID"
            }
                                                        andKochavaTracker: mockCustomTracker];

            expect(integration.tracker).to.equal(mockCustomTracker);
            [verifyCount(mockAppTrackingTransparency, never()) setEnabledBool:anything()];
            [[verifyCount(mockAppTrackingTransparency, never()) withMatcher:anything()] setAuthorizationStatusWaitTimeInterval:0];
            [verifyCount(mockConversion, never()) setDidUpdateValueBlock:anything()];
            [verifyCount(mockAdNetwork, never()) setDidRegisterAppForAttributionBlock:anything()];
            [verify(mockCustomTracker) startWithAppGUIDString: @"TEST_GUID"];
            [verify(mockProduct) register];

            expect(KVATracker.shared).to.equal(mockSharedTracker);
            expect(KVATracker.shared).toNot.equal(mockCustomTracker);
            expect(KVALog.shared).toNot.beNil();
        });

        it(@"subscribes to notifications", ^{
            integration = [[SEGKochavaIntegration alloc] initWithSettings: @{
                SKConfigApiKey: @"TEST_GUID",
                SKConfigSubscribeToNotifications: @YES
            }
                                                        andKochavaTracker: mockCustomTracker];

            [verify(mockConversion) setDidUpdateValueBlock:notNilValue()];
            [verify(mockAdNetwork) setDidRegisterAppForAttributionBlock:notNilValue()];
            [verify(mockCustomTracker) startWithAppGUIDString: @"TEST_GUID"];
        });

        it(@"does not subscribe to notifications", ^{
            integration = [[SEGKochavaIntegration alloc] initWithSettings: @{
                SKConfigApiKey: @"TEST_GUID"
            }
                                                        andKochavaTracker: mockCustomTracker];

            [verifyCount(mockConversion, never()) setDidUpdateValueBlock:anything()];
            [verifyCount(mockAdNetwork, never()) setDidRegisterAppForAttributionBlock:anything()];
            [verify(mockCustomTracker) startWithAppGUIDString: @"TEST_GUID"];
        });

        it(@"enables application transparency ", ^{
            integration = [[SEGKochavaIntegration alloc] initWithSettings: @{
                SKConfigApiKey: @"TEST_GUID",
                SKConfigEnforceATT: @YES,
                SKConfigCustomPromptLength: @1000.0
            }
                                                        andKochavaTracker: mockCustomTracker];

            [verify(mockAppTrackingTransparency) setEnabledBool: YES];
            [verify(mockAppTrackingTransparency) setAuthorizationStatusWaitTimeInterval: 1000.0];
            [verify(mockCustomTracker) startWithAppGUIDString: @"TEST_GUID"];
        });
    });
    
    
    describe(@"Tracking", ^{
        beforeEach(^{
            integration = [[SEGKochavaIntegration alloc] initWithSettings:@{SKConfigApiKey:@"TEST_GUID"} andKochavaTracker:mockCustomTracker];
        });
        
        it(@"tracks a normal event", ^{
            SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Some Test Event"
                                                                   properties:@{
                                                                       @"Event Property 1": @"Property value",
                                                                       @"Event Property 2": @"Some other value",
                                                                       @"Event Type": @"Some type"
                                                                   }
                                                                      context:@{}
                                                                 integrations:@{
                                                                     @"Kochava iOS": @{
                                                                             @"KochavaSpecificProperty": @"Test Value"
                                                                     },
                                                                     @"Some Other Integration": @{
                                                                             @"SOIProp": @"Hello"
                                                                     }
                                                                 }];
            
            stubSingleton(mockEventClass, customEventWithNameString:);
            KVAEvent *mockEvent = mock(KVAEvent.class);
            [given([KVAEvent customEventWithNameString:anything()]) willReturn:mockEvent];

            stubSingleton(mockEventClass, eventWithType:);
            KVAEvent *mockWrongEvent = mock(KVAEvent.class);
            [given([KVAEvent eventWithType:anything()]) willReturn:mockWrongEvent];

            [integration track:payload];

            [verify(mockEvent) setInfoDictionary:@{
                @"Event Property 1": @"Property value",
                @"Event Property 2": @"Some other value",
                @"Event Type": @"Some type",
                @"KochavaSpecificProperty": @"Test Value"
            }];
        });
        
        it(@"Tracks deep links", ^{
            SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:SKTrackDeepLinkOpened
                                                                   properties:@{
                                                                       @"linkType": @"External",
                                                                       @"url": @"https://www.someothersite.com/redirect"
                                                                   }
                                                                      context:@{}
                                                                 integrations:@{}];
            
            stubSingleton(mockEventClass, customEventWithNameString:);
            KVAEvent *mockWrongEvent = mock(KVAEvent.class);
            [given([KVAEvent customEventWithNameString:anything()]) willReturn:mockWrongEvent];

            stubSingleton(mockEventClass, eventWithType:);
            KVAEvent *mockEvent = mock(KVAEvent.class);
            [given([KVAEvent eventWithType:anything()]) willReturn:mockEvent];

            [integration track:payload];

            // [verify(mockEvent) setEventType:KVAEventType.deeplink];
            [verify(mockEvent) setCustomEventNameString: SKTrackDeepLinkOpened];
            [verify(mockEvent) setUriString: @"https://www.xoom.com/documents"];
            [verify(mockEvent) setInfoDictionary: @{
                @"linkType": @"External",
                @"url": @"https://www.someothersite.com/redirect"
            }];
        });
    });
    
    describe(@"Identification", ^{
        beforeEach(^{
            integration = [[SEGKochavaIntegration alloc] initWithSettings:@{SKConfigApiKey:@"TEST_GUID"} andKochavaTracker:mockCustomTracker];
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
                                                                            @"Kochava iOS": @{
                                                                                    @"a1": @"v2021"
                                                                            },
                                                                            @"Another Integration": @{
                                                                                    @"Some Value": @"ABC"
                                                                            }
                                                                        }];

            [integration identify:payload];

            [verify(mockIdentityLink) registerWithNameString:@"User ID" identifierString:@"dd7148953a72573614d38e4bbcb2a9a1"];
            [verify(mockIdentityLink) registerWithNameString:@"Login" identifierString:@"roger2031"];
            [verify(mockIdentityLink) registerWithNameString:@"a1" identifierString:@"v2021"];
            [verifyCount(mockIdentityLink, times(0)) registerWithNameString:@"Some Value" identifierString:@"ABC"];
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
