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

---

## What Gets Created

When you set up a new project, Claude creates this structure:

```
your-project/
├── src/
│   ├── client/          ← Client-side scripts
│   ├── server/          ← Server-side scripts
│   └── shared/          ← Code used by both
├── Packages/            ← Wally dependencies
├── .vscode/             ← Editor settings
├── default.project.json ← Rojo config
├── wally.toml           ← Package manager config
├── selene.toml          ← Linter config
├── CLAUDE.md            ← Project notes for AI
└── README.md
```

Plus starter code for logging, remote events, and game config.

---

## Manual Installation

If you prefer not to run scripts from the internet:

1. Download this repository (Code → Download ZIP)
2. Extract and copy these to `~/.claude/skills/roblox-dev/`:
   - `SKILL.md`
   - `assets/` folder
   - `references/` folder

---

## Included Reference Docs

The skill includes guides that Claude reads when relevant:

| Guide | What it covers |
|-------|----------------|
| **libraries.md** | Which packages to use (Promise, ProfileStore, Fusion, etc.) |
| **gotchas.md** | Common mistakes and how to fix them |
| **luau-conventions.md** | Code style and naming conventions |
| **luau-patterns.md** | Reusable code patterns |
| **asset-pipeline.md** | Working with images, sounds, and models |
| **mcp-setup.md** | Connecting Claude directly to Roblox Studio |

---

## After Your Project Is Set Up

1. **Install VS Code extensions** — Claude will remind you, but: Command Palette → "Show Recommended Extensions" → Install all
2. **Start the sync:** Run `rojo serve` in your terminal
3. **Connect Studio:** Open Roblox Studio → Rojo plugin → Connect
4. **Save your place:** File → Save to File As → `game.rbxl`
5. **Test:** Press F5, check Output for "[Client] Ready" and "[Server] Ready"

---

## Questions?

- **Issues with this skill?** [Open an issue](https://github.com/undeadpickle/roblox-project-skill/issues)
- **General Roblox questions?** Just ask Claude — that's what this skill is for!

---

## License

MIT — do whatever you want with it.
