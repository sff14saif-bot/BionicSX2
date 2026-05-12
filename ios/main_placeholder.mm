// BionicSX2 — iOS entry point placeholder
// Phase 1: exists only to satisfy linker for build validation
// TODO Phase 7: replace with full UIKit / SwiftUI app delegate
#import <UIKit/UIKit.h>

@interface BionicSX2AppDelegate : UIResponder <UIApplicationDelegate>
@property (nonatomic, strong) UIWindow *window;
@end

@implementation BionicSX2AppDelegate
- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.backgroundColor = UIColor.blackColor;
    [self.window makeKeyAndVisible];
    return YES;
}
@end

int main(int argc, char *argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil,
            NSStringFromClass([BionicSX2AppDelegate class]));
    }
}
