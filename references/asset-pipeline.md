# Asset Pipeline for Roblox Projects

How assets (images, sounds, models, maps) flow from source files into your game.

## Workflow Options

### Partially Managed (Recommended Start)

**Rojo manages code. Studio manages everything else.**

```
Your Rojo project:
  src/           ← Rojo syncs scripts
  Packages/      ← Wally dependencies
  
Roblox Studio:
  Workspace      ← Build maps directly in Studio
  Assets folder  ← Import images/sounds via Asset Manager
```

**When to use:** Most projects. Especially with builders/artists who work in Studio.

**How it works:**
1. Scripts sync via Rojo
2. Build maps in Studio (save place file locally as backup)
3. Upload images/sounds via Studio's Asset Manager
4. Reference assets by ID in code: `rbxassetid://123456789`

**Pros:** Simple, familiar to Studio users, no extra tooling  
**Cons:** Assets not in version control, manual ID management


### Fully Managed (Advanced)

**Rojo controls everything. Build place from scratch with `rojo build`.**

```
your-project/
├── src/              # Scripts (Luau)
├── assets/           # Raw files → uploaded → referenced
│   ├── images/
│   ├── sounds/
│   └── models/
├── map/              # Exported .rbxm files from Studio
│   ├── Workspace.rbxm
│   └── Lighting.rbxm
└── default.project.json  # References all of above
```

**When to use:** Solo devs wanting hermetic builds, CI/CD pipelines, asset version control.

**How it works:**
1. Raw asset files live in `assets/`
2. Tool (Asphalt) uploads to Roblox, gets asset IDs
3. Tool generates Luau module with IDs
4. Build place from project: `rojo build -o game.rbxl`

**Pros:** Everything in git, reproducible builds, CI/CD friendly  
**Cons:** More setup, builders need to export `.rbxm` files


## Asset Folder Structure

Regardless of workflow, organize assets predictably:

```
assets/
├── images/
│   ├── ui/           # UI icons, buttons, backgrounds
│   ├── textures/     # Part textures, decals
│   └── effects/      # Particle textures, billboards
├── sounds/
│   ├── sfx/          # Sound effects
│   ├── music/        # Background tracks
│   └── ui/           # Button clicks, notifications
├── models/           # .rbxm files exported from Studio
│   ├── props/
│   ├── npcs/
│   └── tools/
└── animations/       # KeyframeSequence exports
```


## Roblox Studio Packages (Alternative for Asset-Heavy Teams)

Roblox Studio has a built-in **Packages** feature for reusable assets (models, UI kits, rigs). This is separate from Wally packages (which are code libraries).

**When to consider Studio Packages:**
- Large teams sharing prefabs across multiple places
- Asset-heavy games with lots of reusable models
- Using Feature Packages (Roblox's pre-built game features)

**When to skip:**
- Code-focused projects (Wally + Rojo is better)
- Solo developers (overkill)
- You want everything in Git (Studio Packages are cloud-only)

Learn more: [Roblox Packages Documentation](https://create.roblox.com/docs/studio/packages)

This skill focuses on code-first workflows, so Studio Packages aren't covered in depth. Use them alongside Rojo if your team needs asset versioning.


## Asset Tools

### Asphalt (Recommended)

Modern asset manager. Uploads files, generates code to reference them.

**Install:**
```bash
rokit add jackTabsCode/asphalt
```

**Configure (`asphalt.toml`):**
```toml
[creator]
type = "user"  # or "group"
id = 12345678  # Your Roblox user/group ID

[codegen]
style = "nested"  # or "flat"

[inputs.assets]
path = "assets/**/*"
output_path = "src/shared/Assets"
```

**Sync assets:**
```bash
# Upload to Roblox (requires API key)
asphalt sync --target cloud

# Test locally in Studio first
asphalt sync --target studio
```

**Generated code:**
```lua
-- src/shared/Assets.luau (auto-generated)
return {
    images = {
        ui = {
            button = "rbxassetid://123456789",
            icon = "rbxassetid://987654321",
        },
    },
    sounds = {
        sfx = {
            jump = "rbxassetid://111222333",
        },
    },
}
```

**Use in code:**
```lua
local Assets = require(ReplicatedStorage.Shared.Assets)
local button = Instance.new("ImageButton")
button.Image = Assets.images.ui.button
```

### Tarmac (Legacy Alternative)

Roblox-maintained. Supports spritesheets. Less active development.

```bash
rokit add Roblox/tarmac
```

Mostly same workflow as Asphalt. Use Asphalt for new projects.


## Working With Models (.rbxm)

For map geometry, props, and complex models:

### Export from Studio
1. Select instances in Explorer
2. Right-click → "Save to File..."
3. Save as `.rbxm` (binary) or `.rbxmx` (XML, larger but diffable)
4. Place in `assets/models/` or `map/`

### Reference in project.json
```json
{
  "tree": {
    "Workspace": {
      "$className": "Workspace",
      "Map": {
        "$path": "map/Workspace.rbxm"
      }
    }
  }
}
```

### Automation with Lune

For fully managed projects, automate model exports:

```lua
-- lune/export-map.luau
local roblox = require("@lune/roblox")
local fs = require("@lune/fs")

local game = roblox.deserializePlace(fs.readFile("game.rbxl"))
fs.writeFile("map/Workspace.rbxm", roblox.serializeModel(game.Workspace))
fs.writeFile("map/Lighting.rbxm", roblox.serializeModel(game.Lighting))
```

```bash
rokit add lune-org/lune
lune run export-map
```


## Asset Types Reference

| Type | Formats | Upload Method | Notes |
|------|---------|---------------|-------|
| Images | .png, .jpg, .gif, .tga, .bmp | Asset Manager or Asphalt | Decals, textures, UI |
| Sounds | .ogg, .mp3, .flac, .wav | Asset Manager or Asphalt | .ogg preferred |
| Videos | .mp4, .webm | Asset Manager | Costs Robux |
| Meshes | .fbx, .obj | 3D Importer in Studio | Use Importer for settings |
| Models | .rbxm, .rbxmx | Rojo sync | Exported from Studio |
| Animations | KeyframeSequence | Animation Editor or Asphalt | Export as .rbxm |


## Recommendations by Project Type

| Project | Recommended Approach |
|---------|---------------------|
| **Learning/Prototyping** | Partially managed. Focus on code. |
| **Solo game** | Partially managed. Upgrade later if needed. |
| **Team with builders** | Partially managed. Builders stay in Studio. |
| **Library/Plugin** | Fully managed. No map, just code. |
| **CI/CD pipeline** | Fully managed. Hermetic builds required. |


## Quick Start (Partially Managed)

Don't overthink it. Most projects:

1. **Code** → `src/` folder, synced by Rojo
2. **Map** → Build in Studio, save `game.rbxl` locally (backup)
3. **Images/Sounds** → Upload via Studio's Asset Manager
4. **Asset IDs** → Create manual `Assets.luau` module:

```lua
-- src/shared/Assets.luau
return {
    sounds = {
        buttonClick = "rbxassetid://123456789",
        coinCollect = "rbxassetid://987654321",
    },
    images = {
        logo = "rbxassetid://111222333",
    },
}
```

Graduate to Asphalt when:
- You have 50+ assets
- You want assets in version control
- You're setting up CI/CD
