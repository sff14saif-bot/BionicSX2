// ExitWrapper.c — intercept exit() and _exit() on Darwin/iOS.
// Apple's linker does not support --wrap, so we override the symbols directly
// and call the originals via dlsym(RTLD_NEXT, ...).
// This ensures any PCSX2 core exit/_exit call is logged before termination.

#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <dlfcn.h>

// Saved original implementations
typedef void (*exit_func_t)(int);
static exit_func_t s_real_exit = NULL;
static exit_func_t s_real__exit = NULL;

// Helper — async-signal-safe write to stderr (no BionicLogger dependency)
static void RawWrite(const char* msg) {
    if (msg == NULL) return;
    size_t len = strlen(msg);
    if (len > 0) write(STDERR_FILENO, msg, len);
}

__attribute__((constructor))
static void ExitWrapper_Init(void) {
    // Lookup originals via RTLD_NEXT (skips our overrides)
    s_real_exit = (exit_func_t)dlsym(RTLD_NEXT, "exit");
    s_real__exit = (exit_func_t)dlsym(RTLD_NEXT, "_exit");
    if (!s_real_exit) s_real_exit = (exit_func_t)_exit;  // ultimate fallback
    if (!s_real__exit) s_real__exit = (exit_func_t)abort; // ultimate fallback
}

void exit(int status) {
    RawWrite("[ExitWrapper] PCSX2 called exit()\n");
    if (s_real_exit) s_real_exit(status);
    // If s_real_exit wasn't captured, fallback
    _exit(status);
}

void _exit(int status) {
    RawWrite("[ExitWrapper] PCSX2 called _exit()\n");
    if (s_real__exit) s_real__exit(status);
    // Fallback to abort so our crash handler can catch it
    abort();
}
