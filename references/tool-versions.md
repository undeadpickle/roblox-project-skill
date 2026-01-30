# Tool Versions

Rokit automatically installs the latest stable release when no version is specified. This is the recommended approach for new projects.

## Default Installation (Latest)

```bash
rokit add rojo-rbx/rojo
rokit add UpliftGames/wally
rokit add JohnnyMorganz/StyLua
rokit add Kampfkarren/selene
```

## Version Pinning Strategies

Use version pinning when you need reproducible builds or team consistency.

| Strategy | Example | Use Case |
|----------|---------|----------|
| No version | `rojo-rbx/rojo` | Always latest stable |
| Major only | `rojo-rbx/rojo@7` | Latest within major version |
| Major.minor | `rojo-rbx/rojo@7.6` | Latest patch only |
| Exact | `rojo-rbx/rojo@7.6.1` | Fully reproducible |

```bash
# Examples
rokit add rojo-rbx/rojo           # Latest stable
rokit add rojo-rbx/rojo@7         # Latest 7.x.x
rokit add rojo-rbx/rojo@7.6.1     # Exact version
```

## Checking Installed Versions

```bash
rokit list
```

## Updating Tools

```bash
# Update a specific tool to latest
rokit add rojo-rbx/rojo

# Update Rokit itself
rokit self-update
```

## Tool Overview

### Rojo
- Syncs filesystem to Roblox Studio
- Config: `default.project.json`
- Supports `$path`, `$className`, `$properties`
- Requires Studio plugin for live sync

### Wally
- Package manager for Luau
- Config: `wally.toml`
- Packages install to `Packages/`
- Lock file: `wally.lock`

### StyLua
- Luau-aware code formatter
- Config: `stylua.toml`
- Supports `sort_requires`

### Selene
- Luau linter
- Config: `selene.toml`
- Use `std = "roblox"` for Roblox API support

## Troubleshooting

### "Tool not found" after install
```bash
# Restart terminal or source shell config
source ~/.bashrc  # or ~/.zshrc
```

### Reinstall a tool
```bash
rokit remove rojo
rokit add rojo-rbx/rojo
```

### Wally install fails
```bash
rm -rf ~/.wally
wally install
```
