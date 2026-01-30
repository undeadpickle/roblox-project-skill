# PROJECT_NAME

Brief description of your game.

**Stack**: Luau, Rojo, Wally, Roblox Studio

## Rojo Sync

**Filesystem is the source of truth for scripts.**

| Local Path | Studio Location |
|------------|-----------------|
| `src/server/` | `ServerScriptService.Server` |
| `src/client/` | `StarterPlayer.StarterPlayerScripts.Client` |
| `src/shared/` | `ReplicatedStorage.Shared` |
| `Packages/` | `ReplicatedStorage.Packages` |

## Commands

| Command | Purpose |
|---------|---------|
| `rojo serve` | Start sync server |
| `wally install` | Install packages |
| `selene src/` | Lint code |
| `stylua src/` | Format code |

**Before commits:** `selene src/ && stylua src/`

## File Naming

| Pattern | Use For |
|---------|---------|
| `*.server.luau` | Server scripts |
| `*.client.luau` | Client scripts |
| `*.luau` | Shared modules |

## Key Files

| File | Purpose |
|------|---------|
| `src/client/init.client.luau` | Client entry point |
| `src/server/init.server.luau` | Server entry point |
| `src/shared/GameConfig.luau` | All configuration |
| `src/shared/Remotes.luau` | Remote event helpers |
| `src/shared/Logger.luau` | Logging utility |

## Client-Server Communication

```
Client (action) → RemoteEvent → Server (validate & process) → RemoteEvent → Client (update UI)
```

## Conventions

- Use `game:GetService()` for all services
- Use `task.wait()`, `task.spawn()`, `task.delay()` (never legacy)
- Every file starts with `--!strict`
- PascalCase for modules, camelCase for variables

See `.claude/rules/` for detailed conventions and patterns.

## MCP Integration

If MCP servers are configured, Claude can:
- **Official MCP**: Run Luau code in Studio, insert marketplace models
- **boshyxd MCP**: Read/edit scripts, search objects, bulk operations

Studio must be open for MCP tools to work. See `docs/mcp-setup.md` if available.

## Game-Specific Notes

<!-- Add your game-specific architecture, systems, and notes here -->

## Learnings & Gotchas

**AI agents: Update this section when you discover something doesn't work as expected, is outdated, or has a better alternative. Check this section before implementing to avoid repeating mistakes.**

Format: `- [Category] Brief description of what doesn't work and what to do instead`

<!-- Add learnings below -->
