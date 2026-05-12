// BionicSX2 — iOS Entry Point
#import <UIKit/UIKit.h>
#import "ui/AppDelegate.h"
#include "BionicLogger.hpp"

static void BionicObjCExceptionHandler(NSException* exc) {
    BionicLogger::instance().log("FATAL", "UI   ",
        [[NSString stringWithFormat:@"ObjC exception: %@\n  Reason: %@",
            exc.name, exc.reason] UTF8String]);
    BionicLogger::instance().flush();
}

int main(int argc, char* argv[]) {
    @autoreleasepool {
        NSSetUncaughtExceptionHandler(&BionicObjCExceptionHandler);

        return UIApplicationMain(
            argc, argv,
            nil,
            NSStringFromClass([BionicSX2AppDelegate class])
        );
    }
}
