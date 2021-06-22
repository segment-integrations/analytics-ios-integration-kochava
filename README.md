# Segment Kochava Integration

## Prerequisites

While the Kochava integration communicates directly with Kochava servers from within the iOS application, you must configure a Kochava iOS destination in your Segment workspace. You can set a number of Kochava integration options when configuring the Kochava iOS destination.

This destination is currently in Private Beta and can only be accessed via a unique link. Please reach out to our team if you need access.

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Installation

To install the Segment-Kochava integration, simply add this line to your [CocoaPods](http://cocoapods.org) `Podfile`:

```ruby
pod "Segment-Kochava"
```

## Usage

After adding the dependency, you must register the integration with our SDK.  To do this, import the Kochava integration in your `AppDelegate`:

```
#import <Segment-Kochava/SEGKochavaIntegrationFactory.h>
```

And add the following lines:

```
NSString *const SEGMENT_WRITE_KEY = @" ... ";
SEGAnalyticsConfiguration *config = [SEGAnalyticsConfiguration configurationWithWriteKey:SEGMENT_WRITE_KEY];

[config use:[SEGKochavaIntegrationFactory instance]];

[SEGAnalytics setupWithConfiguration:config];

```

## License

Segment-Kochava is available under the MIT license. See the LICENSE file for more info.
