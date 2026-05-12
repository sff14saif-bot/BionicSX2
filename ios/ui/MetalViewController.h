#pragma once
#import <UIKit/UIKit.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

@interface MetalViewController : UIViewController <MTKViewDelegate>

@property (nonatomic, strong) NSString* isoPath;
@property (nonatomic, strong) MTKView*            metalView;
@property (nonatomic, strong) id<MTLDevice>       device;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;

- (void)startEmulatorLoop;
- (void)stopEmulatorLoop;

@end
