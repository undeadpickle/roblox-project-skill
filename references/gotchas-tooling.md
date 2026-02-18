# Gotchas: Tooling (Rojo, Wally, Git)

Issues with the development toolchain — Rojo sync, Wally packages, and Git workflows.

**AI agents:** Update this file when you discover new tooling issues. Check before debugging tool-related problems.

## Contents

- [Rojo](#rojo) — Script Sync vs Rojo, `$ignoreUnknownInstances`, sync issues, Team Create conflicts
- [Wally](#wally) — Private flag, realm separation, dependency resolution
- [Git](#git) — Place files, wally.lock, line endings

---

## Rojo

### Studio Script Sync vs Rojo

Roblox released **Studio Script Sync** (beta, Nov 2025) which syncs scripts to local files without Rojo. Should you switch?

| Use Case | Recommendation |
|----------|----------------|
| Solo dev, simple project, staying in Studio | Script Sync may work |
| Team project, Git workflow, CI/CD | **Rojo** (more mature, full ecosystem) |
| External tooling (Selene, StyLua, Wally) | **Rojo** (Script Sync doesn't integrate) |
| Full project structure control | **Rojo** (Script Sync is script-only) |

**Bottom line:** Script Sync is promising but still beta with limitations. Rojo remains the production-grade choice for serious projects. This skill defaults to Rojo.

### Rojo Deletes Studio-Created Assets (`$ignoreUnknownInstances`)

> **What is `$ignoreUnknownInstances`?**
> A Rojo setting that tells it to leave Studio-created objects alone. Without it, Rojo deletes anything it doesn't recognize in the filesystem—including your hand-placed models and particles.

By default, Rojo deletes any instances in Studio that don't exist in your filesystem. This means particles, models, sounds, and other Studio-created assets disappear on sync.

```json
// ❌ DEFAULT BEHAVIOR: Studio assets get deleted
"Workspace": {
  "$properties": { "FilteringEnabled": true }
}

// ✅ RECOMMENDED: Preserve Studio-created instances
"Workspace": {
  "$properties": { "FilteringEnabled": true },
  "$ignoreUnknownInstances": true
}
```

**Best practice:** Add `"$ignoreUnknownInstances": true` to every service in your project.json. This enables a "hybrid workflow" where Rojo manages code and Studio manages assets.

Services that commonly need it: `Workspace`, `ServerStorage`, `StarterGui`, `Lighting`, `SoundService`, `ReplicatedStorage`, `StarterPlayer`.

Source: [GitHub issue #716](https://github.com/rojo-rbx/rojo/issues/716)

### Don't use `$schema` in project.json

Current Rojo versions throw parse errors if you include a `$schema` field.

```json
// ❌ Causes parse error
{
  "$schema": "...",
  "name": "MyGame"
}

// ✅ Works
{
  "name": "MyGame"
}
```

### Scripts Not Syncing After Edits

Most common Rojo complaint. Checklist:

1. **Is the Rojo plugin actually connected?** The icon should be green/active.
2. **Did you restart Studio without reconnecting?** Rojo doesn't auto-reconnect.
3. **Multiple Rojo plugins installed?** Remove duplicates from Studio plugins folder.
4. **File saved?** Rojo syncs on file save, not on every keystroke.
5. **Check port conflicts:** `lsof -i :34872` (default Rojo port)

### Two-Way Sync Crashes ("Access Denied")

> **What is two-way sync?**
> Normally, Rojo syncs one direction: files → Studio. Two-way sync is an experimental feature that also syncs Studio → files, so changes you make in Studio appear in your code files. It's useful but can be unstable.

Two-way sync (experimental) can crash with permission errors:

```
[ERROR rojo] Details: called `Result::unwrap()` on an `Err` value:
Os { code: 5, kind: PermissionDenied, message: "Access is denied." }
```

**Causes:**
- Project on OneDrive/Dropbox with sync conflicts
- Files on external/SD drives with permission issues
- Antivirus blocking file writes

**Fix:** Move project to a local, non-synced folder. Or disable two-way sync.

### macOS: Paths with `../` Ancestors Don't Trigger Sync

Known bug: If your project.json references paths above the project root (like `../../shared/`), changes in those folders won't trigger sync on macOS.

**Workaround:** Keep all source files inside the project directory, or manually reconnect when editing shared files.

### MeshPart/UnionOperation Not Syncing Properly

After a Roblox update, `Instance.new("MeshPart")` succeeds but creates an empty mesh. Rojo can't set `MeshContent` after creation.

**Workaround:** Keep complex MeshParts in a separate `.rbxm` file and use `$path` to reference it, or create them manually in Studio.

### Team Create Confusion

Rojo syncs on file save—it doesn't integrate with Team Create's commit workflow. If your team uses both:

- Rojo changes bypass Team Create and apply immediately
- This can cause conflicts if someone is editing in Studio without Rojo

**Recommendation:** Pick one workflow. For code: Rojo + Git. For level design: Team Create.

### Sync Issues Checklist (Comprehensive)

If Rojo isn't syncing properly:

1. **Is Rojo plugin installed AND connected in Studio?** Check the Rojo toolbar button.
2. **Do project.json paths match actual file structure?** Typos in `$path` are common.
3. **Naming conflicts?** Studio instance names vs filesystem names must align.
4. **init.luau vs .src.luau?** Pick one convention. `init.luau` inside a folder = ModuleScript with folder name.
5. **Rojo version mismatch?** CLI and plugin versions should match. Run `rojo --version` and check plugin.
6. **Multiple plugins?** Remove duplicates from Roblox plugins folder.
7. **Port in use?** Check `lsof -i :34872` and kill any conflicting processes.

---

## Wally

### Add `private = true`

Prevents accidental publishing to the Wally registry:

```toml
[package]
name = "username/project-name"
version = "0.1.0"
private = true
```

### "Resolved 0 Dependencies"

If `wally install` outputs "Resolved 0 dependencies" but you have packages listed:

1. **Check section names:** It's `[dependencies]`, not `[dependancies]` or `[dependency]`
2. **Packages must be under correct section:**
```toml
# ❌ Wrong - packages outside sections
Promise = "evaera/promise@4"

# ✅ Correct
[dependencies]
Promise = "evaera/promise@4"
```

### Packages Installing "Outside DataModel"

Wally creates a `Packages/` folder on disk. If you see packages in the Explorer but they're grayed out or "outside" the DataModel, your `default.project.json` doesn't reference them:

```json
"ReplicatedStorage": {
  "Packages": {
    "$path": "Packages"
  }
}
```

### Shared Dependency Missing from ServerPackages

Bug: When a server-only package depends on a shared package, Wally may install the shared package only in `ServerPackages/`, but the link still looks for it in `Packages/`.

**Workaround:** Add the shared dependency explicitly to your `[dependencies]` section:

```toml
[dependencies]
Promise = "evaera/promise@4"  # Explicitly add shared deps

[server-dependencies]
ProfileStore = "lm-loleris/profilestore"  # Uses Promise internally
```

### Realm Separation

| Realm | Use For |
|-------|---------|
| `[dependencies]` | Shared code (client + server access) |
| `[server-dependencies]` | Server-only (ProfileStore, data libs) |
| `[dev-dependencies]` | Testing tools, not shipped |

### "Package not found" errors

1. Check spelling and case (Wally is case-sensitive)
2. Verify package exists on [wally.run](https://wally.run)
3. Try clearing cache: `rm -rf ~/.wally && wally install`

---

## Git

### Large place files

Don't commit `.rbxl` files to git—they're large binaries:

```gitignore
*.rbxl
*.rbxlx
```

### wally.lock: commit or not?

**Commit it.** Ensures everyone on the team gets the same package versions.

### Line ending issues (Windows)

Use `.gitattributes` to enforce LF endings:

```
* text=auto
*.luau text eol=lf
*.lua text eol=lf
```
