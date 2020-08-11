#import <Flutter/Flutter.h>

@interface FlutterSendbirdPlugin : NSObject<FlutterPlugin>

+ (void)saveFCMToken: (NSData*) data;
@end
