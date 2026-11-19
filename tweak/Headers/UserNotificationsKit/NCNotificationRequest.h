@class NCNotificationContent, NCNotificationOptions, NCNotificationAction;

// Private runtime class: compile without requiring a link-time framework binary.
// Weak import does NOT guarantee the class exists on the device.
__attribute__((weak_import))
@interface NCNotificationRequest : NSObject
@property (nonatomic, retain) NCNotificationContent *content;
@property (nonatomic, retain) NCNotificationOptions *options;
@property (nonatomic, readonly) NCNotificationAction *defaultAction;
@property (nonatomic, retain) NSDate *timestamp;
@end
