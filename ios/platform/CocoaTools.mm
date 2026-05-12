// BionicSX2 — iOS CocoaTools Implementation
// MUST remain a .mm file — Objective-C++ required
// Phase 2 implementation target
// Reference: PCSX2 macOS CocoaTools — adapted for UIKit

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>

#include <string>

// TODO Phase 2: Return iOS app bundle path
// macOS used: [[NSBundle mainBundle] bundlePath]
// iOS: identical API — no change required
std::string GetBundlePath() {
    NSString* path = [[NSBundle mainBundle] bundlePath];
    return std::string([path UTF8String]);
}

// TODO Phase 2: Return iOS Documents directory
// macOS used: ~/Documents — iOS uses sandbox Documents
std::string GetResourcePath() {
    NSArray* paths = NSSearchPathForDirectoriesInDomains(
        NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documents = [paths firstObject];
    return std::string([documents UTF8String]);
}

// TODO Phase 2: Create CAMetalLayer attached to UIView
// macOS used: NSView — iOS uses UIView
// CAMetalLayer itself is identical on both platforms
CAMetalLayer* CreateMetalLayer(UIView* view) {
    CAMetalLayer* layer = [CAMetalLayer layer];
    layer.device = MTLCreateSystemDefaultDevice();
    layer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    layer.framebufferOnly = YES;
    layer.frame = view.bounds;
    [view.layer addSublayer:layer];
    return layer;
}

// TODO Phase 2: Destroy CAMetalLayer
void DestroyMetalLayer(CAMetalLayer* layer) {
    if (layer) {
        [layer removeFromSuperlayer];
    }
}

// TODO Phase 2: Get display refresh rate
// macOS used: CVDisplayLink — iOS uses UIScreen.maximumFramesPerSecond
float GetViewRefreshRate() {
    if (@available(iOS 15.0, *)) {
        return (float)[UIScreen mainScreen].maximumFramesPerSecond;
    }
    return 60.0f; // Safe fallback for iOS 14.2
}
