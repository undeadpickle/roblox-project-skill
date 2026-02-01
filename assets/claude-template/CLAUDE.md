# PROJECT_NAME

## Overview

Brief description of what this project does.

> Generated with [roblox-dev skill](https://github.com/undeadpickle/roblox-project-skill) vSKILL_VERSION

## Project Profile

> Captured during initial setup — informs architecture decisions.

- **Intent:** PROJECT_INTENT
- **Source of truth:** PROJECT_SOURCE_OF_TRUTH
- **Team:** PROJECT_TEAM_SHAPE
- **Core loop:** PROJECT_GAME_LOOP
- **Session format:** PROJECT_SESSION_FORMAT
- **Platform:** PROJECT_PLATFORM
- **Exploit sensitivity:** PROJECT_EXPLOIT_SENSITIVITY
- **Persistence:** PROJECT_PERSISTENCE
- **Structure:** PROJECT_STRUCTURE

**Auto-included modules:** PROJECT_AUTO_MODULES

## Build Roadmap

> Suggested build order based on your game type. Tackle Phase 1 first for a playable vertical slice.

### Phase 1: Core Loop
PROJECT_ROADMAP_PHASE1

### Phase 2: Depth
PROJECT_ROADMAP_PHASE2

### Phase 3: Engagement
PROJECT_ROADMAP_PHASE3

**Current focus:** Phase 1 — get the core loop working first.

> Ask Claude: "Help me implement [next item]" to continue.

## Architecture

### Code Organization
- `src/client/` — Client-side code (runs on player's device)
- `src/server/` — Server-side code (runs on Roblox servers)
- `src/shared/` — Shared modules (used by both client and server)
- `src/replicatedFirst/` — Early client code (loading screens, pre-game setup)
- `Packages/` — Wally dependencies (auto-generated, don't edit)

### Key Modules
- `GameConfig` — Central configuration values
- `Remotes` — Client-server communication helpers
- `Logger` — Debug logging with [Server]/[Client] prefixes

## Development Workflow

```bash
# Start Rojo sync
rojo serve

# In Studio: Rojo plugin → Connect

# Before committing
selene src/
stylua --check src/
```

## Documentation

**Primary (Context7 MCP):**
- `/websites/create_roblox` — Tutorials, guides, best practices
- `/websites/create_roblox_reference_engine` — Engine API reference

**Fallback (if Context7 unavailable):**
- Engine API: https://create.roblox.com/docs/reference/engine
- Guides: https://create.roblox.com/docs
- Use WebSearch/WebFetch with `site:create.roblox.com` for specific lookups

## Conventions

- See `.claude/rules/` for Luau style guide
- Use `Logger` module instead of raw `print()`
- All remote events go through `Remotes` module

## Learnings & Gotchas

**AI agents: Update this section when you discover something doesn't work as expected, is outdated, or has a better alternative. Check this section before implementing to avoid repeating mistakes.**

Format: `- [Category] Brief description of what doesn't work and what to do instead`

<!-- Add learnings below -->
