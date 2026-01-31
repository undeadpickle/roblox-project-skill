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
| Roblox API, engine classes, how does X work | Context7: `/websites/create_roblox_reference_engine` → fallback: `create.roblox.com/docs/reference/engine` |
| Tutorials, guides, best practices, "how to" | Context7: `/websites/create_roblox` → fallback: `create.roblox.com/docs` |
| Package recommendations, "what library for X", dependencies | `references/libraries.md` |
| Something not working, debugging, errors, "why isn't X working" | `references/gotchas.md` then `references/debugging.md` |
| Code style, naming conventions, file organization | `references/luau-conventions.md` |
| How to implement patterns (services, cleanup, validation, etc.) | `references/luau-patterns.md` |
| Tool version conflicts, Rokit pinning, compatibility | `references/tool-versions.md` |
| MCP setup, Studio connection, AI-assisted development | `references/mcp-setup.md` |
| Images, sounds, models, asset workflows | `references/asset-pipeline.md` |
| Testing, Jest Lua, writing tests | `references/testing.md` |
| Quick syntax lookup, common APIs | `references/quick-reference.md` |
| **Starting a new project** | Follow [Project Setup Workflow](#project-setup-workflow) below |

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

**Context7 MCP (documentation lookup):**
If not already configured, add for live Roblox docs:
```bash
claude mcp add context7 -- npx -y @upstash/context7-mcp --api-key YOUR_API_KEY
```
Get API key at [context7.com](https://context7.com). Use library IDs:
- `/websites/create_roblox` — Tutorials & guides
- `/websites/create_roblox_reference_engine` — Engine API reference

### Step 10: Optional — Data Manager

If user selected ProfileStore, ask:
> "Want me to add a DataManager starter module? (ProfileStore + Promise integration)"

If yes, copy `assets/starter-code/DataManager.luau` to `src/server/modules/DataManager.luau`.

### Step 10b: Optional — Rate Limiting

Ask:
> "Want me to add rate limiting for RemoteEvents? (Recommended for exploit protection)"

If yes, copy `assets/starter-code/RateLimiter.luau` to `src/server/modules/RateLimiter.luau`.

### Step 10c: Optional — Error Reporting

Ask:
> "Want me to add global error reporting? (Captures unhandled errors)"

If yes:
1. Copy `assets/starter-code/ErrorReporter.luau` to `src/server/modules/ErrorReporter.luau`
2. Add to `init.server.luau` after requires:
```luau
local ErrorReporter = require(ServerModules.ErrorReporter)
ErrorReporter.init()
```

### Step 10d: Optional — Analytics

Ask:
> "Want me to add player analytics tracking? (Session, purchase, level events)"

If yes, copy `assets/starter-code/Analytics.luau` to `src/server/modules/Analytics.luau`.

### Step 10e: Optional — Testing Setup

Ask:
> "Want me to set up Jest Lua for unit testing?"

If yes:
1. Add to `wally.toml`:
```toml
[dev-dependencies]
Jest = "jsdotlua/jest@3.10.0"
JestGlobals = "jsdotlua/jest-globals@3.10.0"
```

2. Run `wally install`

3. Create `scripts/run-tests.luau` with the test runner (see `references/testing.md`)

4. Inform user:
> "Testing is set up! Create test files with `.spec.luau` suffix next to your modules. Run tests in Studio or via `run-in-roblox`."

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

### How to Write Tests

1. **Create test file** next to the module:
   ```
   src/shared/MathUtils.luau
   src/shared/MathUtils.spec.luau  ← Test file
   ```

2. **Follow Jest Lua syntax** (see `references/testing.md`):
   ```luau
   local JestGlobals = require("@DevPackages/JestGlobals")
   local describe = JestGlobals.describe
   local it = JestGlobals.it
   local expect = JestGlobals.expect

   return function()
       describe("ModuleName", function()
           it("should do the expected thing", function()
               expect(result).toBe(expected)
           end)
       end)
   end
   ```

3. **Test behavior, not implementation** — Focus on inputs/outputs

### How to Run Tests

**In Studio:**
- Run the test runner script (usually `scripts/run-tests.luau`)
- Check Output window for results

**From CLI (CI/CD):**
```bash
run-in-roblox --place test-place.rbxl --script scripts/run-tests.luau
```

**Pure logic tests (no Roblox APIs):**
```bash
lune run tests/math-utils.spec.luau
```
