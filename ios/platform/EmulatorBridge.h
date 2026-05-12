// EmulatorBridge.h — C++ bridge for Objective-C callers
// Hides all PCSX2 C++ from .mm files
// Phase 5: init/shutdown/state/metal layer

#pragma once

#ifdef __OBJC__
#import <Metal/Metal.h>
#endif

#ifdef __cplusplus
extern "C" {
#endif

void BionicSX2_SetMetalLayer(void* layer, void* device);
void BionicSX2_SetCurrentISO(const char* path);

bool EmulatorBridge_Init(void);
void EmulatorBridge_Shutdown(void);
bool EmulatorBridge_BootGame(const char* isoPath);
void EmulatorBridge_RunFrame(void);
bool EmulatorBridge_IsRunning(void);

#ifdef __cplusplus
}
#endif