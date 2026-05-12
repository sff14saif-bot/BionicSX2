# BionicSX2 — iOS CMake Toolchain File
# Usage: cmake -DCMAKE_TOOLCHAIN_FILE=cmake/ios.toolchain.cmake
#              -DPCSX2_TARGET_IOS=ON

# Target processor is always ARM64 for iOS — set as cache to prevent override
set(CMAKE_SYSTEM_PROCESSOR "arm64" CACHE STRING "Target processor" FORCE)

# Only set full iOS system properties on macOS hosts with Xcode
if(APPLE)
    set(CMAKE_SYSTEM_NAME iOS)
    set(CMAKE_OSX_ARCHITECTURES "arm64")
    set(CMAKE_OSX_DEPLOYMENT_TARGET "14.2" CACHE STRING "Minimum iOS version")
    set(CMAKE_OSX_SYSROOT iphoneos)
else()
    # Non-macOS: use host system, add iOS compile definitions for code validation
    message(WARNING "Non-macOS host — building with iOS defines for code validation only")
endif()

# Compiler — target ARM64 iOS
set(CMAKE_C_COMPILER   /usr/bin/clang)
set(CMAKE_CXX_COMPILER /usr/bin/clang++)
set(CMAKE_OBJC_COMPILER /usr/bin/clang)
set(CMAKE_OBJCXX_COMPILER /usr/bin/clang++)

# Cross-compile flags for ARM64 iOS (even on non-macOS hosts)
set(CMAKE_C_FLAGS_INIT "-target arm64-apple-ios14.2")
set(CMAKE_CXX_FLAGS_INIT "-target arm64-apple-ios14.2")
set(CMAKE_OBJC_FLAGS_INIT "-target arm64-apple-ios14.2")
set(CMAKE_OBJCXX_FLAGS_INIT "-target arm64-apple-ios14.2")

# ARM64 detection — PCSX2 depends on this internally
add_compile_definitions(_M_ARM64=1)
add_compile_definitions(TARGET_OS_IPHONE=1)
add_compile_definitions(PCSX2_TARGET_IOS=1)

# Disable x86 JIT — non-negotiable on ARM64 iOS
add_compile_definitions(DISABLE_PCSX2_RECOMPILER=1)

# Disable Vulkan — Metal is the authoritative backend
add_compile_definitions(DISABLE_VULKAN=1)

# Disable Android paths
add_compile_definitions(DISABLE_ANDROID=1)

# Include paths for 3rdparty sources (must be set early, before project())
# ryml must be findable for #include "ryml.hpp"
set(CMAKE_INCLUDE_PATH "${CMAKE_SOURCE_DIR}/pcsx2/3rdparty/ryml/src"
    CACHE STRING "Include search path for 3rdparty sources")
