#import "MetalViewController.h"
#import <UIKit/UIKit.h>
#include "platform/EmulatorBridge.h"

@interface MetalViewController ()
@property (nonatomic, assign) BOOL               emulatorRunning;
@end

@implementation MetalViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.device = MTLCreateSystemDefaultDevice();
    NSAssert(self.device, @"Metal not available on this device");

    self.commandQueue = [self.device newCommandQueue];

    self.metalView = [[MTKView alloc] initWithFrame:self.view.bounds
                                             device:self.device];
    self.metalView.delegate             = self;
    self.metalView.preferredFramesPerSecond = 60;
    self.metalView.clearColor           = MTLClearColorMake(0, 0, 0, 1);
    self.metalView.colorPixelFormat     = MTLPixelFormatBGRA8Unorm;
    self.metalView.autoresizingMask     =
        UIViewAutoresizingFlexibleWidth |
        UIViewAutoresizingFlexibleHeight;

    [self.view insertSubview:self.metalView atIndex:0];

    // Register the Metal layer for the GS device
    CAMetalLayer* layer = (CAMetalLayer*)self.metalView.layer;
    BionicSX2_SetMetalLayer(layer, self.device);

    [self initializeEmulator];
}

- (void)initializeEmulator {
    if (!EmulatorBridge_Init()) return;

    NSString* docs = NSSearchPathForDirectoriesInDomains(
        NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString* biosDir = [docs stringByAppendingPathComponent:@"bios"];
    NSArray* files = [[NSFileManager defaultManager]
        contentsOfDirectoryAtPath:biosDir error:nil];
    NSString* bios = nil;
    for (NSString* f in files) {
        if ([f.pathExtension.lowercaseString isEqualToString:@"bin"]) {
            bios = [biosDir stringByAppendingPathComponent:f];
            break;
        }
    }

    if (!bios) {
        NSLog(@"[BionicSX2] No BIOS — add via Game Library");
        return;
    }

    const char* isoC = self.isoPath ? self.isoPath.UTF8String : nullptr;

    if (EmulatorBridge_BootGame(isoC)) {
        self.emulatorRunning = YES;
        NSLog(@"[BionicSX2] Booting: %@",
            self.isoPath ? self.isoPath.lastPathComponent : @"BIOS shell");
    }
}

- (void)startEmulatorLoop {
    NSLog(@"[BionicSX2] Emulator loop started");
}

- (void)stopEmulatorLoop {
    NSLog(@"[BionicSX2] Stopping emulator");
    self.emulatorRunning = NO;
    EmulatorBridge_Shutdown();
}

- (void)drawInMTKView:(MTKView*)view {
    // Minimal Metal frame: acquire drawable, clear to black, present.
    // MTKView requires the delegate to complete the render cycle — a stub
    // crashes CoreAnimation with an exception during CA::Transaction::commit.
    @autoreleasepool {
        id<MTLCommandBuffer> cmdBuf = [self.commandQueue commandBuffer];
        MTLRenderPassDescriptor* desc = view.currentRenderPassDescriptor;
        if (desc) {
            id<MTLRenderCommandEncoder> enc =
                [cmdBuf renderCommandEncoderWithDescriptor:desc];
            [enc endEncoding];

            [cmdBuf presentDrawable:view.currentDrawable];
            [cmdBuf commit];
        }
    }

    // When PCSX2 GS is active, this will be replaced with EmulatorBridge_RunFrame()
}

- (void)mtkView:(MTKView*)view drawableSizeDidChange:(CGSize)size {
    NSLog(@"[BionicSX2] drawableSizeDidChange: %@", NSStringFromCGSize(size));
}

- (void)touchesBegan:(NSSet<UITouch*>*)touches withEvent:(UIEvent*)event {
    for (UITouch* t in touches) {
        CGPoint pt = [t locationInView:self.view];
        [self handleTouch:pt pressed:YES];
    }
}

- (void)touchesEnded:(NSSet<UITouch*>*)touches withEvent:(UIEvent*)event {
    for (UITouch* t in touches) {
        CGPoint pt = [t locationInView:self.view];
        [self handleTouch:pt pressed:NO];
    }
}

- (void)touchesCancelled:(NSSet<UITouch*>*)touches withEvent:(UIEvent*)event {
    [self touchesEnded:touches withEvent:event];
}

- (void)handleTouch:(CGPoint)pt pressed:(BOOL)pressed {
    NSLog(@"[BionicSX2] Touch %@ at %@", pressed ? @"down" : @"up", NSStringFromCGPoint(pt));
}

@end