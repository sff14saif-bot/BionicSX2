// iOSVMManager.mm — Minimal PS2 boot for iOS
// Phase 8: Stub mode — builds, real init deferred

#import <Foundation/Foundation.h>
#include "common/Console.h"
#include "common/Error.h"
#include "Memory.h"
#include "R5900.h"
#include "Config.h"
#include "BionicLogger.hpp"
#include "GS/GS.h"
#include "SPU2/spu2.h"
#include "DEV9/DEV9.h"
#include "USB/USB.h"

extern "C" {

static bool s_iOSVM_initialized = false;

bool iOSVM_Initialize(const char* isoPath) {
    if (s_iOSVM_initialized) return true;

    Console.WriteLn("[BionicSX2] iOSVM_Initialize start");
    BionicLogger::instance().flush();

    // Phase 8: Stub - just allocate memory
    Console.WriteLn("[BionicSX2] Allocating memory...");
    BionicLogger::instance().flush();
    if (!SysMemory::Allocate()) {
        Console.WriteLn("[BionicSX2] SysMemory::Allocate failed");
        BionicLogger::instance().flush();
        return false;
    }
    BionicLogger::instance().flush();

    // CPU reset (minimal interpreter-only)
    Console.WriteLn("[BionicSX2] Resetting CPU...");
    BionicLogger::instance().flush();
    cpuReset();

    // Initialize subsystems so VMManager sees init as complete
    USBinit();
    DEV9init();
    SPU2::Open();
    GSopen(EmuConfig.GS, EmuConfig.GS.Renderer, SysMemory::GetEEMem(), GSVSyncMode::Disabled, true);
    Console.WriteLn("[BionicSX2] Subsystems initialized (stub)");
    BionicLogger::instance().flush();

    s_iOSVM_initialized = true;
    Console.WriteLn("[BionicSX2] iOSVM_Initialize complete (STUB)");
    BionicLogger::instance().flush();
    return true;
}

void iOSVM_RunFrame(void) {
    // TODO Phase 9: cpuExecute() in interpreter
}

void iOSVM_Shutdown(void) {
    if (!s_iOSVM_initialized) return;

    Console.WriteLn("[BionicSX2] iOSVM_Shutdown");
    SysMemory::Release();
    s_iOSVM_initialized = false;
}

} // extern "C"