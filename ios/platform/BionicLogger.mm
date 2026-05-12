#include "BionicLogger.hpp"
#import <Foundation/Foundation.h>
#include <cstdio>
#include <cstdarg>
#include <ctime>
#include <cstring>
#include <unistd.h>
#include <fcntl.h>

// ── Helper: subsystem enum → C string ──────────────────────────────────────

static const char* SubsystemName(BionicSubsystem s) {
    switch(s) {
        case BionicSubsystem::CORE:  return "CORE ";
        case BionicSubsystem::EE:    return "EE   ";
        case BionicSubsystem::IOP:   return "IOP  ";
        case BionicSubsystem::VU0:   return "VU0  ";
        case BionicSubsystem::VU1:   return "VU1  ";
        case BionicSubsystem::GS:    return "GS   ";
        case BionicSubsystem::SPU2:  return "SPU2 ";
        case BionicSubsystem::CDVD:  return "CDVD ";
        case BionicSubsystem::INPUT: return "INPUT";
        case BionicSubsystem::MEM:   return "MEM  ";
        case BionicSubsystem::CRASH: return "CRASH";
        case BionicSubsystem::WATCH: return "WATCH";
        default:                     return "?????";
    }
}

static const char* LevelName(BionicLevel l) {
    switch(l) {
        case BionicLevel::INFO:  return "INFO ";
        case BionicLevel::WARN:  return "WARN ";
        case BionicLevel::ERROR: return "ERROR";
        case BionicLevel::FATAL: return "FATAL";
        default:                 return "?????";
    }
}

// ── Singleton ──────────────────────────────────────────────────────────────

BionicLogger& BionicLogger::instance() {
    static BionicLogger s_logger;
    return s_logger;
}

BionicLogger::BionicLogger()
    : log_fd(-1)
{
    memset(ring_buffer, 0, sizeof(ring_buffer));
    memset(log_path, 0, sizeof(log_path));

    @autoreleasepool {
        NSString* docs = [NSSearchPathForDirectoriesInDomains(
            NSDocumentDirectory, NSUserDomainMask, YES) firstObject];

        time_t now = time(nullptr);
        struct tm* t = localtime(&now);
        char name[64];
        strftime(name, sizeof(name), "bionics2_%Y-%m-%d_%H-%M.log", t);

        snprintf(log_path, sizeof(log_path), "%s/%s", [docs UTF8String], name);
    }

    log_fd = ::open(log_path, O_WRONLY | O_CREAT | O_TRUNC, 0644);
    if (log_fd < 0)
        log_fd = STDERR_FILENO;

    char hdr[512];
    int n = snprintf(hdr, sizeof(hdr),
        "==================================================\n"
        "  BionicSX2 Diagnostic Log\n"
        "  Path: %s\n"
        "==================================================\n\n",
        log_path);
    if (n > 0)
        write_to_file(hdr, (size_t)n < sizeof(hdr) ? (size_t)n : sizeof(hdr));
}

BionicLogger::~BionicLogger() {
    if (log_fd >= 0 && log_fd != STDERR_FILENO)
        ::close(log_fd);
}

void BionicLogger::write_to_file(const char* data, size_t len) {
    if (data == nullptr || len == 0) return;
    if (log_fd >= 0)
        write(log_fd, data, len);
}

void BionicLogger::log(const char* level, const char* subsystem, const char* message) {
    if (level == nullptr || subsystem == nullptr || message == nullptr) return;

    char time_buf[32];
    time_t now = time(nullptr);
    struct tm* t = localtime(&now);
    strftime(time_buf, sizeof(time_buf), "%H:%M:%S", t);

    char line[1200];
    int n = snprintf(line, sizeof(line), "[%s] [%s] [%s] %s\n",
                     time_buf, level, subsystem, message);
    if (n <= 0 || n >= (int)sizeof(line)) return;
    size_t len = (size_t)n;

    // Ring buffer — atomic wrap-around, no locks
    size_t pos = write_pos.load(std::memory_order_relaxed);
    for (size_t i = 0; i < len; i++)
        ring_buffer[(pos + i) % BUFFER_SIZE] = line[i];
    write_pos.store((pos + len) % BUFFER_SIZE, std::memory_order_release);

    // Immediate write to file descriptor
    write_to_file(line, len);
}

void BionicLogger::emergency_dump() {
    // Async-signal-safe: only snprintf + write, no locks, no allocations
    char buf[4096];
    size_t pos = write_pos.load(std::memory_order_acquire);

    int n = snprintf(buf, sizeof(buf),
        "\n══ EMERGENCY DUMP (ring buffer pos=%zu, size=%zu) ══\n",
        pos, BUFFER_SIZE);
    if (n > 0) {
        write(STDERR_FILENO, buf, (size_t)n < sizeof(buf) ? (size_t)n : sizeof(buf));
        if (log_fd >= 0 && log_fd != STDERR_FILENO)
            write(log_fd, buf, (size_t)n < sizeof(buf) ? (size_t)n : sizeof(buf));
    }

    write(STDERR_FILENO, ring_buffer, BUFFER_SIZE);
    if (log_fd >= 0 && log_fd != STDERR_FILENO)
        write(log_fd, ring_buffer, BUFFER_SIZE);

    n = snprintf(buf, sizeof(buf), "\n══ END DUMP ══\n");
    if (n > 0) {
        write(STDERR_FILENO, buf, (size_t)n < sizeof(buf) ? (size_t)n : sizeof(buf));
        if (log_fd >= 0 && log_fd != STDERR_FILENO)
            write(log_fd, buf, (size_t)n < sizeof(buf) ? (size_t)n : sizeof(buf));
    }
}

void BionicLogger::flush() {
    if (log_fd >= 0 && log_fd != STDERR_FILENO)
        fsync(log_fd);
}

// ── Free-function wrappers ────────────────────────────────────────────────

void BionicLog_Init() {
    BionicLogger::instance();
}

void BionicLog_Write(BionicSubsystem sub, BionicLevel level, const char* fmt, ...) {
    char msg[1024];
    va_list args;
    va_start(args, fmt);
    vsnprintf(msg, sizeof(msg), fmt, args);
    va_end(args);
    BionicLogger::instance().log(LevelName(level), SubsystemName(sub), msg);
}

void BionicLog_Flush() {
    BionicLogger::instance().flush();
}

void BionicLog_DumpLastLines(int) {
    BionicLogger::instance().emergency_dump();
}

const char* BionicLog_GetPath() {
    return BionicLogger::instance().get_path();
}
