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
#import <KochavaCore.h>


SpecBegin(SegmentKochavaIntegration)

describe(@"SegmentKochavaIntegration", ^{
    __block __strong SEGKochavaIntegration *integration;
    __block __strong KVATracker *tracker;
    __block __strong KVAIdentityLink *identityLink;
    
    beforeEach(^{
        tracker = mock(KVATracker.class);
        identityLink = mock(KVAIdentityLink.class);
        [given(tracker.identityLink) willReturn:identityLink];
        
        integration = [[SEGKochavaIntegration alloc] initWithSettings:@{SKConfigApiKey:@"TEST_GUID"} andKochavaTracker:tracker];
        
        [KochavaEventManager setShared:mock(KochavaEventManager.class)];
    });
    
    describe(@"General Tracking", ^{
        it(@"Tracks normal events", ^{
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
            
            [givenVoid([identityLink registerWithNameString:anything() identifierString:anything()]) willDo:^id(NSInvocation *invocation) {
                NSString *name = [invocation mkt_arguments][0];
                NSString *identifier = [invocation mkt_arguments][1];
                expect(name).to.equal(@"User ID");
                expect(identifier).to.equal(@"roger2031");
                return nil;
            }];

            // [tracker.identityLink registerWithNameString:@"test" identifierString:@"test"];
            
            [integration identify:payload];
        });
    });

});

SpecEnd

SpecBegin(SegmentKochavaIntegrationFactory)

SpecEnd
