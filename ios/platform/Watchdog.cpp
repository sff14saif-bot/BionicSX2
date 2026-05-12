#include <pthread.h>
#include <atomic>
#include <unistd.h>
#include <ctime>
#include <cstdio>
#include <cstring>

static std::atomic<bool>     s_running{false};
static std::atomic<uint64_t> s_lastHeartbeat{0};
static pthread_t             s_thread;
static int                   s_log_fd = -1;
static constexpr int         HANG_TIMEOUT_SEC = 5;

static void RawWrite(const char* msg) {
    if (msg == nullptr) return;
    size_t len = strlen(msg);
    if (len == 0) return;
    write(STDERR_FILENO, msg, len);
    if (s_log_fd >= 0 && s_log_fd != STDERR_FILENO)
        write(s_log_fd, msg, len);
}

static uint64_t NowSec() {
    return (uint64_t)time(nullptr);
}

void BionicLog_Heartbeat() {
    s_lastHeartbeat.store(NowSec(), std::memory_order_relaxed);
}

static void* WatchdogThread(void*) {
    char buf[512];

    int n = snprintf(buf, sizeof(buf), "[WATCH] Watchdog started (timeout=%ds)\n", HANG_TIMEOUT_SEC);
    if (n > 0 && n < (int)sizeof(buf)) RawWrite(buf);

    s_lastHeartbeat.store(NowSec(), std::memory_order_relaxed);

    while (s_running.load()) {
        sleep(1);
        uint64_t last = s_lastHeartbeat.load(std::memory_order_relaxed);
        uint64_t now  = NowSec();
        uint64_t diff = now - last;

        if (diff >= HANG_TIMEOUT_SEC) {
            n = snprintf(buf, sizeof(buf), "[WATCH] HANG DETECTED - No heartbeat for %llu seconds\n",
                        (unsigned long long)diff);
            if (n > 0 && n < (int)sizeof(buf)) RawWrite(buf);
            s_lastHeartbeat.store(now, std::memory_order_relaxed);
        }
    }

    return nullptr;
}

void Watchdog_Start() {
    if (s_running.load()) return;
    s_log_fd = STDERR_FILENO;
    s_running.store(true);
    pthread_create(&s_thread, nullptr, WatchdogThread, nullptr);
}

void Watchdog_Stop() {
    if (!s_running.load()) return;
    s_running.store(false);
    pthread_join(s_thread, nullptr);
    s_log_fd = -1;
}
