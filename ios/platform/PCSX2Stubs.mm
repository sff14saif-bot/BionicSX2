// PCSX2Stubs.mm — iOS stubs for all undefined symbols
// Phase 6b: Complete stub implementation for VMManager::Initialize
#import <Foundation/Foundation.h>
#include <string>
#include <memory>
#include <optional>
#include <vector>
#include <span>
#include "BionicLogger.hpp"

#include "common/Pcsx2Defs.h"
#include "common/HostSys.h"
#include "pcsx2/SaveState.h"
#include "pcsx2/StateWrapper.h"
#include "pcsx2/Achievements.h"
#include "pcsx2/USB/USB.h"
// InputRecording.h - stub class provided below
#include "pcsx2/SPU2/spu2.h"
#include "pcsx2/GS/GS.h"

// Type aliases
typedef unsigned int u32;
typedef unsigned long long u64;
typedef unsigned char u8;
typedef unsigned short u16;
typedef int s32;

// Forward declarations
class GSDevice;
class SettingsInterface;
class Error;
class ArchiveEntryList;
class SaveStateScreenshotData;
class StateWrapper;
class SettingsWrapper;
class SettingsWrapperFile;
class SaveStateWrapper;
class Pcsx2Config;
struct ControllerInfo;
struct InputBindingInfo;
struct SettingInfo;
struct ButtonData;

// Note: AudioBackend and AudioExpansionMode enums are now provided by SPU2 headers
// Do not redefine here - they conflict with real implementations

// ── DEV9 ────────────────────────────────────────────────────────────
void DEV9shutdown() {}
s32 DEV9open() { return 0; }
void DEV9close() {}

// ── USB ─────────────────────────────────────────────────────────────
void USBclose() {}

// ── gsIrq ───────────────────────────────────────────────────────────
void gsIrq() {}

// ── AbortWithMessage ───────────────────────────────────────────────
void AbortWithMessage(const char* msg) {
    BionicLogger::instance().log("FATAL", "PCSX2", msg ? msg : "Unknown abort");
    BionicLogger::instance().flush();
    abort();
}

// ── GSopen stub (required by VMManager) ────────────────────────────
bool GSopen(const Pcsx2Config::GSOptions&, GSRendererType, u8*, GSVSyncMode, bool) { return true; }

// ── DEV9init stub ──────────────────────────────────────────────
s32 DEV9init() { return 0; }

// ── USBinit stub ──────────────────────────────────────────────
void USBinit() {}

// ── MakeGSDeviceMTL ───────────────────────────────────────────────
GSDevice* MakeGSDeviceMTL() { return nullptr; }

// ── Threading ────────────────────────────────────────────────────────
namespace Threading {
    class KernelSemaphore {
    public:
        KernelSemaphore() {}
        ~KernelSemaphore() {}
        void Post() {}
        void Wait() {}
    };
    class Thread {
    public:
        Thread() {}
        ~Thread() {}
        void Join() {}
    };
    class ThreadHandle {
    public:
        ThreadHandle() {}
        ~ThreadHandle() {}
        void SetAffinity(unsigned long long) {}
    };
}

// ── SharedMemoryMappingArea - provided by HostSys_iOS.cpp ─────────────

// ── FullscreenUI ───────────────────────────────────────────────────
namespace FullscreenUI {
    __attribute__((weak_import)) void OnVMDestroyed() {}
}

// Note: Achievements, SPU2, USB namespaces are now provided by their headers
// When SaveState.cpp is guarded, these compilation units ARE linked

// ── Achievements stubs (required by VMManager) ────────────────────────
namespace Achievements {
    void GameChanged(unsigned int, unsigned int) {}
    bool IsHardcoreModeActive() { return false; }
}

// ── SPU2 stubs (required by VMManager) ────────────────────────────────
namespace SPU2 {
    bool Open() { return true; }
    void Close() {}
}

// ── USB stubs (required by Pcsx2Config) ──────────────────────────────
namespace USB {
    std::string GetConfigSection(int) { return ""; }
    const char* DeviceTypeIndexToName(s32) { return nullptr; }
    s32 DeviceTypeNameToIndex(std::string_view) { return 0; }
}

// ── FullscreenUI::GameChanged stub ───────────────────────────────────
namespace FullscreenUI {
    void GameChanged(std::string title, std::string path, std::string serial, u32 disc_crc, u32 crc) {}
}

// ── GSCapture ───────────────────────────────────────────────────────
namespace GSCapture {
    void EndCapture() {}
    bool IsCapturing() { return false; }
}

// ── GSTextureReplacements ───────────────────────────────────────────
namespace GSTextureReplacements {
    __attribute__((weak_import)) void GameChanged() {}
    void ReloadReplacementMap() {}
    void Shutdown() {}
    void UpdateConfig(void*) {}
}

// ── SaveStateSelectorUI ─────────────────────────────────────────────
namespace SaveStateSelectorUI {
    void Clear() {}
}

// ── GameDatabase ───────────────────────────────────────────────────
namespace GameDatabase {
    class GameEntry;
    const GameEntry* findGame(std::string_view) { return nullptr; }
}

// ── GameList ───────────────────────────────────────────────────────
namespace GameList {
    void AddPlayedTimeForSerial(const std::string&, long, long) {}
}

// Note: AudioStream namespace now provided by SPU2 headers - don't redefine
// Note: AudioStreamParameters class now provided by SPU2 headers - don't redefine
// Note: USB namespace functions now provided by USB.h - don't redefine

// ── InputRecording stubs ──────────────────────────────────────────
class InputRecording {
public:
    bool isActive() const { return false; }
    void stop() {}
    void incFrameCounter() {}
    u32 getFrameCounter() const { return 0; }
    void setStartingFrame(u32) {}
    u32 getStartingFrame() { return 0; }
};
InputRecording g_InputRecording;

// ── IOCtlSrc (macOS only - stubbed for iOS) ──────────────────────────
class IOCtlSrc {
public:
    ~IOCtlSrc() {}
};

// ── ImGuiManager stubs ──────────────────────────────────────────────
class ImGuiManager {
public:
    void Initialize() {}
    void Shutdown(bool) {}
    void ReloadFonts() {}
    void RequestScaleUpdate() {}
    bool HasSoftwareCursor(u32) { return false; }
};
ImGuiManager* g_imGuiManager = nullptr;

class GSRendererHW { public: GSRendererHW() {} };
class GSRendererNull { public: GSRendererNull() {} };
class GSDrawingContext {
public:
    void Dump(const std::string&) const {}
    void UpdateScissor() {}
};
class GSDrawingEnvironment {
public:
    void Dump(const std::string&) const {}
};

// ── GSPng ──────────────────────────────────────────────────────────
namespace GSPng {
    bool Save(int, const std::string&, const u8*, int, int, int, int, bool) { return false; }
}

// ── InputManager stubs ───────────────────────────────────────────────
namespace InputManager {
    std::string ConvertHostKeyboardCodeToString(u32) { return ""; }
    std::optional<u32> ConvertHostKeyboardStringToCode(std::string_view) { return std::nullopt; }
    void ReloadSources(SettingsInterface&, std::unique_lock<std::mutex>&) {}
    void ReloadBindings(SettingsInterface&, SettingsInterface&, SettingsInterface&, bool, bool) {}
    void SetPadVibrationIntensity(u32 port, float large, float small) {}
}

// ── SaveState stubs ────────────────────────────────────────────────
bool SaveState_ZipToDisk(std::unique_ptr<ArchiveEntryList>, std::unique_ptr<SaveStateScreenshotData>, const char*, Error*) { return false; }
std::unique_ptr<ArchiveEntryList> SaveState_DownloadState(Error* error) { return nullptr; }
std::unique_ptr<SaveStateScreenshotData> SaveState_SaveScreenshot() { return nullptr; }

// ── Host callbacks ──────────────────────────────────────────────────
namespace Host {
    void OnGameChanged(const std::string& title, const std::string& elf_override, const std::string& disc_path, const std::string& disc_serial, u32 disc_crc, u32 crc) {}
    void OnVMDestroyed() {}
    void OnSaveStateSaved(std::string_view path) {}
}

// ── GameDatabaseSchema::GameEntry ───────────────────────────────────
namespace GameDatabaseSchema {
    class GameEntry {
    public:
        void applyGameFixes(void* config, bool applyAuto) const {}
        void applyGSHardwareFixes(void* options) const {}
    };
}

// ── _g_RealGSMem ───────────────────────────────────────────────────
u8* g_RealGSMem = nullptr;

// ── Pad base class ─────────────────────────────────────────────────