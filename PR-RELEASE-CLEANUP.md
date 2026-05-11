# Release Cleanup: Launcher and Entrypoint Consolidation

## Suggested Commit Message

chore(tooling): consolidate launch flow to one launcher and one public PS1 entrypoint

- add unified entry script with Gui/Core/Test modes and elevation handoff
- keep GUI and Core scripts as internal implementation engines
- point official launcher to unified script
- remove duplicate legacy batch launchers
- update setup verification and user docs to canonical paths
- include unified entry script in parser validation

## Suggested PR Title

Release cleanup: consolidate to one launcher and one public PowerShell entrypoint

## Suggested PR Description

## Summary

This PR performs a release-focused cleanup that simplifies startup and reduces maintenance overhead by standardizing on:

- one official launcher
- one official PowerShell entry script

The existing GUI and Core scripts remain as internal implementation files to preserve behavior and minimize regression risk.

## Why

The repository had multiple batch launchers that performed overlapping tasks with slightly different behavior. That increased support burden and made user instructions inconsistent.

This change provides a single canonical launch path while keeping diagnostic logic stable.

## What Changed

### Unified entrypoint

- Added [Cipher-System-Check-v7.ps1](Cipher-System-Check-v7.ps1)
- Supports mode routing: Gui, Core, Test
- Handles elevation handoff in one place

### Official launcher path

- Updated [Cipher-System-Check-v7-Launcher.bat](Cipher-System-Check-v7-Launcher.bat) to call the unified script

### Removed duplicate launchers

- Deleted [Cipher-System-Check-v7-GUI.bat](Cipher-System-Check-v7-GUI.bat)
- Deleted [LAUNCH-GUI.bat](LAUNCH-GUI.bat)
- Deleted [Open-Cipher-GUI.bat](Open-Cipher-GUI.bat)
- Deleted [Open-Cipher-GUI-Test.bat](Open-Cipher-GUI-Test.bat)

### Setup and docs updates

- Removed legacy verifier batch file (`VERIFY-SETUP.bat`)
- Updated [00-START-HERE.txt](00-START-HERE.txt)
- Updated [Cipher-System-Check-v7-README.md](Cipher-System-Check-v7-README.md)
- Updated [QUICK-REFERENCE.txt](QUICK-REFERENCE.txt)
- Updated [docs/legacy/GUI-IMPROVEMENTS-v7-2.md](docs/legacy/GUI-IMPROVEMENTS-v7-2.md)
- Updated [SESSION-CONTEXT.md](SESSION-CONTEXT.md)

### Tooling

- Updated [tools/parse_check.ps1](tools/parse_check.ps1) to include the unified entry script

## Validation

- Parse checks pass for all scanned scripts
- No remaining references to removed legacy launcher files
- Unified entry script smoke-tested for expected elevation behavior

## Risk Assessment

- Low to moderate risk
- Main behavior is preserved because GUI/Core internals were not collapsed into a monolithic script
- Primary change is startup orchestration simplification and reference cleanup

## Reviewer Checklist

- Confirm launcher starts GUI via unified entry script
- Confirm Core mode and Test mode still work through unified entrypoint
- Confirm setup verification reflects canonical files
- Confirm docs match current launch and run commands

## Follow-up (Optional)

- Add deprecation notes in release notes for users who previously used deleted legacy launcher names
- Consider a future major-version refactor only if full GUI/Core script merge is desired
