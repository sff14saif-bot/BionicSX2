cmake_minimum_required(VERSION 3.20)

project(BionicSX2
    VERSION 0.1.0
    LANGUAGES C CXX OBJC OBJCXX
)

# ─── iOS Target Guard ──────────────────────────────────────────────────────
if(NOT PCSX2_TARGET_IOS)
    message(FATAL_ERROR
        "BionicSX2 is an iOS-only project.\n"
        "Configure with: -DPCSX2_TARGET_IOS=ON\n"
        "and: -DCMAKE_TOOLCHAIN_FILE=cmake/ios.toolchain.cmake"
    )
endif()

# ─── C++ Standard ──────────────────────────────────────────────────────────
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# ─── ARM64 Verification ────────────────────────────────────────────────────
if(NOT CMAKE_SYSTEM_PROCESSOR STREQUAL "arm64")
    message(FATAL_ERROR
        "BionicSX2 requires ARM64. Got: ${CMAKE_SYSTEM_PROCESSOR}"
    )
endif()

# ─── Global Compile Definitions ────────────────────────────────────────────
add_compile_definitions(
    PCSX2_TARGET_IOS=1
    _M_ARM64=1
    TARGET_OS_IPHONE=1
    DISABLE_PCSX2_RECOMPILER=1
    DISABLE_VULKAN=1
    DISABLE_ANDROID=1
)

# ─── 3rdparty dependencies ───────────────────────────────────────────────

# fmt — header-only + compiled
add_subdirectory(pcsx2/3rdparty/fmt EXCLUDE_FROM_ALL)

# fast_float — header-only
add_subdirectory(pcsx2/3rdparty/fast_float EXCLUDE_FROM_ALL)

# rapidyaml / ryml — disable c4core fast_float (uses Windows x86 intrinsics incompatible with iOS/clang)
# c4core's nested fast_float uses _M_ARM64 to detect ARM64 but then includes <intrin.h> which is Windows-only.
# This is a known incompatibility in c4core's fast_float when cross-compiling.
set(C4CORE_WITH_FASTFLOAT OFF CACHE BOOL "" FORCE)
add_subdirectory(pcsx2/3rdparty/ryml EXCLUDE_FROM_ALL)

# zlib — NOT FOUND in pcsx2/3rdparty
# add_subdirectory(pcsx2/3rdparty/zlib EXCLUDE_FROM_ALL)  # Directory does not exist

# libzip deferred — requires zstd + zlib which are not available on iOS
# Enable when proper iOS zstd/zlib integration is implemented

# ── Image Libraries (built from source for iOS ARM64) ──────────────────

# libjpeg-turbo — native ARM64 SIMD, supports CMake cross-compile
set(ENABLE_SHARED     OFF CACHE BOOL "" FORCE)
set(ENABLE_STATIC     ON  CACHE BOOL "" FORCE)
set(WITH_TURBOJPEG    OFF CACHE BOOL "" FORCE)
set(WITH_JAVA         OFF CACHE BOOL "" FORCE)
set(WITH_SIMD         ON  CACHE BOOL "" FORCE)
set(CMAKE_INSTALL_DOCDIR "share/doc/libjpeg-turbo" CACHE STRING "" FORCE)
set(CMAKE_INSTALL_MANDIR "share/man" CACHE STRING "" FORCE)
set(CMAKE_INSTALL_DOXYDIR "share/doc" CACHE STRING "" FORCE)
add_subdirectory(3rdparty/libjpeg-turbo EXCLUDE_FROM_ALL)
target_include_directories(jpeg-static PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/libjpeg-turbo/src>
    $<BUILD_INTERFACE:${CMAKE_BINARY_DIR}/3rdparty/libjpeg-turbo>
)
add_library(JPEG::JPEG ALIAS jpeg-static)

# libpng — zlib is part of iOS SDK
find_package(ZLIB QUIET)
set(PNG_SHARED    OFF CACHE BOOL "" FORCE)
set(PNG_STATIC    ON  CACHE BOOL "" FORCE)
set(PNG_TESTS     OFF CACHE BOOL "" FORCE)
add_subdirectory(3rdparty/libpng EXCLUDE_FROM_ALL)
add_library(PNG::PNG ALIAS png_static)

# libwebp
set(WEBP_BUILD_ANIM_UTILS OFF CACHE BOOL "" FORCE)
set(WEBP_BUILD_CWEBP      OFF CACHE BOOL "" FORCE)
set(WEBP_BUILD_DWEBP      OFF CACHE BOOL "" FORCE)
set(WEBP_BUILD_GIF2WEBP   OFF CACHE BOOL "" FORCE)
set(WEBP_BUILD_IMG2WEBP   OFF CACHE BOOL "" FORCE)
set(WEBP_BUILD_VWEBP      OFF CACHE BOOL "" FORCE)
set(WEBP_BUILD_WEBPINFO   OFF CACHE BOOL "" FORCE)
set(WEBP_BUILD_WEBPMUX    OFF CACHE BOOL "" FORCE)
set(WEBP_BUILD_EXTRAS     OFF CACHE BOOL "" FORCE)
set(WEBP_BUILD_WEBP_JS     OFF CACHE BOOL "" FORCE)
add_subdirectory(3rdparty/libwebp EXCLUDE_FROM_ALL)
if(NOT TARGET WebP::libwebp)
    add_library(WebP::libwebp ALIAS webp)
endif()

# cpuinfo — ARM64 CPU feature detection
set(CPUINFO_BUILD_TOOLS OFF CACHE BOOL "" FORCE)
set(CPUINFO_BUILD_UNIT_TESTS OFF CACHE BOOL "" FORCE)
set(CPUINFO_BUILD_MOCK_TESTS OFF CACHE BOOL "" FORCE)
set(CPUINFO_BUILD_BENCHMARKS OFF CACHE BOOL "" FORCE)
add_subdirectory(pcsx2/3rdparty/cpuinfo EXCLUDE_FROM_ALL)

# freesurround — audio expander
add_subdirectory(pcsx2/3rdparty/freesurround EXCLUDE_FROM_ALL)

# SoundTouch — audio time stretch
add_subdirectory(pcsx2/3rdparty/soundtouch EXCLUDE_FROM_ALL)

# demangler — symbol demangling (required by SymbolImporter)
add_subdirectory(pcsx2/3rdparty/demangler EXCLUDE_FROM_ALL)

# libzip — save states and patches
# Disable zstd on iOS — not available in iOS SDK
set(HAVE_LIBZSTD FALSE CACHE BOOL "" FORCE)
set(LIBZIP_BUILD_TOOLS      OFF CACHE BOOL "" FORCE)
set(LIBZIP_BUILD_REGRESS    OFF CACHE BOOL "" FORCE)
set(LIBZIP_BUILD_EXAMPLES   OFF CACHE BOOL "" FORCE)
set(LIBZIP_BUILD_DOC        OFF CACHE BOOL "" FORCE)
set(LIBZIP_ENABLE_COMMONCRYPTO OFF CACHE BOOL "" FORCE)
set(LIBZIP_ENABLE_GNUTLS   OFF CACHE BOOL "" FORCE)
set(LIBZIP_ENABLE_MBEDTLS   OFF CACHE BOOL "" FORCE)
set(LIBZIP_ENABLE_OPENSSL   OFF CACHE BOOL "" FORCE)
set(LIBZIP_ENABLE_WINDOWS_CRYPTO OFF CACHE BOOL "" FORCE)
# zlib is in iOS SDK; libzip will find it via find_package
find_package(ZLIB REQUIRED)
add_subdirectory(pcsx2/3rdparty/libzip EXCLUDE_FROM_ALL)

# ─── pcsx2_common — platform-agnostic utilities ───────────────────────────

set(PCSX2_COMMON_SOURCES
    # [SAFE] — verified in Layer 0 audit
    pcsx2/common/AlignedMalloc.cpp
    pcsx2/common/Assertions.cpp
    pcsx2/common/Console.cpp
    pcsx2/common/CrashHandler.cpp
    pcsx2/common/DynamicLibrary.cpp
    pcsx2/common/Error.cpp
    pcsx2/common/FastJmp.cpp
    pcsx2/common/FileSystem.cpp
    pcsx2/common/HTTPDownloader.cpp
    pcsx2/common/Image.cpp
    pcsx2/common/MD5Digest.cpp
    pcsx2/common/MemoryInterface.cpp
    pcsx2/common/MemorySettingsInterface.cpp
    pcsx2/common/ProgressCallback.cpp
    pcsx2/common/ReadbackSpinManager.cpp
    pcsx2/common/Semaphore.cpp
    pcsx2/common/SettingsWrapper.cpp
    pcsx2/common/SmallString.cpp
    pcsx2/common/StringUtil.cpp
    pcsx2/common/TextureDecompress.cpp
    pcsx2/common/Timer.cpp
    pcsx2/common/WAVWriter.cpp
    pcsx2/common/WindowInfo.cpp
    pcsx2/common/YAML.cpp

    # iOS platform layer (replaces HostSys.cpp and CocoaTools.mm)
    ios/platform/HostSys_iOS.cpp
    ios/platform/CocoaTools.mm
    ios/platform/AudioStream_iOS.mm
    ios/platform/Filesystem_iOS.mm

    # Darwin threading + misc (macOS/iOS shared)
    pcsx2/common/Darwin/DarwinThreads.cpp

    # EXCLUDED — DO NOT ADD:
    # pcsx2/common/HostSys.cpp        (replaced by HostSys_iOS.cpp)
    # pcsx2/common/Perf.cpp           (Linux perf_event_open — iOS incompatible)
    # pcsx2/common/PrecompiledHeader.cpp (HEADER_FILE_ONLY)
    # pcsx2/common/emitter/*          (x86 only)
    # pcsx2/common/Windows/*          (Windows only)
    # pcsx2/common/Linux/*            (Linux only)
    # pcsx2/common/Darwin/DarwinMisc.cpp (macOS-specific — excluded)
    # pcsx2/common/CocoaTools.mm      (macOS — we have iOS replacement)
    # pcsx2/common/HTTPDownloaderCurl.cpp (no libcurl on iOS)
)

add_library(pcsx2_common STATIC ${PCSX2_COMMON_SOURCES})

target_include_directories(pcsx2_common PUBLIC
    ${CMAKE_SOURCE_DIR}/pcsx2
    ${CMAKE_SOURCE_DIR}/pcsx2/common
    ${CMAKE_SOURCE_DIR}/ios/platform
    ${CMAKE_SOURCE_DIR}/pcsx2/3rdparty/ryml/src
    ${CMAKE_SOURCE_DIR}/pcsx2/3rdparty/ryml/ext/c4core/src
    ${CMAKE_SOURCE_DIR}/pcsx2/3rdparty/fmt/include
    ${CMAKE_SOURCE_DIR}/pcsx2/3rdparty/fast_float/include
    ${CMAKE_SOURCE_DIR}/3rdparty/libjpeg-turbo
    ${CMAKE_SOURCE_DIR}/3rdparty/libpng
    ${CMAKE_SOURCE_DIR}/3rdparty/libwebp
)

target_compile_definitions(pcsx2_common PUBLIC
    PCSX2_TARGET_IOS=1
    _M_ARM64=1
    DISABLE_VULKAN=1
    DISABLE_ANDROID=1
    TARGET_OS_IPHONE=1
)

target_link_libraries(pcsx2_common PUBLIC
    fmt::fmt
    fast_float
    cpuinfo
    ryml
    JPEG::JPEG
    PNG::PNG
    WebP::libwebp
)

# fast_float: disable __umulh usage on ARM64/clang (not available)
target_compile_definitions(pcsx2_common PUBLIC
    FASTFLOAT_ALLOWS_LEADING_PLUS=1
)

# ── pcsx2_core — PS2 interpreter ─────────────────────────────────────────

set(PCSX2_CORE_SOURCES
    # EE / IOP Interpreters
    pcsx2/pcsx2/R3000A.cpp
    pcsx2/pcsx2/R3000AInterpreter.cpp
    pcsx2/pcsx2/R3000AOpcodeTables.cpp
    pcsx2/pcsx2/R5900.cpp
    pcsx2/pcsx2/R5900OpcodeImpl.cpp
    pcsx2/pcsx2/R5900OpcodeTables.cpp
    pcsx2/pcsx2/COP0.cpp
    pcsx2/pcsx2/COP2.cpp
    pcsx2/pcsx2/FPU.cpp
    pcsx2/pcsx2/MMI.cpp
    pcsx2/pcsx2/Interpreter.cpp

    # VU
    pcsx2/pcsx2/VU0.cpp
    pcsx2/pcsx2/VU0micro.cpp
    pcsx2/pcsx2/VU0microInterp.cpp
    pcsx2/pcsx2/VU1micro.cpp
    pcsx2/pcsx2/VU1microInterp.cpp
    pcsx2/pcsx2/VUflags.cpp
    pcsx2/pcsx2/VUmicro.cpp
    pcsx2/pcsx2/VUmicroMem.cpp
    pcsx2/pcsx2/VUops.cpp

    # Hardware
    pcsx2/pcsx2/Cache.cpp
    pcsx2/pcsx2/Counters.cpp
    pcsx2/pcsx2/Dmac.cpp
    pcsx2/pcsx2/FiFo.cpp
    pcsx2/pcsx2/FW.cpp
    pcsx2/pcsx2/Gif.cpp
    pcsx2/pcsx2/Gif_Logger.cpp
    pcsx2/pcsx2/Gif_Unit.cpp
    pcsx2/pcsx2/Hw.cpp
    pcsx2/pcsx2/HwRead.cpp
    pcsx2/pcsx2/HwWrite.cpp
    pcsx2/pcsx2/Memory.cpp
    pcsx2/pcsx2/MTGS.cpp
    pcsx2/pcsx2/MTVU.cpp
    pcsx2/pcsx2/Patch.cpp
    pcsx2/pcsx2/PINE.cpp
    pcsx2/pcsx2/SaveState.cpp
    pcsx2/pcsx2/Sif.cpp
    pcsx2/pcsx2/Sif0.cpp
    pcsx2/pcsx2/Sif1.cpp
    pcsx2/pcsx2/sif2.cpp
    pcsx2/pcsx2/SPR.cpp
    pcsx2/pcsx2/StateWrapper.cpp
    pcsx2/pcsx2/Vif.cpp
    pcsx2/pcsx2/Vif_Codes.cpp
    pcsx2/pcsx2/Vif_Transfer.cpp
    pcsx2/pcsx2/Vif_Unpack.cpp
    pcsx2/pcsx2/Vif0_Dma.cpp
    pcsx2/pcsx2/Vif1_Dma.cpp
    pcsx2/pcsx2/Vif1_MFIFO.cpp

    # ARM64 VU/VIF (replaces x86 dynarec)
    pcsx2/pcsx2/arm64/Vif_Dynarec.cpp
    pcsx2/pcsx2/arm64/Vif_UnpackNEON.cpp
    pcsx2/pcsx2/arm64/AsmHelpers.cpp

    # PS2 hardware access (pgif, VU, etc.)
    pcsx2/pcsx2/ps2/pgif.cpp

    # MIPS debugger/assembler (needed for debug builds)
    pcsx2/pcsx2/DebugTools/ExpressionParser.cpp
    pcsx2/pcsx2/DebugTools/MipsAssembler.cpp
    pcsx2/pcsx2/DebugTools/MipsAssemblerTables.cpp
    pcsx2/pcsx2/DebugTools/MipsStackWalk.cpp
    pcsx2/pcsx2/DebugTools/MIPSAnalyst.cpp
    pcsx2/pcsx2/DebugTools/DebugInterface.cpp
    pcsx2/pcsx2/DebugTools/BiosDebugData.cpp
    pcsx2/pcsx2/DebugTools/Breakpoints.cpp
    pcsx2/pcsx2/vtlb.cpp
    pcsx2/pcsx2/Elfheader.cpp

    # IOP
    pcsx2/pcsx2/IopBios.cpp
    pcsx2/pcsx2/IopCounters.cpp
    pcsx2/pcsx2/IopDma.cpp
    pcsx2/pcsx2/IopGte.cpp
    pcsx2/pcsx2/IopHw.cpp
    pcsx2/pcsx2/IopIrq.cpp
    pcsx2/pcsx2/IopMem.cpp
    pcsx2/pcsx2/Mdec.cpp

    # IPU
    pcsx2/pcsx2/IPU/IPU.cpp
    pcsx2/pcsx2/IPU/IPUdma.cpp
    pcsx2/pcsx2/IPU/IPU_Fifo.cpp
    pcsx2/pcsx2/IPU/IPU_MultiISA.cpp
    pcsx2/pcsx2/IPU/IPUdither.cpp
    pcsx2/pcsx2/IPU/yuv2rgb.cpp

    # CDVD
    pcsx2/pcsx2/CDVD/CDVD.cpp
    pcsx2/pcsx2/CDVD/CDVDcommon.cpp
    pcsx2/pcsx2/CDVD/CDVDdiscReader.cpp
    # pcsx2/pcsx2/CDVD/Darwin/IOCtlSrc.cpp  # macOS only - IOKit not available on iOS
    pcsx2/pcsx2/CDVD/CDVDisoReader.cpp
    pcsx2/pcsx2/CDVD/InputIsoFile.cpp
    pcsx2/pcsx2/CDVD/OutputIsoFile.cpp
    pcsx2/pcsx2/CDVD/ThreadedFileReader.cpp
    pcsx2/pcsx2/CDVD/BlockdumpFileReader.cpp
    pcsx2/pcsx2/CDVD/ChdFileReader.cpp
    pcsx2/pcsx2/CDVD/CsoFileReader.cpp
    pcsx2/pcsx2/CDVD/GzippedFileReader.cpp

    # PS2 subsystem (required by interpreter)
    pcsx2/pcsx2/ps2/BiosTools.cpp
    pcsx2/pcsx2/CDVD/FlatFileReader.cpp
    pcsx2/pcsx2/CDVD/Ps1CD.cpp

    # SIO / Pad
    pcsx2/pcsx2/SIO/Sio.cpp
    pcsx2/pcsx2/SIO/Pad/Pad.cpp
    pcsx2/pcsx2/SIO/Pad/PadBase.cpp
    pcsx2/pcsx2/SIO/Pad/PadDualshock2.cpp
    pcsx2/pcsx2/SIO/Pad/PadGuitar.cpp
    pcsx2/pcsx2/SIO/Pad/PadJogcon.cpp
    pcsx2/pcsx2/SIO/Pad/PadNegcon.cpp
    pcsx2/pcsx2/SIO/Pad/PadPopn.cpp
    pcsx2/pcsx2/SIO/Pad/PadNotConnected.cpp
    pcsx2/pcsx2/SIO/Sio0.cpp
    pcsx2/pcsx2/SIO/Sio2.cpp
    pcsx2/pcsx2/SIO/Memcard/MemoryCardFile.cpp
    pcsx2/pcsx2/SIO/Memcard/MemoryCardFolder.cpp

# SPU2 — ADSR and ReadInput (missing from build)
    pcsx2/pcsx2/SPU2/ADSR.cpp
    pcsx2/pcsx2/SPU2/ReadInput.cpp
    pcsx2/pcsx2/SPU2/spu2freeze.cpp
    pcsx2/pcsx2/SPU2/Debug.cpp
    pcsx2/pcsx2/SPU2/Wavedump_wav.cpp

    # IOP hardware — missing IopHw files
    pcsx2/pcsx2/ps2/Iop/IopHwRead.cpp
    pcsx2/pcsx2/ps2/Iop/IopHwWrite.cpp
    pcsx2/pcsx2/ps2/Iop/PsxBios.cpp

    # ShiftJIS conversion
    pcsx2/pcsx2/ShiftJisToUnicode.cpp

    # Debug Tools / Disassemblers (required by IopBios, VMManager)
    pcsx2/pcsx2/DebugTools/DisR5900asm.cpp
    pcsx2/pcsx2/DebugTools/DisR3000A.cpp
    pcsx2/pcsx2/DebugTools/SymbolGuardian.cpp
    pcsx2/pcsx2/DebugTools/SymbolImporter.cpp
    pcsx2/pcsx2/DebugTools/DisassemblyManager.cpp
    pcsx2/pcsx2/DebugTools/DisassemblyManager.h
    pcsx2/pcsx2/DebugTools/DisASM.h
    pcsx2/pcsx2/DebugTools/DisVU0Micro.cpp
    pcsx2/pcsx2/DebugTools/DisVU1Micro.cpp
    pcsx2/pcsx2/DebugTools/DisVUmicro.h
    pcsx2/pcsx2/DebugTools/DisVUops.h

    # ccc symbol library (required by SymbolGuardian/SymbolImporter)
    pcsx2/3rdparty/ccc/src/ccc/ast.cpp
    pcsx2/3rdparty/ccc/src/ccc/elf.cpp
    pcsx2/3rdparty/ccc/src/ccc/elf_symtab.cpp
    pcsx2/3rdparty/ccc/src/ccc/importer_flags.cpp
    pcsx2/3rdparty/ccc/src/ccc/mdebug_analysis.cpp
    pcsx2/3rdparty/ccc/src/ccc/mdebug_importer.cpp
    pcsx2/3rdparty/ccc/src/ccc/mdebug_section.cpp
    pcsx2/3rdparty/ccc/src/ccc/mdebug_symbols.cpp
    pcsx2/3rdparty/ccc/src/ccc/sndll.cpp
    pcsx2/3rdparty/ccc/src/ccc/stabs.cpp
    pcsx2/3rdparty/ccc/src/ccc/stabs_to_ast.cpp
    pcsx2/3rdparty/ccc/src/ccc/symbol_database.cpp
    pcsx2/3rdparty/ccc/src/ccc/symbol_file.cpp
    pcsx2/3rdparty/ccc/src/ccc/symbol_table.cpp
    pcsx2/3rdparty/ccc/src/ccc/util.cpp

    # CDVD / ISO
    pcsx2/pcsx2/CDVD/IsoReader.cpp
    pcsx2/pcsx2/CDVD/IsoHasher.cpp

    # SIO / Memory Card
    pcsx2/pcsx2/SIO/Memcard/MemoryCardProtocol.cpp

    # GS Capture (audio/frame capture) — requires ffmpeg, disabled for iOS
    # pcsx2/pcsx2/GS/GSCapture.cpp

    # Logging
    pcsx2/pcsx2/SourceLog.cpp

    # Config / VM
    pcsx2/pcsx2/Pcsx2Config.cpp
    pcsx2/pcsx2/VMManager.cpp
    pcsx2/pcsx2/Host.cpp

    # Audio Stream
    pcsx2/pcsx2/Host/AudioStream.cpp

    # Input Manager
    # pcsx2/pcsx2/Input/InputManager.cpp  # Commented - causes more issues
    pcsx2/pcsx2/INISettingsInterface.cpp

    # Game Database
    pcsx2/pcsx2/GameDatabase.cpp
    # pcsx2/pcsx2/GameList.cpp

    # PS2 subsystem
    pcsx2/pcsx2/ps2/BiosTools.cpp

    # GSDump Replayer
    pcsx2/pcsx2/GSDumpReplayer.cpp

    # GS Core (no Vulkan, no OpenGL, no DX)
    pcsx2/pcsx2/GS/GS.cpp
    pcsx2/pcsx2/GS/GSBlock.cpp
    pcsx2/pcsx2/GS/GSClut.cpp
    pcsx2/pcsx2/GS/GSLocalMemory.cpp
    pcsx2/pcsx2/GS/GSPerfMon.cpp
    pcsx2/pcsx2/GS/GSState.cpp
    pcsx2/pcsx2/GS/GSTables.cpp
    pcsx2/pcsx2/GS/GSUtil.cpp
    pcsx2/pcsx2/GS/Renderers/Common/GSDevice.cpp
    pcsx2/pcsx2/GS/Renderers/Common/GSRenderer.cpp
    pcsx2/pcsx2/GS/Renderers/Common/GSTexture.cpp
    pcsx2/pcsx2/GS/Renderers/Common/GSVertexTraceFMM.cpp
    pcsx2/pcsx2/GS/Renderers/SW/GSDrawScanline.cpp
    pcsx2/pcsx2/GS/Renderers/SW/GSRasterizer.cpp
    pcsx2/pcsx2/GS/Renderers/SW/GSTextureCacheSW.cpp
)

add_library(pcsx2_core STATIC ${PCSX2_CORE_SOURCES})

target_include_directories(pcsx2_core PUBLIC
    ${CMAKE_SOURCE_DIR}/pcsx2
    ${CMAKE_SOURCE_DIR}/pcsx2/pcsx2
    ${CMAKE_SOURCE_DIR}/pcsx2/common
    ${CMAKE_SOURCE_DIR}/pcsx2/3rdparty/ryml/src
    ${CMAKE_SOURCE_DIR}/pcsx2/3rdparty/ryml/ext/c4core/src
    ${CMAKE_SOURCE_DIR}/pcsx2/3rdparty/ccc/src
    ${CMAKE_SOURCE_DIR}/pcsx2/3rdparty/demangler/include
    ${CMAKE_SOURCE_DIR}/pcsx2/3rdparty/simpleini/include
    ${CMAKE_SOURCE_DIR}/pcsx2/3rdparty/include
    ${CMAKE_SOURCE_DIR}/pcsx2/3rdparty/libzip/lib
    ${CMAKE_SOURCE_DIR}/pcsx2/3rdparty/libzip/msvc
    ${CMAKE_SOURCE_DIR}/pcsx2/3rdparty/vixl/include
    ${CMAKE_SOURCE_DIR}/pcsx2/3rdparty/imgui/include
    ${CMAKE_SOURCE_DIR}/ios/platform
    ${CMAKE_SOURCE_DIR}/pcsx2/3rdparty/fast_float/include
    ${CMAKE_SOURCE_DIR}/pcsx2/3rdparty/fmt/include
    ${CMAKE_SOURCE_DIR}/pcsx2/3rdparty/cpuinfo/include
    ${CMAKE_SOURCE_DIR}/3rdparty/libjpeg-turbo
    ${CMAKE_SOURCE_DIR}/3rdparty/libpng
    ${CMAKE_SOURCE_DIR}/3rdparty/libwebp
)

target_compile_definitions(pcsx2_core PUBLIC
    PCSX2_TARGET_IOS=1
    _M_ARM64=1
    DISABLE_PCSX2_RECOMPILER=1
    DISABLE_VULKAN=1
    DISABLE_ANDROID=1
    TARGET_OS_IPHONE=1
    DISABLE_DISCORD_RPC=1
)

# ─── Apple Frameworks (direct linking - no find_library needed) ─────────────────────────
# Note: -framework flags work directly in Xcode/Apple toolchains

target_link_libraries(pcsx2_core PUBLIC
    "-framework Metal"
    "-framework MetalKit"
    "-framework AVFoundation"
    "-framework AudioToolbox"
    zip
    demanglegnu
    freesurround
    SoundTouch::SoundTouch
)

# ─── iOS Platform Layer ────────────────────────────────────────────────────
set(IOS_PLATFORM_SOURCES
    ios/platform/EmulatorBridge.h
    ios/platform/EmulatorBridge.mm
    ios/platform/iOSVMManager.mm
    ios/platform/AudioStream_iOS.mm
    ios/platform/Filesystem_iOS.mm
    ios/platform/Host_iOS.mm
    ios/platform/PCSX2Stubs.mm
    ios/platform/BionicLogger.hpp
    ios/platform/BionicLogger.mm
    ios/platform/CrashHandler.hpp
    ios/platform/CrashHandler.cpp
    ios/platform/Watchdog.hpp
    ios/platform/Watchdog.cpp
    ios/platform/ExitWrapper.c
)

# ─── iOS UI Layer ──────────────────────────────────────────────────────────
set(IOS_UI_SOURCES
    ios/ui/AppDelegate.mm
    ios/ui/MetalViewController.mm
    ios/ui/GameLibraryViewController.mm
    ios/ui/LogViewerController.mm
)

# ─── Main Executable ───────────────────────────────────────────────────────
add_executable(BionicSX2
    ios/main.mm
    ${IOS_UI_SOURCES}
    ${IOS_PLATFORM_SOURCES}
)

target_include_directories(BionicSX2 PRIVATE
    ${CMAKE_SOURCE_DIR}/src
    ${CMAKE_SOURCE_DIR}/pcsx2
    ${CMAKE_SOURCE_DIR}/pcsx2/pcsx2
    ${CMAKE_SOURCE_DIR}/pcsx2/common
    ${CMAKE_SOURCE_DIR}/ios
    ${CMAKE_SOURCE_DIR}/ios/platform
    ${CMAKE_SOURCE_DIR}/ios/ui
)

target_link_libraries(BionicSX2 PRIVATE
    "-framework UniformTypeIdentifiers"
    pcsx2_common
    pcsx2_core
    "-framework Metal"
    "-framework MetalKit"
    "-framework AVFoundation"
    "-framework AudioToolbox"
    "-framework UIKit"
    "-framework Foundation"
    "-framework QuartzCore"
    "-framework CoreGraphics"
)

# ─── iOS Bundle Properties ─────────────────────────────────────────────────
set_target_properties(BionicSX2 PROPERTIES
    MACOSX_BUNDLE                   TRUE
    MACOSX_BUNDLE_INFO_PLIST        ${CMAKE_SOURCE_DIR}/ios/Info.plist
    XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY ""
    XCODE_ATTRIBUTE_CODE_SIGNING_REQUIRED NO
    XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER "com.bionics2.emulator"
    XCODE_ATTRIBUTE_IPHONEOS_DEPLOYMENT_TARGET "14.2"
    XCODE_ATTRIBUTE_CODE_SIGN_ENTITLEMENTS
        "${CMAKE_SOURCE_DIR}/ios/entitlements/BionicSX2.entitlements"
)

message(STATUS "✓ BionicSX2 iOS build configured")
message(STATUS "  Target:     iOS ${CMAKE_OSX_DEPLOYMENT_TARGET}+")
message(STATUS "  Arch:       ${CMAKE_SYSTEM_PROCESSOR}")
message(STATUS "  Build type: ${CMAKE_BUILD_TYPE}")
