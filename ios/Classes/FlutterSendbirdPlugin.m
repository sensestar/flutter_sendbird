#import "FlutterSendbirdPlugin.h"
#if __has_include(<flutter_sendbird/flutter_sendbird-Swift.h>)
#import <flutter_sendbird/flutter_sendbird-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_sendbird-Swift.h"
#import "SendBirdUtils-swift.h"
#endif

@implementation FlutterSendbirdPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterSendbirdPlugin registerWithRegistrar:registrar];
}

+ (void)saveFCMToken: (NSData*) data{
   [SwiftFlutterSendbirdPlugin saveDeviceTokenWith: data];
    //[[SendBirdUtils sharedInstance ]saveDeviceToken: data ]
  
}
@end
