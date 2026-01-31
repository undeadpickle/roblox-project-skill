# PROJECT_NAME

## Overview

Brief description of what this project does.

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
