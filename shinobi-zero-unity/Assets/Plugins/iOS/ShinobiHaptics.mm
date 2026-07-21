#import <UIKit/UIKit.h>

extern "C" void SZ_HapticImpact(int style)
{
    UIImpactFeedbackStyle impactStyle = style == 0 ? UIImpactFeedbackStyleLight : UIImpactFeedbackStyleMedium;
    UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:impactStyle];
    [generator prepare];
    [generator impactOccurred];
}

extern "C" void SZ_HapticNotification(int type)
{
    UINotificationFeedbackType notification = type == 0
        ? UINotificationFeedbackTypeSuccess
        : UINotificationFeedbackTypeError;
    UINotificationFeedbackGenerator *generator = [[UINotificationFeedbackGenerator alloc] init];
    [generator prepare];
    [generator notificationOccurred:notification];
}
