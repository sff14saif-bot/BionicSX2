#pragma once
#include <cstdint>
#include <cstddef>
#include <atomic>

// Subsystems
enum class BionicSubsystem : uint8_t {
    CORE   = 0,
    EE     = 1,
    IOP    = 2,
    VU0    = 3,
    VU1    = 4,
    GS     = 5,
    SPU2   = 6,
    CDVD   = 7,
    INPUT  = 8,
    MEM    = 9,
    CRASH  = 10,
    WATCH  = 11,
};

// Log levels
enum class BionicLevel : uint8_t {
    INFO  = 0,
    WARN  = 1,
    ERROR = 2,
    FATAL = 3,
};

// Pure-C ring-buffer logger — zero STL, zero fmt, zero allocations.
// Singleton is a Meyer's static local; never returns null.
class BionicLogger {
public:
    static constexpr size_t BUFFER_SIZE = 65536;

    static BionicLogger& instance();

    void log(const char* level, const char* subsystem, const char* message);

    // Async-signal-safe ring buffer dump
    void emergency_dump();

    int         get_log_fd()    const { return log_fd; }
    const char* get_ring_buffer() const { return ring_buffer; }
    size_t      get_write_pos() const { return write_pos.load(std::memory_order_acquire); }
    const char* get_path()      const { return log_path; }

    void flush();

private:
    BionicLogger();
    ~BionicLogger();
    BionicLogger(const BionicLogger&) = delete;
    BionicLogger& operator=(const BionicLogger&) = delete;

    char                ring_buffer[BUFFER_SIZE];
    std::atomic<size_t> write_pos{0};
    int                 log_fd;
    char                log_path[512];

    void write_to_file(const char* data, size_t len);
};

// Free-function wrappers for backward compatibility
void BionicLog_Init();
void BionicLog_Write(BionicSubsystem sub, BionicLevel level, const char* fmt, ...)
    __attribute__((format(printf, 3, 4)));
void BionicLog_Flush();
void BionicLog_DumpLastLines(int count);
void BionicLog_Heartbeat();
const char* BionicLog_GetPath();

// Macros
#define BIONIC_INFO(sub, fmt, ...)  BionicLog_Write(BionicSubsystem::sub, BionicLevel::INFO,  fmt, ##__VA_ARGS__)
#define BIONIC_WARN(sub, fmt, ...)  BionicLog_Write(BionicSubsystem::sub, BionicLevel::WARN,  fmt, ##__VA_ARGS__)
#define BIONIC_ERROR(sub, fmt, ...) BionicLog_Write(BionicSubsystem::sub, BionicLevel::ERROR, fmt, ##__VA_ARGS__)
#define BIONIC_FATAL(sub, fmt, ...) BionicLog_Write(BionicSubsystem::sub, BionicLevel::FATAL, fmt, ##__VA_ARGS__)
