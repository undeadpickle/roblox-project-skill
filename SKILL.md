---
name: roblox-dev
description: Roblox game development with professional tooling (Rojo, Wally, Luau). Use for any Roblox development question including debugging issues, package selection, code patterns, MCP setup, OR when starting a new project. Covers Luau scripting, tool configuration, and Studio workflows.
---

# Roblox Development

Professional Roblox game development with Rojo, Wally, and modern Luau patterns.

## Reference Routing

Consult these files based on the topic:

| User asks about... | Consult first |
|-------------------|---------------|
| Package recommendations, "what library for X", dependencies | `references/libraries.md` |
| Something not working, debugging, errors, "why isn't X working" | `references/gotchas.md` then `references/debugging.md` |
| Code style, naming conventions, file organization | `references/luau-conventions.md` |
| How to implement patterns (services, cleanup, validation, etc.) | `references/luau-patterns.md` |
| Tool version conflicts, Rokit pinning, compatibility | `references/tool-versions.md` |
| MCP setup, Studio connection, AI-assisted development | `references/mcp-setup.md` |
| Images, sounds, models, asset workflows | `references/asset-pipeline.md` |
| Testing, TestEZ, writing tests | `references/testing.md` |
| Quick syntax lookup, common APIs | `references/quick-reference.md` |
| **Starting a new project** | Follow [Project Setup Workflow](#project-setup-workflow) below |

**Starter code in `assets/starter-code/`** shows recommended patterns:
- `init.client.luau` / `init.server.luau` — Entry point structure
- `Remotes.luau` — Remote event organization
- `DataManager.luau` — ProfileStore + Promise integration
- `Logger.luau` — Contextual logging with prefixes

---

## Project Setup Workflow

**Use this section when starting a new Roblox project from scratch.**

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
mkdir -p src/client/modules src/server/modules src/shared src/replicatedFirst Packages .vscode .claude/rules
touch Packages/.gitkeep
```

### Step 3: Initialize Git & Tools

```bash
git init
rokit init
rokit add rojo-rbx/rojo
rokit add UpliftGames/wally
rokit add JohnnyMorganz/StyLua
rokit add Kampfkarren/selene
```

**Verify tools installed:**
```bash
rojo --version
wally --version
stylua --version
selene --version
```

If any command fails, check Rokit installation and retry `rokit add`.

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

Copy `assets/claude-template/CLAUDE.md` to project root. Replace `PROJECT_NAME`.

Copy `assets/docs/README.md` to project root. Replace `PROJECT_NAME`.

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

**Note:** `private = true` prevents accidental publishing. See `references/gotchas.md` for other Wally pitfalls.

### Step 8: Optional — Add Common Packages

**Ask the user:**
> "Want me to add Wally packages? Common options:
> - **Core utilities:** Promise, GoodSignal, Trove
> - **Data persistence:** ProfileStore
> - **UI framework:** Fusion (typically vendored, not via Wally)"

Based on response, add to `wally.toml`:

**Core utilities (recommended):**
```toml
[dependencies]
Promise = "evaera/promise"
GoodSignal = "stravant/goodsignal"
Trove = "sleitnick/trove"
```

**With data persistence:**
```toml
[dependencies]
Promise = "evaera/promise"
GoodSignal = "stravant/goodsignal"
Trove = "sleitnick/trove"

[server-dependencies]
ProfileStore = "loleris/profilestore"
```

Then run:
```bash
wally install
```

**For detailed library recommendations:** See `references/libraries.md`.

### Step 9: Optional — MCP Setup

**Ask the user:**
> "Do you have Roblox Studio MCP configured? (Lets AI run code and insert models in Studio)"

If no and they want it, see `references/mcp-setup.md` for full setup instructions.

**Quick path (Official Roblox MCP):**

1. Download from [GitHub releases](https://github.com/Roblox/studio-rust-mcp-server/releases)
2. Move to global location (`/Applications/` or `C:\Program Files\`)
3. Add to Claude Code:
   ```bash
   # macOS
   claude mcp add roblox-studio -- "/Applications/RobloxStudioMCP.app/Contents/MacOS/rbx-studio-mcp" --stdio
   ```
4. Restart VS Code, open Studio — check Output for "MCP Studio plugin is ready"

**Troubleshooting MCP issues:** See `references/gotchas.md` → MCP Servers section.

### Step 10: Optional — Data Manager

If user selected ProfileStore, ask:
> "Want me to add a DataManager starter module? (ProfileStore + Promise integration)"

If yes, copy `assets/starter-code/DataManager.luau` to `src/server/modules/DataManager.luau`.

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

### Step 12: Final Instructions

Tell user:

1. **Install VS Code extensions** — Command Palette → "Extensions: Show Recommended Extensions" → Install all

2. **Start Rojo:** `rojo serve`

3. **Connect Studio:** Open Roblox Studio → Rojo plugin → Connect

4. **Save place file:** File → Save to File As → `game.rbxl`

5. **Test:** Press F5 in Studio, check Output for "[Client] Ready" and "[Server] Ready"

**Project is ready for development.**
