# Audio Systems

Modern audio patterns using Roblox's new Audio API (2024+).

**Use cases:** Dynamic music, ambient soundscapes, positional audio, intensity-based layers, horror atmosphere, combat audio

---

## New Audio API Overview

The new Audio API replaces legacy `Sound` objects with a more powerful system:

| Old (Legacy) | New (2024+) |
|--------------|-------------|
| `Sound` | `AudioPlayer` |
| Sound parented to Part | `AudioEmitter` at position |
| SoundService listener | `AudioListener` on character |
| N/A | `Wire` to connect sources |
| N/A | Acoustic Simulation (beta) |

**Advantages:**
- Built-in occlusion and reverb (via Acoustic Simulation)
- Directional audio
- More control over audio routing
- Better performance for many sources

---

## Basic Setup

```luau
-- Client: AudioSetup.luau
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")

local function setupAudioListener()
    local player = Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local rootPart = character:WaitForChild("HumanoidRootPart")

    -- Create listener attached to player
    local listener = Instance.new("AudioListener")
    listener.Parent = rootPart

    -- Set as default listener location
    SoundService.DefaultListenerLocation = Enum.ListenerLocation.Character

    return listener
end
```

---

## Dynamic Music System

Layer multiple audio tracks and crossfade based on game state.

```luau
-- Client: MusicManager.luau
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local MusicManager = {}

type MusicLayer = {
    player: AudioPlayer,
    baseVolume: number,
    currentVolume: number,
}

local layers: { [string]: MusicLayer } = {}
local currentState: string = "calm"
local transitionTime: number = 1.5

-- State definitions: which layers play at what volume for each state
local stateConfigs: { [string]: { [string]: number } } = {
    calm = {
        ambient = 0.4,
        tension = 0,
        action = 0,
        boss = 0,
    },
    exploration = {
        ambient = 0.3,
        tension = 0.2,
        action = 0,
        boss = 0,
    },
    combat = {
        ambient = 0.1,
        tension = 0.3,
        action = 0.6,
        boss = 0,
    },
    boss = {
        ambient = 0,
        tension = 0,
        action = 0.2,
        boss = 0.8,
    },
}

function MusicManager.init(tracks: { [string]: string }) -- { layerName = assetId }
    for layerName, assetId in tracks do
        local audioPlayer = Instance.new("AudioPlayer")
        audioPlayer.AssetId = assetId
        audioPlayer.Looping = true
        audioPlayer.Volume = 0
        audioPlayer.Parent = SoundService

        layers[layerName] = {
            player = audioPlayer,
            baseVolume = 0,
            currentVolume = 0,
        }

        audioPlayer:Play()
    end

    -- Update loop
    RunService.RenderStepped:Connect(function(dt)
        MusicManager.update(dt)
    end)

    -- Set initial state
    MusicManager.setState("calm")
end

function MusicManager.setState(newState: string)
    if not stateConfigs[newState] then
        warn("Unknown music state:", newState)
        return
    end

    currentState = newState
    local config = stateConfigs[newState]

    -- Update target volumes for each layer
    for layerName, layer in layers do
        layer.baseVolume = config[layerName] or 0
    end
end

function MusicManager.update(dt: number)
    local lerpSpeed = dt / transitionTime

    for _, layer in layers do
        -- Smooth transition to target volume
        local diff = layer.baseVolume - layer.currentVolume
        layer.currentVolume = layer.currentVolume + diff * math.min(1, lerpSpeed * 3)
        layer.player.Volume = layer.currentVolume
    end
end

-- Quick state helpers
function MusicManager.calm() MusicManager.setState("calm") end
function MusicManager.exploration() MusicManager.setState("exploration") end
function MusicManager.combat() MusicManager.setState("combat") end
function MusicManager.boss() MusicManager.setState("boss") end

return MusicManager
```

### Usage

```luau
MusicManager.init({
    ambient = "rbxassetid://123456789",
    tension = "rbxassetid://234567890",
    action = "rbxassetid://345678901",
    boss = "rbxassetid://456789012",
})

-- In gameplay code:
MusicManager.combat()  -- Crossfade to combat music
MusicManager.calm()    -- Return to calm
```

---

## Positional Audio (3D Sound)

For sounds that exist at world positions (footsteps, gunshots, environmental).

```luau
-- Shared: PositionalAudio.luau
local SoundService = game:GetService("SoundService")

local PositionalAudio = {}

type SoundConfig = {
    assetId: string,
    volume: number?,
    rollOffMin: number?,
    rollOffMax: number?,
    looping: boolean?,
}

-- Play a one-shot sound at a world position
function PositionalAudio.playAt(position: Vector3, config: SoundConfig): AudioPlayer
    local audioPlayer = Instance.new("AudioPlayer")
    audioPlayer.AssetId = config.assetId
    audioPlayer.Volume = config.volume or 1
    audioPlayer.Looping = config.looping or false

    local emitter = Instance.new("AudioEmitter")
    emitter.Parent = SoundService

    -- Position the emitter
    local attachment = Instance.new("Attachment")
    attachment.WorldPosition = position
    attachment.Parent = workspace.Terrain
    emitter.Parent = attachment

    -- Wire player to emitter
    local wire = Instance.new("Wire")
    wire.SourceInstance = audioPlayer
    wire.TargetInstance = emitter
    wire.Parent = audioPlayer

    audioPlayer.Parent = SoundService
    audioPlayer:Play()

    -- Cleanup when done (if not looping)
    if not config.looping then
        audioPlayer.Ended:Once(function()
            audioPlayer:Destroy()
            emitter:Destroy()
            attachment:Destroy()
        end)
    end

    return audioPlayer
end

-- Play a sound attached to a part (follows the part)
function PositionalAudio.playOnPart(part: BasePart, config: SoundConfig): AudioPlayer
    local audioPlayer = Instance.new("AudioPlayer")
    audioPlayer.AssetId = config.assetId
    audioPlayer.Volume = config.volume or 1
    audioPlayer.Looping = config.looping or false

    local emitter = Instance.new("AudioEmitter")
    emitter.Parent = part

    local wire = Instance.new("Wire")
    wire.SourceInstance = audioPlayer
    wire.TargetInstance = emitter
    wire.Parent = audioPlayer

    audioPlayer.Parent = part
    audioPlayer:Play()

    if not config.looping then
        audioPlayer.Ended:Once(function()
            audioPlayer:Destroy()
            emitter:Destroy()
        end)
    end

    return audioPlayer
end

return PositionalAudio
```

### Usage

```luau
-- Explosion at position
PositionalAudio.playAt(explosionPosition, {
    assetId = "rbxassetid://explosion_sound",
    volume = 0.8,
})

-- Footsteps on character
PositionalAudio.playOnPart(character.HumanoidRootPart, {
    assetId = "rbxassetid://footstep_sound",
    volume = 0.5,
})
```

---

## Intensity-Based Audio Layers

Audio that responds to game intensity (threat level, health, speed).

```luau
-- Client: IntensityAudio.luau
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local IntensityAudio = {}

type AudioLayer = {
    player: AudioPlayer,
    baseVolume: number,
    threshold: number, -- Intensity level where this layer activates (0-1)
}

local layers: { [string]: AudioLayer } = {}
local currentIntensity: number = 0
local targetIntensity: number = 0
local LERP_SPEED = 2

function IntensityAudio.init(layerConfigs: { { name: string, assetId: string, volume: number, threshold: number } })
    for _, config in layerConfigs do
        local audioPlayer = Instance.new("AudioPlayer")
        audioPlayer.AssetId = config.assetId
        audioPlayer.Looping = true
        audioPlayer.Volume = 0
        audioPlayer.Parent = SoundService

        layers[config.name] = {
            player = audioPlayer,
            baseVolume = config.volume,
            threshold = config.threshold,
        }

        audioPlayer:Play()
    end

    RunService.RenderStepped:Connect(function(dt)
        IntensityAudio.update(dt)
    end)
end

function IntensityAudio.setIntensity(intensity: number)
    targetIntensity = math.clamp(intensity, 0, 1)
end

function IntensityAudio.update(dt: number)
    -- Smooth intensity transition
    currentIntensity = currentIntensity + (targetIntensity - currentIntensity) * math.min(1, dt * LERP_SPEED)

    -- Update layer volumes
    for _, layer in layers do
        local targetVolume: number
        if currentIntensity >= layer.threshold then
            -- Calculate fade-in based on distance above threshold
            local fadeRange = 1 - layer.threshold
            if fadeRange > 0 then
                local fadeProgress = (currentIntensity - layer.threshold) / fadeRange
                targetVolume = layer.baseVolume * math.min(1, fadeProgress * 2)
            else
                targetVolume = layer.baseVolume
            end
        else
            targetVolume = 0
        end

        layer.player.Volume = layer.player.Volume + (targetVolume - layer.player.Volume) * math.min(1, dt * LERP_SPEED)
    end
end

return IntensityAudio
```

### Usage

```luau
IntensityAudio.init({
    { name = "ambient", assetId = "rbxassetid://ambient", volume = 0.3, threshold = 0 },
    { name = "tension", assetId = "rbxassetid://tension", volume = 0.4, threshold = 0.3 },
    { name = "danger", assetId = "rbxassetid://danger", volume = 0.5, threshold = 0.6 },
    { name = "critical", assetId = "rbxassetid://critical", volume = 0.6, threshold = 0.85 },
})

-- In gameplay:
IntensityAudio.setIntensity(0)    -- Calm
IntensityAudio.setIntensity(0.5)  -- Tense
IntensityAudio.setIntensity(1)    -- Maximum danger
```

---

## Acoustic Simulation (Beta)

Roblox's Acoustic Simulation (beta as of Jan 2025) provides automatic:
- **Occlusion** — Sounds muffled through walls
- **Diffraction** — Sounds bending around corners
- **Reverb** — Room-appropriate echo

### Enabling

1. Game Settings → Beta Features → Enable "Acoustic Simulation"
2. Sounds automatically respond to environment

### Manual Occlusion Fallback

If Acoustic Simulation isn't available, implement basic occlusion:

```luau
-- Client: AudioOcclusion.luau
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local AudioOcclusion = {}

local trackedSounds: { { player: AudioPlayer, source: Vector3, baseVolume: number } } = {}

function AudioOcclusion.track(audioPlayer: AudioPlayer, sourcePosition: Vector3)
    table.insert(trackedSounds, {
        player = audioPlayer,
        source = sourcePosition,
        baseVolume = audioPlayer.Volume,
    })
end

function AudioOcclusion.update(listenerPosition: Vector3)
    for _, tracked in trackedSounds do
        local direction = tracked.source - listenerPosition
        local result = Workspace:Raycast(listenerPosition, direction)

        if result then
            -- Sound is occluded - reduce volume
            tracked.player.Volume = tracked.baseVolume * 0.3
        else
            -- Clear line of sight
            tracked.player.Volume = tracked.baseVolume
        end
    end
end

-- Call in RenderStepped with camera position
```

---

## Sound Effects Pool

Reuse audio players for frequently played sounds (footsteps, gunshots).

```luau
-- Client: SFXPool.luau
local SoundService = game:GetService("SoundService")

local SFXPool = {}

type PooledSound = {
    player: AudioPlayer,
    inUse: boolean,
}

local pools: { [string]: { PooledSound } } = {}
local POOL_SIZE = 5

function SFXPool.init(soundConfigs: { [string]: string }) -- { name = assetId }
    for name, assetId in soundConfigs do
        pools[name] = {}

        for i = 1, POOL_SIZE do
            local audioPlayer = Instance.new("AudioPlayer")
            audioPlayer.AssetId = assetId
            audioPlayer.Parent = SoundService

            table.insert(pools[name], {
                player = audioPlayer,
                inUse = false,
            })
        end
    end
end

function SFXPool.play(soundName: string, volume: number?): AudioPlayer?
    local pool = pools[soundName]
    if not pool then
        warn("Unknown sound:", soundName)
        return nil
    end

    -- Find available player
    for _, pooled in pool do
        if not pooled.inUse then
            pooled.inUse = true
            pooled.player.Volume = volume or 1
            pooled.player:Play()

            -- Mark as available when done
            pooled.player.Ended:Once(function()
                pooled.inUse = false
            end)

            return pooled.player
        end
    end

    -- All in use - steal oldest (optional)
    warn("SFX pool exhausted for:", soundName)
    return nil
end

return SFXPool
```

---

## Pitfalls

### ❌ Using legacy Sound objects
**Problem:** Miss out on occlusion, directional audio, and modern features.
**Fix:** Use `AudioPlayer`, `AudioEmitter`, `AudioListener`, and `Wire`.

### ❌ Not cleaning up one-shot sounds
**Problem:** Memory leak from accumulating audio instances.
**Fix:** Destroy AudioPlayer and related instances when sound ends.

### ❌ No volume transitions
**Problem:** Jarring audio when switching states.
**Fix:** Always lerp/tween volume changes over 0.5-1.5 seconds.

### ❌ Too many simultaneous sounds
**Problem:** Audio becomes noise, performance suffers.
**Fix:** Use sound pools, limit concurrent sounds, prioritize important audio.

### ❌ Ignoring muted players
**Problem:** Game relies on audio cues that some players can't hear.
**Fix:** Provide visual alternatives for critical audio information.
