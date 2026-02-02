# Game Type Profiles

Quick-start profiles for common Roblox game genres. Each profile documents:

- **Implied decisions** — What this game type typically needs (so you don't have to guess)
- **Recommended packages** — Genre-specific dependencies
- **MVP checklist** — What to build first for a playable vertical slice
- **Common patterns** — Architecture and code patterns specific to this genre
- **Pitfalls** — Genre-specific gotchas to avoid

## Available Profiles

| Game Type | Best For | Key Characteristics |
|-----------|----------|---------------------|
| [Tycoon](tycoon.md) | Economy/building games | Plots, currency, upgrades, continuous world |
| [Obby](obby.md) | Platformers, skill games | Checkpoints, attempts, leaderboards, minimal persistence |
| [Simulator](simulator.md) | Collection/progression games | Pets, eggs, rebirths, heavy progression systems |
| [Combat Arena](combat-arena.md) | PvP, competitive games | Rounds, matchmaking, ranked systems, high exploit sensitivity |
| [Horror/Exploration](horror-exploration.md) | Survival horror, story games | Chapters, AI pursuers, atmosphere, medium-high exploit sensitivity |

## Reusable Patterns

Many code patterns apply across multiple game types. See [patterns/](../patterns/INDEX.md) for:

- **AI Systems** — State machines, pathfinding, detection
- **Audio Systems** — New Audio API, dynamic music, 3D sound
- **Camera Effects** — Shake, post-processing, vignette
- **Multiplayer Systems** — Spectate, revive, event sync
- **Anti-Exploit** — Movement validation, action validation
- **Trigger Systems** — Proximity triggers, interactables

Each game-type profile links to the patterns it commonly uses.

---

## How to Use These Profiles

### During Project Setup

When a user says something like "I want to build a tycoon":

1. Load the relevant profile
2. Present the implied decisions: "Tycoons typically need X, Y, Z. Sound right?"
3. If they confirm, use profile defaults for the wizard
4. If they want changes, ask targeted follow-ups

### For Architecture Guidance

Each profile includes a "Common Patterns" section showing how modules typically connect for that genre. Use these as starting points, not rigid rules.

### For Build Planning

The MVP checklist gives users a clear "build these 5 things first" roadmap. This goes into the generated CLAUDE.md file.

## Routing

| User says... | Load profile... |
|--------------|-----------------|
| "tycoon", "factory", "base builder" | `tycoon.md` |
| "obby", "parkour", "platformer", "racing" | `obby.md` |
| "simulator", "pet game", "clicker", "idle" | `simulator.md` |
| "arena", "pvp", "shooter", "fighting", "competitive" | `combat-arena.md` |
| "horror", "escape", "piggy", "granny", "doors", "story game", "survival horror" | `horror-exploration.md` |
| Hybrid or unclear | Ask clarifying questions, may combine patterns |

## Not Covered (Yet)

These genres aren't profiled but can be approximated:

- **Social/Roleplay** — Use tycoon profile (continuous world) with lower exploit sensitivity
- **Sandbox/Creative** — Unique enough to need custom discussion
