# Roblox Development Skill

**Give Claude AI expert knowledge about Roblox game development.**

This is a "skill" — a knowledge pack that teaches Claude how to help you build Roblox games using professional tools like Rojo, Wally, and modern Luau patterns. Once installed, just ask Claude and it knows what to do.

---

## What Can It Do?

| Ask Claude... | And it will... |
|---------------|----------------|
| "Set up a new Roblox project" | Create a full project with folders, config files, and starter code |
| "What library should I use for saving player data?" | Recommend ProfileStore with setup instructions |
| "Why isn't my Rojo sync working?" | Walk through common fixes from the troubleshooting guide |
| "How do I prevent memory leaks?" | Explain cleanup patterns with code examples |

**No more Googling DevForum posts** — Claude has the answers built in.

---

## Quick Start

### Step 1: Get Claude Code

You need **Claude Code** — the VS Code extension that lets Claude edit your files and run commands.

1. Open VS Code
2. Install the [Claude Code extension](https://marketplace.visualstudio.com/items?itemName=anthropic.claude-code)
3. Sign in with your Anthropic account

> **Don't have Claude Code?** You can also use this skill on [claude.ai](https://claude.ai) with computer use enabled, but Claude Code is easier.

### Step 2: Install the Skill

Open your terminal and run:

**macOS/Linux:**
```bash
curl -sSL https://raw.githubusercontent.com/undeadpickle/roblox-project-skill/main/install.sh | bash
```

**Windows (PowerShell):**
```powershell
irm https://raw.githubusercontent.com/undeadpickle/roblox-project-skill/main/install.ps1 | iex
```

That's it! The skill is now installed.

### Step 3: Use It

Open Claude Code (click the Claude icon in VS Code) and try:

```
Set up a new Roblox project called MyGame
```

Claude will ask a few questions, then create everything for you.

---

## Before You Build a Project

When you're ready to actually create a Roblox project (not just install this skill), you'll need:

- **[Rokit](https://github.com/rojo-rbx/rokit)** — Tool manager (Claude will help you install this)
- **VS Code** — Code editor (you probably already have this)
- **Roblox Studio** — For testing your game

Don't worry if you don't have Rokit yet — when you ask Claude to set up a project, it will check and guide you through installing anything that's missing.

---

## What You Can Ask

**Starting a project:**
- "Set up a new Roblox project called ParkourPanic"
- "Initialize a Roblox game with data persistence"

**Getting recommendations:**
- "What's the best library for UI in Roblox?"
- "Should I use Knit or go framework-less?"
- "What packages do I need for a trading system?"

**Troubleshooting:**
- "My Rojo plugin won't connect"
- "Why am I getting 'infinite yield' warnings?"
- "How do I fix DataStore throttling?"

**Learning patterns:**
- "How do I validate RemoteEvent arguments?"
- "Show me a debounce pattern for Roblox"
- "What's the right way to clean up connections?"
- "How do I rate limit RemoteEvents?"
- "What's the best way to migrate player data schemas?"

**Testing:**
- "Set up Jest Lua for testing"
- "Write tests for my InventoryManager module"
- "How do I mock RemoteEvents in tests?"
- "Run my tests"

---

## What Gets Created

When you set up a new project, Claude creates this structure:

```
your-project/
├── src/
│   ├── client/          ← Client-side scripts
│   ├── server/          ← Server-side scripts
│   ├── shared/          ← Code used by both
│   └── replicatedFirst/ ← Early client code (loading screens)
├── Packages/            ← Wally dependencies
├── .vscode/             ← Editor settings + task shortcuts
├── default.project.json ← Rojo config
├── wally.toml           ← Package manager config (pre-filled with common packages)
├── selene.toml          ← Linter config
├── CLAUDE.md            ← Project notes for AI
└── README.md
```

**Starter code included:**
- Entry points with error boundaries
- Logger with context prefixes
- RemoteEvent/RemoteFunction helpers
- Game config with `table.freeze()`

**Optional modules** (Claude will ask if you want them):
- `DataManager` — ProfileStore integration with data versioning
- `RateLimiter` — Protect RemoteEvents from exploit spam
- `Analytics` — Track player engagement (sessions, purchases, levels)
- `ErrorReporter` — Capture unhandled errors globally
- `Jest Lua` — Unit testing framework for your modules

---

## Manual Installation

If you prefer not to run scripts from the internet:

1. Download this repository (Code → Download ZIP)
2. Extract and copy these to `~/.claude/skills/roblox-dev/`:
   - `SKILL.md`
   - `assets/` folder
   - `references/` folder

---

## Tools & Libraries Explained

This skill sets up professional Roblox development using modern tools. Here's what each one does:

### Development Tools

| Tool | What it does |
|------|--------------|
| **[Rokit](https://github.com/rojo-rbx/rokit)** | Installs and manages the other tools. Like a toolbox that keeps everything organized. |
| **[Rojo](https://rojo.space/)** | Syncs your code files to Roblox Studio. Edit in VS Code → changes appear in Studio instantly. |
| **[Wally](https://wally.run/)** | Package manager. Downloads libraries (like npm for JavaScript). |
| **[Selene](https://kampfkarren.github.io/selene/)** | Linter. Catches bugs and bad patterns before you run your code. |
| **[StyLua](https://github.com/JohnnyMorganz/StyLua)** | Formatter. Auto-formats your code so it's consistent and readable. |

### Recommended Libraries

| Library | What it does | When you need it |
|---------|--------------|------------------|
| **[Promise](https://eryn.io/roblox-lua-promise/)** | Handles async operations cleanly. | Anytime you wait for something (data loading, HTTP requests). |
| **[ProfileStore](https://madstudioroblox.github.io/ProfileStore/)** | Saves player data reliably. Prevents data loss and duplication. | Any game that saves progress. |
| **[GoodSignal](https://github.com/stravant/goodsignal)** | Custom events for your code. Lets modules talk to each other. | When you need event-driven architecture. |
| **[Trove](https://sleitnick.github.io/RbxUtil/api/Trove/)** | Tracks things for cleanup. Prevents memory leaks. | Managing connections, instances, any cleanup. |
| **[Fusion](https://elttob.uk/Fusion/)** | Reactive UI framework. UI updates automatically when data changes. | Building complex interfaces. |

**You don't need all of these** — Claude will recommend what's appropriate for your specific game.

---

## Included Reference Docs

The skill includes guides that Claude reads when relevant:

| Guide | What it covers |
|-------|----------------|
| **libraries.md** | Which packages to use and migration paths |
| **gotchas.md** | Common mistakes and how to fix them |
| **luau-conventions.md** | Code style and naming conventions |
| **luau-patterns.md** | Reusable code patterns |
| **tool-versions.md** | Rokit, version pinning, team setup |
| **asset-pipeline.md** | Working with images, sounds, and models |
| **mcp-setup.md** | Connecting Claude directly to Roblox Studio |
| **testing.md** | Unit testing with Jest Lua |
| **debugging.md** | Finding and fixing bugs in Studio |
| **quick-reference.md** | Cheat sheet for common Luau patterns |

---

## After Your Project Is Set Up

1. **Install VS Code extensions** — Claude will remind you, but: Command Palette → "Show Recommended Extensions" → Install all
2. **Install packages:** Run `wally install` (or use Cmd+Shift+P → "Tasks: Run Task" → "Wally Install")
3. **Start the sync:** Run `rojo serve` (or use the "Rojo Serve" task)
4. **Connect Studio:** Open Roblox Studio → Rojo plugin → Connect
5. **Save your place:** File → Save to File As → `game.rbxl`
6. **Test:** Press F5, check Output for "[Client] Ready" and "[Server] Ready"

**VS Code tasks included:** Rojo Serve, Wally Install, Lint (Selene), Format (StyLua), Run Tests (Lune/Studio) — access via Cmd+Shift+P → "Tasks: Run Task"

---

## Testing

Verify the skill works correctly:

**Quick automated check:**
```bash
./scripts/smoke-test.sh
```

**Full manual walkthrough:** See [TESTING.md](TESTING.md)

---

## Questions?

- **Issues with this skill?** [Open an issue](https://github.com/undeadpickle/roblox-project-skill/issues)
- **General Roblox questions?** Just ask Claude — that's what this skill is for!

---

## License

MIT — do whatever you want with it.
