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
# rokit.toml (committed to git) — verify current versions before writing
[tools]
rojo = "rojo-rbx/rojo@7.6.1"
wally = "UpliftGames/wally@0.3.2"
selene = "Kampfkarren/selene@0.30.0"
stylua = "JohnnyMorganz/StyLua@2.3.1"
```

Team members run `rokit install` after pulling to get exact versions.

### Wally Package Pinning

**Important:** Wally requires a version specifier — entries without `@version` will fail to install. Use caret ranges or exact versions:

```toml
# Caret range (latest compatible within major/minor)
[dependencies]
Promise = "evaera/promise@^4.0.0"   # Gets 4.x.x, never 5.0.0

# Exact (fully reproducible, team/production)
[dependencies]
Promise = "evaera/promise@4.0.0"
```

**Recommendation:** Use caret ranges (`^major.minor.patch`) by default. Pin to exact versions for CI/CD or team projects where reproducibility matters. Always verify current versions before writing — check via `curl -s "https://raw.githubusercontent.com/UpliftGames/wally-index/main/AUTHOR/PACKAGE" | tail -1`.

## Checking Installed Versions

```bash
rokit list
```

## Updating Tools

```bash
# Update a specific tool to latest
rokit update rojo-rbx/rojo

# Update all tools in rokit.toml
rokit update

# Update Rokit itself
rokit self-update
```

## Tool Overview

### Rokit
- Toolchain manager for Roblox projects
- Config: `rokit.toml`
- Installs and manages all other tools (Rojo, Wally, StyLua, Selene)
- Run `rokit install` to install tools from config

### Rojo
- Syncs filesystem to Roblox Studio
- Config: `default.project.json`
- Supports `$path`, `$className`, `$properties`
- Requires Studio plugin for live sync
- v7.7.0+: `rojo syncback` converts existing places to Rojo projects

### Wally
- Package manager for Luau
- Config: `wally.toml`
- Packages install to `Packages/`
- Lock file: `wally.lock`

### StyLua
- Luau-aware code formatter
- Config: `.stylua.toml` (v2.0+) or `stylua.toml` (still supported)
- Supports `sort_requires`
- v2.0+ includes language server mode (`stylua --lsp`)

### Selene
- Luau linter
- Config: `selene.toml`
- Use `std = "roblox"` for Roblox API support

### Lune (Optional)
- Standalone Luau runtime
- Run Luau scripts outside of Roblox Studio
- Useful for build scripts, testing, CI/CD automation
- Install: `rokit add lune-org/lune`

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
