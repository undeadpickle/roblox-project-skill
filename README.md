# Roblox Development Skill

A Claude skill for professional Roblox game development with Rojo, Wally, and modern Luau patterns.

Use for **any Roblox development question** including:
- Starting new projects with professional tooling
- Debugging issues and troubleshooting
- Package/library recommendations
- Code patterns and best practices
- MCP setup for AI-assisted Studio control

## What It Does

**Project Setup:**
- Creates folder structure (`src/client`, `src/server`, `src/shared`)
- Configures tooling (Rojo, Wally, Selene, StyLua)
- Sets up VS Code with recommended extensions
- Copies starter code modules (Logger, Remotes, GameConfig, DataManager)
- Makes initial git commit

**Ongoing Development:**
- Answers Luau/Roblox questions with reference docs
- Recommends libraries (Promise, GoodSignal, ProfileStore, etc.)
- Provides troubleshooting via gotchas guide
- Guides MCP setup for Studio integration

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
   - **Claude Code (global):** `~/.claude/skills/roblox-dev/`
   - **Claude Code (per-project):** `.claude/skills/roblox-dev/`
   - **claude.ai computer use:** `/mnt/skills/user/roblox-dev/`

## Usage

In Claude Code or claude.ai:

**Start a new project:**
```
Set up a new Roblox project called ParkourPanic
```

**Ask development questions:**
```
What library should I use for data persistence?
Why isn't my Rojo sync working?
How do I validate remote event arguments?
```

**Reference the skill directly:**
```
Use the roblox-dev skill to help me debug this issue
```

**Project setup flow:**
1. Ask project name and language (Luau/roblox-ts)
2. Create folder structure
3. Initialize and verify tools (Rojo, Wally, Selene, StyLua)
4. Copy config files and starter code
5. Optionally add Wally packages (Promise, GoodSignal, ProfileStore)
6. Optionally set up MCP for AI-assisted Studio control
7. Optionally add DataManager module
8. Run linting and make initial commit

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
| `libraries.md` | Package recommendations (Promise, GoodSignal, ProfileStore, Fusion) |
| `gotchas.md` | Common issues and troubleshooting (memory leaks, Rojo, Wally, security) |
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
