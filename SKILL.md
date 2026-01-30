---
name: roblox-project
description: Initialize a Roblox game project with professional tooling. Creates folder structure, config files (Rojo, Wally, Selene, StyLua), starter code, VS Code settings, and CLAUDE.md. Use when starting a new Roblox game or setting up Rojo workflow.
---

# Roblox Project Setup

Set up a Roblox project with professional tooling and best practices.

## Prerequisites

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

## Workflow

### Step 1: Gather Project Info

**Ask the user:**

1. **Project name?** — Default: folder name in PascalCase

2. **Language?**
   - Luau (default)
   - roblox-ts (TypeScript)

If roblox-ts selected, inform user this skill sets up Luau projects only. Point them to [roblox-ts docs](https://roblox-ts.com/) for TypeScript setup.

### Step 2: Create Folder Structure

```bash
mkdir -p src/client/modules src/server/modules src/shared Packages .vscode .claude/rules
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
- `.luaurc` (from `luaurc.json`)
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
```

### Step 8: Optional — Add Common Packages

**Ask the user:**
> "Want me to add any common Wally packages? (Promise, Signal, Trove)"

If yes, add to `wally.toml` under `[dependencies]`:

```toml
[dependencies]
Promise = "evaera/promise@4.0.0"
Signal = "sleitnick/signal@2.0.1"
Trove = "sleitnick/trove@1.1.0"
```

Then run:
```bash
wally install
```

### Step 9: Optional — MCP Setup

**Ask the user:**
> "Do you have Roblox Studio MCP configured? (Lets AI control Studio directly)"

If no and they want it:

**Quick setup (recommended):**

1. Download Studio plugin from [robloxstudio-mcp releases](https://github.com/boshyxd/robloxstudio-mcp/releases)
2. Copy to Plugins folder (`%LOCALAPPDATA%\Roblox\Plugins\` on Windows)
3. In Studio: Game Settings → Security → Enable HTTP Requests
4. Add to Claude Code:
   ```bash
   claude mcp add robloxstudio -- npx -y robloxstudio-mcp
   ```

See `references/mcp-setup.md` for detailed options and troubleshooting.

### Step 10: Verify & Commit

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

### Step 11: Final Instructions

Tell user:

1. **Install VS Code extensions** — Command Palette → "Extensions: Show Recommended Extensions" → Install all

2. **Start Rojo:** `rojo serve`

3. **Connect Studio:** Open Roblox Studio → Rojo plugin → Connect

4. **Save place file:** File → Save to File As → `game.rbxl`

5. **Test:** Press F5 in Studio, check Output for "[Client] Ready" and "[Server] Ready"

**Project is ready for development.**

## Reference Files

Available on-demand for deeper guidance:

- `references/luau-conventions.md` — Naming, file structure, task library usage
- `references/luau-patterns.md` — Common patterns (validation, tweening, error handling)
- `references/tool-versions.md` — Version pinning strategies
- `references/asset-pipeline.md` — Images, sounds, models workflows
- `references/mcp-setup.md` — MCP server setup for AI-assisted Studio control
