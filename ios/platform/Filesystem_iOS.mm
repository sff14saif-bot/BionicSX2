// BionicSX2 — iOS Filesystem Implementation
// Phase 2 implementation target
// iOS sandbox paths — NO assumptions from macOS or Android
// Reference: PCSX2 macOS Filesystem → path roots updated for iOS sandbox

#include <string>
#include <cstdlib>
#import <Foundation/Foundation.h>

// iOS Sandbox Directory Layout:
//
//   Documents/          ← User-visible files (ROMs, BIOS, saves)
//   Library/            ← App data (settings, cache)
//   Library/Caches/     ← Temporary cache (evictable by OS)
//   tmp/                ← Temporary files (cleared on relaunch)
//
// NEVER hardcode paths — always derive from NSSearchPathForDirectoriesInDomains
// or NSTemporaryDirectory() at runtime.
// These are implemented in Filesystem_iOS.mm (Objective-C++ required for NS APIs)

// TODO Phase 2: Move all path resolution to Filesystem_iOS.mm
// and expose via these C++ function signatures.

// Returns: iOS Documents directory (ROMs, BIOS, memory cards)
// Example: /var/mobile/Containers/Data/Application/<UUID>/Documents
std::string Filesystem_GetDocumentsPath() {
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentsPath = [paths firstObject];
    return std::string([documentsPath UTF8String]) + "/";
}

// Returns: iOS Library directory (settings, databases)
std::string Filesystem_GetLibraryPath() {
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString* libraryPath = [paths firstObject];
    return std::string([libraryPath UTF8String]) + "/";
}

// Returns: iOS tmp directory (scratch space, cleared on relaunch)
std::string Filesystem_GetTempPath() {
    NSString* tempPath = NSTemporaryDirectory();
    return std::string([tempPath UTF8String]);
}

// Returns: BIOS file path inside Documents/bios/
// BIOS must be user-supplied — cannot be bundled (legal requirement)
std::string Filesystem_GetBIOSPath(const std::string& filename) {
    return Filesystem_GetDocumentsPath() + "bios/" + filename;
}

// Returns: Memory card path inside Documents/memcards/
std::string Filesystem_GetMemCardPath(int slot) {
    return Filesystem_GetDocumentsPath() + "memcards/Mcd00" + std::to_string(slot) + ".ps2";
}

// Returns: Save state path inside Documents/sstates/
std::string Filesystem_GetSaveStatePath(const std::string& serial, int slot) {
    return Filesystem_GetDocumentsPath() + "sstates/" + serial + "_" + std::to_string(slot) + ".p2s";
}
