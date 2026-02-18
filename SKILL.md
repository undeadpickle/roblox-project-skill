---
name: roblox-dev
description: Roblox game development with professional tooling (Rojo, Wally, Luau). Use for any Roblox development question including debugging issues, package selection, code patterns, MCP setup, OR when starting a new project. Covers Luau scripting, tool configuration, and Studio workflows.
---

# Roblox Development

Professional Roblox game development with Rojo, Wally, and modern Luau patterns.

## Quick Navigation

- **Slash command:** `/roblox-dev:new-project` — Interactive wizard for new projects
- **With game type:** `/roblox-dev:new-project tycoon` — Quick-start with genre defaults
- [Reference Routing](#reference-routing) — Which docs answer which questions
- [Project Setup](#project-setup-workflow) — Create a new project from scratch
- [Testing Guidelines](#testing-guidelines) — When and how to write tests

---

## Reference Routing

Consult these files based on the topic:

| User asks about... | Consult first |
|-------------------|---------------|
| "Set up a tycoon", "make a tycoon game" | `references/game-types/tycoon.md` → then [PROJECT_WIZARD.md](PROJECT_WIZARD.md) quick-start flow |
| "Set up an obby", "parkour game", "platformer" | `references/game-types/obby.md` → then [PROJECT_WIZARD.md](PROJECT_WIZARD.md) quick-start flow |
| "Pet simulator", "simulator game", "clicker" | `references/game-types/simulator.md` → then [PROJECT_WIZARD.md](PROJECT_WIZARD.md) quick-start flow |
| "Arena game", "PvP", "shooter", "competitive" | `references/game-types/combat-arena.md` → then [PROJECT_WIZARD.md](PROJECT_WIZARD.md) quick-start flow |
| **Starting a new project** (generic) | Start with [PROJECT_WIZARD.md](PROJECT_WIZARD.md) for foundation questions, then [Project Setup Workflow](#project-setup-workflow) |
| Roblox API, engine classes, how does X work | Context7: `/websites/create_roblox_reference_engine` → fallback: `create.roblox.com/docs/reference/engine` |
| Tutorials, guides, best practices, "how to" | Context7: `/websites/create_roblox` → fallback: `create.roblox.com/docs` |
| Package recommendations, "what library for X", dependencies | `references/libraries.md` |
| Rojo sync issues, Wally package errors, Git problems | `references/gotchas-tooling.md` then `references/debugging.md` |
| Runtime errors, memory leaks, DataStores, "works in Studio breaks in prod" | `references/gotchas-runtime.md` then `references/debugging.md` |
| Type errors, LSP config, strict mode, sourcemap issues | `references/gotchas-lsp.md` |
| Something not working (unclear category) | `references/gotchas.md` (index) → load the relevant category file |
| Code style, naming conventions, file organization | `references/luau-conventions.md` |
| How to implement patterns (services, cleanup, validation, etc.) | `references/luau-patterns.md` |
| AI behavior, state machines, pathfinding, detection | `references/patterns/ai-systems.md` |
| Audio, dynamic music, 3D sound | `references/patterns/audio-systems.md` |
| Camera shake, post-processing, screen effects | `references/patterns/camera-effects.md` |
| Spectate, revive, multiplayer sync | `references/patterns/multiplayer-systems.md` |
| Anti-exploit, movement validation, rate limiting | `references/patterns/anti-exploit.md` |
| Proximity triggers, interactables, cooldowns | `references/patterns/trigger-systems.md` |
| Tool version conflicts, Rokit pinning, compatibility | `references/tool-versions.md` |
| MCP setup, Studio connection, AI-assisted development | `references/mcp-setup.md` |
| Images, sounds, models, asset workflows | `references/asset-pipeline.md` |
| Testing, Jest Lua, writing tests | `references/testing.md` |
| "What should I build next?", progress guidance | Check project's `CLAUDE.md` roadmap section |

**Starter code in `assets/starter-code/`** shows recommended patterns:
- `init.client.luau` / `init.server.luau` — Entry point structure
- `Remotes.luau` — Remote event organization
- `DataManager.luau` — ProfileStore + Promise integration
- `Logger.luau` — Contextual logging with prefixes
- `RateLimiter.luau` — Protect remotes from exploit spam
- `Analytics.luau` — Track player events for engagement metrics
- `ErrorReporter.luau` — Capture and report unhandled errors

---

## Project Setup Workflow

**Use this section when starting a new Roblox project from scratch.**

> **Start with the wizard:** Before running these steps, complete the [Foundation Questions in PROJECT_WIZARD.md](PROJECT_WIZARD.md). The wizard determines your project profile (intent, authority model, persistence needs) which informs what gets generated below. If you've already completed the wizard, proceed to Step 2.

### Prerequisites

Verify before starting:
- **Rokit** installed (`rokit --version`)
- **VS Code** with project folder open
- **Roblox Studio** installed

If Rokit missing:
```bash
# macOS/Linux
curl -sSf https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.sh | bash

# Windows (PowerShell)
irm https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.ps1 | iex
```

### Step 1: Gather Project Info

**Ask the user:**

1. **Project name?** — Default: folder name in PascalCase

2. **Language?**
   - Luau (default)
   - roblox-ts (TypeScript)

If roblox-ts selected, inform user this skill sets up Luau projects only. Point them to [roblox-ts docs](https://roblox-ts.com/) for TypeScript setup.

### Step 2: Create Folder Structure

```bash
mkdir -p src/client/modules src/server/modules src/shared src/replicatedFirst Packages ServerPackages .vscode .claude/rules
touch Packages/.gitkeep ServerPackages/.gitkeep
```

### Step 3: Initialize Git & Tools

```bash
git init
```

**Check if Rokit tools are already globally installed:**
```bash
rojo --version && wally --version && stylua --version && selene --version
```

- **If all four pass:** Tools are globally available — skip `rokit init` and `rokit add`, proceed to `wally init`.
- **If any fail:** Install via Rokit:
  ```bash
  rokit init
  rokit add rojo-rbx/rojo
  rokit add UpliftGames/wally
  rokit add JohnnyMorganz/StyLua
  rokit add Kampfkarren/selene
  ```
  Then re-verify all four tools before continuing.

Initialize Wally:
```bash
wally init
```

### Step 4: Copy Config Files

Copy from `assets/config/` to project root:
- `default.project.json` → Replace `PROJECT_NAME` with user's project name
- `selene.toml`
- `stylua.toml`
- `.luaurc.json`
- `.gitignore` (from `gitignore.txt`)
- `.gitattributes` (from `gitattributes.txt`)

Copy `assets/vscode/` contents to `.vscode/`:
- `settings.json`
- `extensions.json`

### Step 5: Copy Starter Code

Copy from `assets/starter-code/`:

| Source File | Destination | Notes |
|-------------|-------------|-------|
| `init.client.luau` | `src/client/init.client.luau` | Client entry point |
| `init.server.luau` | `src/server/init.server.luau` | Server entry point |
| `GameConfig.luau` | `src/shared/GameConfig.luau` | Replace `PROJECT_NAME` |
| `Remotes.luau` | `src/shared/Remotes.luau` | Remote event helpers |
| `Logger.luau` | `src/shared/Logger.luau` | Logging utility |

### Step 6: Create Project Files

Copy `assets/claude-template/CLAUDE.md` to project root. Replace:
- `PROJECT_NAME` with user's project name
- `SKILL_VERSION` with the version from `VERSION` file (e.g., `1.0.0`)
- `PROJECT_INTENT` with the intent (e.g., "MVP", "Prototype", "Long-lived")
- `PROJECT_SOURCE_OF_TRUTH` with source of truth (e.g., "Git + Rojo", "Studio-first")
- `PROJECT_TEAM_SHAPE` with team info (e.g., "Solo, no PRs", "Small team with PRs")
- `PROJECT_GAME_LOOP` with game loop categories (e.g., "Economy/building (tycoon)")
- `PROJECT_SESSION_FORMAT` with session format (e.g., "Continuous world", "Rounds/matches", "Runs/attempts", "Instanced levels")
- `PROJECT_PLATFORM` with platform target (e.g., "Cross-platform", "Mobile-first", "PC-first", "Gamepad important")
- `PROJECT_EXPLOIT_SENSITIVITY` with sensitivity and implication (e.g., "High → server-authoritative for value changes")
- `PROJECT_PERSISTENCE` with persistence level and implication (e.g., "Core economy → DataManager with schema versioning")
- `PROJECT_STRUCTURE` with structure choice (e.g., "Layered")
- `PROJECT_AUTO_MODULES` with list of auto-included modules (e.g., "DataManager, RateLimiter") or "None" if none

Copy `assets/docs/README.md` to project root. Replace:
- `PROJECT_NAME` with user's project name
- `PROJECT_GAME_LOOP` with game loop categories (e.g., "Economy/building (tycoon)")
- `PROJECT_SESSION_FORMAT` with session format (e.g., "Continuous world", "Rounds/matches")
- `PROJECT_PLATFORM` with platform target (e.g., "Cross-platform", "Mobile-first")
- `PROJECT_STRUCTURE` with structure choice (e.g., "Layered")
- `PROJECT_AUTHORITY_MODEL` with authority posture (e.g., "Server-authoritative for value changes", "Hybrid", "Client-trusted")
- `PROJECT_PERSISTENCE_SUMMARY` with brief persistence description (e.g., "Core economy with ProfileStore", "Light (settings only)", "None")

Copy convention files to `.claude/rules/`:
- `references/luau-conventions.md` → `.claude/rules/luau-conventions.md`
- `references/luau-patterns.md` → `.claude/rules/luau-patterns.md`

### Step 7: Update wally.toml

Edit the generated `wally.toml`:
```toml
[package]
name = "username/project-name"
version = "0.1.0"
registry = "https://github.com/UpliftGames/wally-index"
realm = "shared"
private = true
```

**Note:** `private = true` prevents accidental publishing. See `references/gotchas-tooling.md` for other Wally pitfalls.

### Step 8: Optional — Add Common Packages

**Ask the user:**
> "Want me to add Wally packages? Common options:
> - **Core utilities:** Promise, GoodSignal, Trove
> - **Data persistence:** ProfileStore
> - **UI framework:** Fusion (typically vendored, not via Wally)"

**Before writing wally.toml, look up current versions:**

Wally requires explicit version specifiers — never write a package entry without a version. Use `brave-search` to search `wally.run {author} {package}`, or fetch `https://wally.run/package/{author}/{package}` directly to get the current latest.

Use **caret syntax** (`^major.minor.patch`) — not exact pins. This follows community standard and allows compatible updates:
- `^4.0.0` — gets 4.x.x, never 5.0.0 (safe for major-version API stability)
- `^0.3.1` — gets 0.3.x only (pre-1.0: caret is conservative within the minor)

Based on response, add to `wally.toml` (versions shown are examples — **verify current before writing**):

**Core utilities (recommended):**
```toml
[dependencies]
Promise = "evaera/promise@^4.0.0"
GoodSignal = "stravant/goodsignal@^0.3.1"
Trove = "sleitnick/trove@^1.8.0"
```

**With data persistence:**
```toml
[dependencies]
Promise = "evaera/promise@^4.0.0"
GoodSignal = "stravant/goodsignal@^0.3.1"
Trove = "sleitnick/trove@^1.8.0"

[server-dependencies]
ProfileStore = "lm-loleris/profilestore@^1.0.3"
```

Then run:
```bash
wally install
```

**For detailed library recommendations:** See `references/libraries.md`.

### Step 9: Note — MCP Setup

MCP is covered at Step 12. Continue to optional modules now.

### Step 10: Apply Optional Modules

Apply modules based on the profile from the wizard. If no wizard was run, ask the user using the decision table below.

**Module decision table:**

| Module | Auto-include when... | Ask if... |
|--------|---------------------|-----------|
| DataManager | `persistence` = `core` | persistence is `light` or unclear |
| RateLimiter | `exploitSensitivity` = `high`, OR `medium` + persistence ≠ `none` | exploit sensitivity is unclear |
| ErrorReporter | `intent` = `long-lived` | intent is `mvp` and game will have live players |
| Analytics | `intent` = `long-lived` AND persistence ≠ `none` | user asks for behavior tracking |
| Jest Lua | User explicitly requests it | project has complex business logic worth testing |

**For most games:** DataManager + ErrorReporter is a safe default starting set.

### Asking About Modules

When a module is in the "Ask if" column, use AskUserQuestion with three options:

```json
{
  "question": "Should I include [ModuleName]?",
  "header": "[ModuleName]",
  "options": [
    { "label": "Yes, include it", "description": "[one-line plain-language description of what it does]" },
    { "label": "Skip it for now", "description": "You can add it later if you need it" },
    { "label": "Tell me more", "description": "Explain what it does, the trade-offs, and whether I actually need it" }
  ],
  "multiSelect": false
}
```

If they pick **Tell me more**: explain the module in plain, non-technical language — what problem it solves, what happens if you don't have it, and a direct recommendation based on their project profile. Then ask again with just Yes / Skip. Don't hedge; give a real opinion.

---

#### DataManager (ProfileStore + Promise integration)

If auto-selected or user confirms:
1. Copy `assets/starter-code/DataManager.luau` to `src/server/modules/DataManager.luau`

#### RateLimiter (RemoteEvent exploit protection)

If auto-selected or user confirms:
1. Copy `assets/starter-code/RateLimiter.luau` to `src/server/modules/RateLimiter.luau`

#### ErrorReporter (Global error capture)

If auto-selected or user confirms:
1. Copy `assets/starter-code/ErrorReporter.luau` to `src/server/modules/ErrorReporter.luau`
2. Add to `init.server.luau` after requires:
```luau
local ErrorReporter = require(ServerModules.ErrorReporter)
ErrorReporter.init()
```

**For production:** The module runs in "development" mode by default (logs to Output). For live games, configure an endpoint — see `references/debugging.md` → "Production Error Reporting" for Discord webhook setup.

#### Analytics (Player event tracking)

If auto-selected or user confirms:
1. Copy `assets/starter-code/Analytics.luau` to `src/server/modules/Analytics.luau`

#### Jest Lua (Unit testing)

If requested:
1. Add to `wally.toml`:
```toml
[dev-dependencies]
Jest = "jsdotlua/jest@3.10.0"
JestGlobals = "jsdotlua/jest-globals@3.10.0"
```
2. Run `wally install`
3. Create `scripts/run-tests.luau` with the test runner (see `references/testing.md`)
4. Inform user: "Testing is set up! Create test files with `.spec.luau` suffix next to your modules."

### Step 11: Verify & Commit

**Run linting to verify starter code:**
```bash
selene src/
stylua --check src/
```

Fix any issues before proceeding.

**Show checkpoint:**
> "Here's what I've created:"
> - List folder structure
> - List config files
> - List starter code files
> - Note any packages added

**Ask:** "Does this look correct before I commit?"

**If confirmed, make initial commit:**
```bash
git add .
git commit -m "Initial project setup"
```

### What You've Built

Your project now has:
- **Folder structure** mirroring Roblox services (`server/`, `client/`, `shared/`)
- **Entry points** with error handling (bugs won't crash silently)
- **Logger utility** with context prefixes (`[Server]`, `[Client]`)
- **Remote helpers** for type-safe client-server communication
- **Git integration** for version control
- **Linting/formatting** configs ready to use

Everything below is optional setup. You can run `rojo serve` and start building now.

### Step 12: Final Instructions

Tell user:

1. **Install VS Code extensions** — Command Palette → "Extensions: Show Recommended Extensions" → Install all

2. **Start Rojo:** `rojo serve`

3. **Connect Studio:** Open Roblox Studio → Rojo plugin → Connect

4. **Save place file:** File → Save to File As → `game.rbxl`

5. **Test:** Press F5 in Studio, check Output for "[Client] Ready" and "[Server] Ready"

6. **Optional — MCP:** If you want Claude to run code and inspect objects directly in Studio, set up the Roblox Studio MCP. Follow `references/mcp-setup.md` for complete instructions. Skip for now if you just want to start coding.

**Project is ready for development.**

---

## Testing Guidelines

### When to Suggest Testing

Proactively offer to write tests when:

1. **Creating a new module with business logic** — After writing `InventoryManager.luau`, offer:
   > "Want me to add tests for this module?"

2. **User asks about testing** — Consult `references/testing.md` for full patterns

3. **Bug fixes** — After fixing a bug, suggest:
   > "Want me to add a regression test so this doesn't break again?"

4. **Complex calculations or state machines** — These benefit most from tests

### When NOT to Suggest Testing

Don't push tests for:
- Simple getters/setters
- UI layout code
- Direct Roblox API wrappers
- Quick prototypes (unless user asks)

### How to Write and Run Tests

See `references/testing.md` for Jest Lua syntax, file placement conventions, and how to run tests in Studio vs CLI vs Lune.
