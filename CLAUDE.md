# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

pfUI-WeakIcons is a World of Warcraft Vanilla (1.12) addon that extends pfUI to display customizable aura icons (buffs/debuffs), similar to MPOWA. It tracks player buffs, player debuffs, and enemy target debuffs with timer displays and stack counts.

## Development Environment

This is a WoW Vanilla addon using Lua 5.0 syntax (e.g., `string.gfind` instead of `string.gmatch`, `table.getn` instead of `#`). No build system or tests exist - changes are tested in-game by reloading the UI (`/reload`).

**Dependency:** Requires pfUI to be installed. Uses pfUI's API for configuration, GUI, movable frames, and utilities.

## Architecture

### File Structure

- **watcher.lua** - Loaded first. Creates `pfWeakIconsWatcherFrame`, a background frame that polls aura data every 0.4s. Maintains three tables (`playerbuffs`, `playerdebuffs`, `targetdebuffs`) with 32 slots each storing `[timeleft, index, name, texture, stacks]`. Provides `watcher:fetch(name, unit, auraType)` to query auras by name.

- **pfUI-WeakIcons.lua** - Main module registered with `pfUI:RegisterModule()`. Defines GUI configuration, default settings, and the `NewIcon()` factory function that creates individual icon frames.

### Key Concepts

**Active vs Inactive Icons:**
- Active icons show when the aura IS present (with timer/stacks)
- Inactive icons show when the aura is NOT present (reminder to apply)
- Configuration keys: `pbuff`/`edebuff`/`pdebuff` (active) vs `ipbuff`/`iedebuff`/`ipdebuff` (inactive)

**Aura Types:**
- `unit="player", auraType="HELPFUL"` - Player buffs
- `unit="player", auraType="HARMFUL"` - Player debuffs
- `unit="target"` - Target debuffs (also checks target buff slots when debuff slots are full)

**Special Cases:**
- Handles stacking buffs that use separate auras for timer vs stacks (e.g., Jom Gabbar)
- Handles "soft stacks" where the same buff name appears multiple times (e.g., Holy Might from two sources)

### Configuration Storage

Settings stored in `pfUI_config.weakicons` with `#`-delimited spell name lists:
```lua
C.weakicons.pbuff.enabled = "Power Word: Fortitude#Blessing of Kings"
C.weakicons.bufficonsize = "48"
```

### Icon Frame Naming

Frames are named `pfWeakIcon_[a|i]_[spellname]` where `a`=active, `i`=inactive.
