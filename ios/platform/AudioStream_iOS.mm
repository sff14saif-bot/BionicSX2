// BionicSX2 — iOS Audio Stream Implementation
// Phase 2 implementation target
// Backend: AVAudioEngine / AudioUnit (CoreAudio)
// EXCLUDED: Oboe (Android-only — never use on iOS)
// Reference: PCSX2 macOS CoreAudio backend → adapted for iOS AVAudioSession

#include <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

static AVAudioEngine* g_engine = nil;
static AVAudioPlayerNode* g_playerNode = nil;
static AVAudioFormat* g_format = nil;

// TODO Phase 2: Initialize AVAudioSession before any audio work
// This step is MANDATORY on iOS — absent on macOS
// Category: AVAudioSessionCategoryPlayback
// Mode:     AVAudioSessionModeDefault
// Options:  AVAudioSessionCategoryOptionMixWithOthers (optional)
//
// Objective-C call — move to AudioStream_iOS.mm if AVAudioSession
// Objective-C headers are needed directly here.
// For now: stub with correct TODO for Phase 2 implementation.
void AudioStream_InitSession() {
    AVAudioSession* session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    [session setActive:YES error:nil];
    [session setPreferredSampleRate:48000 error:nil];
}

// TODO Phase 2: Create and start AVAudioEngine
// macOS used: AudioUnit directly
// iOS: AVAudioEngine wraps AudioUnit — identical output quality
// Sample rate: 48000 Hz (PS2 SPU2 native)
// Format: PCM float32, stereo (2 channels)
void AudioStream_Start() {
    AVAudioSession* session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    [session setActive:YES error:nil];

    g_engine = [[AVAudioEngine alloc] init];
    g_playerNode = [[AVAudioPlayerNode alloc] init];
    [g_engine attachNode:g_playerNode];
    g_format = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatFloat32
                                                 sampleRate:48000
                                                  channels:2
                                               interleaved:NO];
    [g_engine connect:g_playerNode to:[g_engine mainMixerNode] format:g_format];
    [g_engine startAndReturnError:nil];
}

// TODO Phase 2: Stop and release AVAudioEngine
void AudioStream_Stop() {
    [g_engine stop];
    [g_engine reset];
    g_engine = nil;
    g_playerNode = nil;
    g_format = nil;
}

// TODO Phase 2: Push audio samples from SPU2 to AVAudioEngine buffer
// Called from SPU2 thread — must be thread-safe
void AudioStream_WriteSamples(const float* samples, int count) {
    if (!g_playerNode || !g_format || count <= 0) return;

    AVAudioFrameCount frames = (AVAudioFrameCount)count;
    AVAudioPCMBuffer* buffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:g_format frameCapacity:frames];
    if (!buffer) return;

    buffer.frameLength = frames;

    float* left = buffer.floatChannelData[0];
    float* right = buffer.floatChannelData[1];
    for (int i = 0; i < count; i++) {
        left[i] = samples[i * 2];
        right[i] = samples[i * 2 + 1];
    }

    [g_playerNode scheduleBuffer:buffer completionHandler:nil];
}
