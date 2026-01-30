# Roblox Project Setup Skill

A Claude skill for initializing professional Roblox game projects with Rojo, Wally, and modern tooling.

## What It Does

- Creates folder structure (`src/client`, `src/server`, `src/shared`)
- Configures tooling (Rojo, Wally, Selene, StyLua)
- Sets up VS Code with recommended extensions
- Optionally captures your game concept (pillars, core loop, MVP)
- Creates CLAUDE.md for AI-assisted development

## Requirements

- [Rokit](https://github.com/rojo-rbx/rokit) installed
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) or [claude.ai](https://claude.ai) with computer use
- VS Code (recommended)
- Roblox Studio

## Installation

### Quick Install (Recommended)

**macOS/Linux:**
```bash
curl -sSL https://raw.githubusercontent.com/undeadpickle/roblox-project-skill/main/install.sh | bash
```

**Windows (PowerShell):**
```powershell
irm https://raw.githubusercontent.com/undeadpickle/roblox-project-skill/main/install.ps1 | iex
```

### Manual Install

1. Clone this repo
2. Copy `SKILL.md`, `assets/`, and `references/` to your Claude skills directory:
   - **Claude Code (global):** `~/.claude/skills/roblox-project/`
   - **Claude Code (per-project):** `.claude/skills/roblox-project/`
   - **claude.ai computer use:** `/mnt/skills/user/roblox-project/`

## Usage

In Claude Code or claude.ai:

```
Set up a new Roblox project for an obby game called ParkourPanic
```

Or reference the skill directly:

```
Use the roblox-project skill to initialize my game
```

The skill will:
1. Ask if you want to capture your game concept now or skip to setup
2. Create the folder structure
3. Initialize tools (Rojo, Wally, Selene, StyLua)
4. Copy config files and starter code
5. Set up CLAUDE.md with project context

## What Gets Created

```
your-project/
├── src/
│   ├── client/
│   │   ├── init.client.luau
│   │   └── modules/
│   ├── server/
│   │   ├── init.server.luau
│   │   └── modules/
│   └── shared/
│       ├── GameConfig.luau
│       ├── Remotes.luau
│       └── Logger.luau
├── Packages/
├── docs/
│   └── game-concept.md
├── .vscode/
│   ├── settings.json
│   └── extensions.json
├── .claude/rules/
├── default.project.json
├── wally.toml
├── selene.toml
├── stylua.toml
├── .luaurc
├── CLAUDE.md
└── .gitignore
```

## Reference Docs

The skill includes reference docs for deeper guidance. These are read on-demand, not copied to your project:

| Doc | Purpose |
|-----|---------|
| `luau-conventions.md` | Naming, file structure, task library |
| `luau-patterns.md` | Validation, tweening, error handling |
| `asset-pipeline.md` | Images, sounds, models workflows |
| `technical-planning.md` | Performance, data, networking decisions |
| `scope-management.md` | Prioritization, feature creep prevention |
| `playtesting-guide.md` | Observation techniques, questions to ask |
| `monetization-roblox.md` | DevEx rates, game passes, ethical considerations |
| `mcp-setup.md` | MCP server setup for AI-assisted Studio control |
| `tool-versions.md` | Version pinning strategies |

## After Setup

1. **Install VS Code extensions** — Command Palette → "Extensions: Show Recommended Extensions" → Install all
2. **Start Rojo:** `rojo serve`
3. **Connect Studio:** Open Roblox Studio → Rojo plugin → Connect
4. **Save place file:** File → Save to File As → `game.rbxl`
5. **Test:** Press F5 in Studio, check Output for "[Client] Ready" and "[Server] Ready"

## Learnings & Gotchas

The generated `CLAUDE.md` includes a "Learnings & Gotchas" section. When you or your AI assistant discovers something that doesn't work as expected, document it there. This knowledge persists across sessions and prevents repeating mistakes.

## Contributing

Issues and PRs welcome. Please keep contributions game-genre-agnostic.

## License

MIT — See [LICENSE](LICENSE)

## Credits

Built for the Roblox developer community. Inspired by modern development workflows and the need for consistent, professional project setup.
