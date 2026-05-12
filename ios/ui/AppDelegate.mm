#import "AppDelegate.h"
#import "GameLibraryViewController.h"
#import "MetalViewController.h"
#include "BionicLogger.hpp"
#include "CrashHandler.hpp"

@interface BionicSX2AppDelegate () <GameLibraryDelegate>
@property (nonatomic, strong) MetalViewController* emulatorVC;
@end

@implementation BionicSX2AppDelegate

- (BOOL)application:(UIApplication*)app
    didFinishLaunchingWithOptions:(NSDictionary*)opts {

    BionicLog_Init();
    CrashHandler_Install();
    BIONIC_INFO(CORE, "BionicSX2 started — logging active");
    BIONIC_INFO(CORE, "Log file: %s", BionicLog_GetPath());

    [self createFolderStructure];

    self.window = [[UIWindow alloc]
        initWithFrame:UIScreen.mainScreen.bounds];

    GameLibraryViewController* lib = [[GameLibraryViewController alloc] init];
    lib.delegate = self;

    UINavigationController* nav = [[UINavigationController alloc]
        initWithRootViewController:lib];
    nav.navigationBar.barTintColor = UIColor.blackColor;
    nav.navigationBar.titleTextAttributes =
        @{NSForegroundColorAttributeName: UIColor.whiteColor};

    self.window.rootViewController = nav;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)createFolderStructure {
    NSString* docs = NSSearchPathForDirectoriesInDomains(
        NSDocumentDirectory, NSUserDomainMask, YES).firstObject;

    NSFileManager* fm = [NSFileManager defaultManager];
    NSArray* folders = @[
        @"bios",
        @"games",
        @"memcards",
        @"sstates",
        @"cheats",
    ];

    for (NSString* folder in folders) {
        NSString* path = [docs stringByAppendingPathComponent:folder];
        [fm createDirectoryAtPath:path
            withIntermediateDirectories:YES
                           attributes:nil error:nil];
    }

    NSLog(@"[BionicSX2] Folder structure ready at: %@", docs);
}

- (void)gameLibraryDidSelectISO:(NSString*)isoPath {
    self.emulatorVC = [[MetalViewController alloc] init];
    self.emulatorVC.isoPath = isoPath;
    self.emulatorVC.modalPresentationStyle = UIModalPresentationFullScreen;
    [self.window.rootViewController
        presentViewController:self.emulatorVC
                     animated:YES completion:nil];
}

- (void)gameLibraryDidSelectBIOS:(NSString*)biosPath {
    UIAlertController* a = [UIAlertController
        alertControllerWithTitle:@"BIOS Detected ✓"
                         message:biosPath.lastPathComponent
                  preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction
        actionWithTitle:@"OK"
                  style:UIAlertActionStyleDefault
                handler:nil]];
    [self.window.rootViewController
        presentViewController:a animated:YES completion:nil];
}

@end