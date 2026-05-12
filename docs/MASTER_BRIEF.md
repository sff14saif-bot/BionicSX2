# BionicSX2 — Master Engineering Brief

> Primary Reference Document — Consult Before Every Action

## Mission Statement

The goal is NOT a compilable IPA.
The goal is a PS2 emulator that runs games at maximum performance on Apple Silicon.

## Mandatory Constraints

1. NO PATCHING. NO GUESSING.
2. READ BEFORE YOU WRITE.
3. BATCH ALL CHANGES — ONE COMMIT PER LOGICAL FIX.
4. STUBS ARE A DIAGNOSTIC TOOL — NOT A SOLUTION.
5. NEVER GUESS FUNCTION SIGNATURES.
6. NEVER DESIGN FOR THE BUILD — DESIGN FOR THE RUNTIME.
7. NO BLIND ANDROID-TO-iOS TRANSPLANTS.

## Phase Roadmap

| Phase | Goal | Success Criterion |
|-------|------|-------------------|
| 0 | Blueprint & Audit | Repo structure complete, no code yet |
| 1 | Build System | Compiles for iOS, zero Android deps |
| 2 | Platform Layer | All stubs replaced with real iOS APIs |
| 3 | BIOS Boot | BIOS screen on physical device |
| 4 | Game Execution | One title reaches in-game (Interpreter) |
| 5 | ARM64 JIT | VIXL recompiler functional |
| 6 | Metal Optimization | 60 FPS on A15+ |
| 7 | UI & Distribution | TestFlight ready |

## CPU Strategy

- Interpreter first (correctness)
- ARM64 JIT via VIXL (performance)
- VU0/VU1 via ARMSX2 NEON-adapted code
- JIT memory: pthread_jit_write_protect_np() — iOS 14.2+
- Entitlement: com.apple.security.cs.allow-jit

## Known Failure Patterns (from prior work)

1. ios_stubs.cpp symbol loops → run nm | c++filt first
2. Signature mismatches → derive from headers, never from memory
3. Edit-without-read regression → read full file before any edit
4. CocoaTools in .cpp → must be in .mm files
5. Global variable type mismatches → derive from header declarations
6. One-symbol-per-commit waste → batch all fixes, one commit

## Debugging Order (MANDATORY)

1. Find the FIRST compiler error
2. Fix ONLY that root cause
3. Rebuild fully
4. Re-evaluate — never chase cascading errors first

## Key Sources

- PCSX2 macOS: https://github.com/pcsx2/pcsx2
- ARMSX2 Android: https://github.com/ARMSX2/ARMSX2
