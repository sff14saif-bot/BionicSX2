#pragma once
// iOS fatal exit handler — logs reason to BionicLogger then abort().
// Used instead of exit()/quick_exit() to ensure the crash handler
// captures the error with full context.
//
// On non-iOS platforms, falls back to std::exit(1).

#include "BionicLogger.hpp"

#ifdef PCSX2_TARGET_IOS
#define STRINGIFY2(x) #x
#define STRINGIFY(x) STRINGIFY2(x)
#define pcsx2_fatal_exit(reason) do { \
    BionicLogger::instance().log("FATAL", "PCSX2", reason " at " __FILE__ ":" STRINGIFY(__LINE__)); \
    BionicLogger::instance().flush(); \
    std::abort(); \
} while(0)
#else
#include <cstdlib>
#define pcsx2_fatal_exit(reason) std::exit(1)
#endif
