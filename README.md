# Roblox Project Setup Skill

A Claude skill for initializing professional Roblox game projects with Rojo, Wally, and modern tooling.

> **Note:** Currently supports game projects only. Library/plugin support planned for future versions.

## What It Does

- Creates folder structure (`src/client`, `src/server`, `src/shared`)
- Configures tooling (Rojo, Wally, Selene, StyLua)
- Sets up VS Code with recommended extensions
- Verifies tools installed before proceeding
- Runs linting to validate setup
- Makes initial git commit
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
Set up a new Roblox project called ParkourPanic
```

Or reference the skill directly:

```
Use the roblox-project skill to initialize my project
```

The skill will:
1. Ask project name and language (Luau/roblox-ts)
2. Create the folder structure
3. Initialize and verify tools (Rojo, Wally, Selene, StyLua)
4. Copy config files and starter code
5. Optionally add common Wally packages
6. Optionally set up MCP for AI-assisted Studio control
7. Run linting to verify setup
8. Show checkpoint and make initial commit

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
├── .vscode/
│   ├── settings.json
│   └── extensions.json
├── .claude/rules/
├── default.project.json
├── wally.toml
├── selene.toml
├── stylua.toml
├── .luaurc
├── .gitignore
├── .gitattributes
├── CLAUDE.md
└── README.md
```

## Reference Docs

The skill includes reference docs for deeper guidance. These are read on-demand, not copied to your project:

| Doc | Purpose |
|-----|---------|
| `luau-conventions.md` | Naming, file structure, task library |
| `luau-patterns.md` | Validation, tweening, error handling |
| `asset-pipeline.md` | Images, sounds, models workflows |
| `tool-versions.md` | Version pinning strategies |
| `mcp-setup.md` | MCP server setup for AI-assisted Studio control |

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
