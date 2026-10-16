RetroBox iOS - Lite build patch

Files:
- Provenance.xcodeproj/project.pbxproj
- codemagic.yaml

Changes:
- In Provenance-Lite ONLY, remove link/embed entries for PVAzahar (Nintendo 3DS), PVEmuThree (Nintendo 3DS), and PVfMSX (MSX).
- Preserve original core sources and all other Xcode targets.
- Switch Codemagic from Provenance to Provenance-Lite scheme, retaining macro and plugin validation flags.

LIMITATIONS:
- This is a targeted first-stage reduction, NOT a verified five-system-only configuration.
- Other unwanted emulator cores may still be pulled in by SwiftPM packages, scripts, or modules.
- No iOS build has been run here; compilation and Atari/NES/SNES/Genesis/Arcade operation are NOT verified.
- To revert, restore the two original files from Git history.

Apply on a new branch. Copy each file to the exact relative path above, replacing the original. Commit both, then run one Codemagic test.
