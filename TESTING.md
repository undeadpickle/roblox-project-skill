# Testing Guide

A simple walkthrough to verify the Roblox development skill works correctly.

---

## Quick Check (Automated)

Run the smoke test to verify everything in seconds:

```bash
./scripts/smoke-test.sh
```

If all checks pass, you're good to go. If something fails, follow the manual steps below to diagnose.

---

## 1. Before You Start

Make sure you have these installed:

- [ ] **Claude Code** — The VS Code extension (or Claude Desktop with computer use)
- [ ] **Rokit** — Run `rokit --version` in terminal. If not found, [install it](https://github.com/rojo-rbx/rokit)
- [ ] **Roblox Studio** — For testing generated projects

> **What this checks:** Your environment is ready to use the skill and test generated projects.

---

## 2. Test the Skill Installation

### Install the skill

**macOS/Linux:**
```bash
curl -sSL https://raw.githubusercontent.com/undeadpickle/roblox-project-skill/main/install.sh | bash
```

**Windows (PowerShell):**
```powershell
irm https://raw.githubusercontent.com/undeadpickle/roblox-project-skill/main/install.ps1 | iex
```

### Verify the files

Check that these exist in `~/.claude/skills/roblox-dev/`:

- [ ] `SKILL.md` — The main skill file Claude reads
- [ ] `VERSION` — Version number (e.g., `1.0.0`)
- [ ] `assets/` folder — Templates and starter code
- [ ] `references/` folder — Guide documents

> **What this checks:** The installer downloaded everything to the right place.

---

## 3. Test Project Creation

### Create a test project

1. Open VS Code in an empty folder
2. Open Claude Code (click the Claude icon)
3. Type: `Set up a new Roblox project called TestGame`
4. Answer Claude's questions (language, packages, etc.)

### Verify the project structure

After Claude finishes, you should see:

- [ ] `src/` folder with `client/`, `server/`, `shared/` subfolders
- [ ] `default.project.json` — Rojo configuration
- [ ] `wally.toml` — Package manager config
- [ ] `selene.toml` and `stylua.toml` — Linter and formatter configs
- [ ] `.vscode/` folder with settings and recommended extensions
- [ ] `CLAUDE.md` — Project notes for AI

> **What this checks:** Claude can read the skill and create a complete project structure.

---

## 4. Test the Generated Project

### Start the sync

1. Open terminal in your project folder
2. Run: `rojo serve`
3. You should see "Rojo server listening on port 34872"

### Connect Roblox Studio

1. Open Roblox Studio
2. Create a new Baseplate or open an existing place
3. Click the Rojo plugin → Connect
4. Save the place as `game.rbxl` in your project folder

### Run the game

1. Press F5 in Studio to play
2. Check the Output window (View → Output)

You should see:

- [ ] `[Server] Ready` — Server script initialized
- [ ] `[Client] Ready` — Client script initialized
- [ ] No red error messages

> **What this checks:** The starter code runs without errors and Rojo syncs correctly.

---

## 5. Test Optional Features

If you added optional modules during setup, verify they work:

### Data Persistence (ProfileStore)

- [ ] Play the game, then stop
- [ ] Check Output for "Profile loaded for [your username]"
- [ ] No DataStore errors

### Rate Limiting

- [ ] The RateLimiter module should be in `src/server/modules/`
- [ ] No errors on require

### Error Reporting

- [ ] Check Output for "ErrorReporter initialized"
- [ ] Intentionally cause an error (e.g., call a nil function) — it should be logged

### Analytics

- [ ] Check Output for "Analytics initialized"
- [ ] Session start should be tracked on player join

> **What this checks:** Optional modules integrate correctly with the base project.

---

## 6. Test the Reference Docs

Claude should give accurate answers based on the reference documents.

### Try these prompts

| Ask Claude... | Should reference... |
|---------------|---------------------|
| "What library should I use for saving data?" | `references/libraries.md` → recommends ProfileStore |
| "My Rojo plugin won't connect" | `references/gotchas.md` → troubleshooting steps |
| "How do I clean up connections?" | `references/luau-patterns.md` → Trove pattern |
| "What's the naming convention for modules?" | `references/luau-conventions.md` → PascalCase |

- [ ] Claude gives relevant, accurate answers
- [ ] Answers match what's in the reference files

### Test Context7 (live Roblox docs)

If you have Context7 MCP configured:

| Ask Claude... | Should fetch from... |
|---------------|----------------------|
| "How does Players:GetPlayers() work?" | Roblox Engine API docs |
| "Show me a tutorial on tweening" | Roblox Creator Hub guides |

- [ ] Claude pulls current documentation (not outdated info)

> **What this checks:** Claude routes questions to the right reference docs and can access live Roblox documentation.

---

## 7. Cleanup

### Remove the test project

Just delete the folder you created. If you committed to git, you can also remove `.git/`.

### Uninstall the skill (optional)

If you need to remove the skill entirely:

```bash
rm -rf ~/.claude/skills/roblox-dev
```

Then restart VS Code / Claude Code.

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Installer fails | Check your internet connection. Try downloading manually from GitHub. |
| Claude doesn't know about Roblox | Restart Claude Code after installing the skill. |
| Rojo won't connect | See `references/gotchas.md` → Rojo section |
| "Module not found" errors | Run `wally install` to download packages |
| Selene/StyLua not found | Run `rokit install` in your project folder |

---

## All Tests Passed?

If everything above works, the skill is functioning correctly. You're ready to build Roblox games with Claude's help.
