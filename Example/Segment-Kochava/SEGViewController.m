//
//  ViewController.m
//  Segment-Kochava
//
//  Created by Ian Mak on 5/4/21.
//  Copyright © 2021 Segment. All rights reserved.
//

#import "SEGViewController.h"
#import <SEGKochavaIntegrationFactory.h>
#import <Analytics/SEGAnalytics.h>
#import <KochavaCoreiOS/KochavaCore.h>
#import <KochavaTrackeriOS/KochavaTracker.h>
#import <KochavaAdNetworkiOS/KochavaAdNetwork.h>

@interface SEGViewController ()

@end

@implementation SEGViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    SEGAnalyticsConfiguration *configuration = [SEGAnalyticsConfiguration configurationWithWriteKey:@"[SEGMENT WRITE KEY]"];
    configuration.trackApplicationLifecycleEvents = YES;
    configuration.flushAt = 1;
    [configuration use:[SEGKochavaIntegrationFactory instance]];
    [SEGAnalytics setupWithConfiguration:configuration];
    
    [[SEGAnalytics sharedAnalytics] identify:@"sally1114"]; // App user's login ID
    [[SEGAnalytics sharedAnalytics] track:@"Kochava Example App Launched."];
    
    [[SEGAnalytics sharedAnalytics]
     track:@"Started Application"
     properties:@{
         @"location": @"Home View"
     }
     options:@{
         @"integrations": @{
                 @"Kochava iOS": @{
                         @"a1": @"prop-v2021"
                 }
         }
     }];

    [[SEGAnalytics sharedAnalytics]
     track:@"Browsing Catalog"
     properties:@{
         @"sessionId": @"SomeSessionId111",
         @"location": @"Catalog View",
         @"section": @"Summer Wear",
         @"page": @"1",
         @"totalPages": @"12"
     }
     options:@{
         @"integrations": @{
                 @"Kochava iOS": @{
                         @"a1": @"prop-v2021"
                 }
         }
     }];

    [[SEGAnalytics sharedAnalytics]
     track:@"Add To Cart"
     properties:@{
         @"sessionId": @"SomeSessionId111",
         @"itemDescription": @"Tennis Shoes",
         @"quantity": @1,
         @"price": @"29.99"
     }
     options:@{
         @"integrations": @{
                 @"Kochava iOS": @{
                         @"a1": @"prop-v2021"
                 }
         }
     }];

    [[SEGAnalytics sharedAnalytics]
     track:@"Viewed Ad"
     properties:@{
         @"sessionId": @"SomeSessionId111",
         @"advertiserId": @"1234"
     }
     options:@{
         @"integrations": @{
                 @"Kochava iOS": @{
                         @"a1": @"prop-v2021"
                 }
         }
     }];

    [[SEGAnalytics sharedAnalytics]
     track:@"Checkout"
     properties:@{
         @"sessionId": @"SomeSessionId111",
         @"cartID": @"SomeCartID-CXksZoswaWSdfD10Pde2Qd",
         @"totalAmount": @"515.29",
         @"paymentMethod": @"Visa",
         @"transactionToken": @"SomeTransactionToken-OdKSwwAQfcXSjdDEidDEGss83eEf22Dz"
     }
     options:@{
         @"integrations": @{
                 @"Kochava iOS": @{
                         @"a1": @"prop-v2021"
                 }
         }
     }];

    [[SEGAnalytics sharedAnalytics] flush];
}


@end
