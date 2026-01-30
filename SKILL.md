---
name: new-roblox-project
description: Initialize a new Roblox game project with professional tooling. Optionally captures game concept (pillars, core loop, MVP scope) during setup. Creates folder structure, config files (Rojo, Wally, Selene, StyLua), starter Luau modules, VS Code settings, and CLAUDE.md. Use when user wants to start a new Roblox project, set up Rojo workflow, or initialize a game from scratch. Run in an empty project folder.
---

# New Roblox Project Setup

Set up a complete Roblox game project with professional tooling and best practices.

## Prerequisites

Verify before starting:
- **Rokit** installed (`rokit --version`)
- **VS Code** with project folder open
- **Roblox Studio** installed

Optional but recommended:
- **MCP servers** for AI-assisted development (see `references/mcp-setup.md`)

If Rokit missing:
```bash
# macOS/Linux
curl -sSf https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.sh | bash

# Windows (PowerShell)
irm https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.ps1 | iex
```

## Workflow

### Step 1: Capture Game Concept

**Ask the user:**
> "Want to capture your game concept now, or skip straight to project setup?"

**If they want to capture it:**

Get project basics. If they've already described the game, extract from their message. Otherwise, ask:
- What's the game about? (becomes the pitch)
- What genre/type? (obby, tycoon, simulator, horror, etc.)
- What's the core activity? (what players do repeatedly)
- Any reference games? ("like X but with Y")

Use responses to pre-fill `docs/game-concept.md` during Step 6. Even partial info helps—a filled-in pitch and genre beats a blank template.

**If they skip:**
Just get project name and move on. Copy blank template in Step 6.

**Required either way:**
- **Project name** — Default: folder name in PascalCase

### Step 2: Create Folder Structure

```bash
mkdir -p src/client/modules src/server/modules src/shared Packages docs .vscode .claude/rules
touch Packages/.gitkeep
```

### Step 3: Initialize Tools

```bash
git init
rokit init
rokit add rojo-rbx/rojo
rokit add UpliftGames/wally
rokit add JohnnyMorganz/StyLua
rokit add Kampfkarren/selene
wally init
```

Rokit automatically installs the latest stable release when no version is specified.

To pin specific versions for reproducible builds, use `tool@version` syntax (e.g., `rojo-rbx/rojo@7.6.1`). See `references/tool-versions.md` for version pinning strategies.

### Step 4: Copy Config Files

Copy all files from `assets/config/` to project root:
- `default.project.json` → Replace `PROJECT_NAME` with user's project name
- `selene.toml`
- `stylua.toml`
- `.luaurc` (from `luaurc.json`)
- `.gitignore` (from `gitignore.txt`)

Copy `assets/vscode/` contents to `.vscode/`:
- `settings.json`
- `extensions.json`

### Step 5: Copy Starter Code

Copy all files from `assets/starter-code/` to appropriate locations:

| Source File | Destination | Notes |
|-------------|-------------|-------|
| `init.client.luau` | `src/client/init.client.luau` | Client entry point |
| `init.server.luau` | `src/server/init.server.luau` | Server entry point |
| `GameConfig.luau` | `src/shared/GameConfig.luau` | Replace `PROJECT_NAME` |
| `Remotes.luau` | `src/shared/Remotes.luau` | Remote event helpers |
| `Logger.luau` | `src/shared/Logger.luau` | Logging utility |

### Step 6: Create CLAUDE.md and Game Concept

Copy `assets/claude-template/CLAUDE.md` to project root. Replace `PROJECT_NAME`.

Optionally copy convention files to `.claude/rules/`:
- `references/luau-conventions.md` → `.claude/rules/luau-conventions.md`
- `references/luau-patterns.md` → `.claude/rules/luau-patterns.md`

**Create game concept doc:**
Copy `assets/docs/game-concept.md` → `docs/game-concept.md`

If user provided game info in Step 1, pre-fill relevant sections:
- **The Pitch**: From their description
- **Game Pillars**: Infer 2-3 from genre/description (mark as drafts)
- **Core Loop**: If they described the main activity
- **Inspirations**: Any reference games they mentioned

Leave unfilled sections as template placeholders—partial doc > blank doc.

Optionally copy other reference docs:
- `references/mcp-setup.md` → `docs/mcp-setup.md`

### Step 7: Update wally.toml

Edit the generated `wally.toml` to set the package name:
```toml
[package]
name = "username/project-name"
version = "0.1.0"
registry = "https://github.com/UpliftGames/wally-index"
realm = "shared"
```

### Step 8: Final Instructions

Tell user:

1. **Install VS Code extensions** — Command Palette → "Extensions: Show Recommended Extensions" → Install all 4

2. **Start Rojo**: `rojo serve`

3. **Connect Studio**: Open Roblox Studio → Rojo plugin → Connect

4. **Save place file**: File → Save to File As → `game.rbxl`

5. **Test**: Press F5 in Studio, check Output for "[Client] Ready" and "[Server] Ready"

## Reference Files

**Technical:**
- `references/luau-conventions.md` — Naming, file structure, task library usage
- `references/luau-patterns.md` — Common patterns (validation, tweening, error handling)
- `references/tool-versions.md` — Recommended tool versions and compatibility notes
- `references/mcp-setup.md` — MCP server setup for AI-assisted development
- `references/technical-planning.md` — Performance, data, network architecture decisions
- `references/asset-pipeline.md` — Images, sounds, models: workflows, folder structure, Asphalt

**Game Design:**
- `assets/docs/game-concept.md` — Template: pillars, core loop, MVP definition
- `references/scope-management.md` — Prioritization, feature creep prevention
- `references/playtesting-guide.md` — What to observe, questions to ask
- `references/monetization-roblox.md` — DevEx math, game passes, ethical monetization
