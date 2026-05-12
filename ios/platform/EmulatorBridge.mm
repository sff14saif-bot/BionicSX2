// EmulatorBridge.mm — Phase 6: VMManager enabled
#import <Foundation/Foundation.h>

#include "EmulatorBridge.h"
#include "VMManager.h"
#include "Config.h"
#include "common/Error.h"
#include "iOSVMManager.h"
#include "Watchdog.hpp"
#include "BionicLogger.hpp"
#include "PCSX2LogRedirect.h"
#include "PCSX2FatalExit.h"

extern "C" {

// Redirect stderr to the BionicLogger log file, capturing any raw
// fprintf(stderr, ...) output from PCSX2.
#include <unistd.h>

static void StderrRedirect_Start(void) {
    int log_fd = BionicLogger::instance().get_log_fd();
    if (log_fd >= 0 && log_fd != STDERR_FILENO)
        dup2(log_fd, STDERR_FILENO);
}

static void BionicExitHandler() {
    BionicLogger::instance().log("FATAL", "CORE ", "Application exiting via exit()/quick_exit()");
    BionicLogger::instance().flush();
}

bool EmulatorBridge_Init(void) {
    NSLog(@"[BionicSX2] EmulatorBridge_Init");
    PCSX2Log_Init();

    // Set EmuFolders::DataRoot to iOS Documents sandbox so BIOS/search paths resolve correctly.
    // Without this, PCSX2 looks in macOS paths (~/Library/...) which don't exist on iOS.
    NSString* docs = NSSearchPathForDirectoriesInDomains(
        NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    EmuFolders::DataRoot = std::string([docs UTF8String]);
    BIONIC_INFO(CORE, "EmuFolders::DataRoot = %s", EmuFolders::DataRoot.c_str());
    EmuFolders::Bios = EmuFolders::DataRoot + "/bios";
    BIONIC_INFO(CORE, "EmuFolders::Bios = %s", EmuFolders::Bios.c_str());
    BionicLogger::instance().flush();

    std::atexit(BionicExitHandler);
    return true;
}

void EmulatorBridge_Shutdown(void) {
    NSLog(@"[BionicSX2] EmulatorBridge_Shutdown");
    if (VMManager::GetState() != VMState::Shutdown) {
        VMManager::Shutdown(false);
    }
    Watchdog_Stop();
}

bool EmulatorBridge_BootGame(const char* isoPath) {
    NSLog(@"[BionicSX2] EmulatorBridge_BootGame: %s", isoPath ? isoPath : "(null)");

    BionicLogger::instance().log("INFO ", "CORE ", "EmulatorBridge_BootGame: starting VMManager");
    BionicLogger::instance().flush();

    NSString* docs = NSSearchPathForDirectoriesInDomains(
        NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString* biosDir = [docs stringByAppendingPathComponent:@"bios"];
    BIONIC_INFO(CORE, "BIOS directory: %s", [biosDir UTF8String]);

    NSFileManager* fm = [NSFileManager defaultManager];
    NSArray* biosFiles = [fm contentsOfDirectoryAtPath:biosDir error:nil];
    if (biosFiles.count > 0) {
        for (NSString* f in biosFiles)
            BIONIC_INFO(CORE, "  BIOS file: %s", [f UTF8String]);
    } else {
        BIONIC_INFO(CORE, "  BIOS directory is empty");
    }

    if (isoPath) {
        BIONIC_INFO(CORE, "ISO path: %s", isoPath);
    } else {
        BIONIC_INFO(CORE, "No ISO — BIOS-only mode");
    }
    BionicLogger::instance().flush();

    // Save ISO path for VMManager settings queries
    BionicSX2_SetCurrentISO(isoPath);

    // stderr redirect disabled temporarily for crash isolation
    // StderrRedirect_Start();

    try {
        Watchdog_Start();
        bool result = iOSVM_Initialize(isoPath);

        BionicLogger::instance().log("INFO ", "CORE ", "iOSVM_Initialize returned.");
        BionicLogger::instance().flush();

        if (result) {
            NSLog(@"[BionicSX2] iOSVM initialized — PS2 running");
        } else {
            NSLog(@"[BionicSX2] iOSVM_Initialize failed");
            Watchdog_Stop();
        }

        if (!VMManager::HasValidVM()) {
            BionicLogger::instance().log("WARN ", "CORE ", "VM is not valid after init");
            BionicLogger::instance().flush();
        }

        return result;
    } catch (const std::exception& e) {
        BIONIC_FATAL(CORE, "Boot exception: %s", e.what());
        BionicLogger::instance().flush();
        Watchdog_Stop();
        return false;
    } catch (...) {
        BIONIC_FATAL(CORE, "Boot exception: unknown");
        BionicLogger::instance().flush();
        Watchdog_Stop();
        return false;
    }
}

void EmulatorBridge_RunFrame(void) {
    if (VMManager::GetState() == VMState::Running) {
        VMManager::Execute();
    }
}

bool EmulatorBridge_IsRunning(void) {
    return VMManager::GetState() == VMState::Running;
}

} // extern "C"