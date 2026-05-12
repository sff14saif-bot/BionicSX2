# BionicSX2

PS2 emulator for iOS/iPadOS — ARM64 native port of PCSX2.

## Architecture
- Base: PCSX2 macOS Metal backend
- CPU: ARM64 JIT via VIXL (Phase 5)
- GPU: Metal renderer (GSDeviceMTL)
- Audio: AVAudioEngine / AudioUnit
- Target: iOS 14.2+ / Apple Silicon

## Phases
- [x] Phase 0 — Blueprint & repo structure
- [ ] Phase 1 — Build system foundation
- [ ] Phase 2 — Platform layer (iOS APIs)
- [ ] Phase 3 — BIOS boot
- [ ] Phase 4 — Game execution (Interpreter)
- [ ] Phase 5 — ARM64 JIT via VIXL
- [ ] Phase 6 — Metal optimization
- [ ] Phase 7 — UI & distribution

## Build
GitHub Actions (macOS runner) → unsigned IPA
See `.github/workflows/build-ipa.yml`

## Reference
- PCSX2: https://github.com/pcsx2/pcsx2
- ARMSX2: https://github.com/ARMSX2/ARMSX2
EOF
