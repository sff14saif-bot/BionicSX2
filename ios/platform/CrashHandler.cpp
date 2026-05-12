#include "BionicLogger.hpp"
#include <signal.h>
#include <execinfo.h>
#include <unistd.h>
#include <cstdio>
#include <cstring>

// Saved at install time — avoids calling BionicLogger::instance() from signal handler
static int          s_crash_log_fd   = -1;
static const char*  s_crash_ring_buf = nullptr;
static size_t       s_crash_buf_size = 0;

static const char* SignalName(int sig) {
    switch(sig) {
        case SIGSEGV: return "SIGSEGV (Segmentation Fault)";
        case SIGABRT: return "SIGABRT (Abort)";
        case SIGBUS:  return "SIGBUS  (Bus Error)";
        case SIGILL:  return "SIGILL  (Illegal Instruction)";
        case SIGFPE:  return "SIGFPE  (Floating Point Exception)";
        default:      return "UNKNOWN SIGNAL";
    }
}

// Async-signal-safe: only snprintf + write, no allocations
static void RawWrite(const char* msg) {
    if (msg == nullptr) return;
    size_t len = strlen(msg);
    if (len == 0) return;
    write(STDERR_FILENO, msg, len);
    if (s_crash_log_fd >= 0 && s_crash_log_fd != STDERR_FILENO)
        write(s_crash_log_fd, msg, len);
}

static void CrashHandler(int sig, siginfo_t* info, void* /*ctx*/) {
    char buf[512];
    int n;

    n = snprintf(buf, sizeof(buf),
        "==================================================\n"
        "SIGNAL RECEIVED: %s (sig=%d)\n",
        SignalName(sig), sig);
    if (n > 0 && n < (int)sizeof(buf)) RawWrite(buf);

    if (info) {
        n = snprintf(buf, sizeof(buf), "Fault address: %p\nSignal code:   %d\n",
                     info->si_addr, info->si_code);
        if (n > 0 && n < (int)sizeof(buf)) RawWrite(buf);
    }

    void* frames[32];
    int count = backtrace(frames, 32);

    n = snprintf(buf, sizeof(buf), "── Stack Trace (%d frames) ──────\n", count);
    if (n > 0 && n < (int)sizeof(buf)) RawWrite(buf);

    // backtrace_symbols_fd is async-signal-safe (no malloc)
    backtrace_symbols_fd(frames, count, STDERR_FILENO);
    if (s_crash_log_fd >= 0 && s_crash_log_fd != STDERR_FILENO)
        backtrace_symbols_fd(frames, count, s_crash_log_fd);

    // Ring buffer dump
    if (s_crash_ring_buf && s_crash_buf_size > 0) {
        n = snprintf(buf, sizeof(buf), "\n══ RING BUFFER DUMP ══\n");
        if (n > 0 && n < (int)sizeof(buf)) RawWrite(buf);

        write(STDERR_FILENO, s_crash_ring_buf, s_crash_buf_size);
        if (s_crash_log_fd >= 0 && s_crash_log_fd != STDERR_FILENO)
            write(s_crash_log_fd, s_crash_ring_buf, s_crash_buf_size);

        n = snprintf(buf, sizeof(buf), "\n══ END DUMP ══\n");
        if (n > 0 && n < (int)sizeof(buf)) RawWrite(buf);
    }

    if (s_crash_log_fd >= 0 && s_crash_log_fd != STDERR_FILENO)
        fsync(s_crash_log_fd);

    signal(sig, SIG_DFL);
    raise(sig);
}

void CrashHandler_Install() {
    // Save BionicLogger state at install time — avoids calling into
    // the logger from the signal handler (Meyer's singleton uses a
    // mutex internally, which can deadlock in signal context).
    {
        BionicLogger& log = BionicLogger::instance();
        s_crash_log_fd   = log.get_log_fd();
        s_crash_ring_buf = log.get_ring_buffer();
        // Use full buffer size for emergency dump
        s_crash_buf_size = 65536;
    }

    struct sigaction sa;
    memset(&sa, 0, sizeof(sa));
    sa.sa_sigaction = CrashHandler;
    sa.sa_flags = SA_SIGINFO;
    sigemptyset(&sa.sa_mask);

    sigaction(SIGSEGV, &sa, nullptr);
    sigaction(SIGABRT, &sa, nullptr);
    sigaction(SIGBUS,  &sa, nullptr);
    sigaction(SIGILL,  &sa, nullptr);
    sigaction(SIGFPE,  &sa, nullptr);

    BIONIC_INFO(CRASH, "Crash handler installed (SIGSEGV/SIGABRT/SIGBUS/SIGILL/SIGFPE)");
}
