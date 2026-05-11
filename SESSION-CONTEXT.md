# AIO-Toolkit Session Context

This file is a fast-start context brief for future sessions.

## What this repo is

A Windows diagnostics + repair toolkit centered on two PowerShell scripts:

- Core engine for data collection, scoring, and optional repair actions.
- WPF GUI for launching scans, showing live progress, visualizing findings, and triggering selected repairs.

## Primary execution flow

1. Official launcher batch starts the unified PS1 entrypoint.
2. Unified script routes to GUI mode by default and ensures elevation.
3. GUI starts core script as a child PowerShell process.
4. Core writes log artifacts and live snapshot files.
5. GUI polls those snapshot files and updates progress + tabs.
6. Core writes final diagnostic XML and ranked analysis text.
7. GUI loads final results and enables repair workflows.

## Key files and responsibilities

- Cipher-System-Check-v7.ps1
  - Unified public entrypoint.
  - Supports Mode Gui/Core/Test and elevation handoff.
  - Launches GUI script or invokes core directly.

- Cipher-System-Check-v7-Core.ps1
  - Main diagnostics engine.
  - Collects system, storage, event, and integrity data.
  - Writes:
    - diagnostic_results.xml
    - analysis_ranked.txt
    - progress_snapshot.json
    - progress_snapshot.txt
    - results_incremental.json
  - Supports switches like RunRepair, RunNetworkReset, RunTdrTweak, RunMemDiag, RunDefenderScan, RunWindowsUpdate, TestMode.

- Cipher-System-Check-v7-GUI.ps1
  - WPF dashboard and run orchestration.
  - Starts/stops core process, tracks live progress, binds result grids/cards.
  - Handles manual repairs + automation mode actions.

- Cipher-System-Check-Config.psd1
  - Central behavior config for logging, polling interval, command timeout, feature flags, module toggles, automation modes, and safety profiles.

- Cipher-System-Check-v7-Launcher.bat
  - Official launcher for end users.
  - Calls the unified entry script.

- tools/parse_check.ps1
  - PowerShell parser sanity check for core + GUI scripts.

- fix_glyphs.ps1
  - Cleanup helper for problematic GUI glyph/font artifacts.

## Branch history summary (main -> current branch)

Base commit on main:

- 177ad15: initial v7 toolkit import.

Branch commits and intent:

### 5978090 - Fix GUI diagnostics workflow and cleanup scripts

- Why: stabilize GUI/core interaction and remove noisy tracked artifacts.
- What changed:

  - Added live progress plumbing in GUI (snapshot/incremental readers, timer loop, status helpers, orchestrated run flow).
  - Improved run workflows (diagnostics, selected repairs, auto modes).
  - Cleaned repository noise (.gitignore added; transient log files removed from tracking).
  - Updated helper scripts for parse checking and glyph cleanup.
- Outcome: branch moved from mostly static UI to active run orchestration with live status.

### af01199 - Modernize diagnostics dashboard and SSD health view

- Why: make dashboard more actionable and add richer storage visibility.
- What changed:

  - Significant UI modernization in GUI layout/components.
  - Added card-style SSD health rendering + helper functions.
  - Core improvements around reliability counters and progress/result snapshot writing behavior.
- Outcome: better UX plus richer per-drive insight during and after scans.

### ee11a4c - Populate all diagnostic result tabs

- Why: tabs existed but needed consistent empty states and population logic.
- What changed:

  - Added section headers/empty-state text blocks for WHEA, TDR, reboot, storage tabs.
  - Introduced reusable grid-binding helper paths.
  - Incremental and final result mapping now updates all major tabs, not only SSD panel.
- Outcome: complete end-to-end tab population and clearer no-data messaging.

### 0c187ed - Polish dark theme controls

- Why: improve dark theme readability, consistency, and control behavior.
- What changed:

  - Refined accent palette, button/foreground contrast, text selection colors.
  - Added custom scrollbar and combo box templates.
  - Replaced non-ASCII arrow glyphs with ASCII-friendly alternatives in some controls.
- Outcome: cleaner, more legible visual system and fewer font/glyph edge cases.

### e56987c - Fix ItemsSource binding for result updates

- Why: inconsistent grid updates from scalar/enumerable/object edge cases.
- What changed:

  - Hardened item normalization and collection wrapping for WPF binding.
  - Ensured helper functions return collection-safe values.
  - Added guard rails around live tick updates.
- Outcome: more reliable real-time and post-run data binding.

### bb70f06 - Harden GUI launch and status handling

- Why: improve startup robustness and avoid stale/overflowed status state.
- What changed:

  - Added host resolution logic (powershell.exe/pwsh fallback).
  - Added cleanup of stale live-run files before new run.
  - Wrapped run flow in safer start/finally stop tracking pattern.
  - Added status text truncation + tooltip for long messages.
- Outcome: fewer launch/polling edge failures and more stable status UX.

## Current architecture notes

- GUI depends on file-based IPC from core (progress_snapshot.json + results_incremental.json).
- Atomic-ish write pattern is used by writing temp files then moving into destination.
- Core script runs long external commands (SFC, DISM, CHKDSK scans, etc.), so progress is phase-based and partially estimated.

## Potential risks to keep in mind

- File-based IPC can still hit transient read/write timing races (partially mitigated by retry logic and temp file moves).
- Progress percent and ETA are heuristic, not exact workload metrics.
- GUI and core both changed heavily on this branch; regression risk is mostly around orchestration and binding edge cases.

## Useful local commands

- Parse validation:
  - powershell -ExecutionPolicy Bypass -File tools/parse_check.ps1
- Recent branch history:
  - git log --oneline --decorate --graph -n 30
- Compare branch to main:
  - git diff --stat main..HEAD
