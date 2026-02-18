---
description: Scaffold a new Roblox game project with Rojo, Wally, and Luau. Interactive wizard adapts to your game type.
argument-hint: [game-type]
allowed-tools:
  [
    "Read",
    "Write",
    "Edit",
    "Glob",
    "Grep",
    "Bash(git *)",
    "Bash(ls *)",
    "Bash(tree *)",
    "Bash(mkdir *)",
    "Bash(cp *)",
    "Bash(touch *)",
    "Bash(cat *)",
    "Bash(rokit *)",
    "Bash(rojo *)",
    "Bash(wally *)",
    "Bash(selene *)",
    "Bash(stylua *)",
    "AskUserQuestion",
    "TodoWrite",
  ]
---

# New Roblox Project

Scaffold a new Roblox game project with professional tooling. Uses an interactive wizard to tailor the setup to your game type, team size, and persistence needs.

**Skill location:** `~/.claude/skills/roblox-dev/`

---

## Pre-flight

Before starting the wizard, verify the environment:

1. **Skill installed?** Check that `~/.claude/skills/roblox-dev/SKILL.md` exists. If not:
   > The roblox-dev skill isn't installed. Run this to install it:
   > ```
   > curl -sSL https://raw.githubusercontent.com/undeadpickle/roblox-project-skill/main/install.sh | bash
   > ```
   > Then restart Claude Code and run `/roblox-dev:new-project` again.

2. **Directory empty?** Run `ls -A` in the current directory.
   - If empty or only has `.git`: proceed normally.
   - If it has existing files: warn the user that scaffolding will add files and may overwrite configs. Ask if they want to continue using AskUserQuestion.

3. **Rokit available?** Run `rokit --version`.
   - If available: note the version, proceed.
   - If not found: inform the user how to install it but **don't block** — you can still create the file structure and configs. Note that tool installation (rojo, wally, selene, stylua) will need to happen after Rokit is set up.

---

## Phase 1: Project Profile Wizard

### Argument Parsing

Check `$ARGUMENTS` for a game type keyword:

| Keyword match | Game type profile |
|---------------|-------------------|
| tycoon, factory, base builder | `references/game-types/tycoon.md` |
| obby, parkour, platformer, racing | `references/game-types/obby.md` |
| simulator, pet, clicker, idle | `references/game-types/simulator.md` |
| arena, pvp, shooter, fighting, competitive | `references/game-types/combat-arena.md` |
| horror, exploration, doors, piggy | `references/game-types/horror-exploration.md` |

- **If a keyword matches:** Use the Quick-Start path (below).
- **If multiple match or none match:** Use the Full Wizard path.
- **If `$ARGUMENTS` is empty:** Use the Full Wizard path.

### Quick-Start Path (game type detected)

1. Read the matching game-type profile from `~/.claude/skills/roblox-dev/references/game-types/`.
2. Read the **"Quick-Start: Game Type Detection"** section of `~/.claude/skills/roblox-dev/PROJECT_WIZARD.md` (the section starting with "Quick-Start: Game Type Detection" through "When Quick-Start Doesn't Apply").
3. Present the implied decisions from the profile to the user.
4. Ask only the remaining questions not covered by the profile (typically: Intent, Source of Truth, Team Shape) using AskUserQuestion. Cluster these into 1-2 calls.

### Full Wizard Path (no game type detected)

1. Read the **"Phase 1: Foundation Questions"** section of `~/.claude/skills/roblox-dev/PROJECT_WIZARD.md` (from "Phase 1: Foundation Questions" through "Phase 1 Complete: Summarize the Profile").
2. Follow the question flow using AskUserQuestion, clustering questions as described in the wizard doc.
3. Apply the **Smart Skipping** rules — skip questions that earlier answers make irrelevant.
4. If the user gives freeform or ambiguous answers, read the **"Adaptive Flow Guidelines"** section for guidance on clarifying follow-ups.

### Profile Checkpoint

**Before moving to Phase 2, you MUST enumerate all captured profile values.** Present them as a structured list:

> **Project Profile:**
> - **Project name:** [name or folder name in PascalCase]
> - **Intent:** [prototype / mvp / long-lived]
> - **Source of truth:** [git-rojo / studio-first]
> - **Team:** [solo / small / large], PRs: [yes / no]
> - **Game loop:** [categories]
> - **Session format:** [continuous / rounds / runs / instanced]
> - **Platform:** [mobile / pc / cross-platform / gamepad]
> - **Exploit sensitivity:** [low / medium / high]
> - **Persistence:** [none / light / core]
> - **Structure:** [simple / layered / feature-based]
> - **Auto-included modules:** [list based on inference rules]

Read the **"Inference Rules"** and **"Auto-Selected Modules"** sections of `~/.claude/skills/roblox-dev/PROJECT_WIZARD.md` to determine which modules to auto-include based on the profile.

For prototypes/MVPs, proceed unless the user objects. For long-lived projects or teams with PRs, ask for explicit confirmation.

---

## Phase 2: Scaffold the Project

Read the **"Project Setup Workflow"** section of `~/.claude/skills/roblox-dev/SKILL.md` (from "Project Setup Workflow" through "Step 12: Final Instructions").

Execute Steps 1-12 in order, applying the profile from Phase 1. Key instructions:

### File Copying Rules

**CRITICAL: All config files, starter code, and templates MUST be copied from `~/.claude/skills/roblox-dev/assets/` — do NOT generate them from memory.**

For each file:
1. **Read** the source file from `~/.claude/skills/roblox-dev/assets/` using the Read tool
2. **Replace** placeholder tokens with actual values from the profile
3. **Write** the result to the destination using the Write tool

Placeholders to replace:
- `PROJECT_NAME` — user's project name
- `SKILL_VERSION` — contents of `~/.claude/skills/roblox-dev/VERSION`
- `PROJECT_INTENT`, `PROJECT_SOURCE_OF_TRUTH`, `PROJECT_TEAM_SHAPE`, etc. — profile values
- `PROJECT_ROADMAP_PHASE1/2/3` — from game-type profile MVP checklist or generic template (see "Generating the Build Roadmap" in PROJECT_WIZARD.md)

### Scaffold Variation

Apply the appropriate variation based on profile:
- **Minimal** (`intent` = prototype OR `sourceOfTruth` = studio-first): Skip Rokit if Studio-first, skip linting if prototype
- **Standard** (`intent` = mvp, `sourceOfTruth` = git-rojo): Full toolchain + auto modules
- **Full** (`intent` = long-lived): Everything in Standard + ErrorReporter + Analytics stubs + stricter lint

### Tool Installation

If Rokit is available, run tool installation (Step 3 in SKILL.md). If any tool fails to install:
- Log the failure
- Continue with the rest of the scaffold
- Note failed tools in the completion summary

### Wally Packages

After adding packages to `wally.toml`, run `wally install`. If it fails:
- Don't block the rest of the scaffold
- Note the failure and tell the user to retry `wally install` manually after checking their network connection

---

## Phase 3: Verify and Complete

1. **Lint check:** Run `selene src/` and `stylua --check src/`. Fix any issues in the generated code.

2. **Show project tree:**
   ```bash
   tree -I 'node_modules|.git|Packages|ServerPackages' -L 3
   ```

3. **Completion summary:** List what was created:
   - Folder structure
   - Config files
   - Starter code modules (base + auto-included)
   - Wally packages added
   - Any failures or items needing manual attention

4. **Initial commit:** Ask the user if they want to make an initial commit. If yes:
   ```bash
   git add .
   git commit -m "Initial project setup"
   ```

5. **Final instructions** (from SKILL.md Step 12):
   - Install VS Code extensions (Command Palette > "Extensions: Show Recommended Extensions")
   - Start Rojo: `rojo serve`
   - Connect Studio: Open Roblox Studio > Rojo plugin > Connect
   - Save place file: File > Save to File As > `game.rbxl`

---

## Recovery

- **Skill not installed:** Give install command and stop.
- **Rokit not found:** Scaffold files and configs, skip tool installation. User can install Rokit and run tools later.
- **Tool install fails:** Continue scaffold, note failure.
- **Wally install fails:** Continue scaffold, note for manual retry.
- **User wants to bail mid-wizard:** Stop gracefully. Whatever questions were answered are lost — the user can re-run the command.
- **Half-built project:** Never leave without telling the user what was and wasn't completed.
