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

### When to Pin Versions

| Context | Recommendation | Why |
|---------|----------------|-----|
| **Solo project, learning** | No pinning | Get latest features, learn current APIs |
| **Solo project, production** | Major version | Avoid breaking changes, still get patches |
| **Team project** | Exact versions | Everyone uses same tooling, no "works on my machine" |
| **CI/CD pipelines** | Exact versions | Reproducible builds, predictable behavior |
| **Open source project** | Major version | Contributors can use compatible versions |

### Example: Team Project Setup

```toml
# rokit.toml (committed to git)
[tools]
rojo = "rojo-rbx/rojo@7.6.1"
wally = "UpliftGames/wally@0.3.2"
selene = "Kampfkarren/selene@0.27.1"
stylua = "JohnnyMorganz/StyLua@0.20.0"
```

Team members run `rokit install` after pulling to get exact versions.

### Wally Package Pinning

Same principles apply to Wally packages in `wally.toml`:

```toml
# No pin (latest compatible)
[dependencies]
Promise = "evaera/promise"

# Pinned to major (safe updates)
[dependencies]
Promise = "evaera/promise@4"

# Exact (team projects, production)
[dependencies]
Promise = "evaera/promise@4.0.0"
```

**Recommendation:** For team projects, pin Wally packages to exact versions and update deliberately.

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

## A Note on GitHub Activity

Some libraries show infrequent commits. This usually means **"stable and feature-complete,"** not "abandoned."

Examples:
- **GoodSignal** — Does one job perfectly. No changes needed.
- **ProfileStore** — Mature, battle-tested. Updates only for engine changes.

Before assuming a library is abandoned, check:

1. **Are issues being responded to?** Active maintainer engagement matters more than commit frequency.
2. **Are there recent releases?** Releases can happen without commits (version bumps, CI builds).
3. **Is it still recommended in DevForum discussions?** Community consensus is a strong signal.
4. **When was the last meaningful update?** A library last updated 6 months ago for a bug fix is healthy.

**Red flags** (actually abandoned):
- Unanswered issues piling up for 1+ years
- Broken with current Roblox engine, no fix in sight
- Author explicitly archived the repo
- Superseded by author's own newer library (e.g., ProfileService → ProfileStore)

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

### Version conflicts in team projects

If team members have different versions:
1. Ensure `rokit.toml` is committed to git
2. Everyone runs `rokit install` after pulling
3. Consider pinning to exact versions for critical tools
