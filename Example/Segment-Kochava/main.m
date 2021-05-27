//
//  main.m
//  Segment-Kochava
//
//  Created by Ian Mak on 5/4/21.
//  Copyright © 2021 Segment. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SEGAppDelegate.h"

int main(int argc, char * argv[]) {
    NSString * appDelegateClassName;
    @autoreleasepool {
        // Setup code that might create autoreleased objects goes here.
        appDelegateClassName = NSStringFromClass([SEGAppDelegate class]);
    }
    return UIApplicationMain(argc, argv, nil, appDelegateClassName);
}
