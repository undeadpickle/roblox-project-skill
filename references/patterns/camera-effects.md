# Camera Effects

Patterns for camera shake, post-processing, and screen effects.

**Use cases:** Impact feedback, horror atmosphere, damage indication, transitions, cinematics

---

## Camera Shake System

Stackable camera shake with presets and decay.

```luau
-- Client: CameraShake.luau
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local CameraShake = {}

type ShakeInstance = {
    magnitude: number,
    frequency: number,
    duration: number,
    elapsed: number,
    decay: boolean,
}

local activeShakes: { ShakeInstance } = {}
local baseOffset = CFrame.new()

function CameraShake.init()
    RunService.RenderStepped:Connect(function(dt)
        CameraShake.update(dt)
    end)
end

-- Add a new shake
function CameraShake.shake(magnitude: number, frequency: number, duration: number, decay: boolean?)
    table.insert(activeShakes, {
        magnitude = magnitude,
        frequency = frequency,
        duration = duration,
        elapsed = 0,
        decay = decay ~= false, -- Default to true
    })
end

-- Presets for common use cases
function CameraShake.light()
    CameraShake.shake(0.1, 20, 0.2, true)
end

function CameraShake.medium()
    CameraShake.shake(0.3, 15, 0.4, true)
end

function CameraShake.heavy()
    CameraShake.shake(0.6, 10, 0.6, true)
end

function CameraShake.explosion()
    CameraShake.shake(1.0, 8, 0.8, true)
end

function CameraShake.impact()
    CameraShake.shake(0.4, 25, 0.15, true)
end

function CameraShake.continuous(magnitude: number, frequency: number)
    -- For ongoing effects like engines, earthquakes
    -- Returns an ID to stop later
    local shake = {
        magnitude = magnitude,
        frequency = frequency,
        duration = math.huge,
        elapsed = 0,
        decay = false,
    }
    table.insert(activeShakes, shake)
    return shake
end

function CameraShake.stop(shakeInstance: ShakeInstance)
    local index = table.find(activeShakes, shakeInstance)
    if index then
        table.remove(activeShakes, index)
    end
end

function CameraShake.stopAll()
    table.clear(activeShakes)
end

function CameraShake.update(dt: number)
    local camera = Workspace.CurrentCamera
    if not camera then return end

    local totalOffset = Vector3.zero

    -- Process all active shakes
    for i = #activeShakes, 1, -1 do
        local shake = activeShakes[i]
        shake.elapsed += dt

        if shake.elapsed >= shake.duration then
            table.remove(activeShakes, i)
        else
            -- Calculate shake intensity
            local intensity = shake.magnitude
            if shake.decay then
                local progress = shake.elapsed / shake.duration
                intensity = shake.magnitude * (1 - progress)
            end

            local time = shake.elapsed * shake.frequency

            -- Use different frequencies for each axis to avoid repetitive patterns
            local offsetX = math.sin(time * 1.1) * intensity
            local offsetY = math.cos(time * 1.3) * intensity
            local offsetZ = math.sin(time * 0.9) * intensity * 0.5

            totalOffset += Vector3.new(offsetX, offsetY, offsetZ)
        end
    end

    -- Apply cumulative shake
    if totalOffset.Magnitude > 0 then
        camera.CFrame = camera.CFrame * CFrame.new(totalOffset)
    end
end

return CameraShake
```

### Usage

```luau
CameraShake.init()

-- On damage
CameraShake.impact()

-- On explosion
CameraShake.explosion()

-- Vehicle engine rumble
local engineShake = CameraShake.continuous(0.05, 30)
-- Later: CameraShake.stop(engineShake)
```

---

## Post-Processing Controller

Dynamic color grading, blur, and effects based on game state.

```luau
-- Client: PostProcessing.luau
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local PostProcessing = {}

-- Effect instances
local colorCorrection: ColorCorrectionEffect
local blur: BlurEffect
local bloom: BloomEffect

-- Preset configurations
type EffectPreset = {
    saturation: number,
    contrast: number,
    brightness: number,
    tintColor: Color3,
    blur: number,
    bloom: number?,
}

local presets: { [string]: EffectPreset } = {
    normal = {
        saturation = 0,
        contrast = 0,
        brightness = 0,
        tintColor = Color3.new(1, 1, 1),
        blur = 0,
        bloom = 0,
    },
    desaturated = {
        saturation = -0.5,
        contrast = 0.1,
        brightness = 0,
        tintColor = Color3.new(1, 1, 1),
        blur = 0,
    },
    warm = {
        saturation = 0.1,
        contrast = 0.05,
        brightness = 0.05,
        tintColor = Color3.fromRGB(255, 245, 235),
        blur = 0,
    },
    cold = {
        saturation = -0.1,
        contrast = 0.1,
        brightness = -0.05,
        tintColor = Color3.fromRGB(230, 240, 255),
        blur = 0,
    },
    horror = {
        saturation = -0.3,
        contrast = 0.2,
        brightness = -0.1,
        tintColor = Color3.fromRGB(200, 200, 220),
        blur = 0,
    },
    damage = {
        saturation = -0.6,
        contrast = 0.3,
        brightness = -0.15,
        tintColor = Color3.fromRGB(255, 180, 180),
        blur = 3,
    },
    lowHealth = {
        saturation = -0.7,
        contrast = 0.2,
        brightness = -0.2,
        tintColor = Color3.fromRGB(255, 150, 150),
        blur = 2,
    },
    death = {
        saturation = -1,
        contrast = 0,
        brightness = -0.3,
        tintColor = Color3.fromRGB(150, 150, 150),
        blur = 10,
    },
    underwater = {
        saturation = -0.2,
        contrast = -0.1,
        brightness = -0.1,
        tintColor = Color3.fromRGB(150, 200, 255),
        blur = 1,
    },
}

local currentPreset = "normal"

function PostProcessing.init()
    -- Create or get ColorCorrectionEffect
    colorCorrection = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
    if not colorCorrection then
        colorCorrection = Instance.new("ColorCorrectionEffect")
        colorCorrection.Parent = Lighting
    end

    -- Create or get BlurEffect
    blur = Lighting:FindFirstChildOfClass("BlurEffect")
    if not blur then
        blur = Instance.new("BlurEffect")
        blur.Size = 0
        blur.Parent = Lighting
    end

    -- Create or get BloomEffect
    bloom = Lighting:FindFirstChildOfClass("BloomEffect")
    if not bloom then
        bloom = Instance.new("BloomEffect")
        bloom.Intensity = 0
        bloom.Parent = Lighting
    end
end

function PostProcessing.setPreset(presetName: string, transitionTime: number?)
    local preset = presets[presetName]
    if not preset then
        warn("Unknown preset:", presetName)
        return
    end

    currentPreset = presetName
    applyPreset(preset, transitionTime or 0.5)
end

function PostProcessing.addPreset(name: string, config: EffectPreset)
    presets[name] = config
end

-- Apply custom settings without a named preset
function PostProcessing.custom(config: EffectPreset, transitionTime: number?)
    applyPreset(config, transitionTime or 0.5)
end

-- Flash effect (for damage, jumpscare, etc.)
function PostProcessing.flash(preset: string, duration: number?)
    duration = duration or 0.3
    local originalPreset = currentPreset

    PostProcessing.setPreset(preset, 0.05)

    task.delay(duration, function()
        PostProcessing.setPreset(originalPreset, 0.3)
    end)
end

-- Pulse effect (heartbeat, danger)
function PostProcessing.pulse(preset: string, pulseTime: number, count: number?)
    count = count or 3

    task.spawn(function()
        for i = 1, count do
            PostProcessing.setPreset(preset, pulseTime * 0.3)
            task.wait(pulseTime * 0.5)
            PostProcessing.setPreset("normal", pulseTime * 0.3)
            task.wait(pulseTime * 0.5)
        end
    end)
end

local function applyPreset(preset: EffectPreset, tweenTime: number)
    local tweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    TweenService:Create(colorCorrection, tweenInfo, {
        Saturation = preset.saturation,
        Contrast = preset.contrast,
        Brightness = preset.brightness,
        TintColor = preset.tintColor,
    }):Play()

    TweenService:Create(blur, tweenInfo, {
        Size = preset.blur,
    }):Play()

    if preset.bloom and bloom then
        TweenService:Create(bloom, tweenInfo, {
            Intensity = preset.bloom,
        }):Play()
    end
end

return PostProcessing
```

### Usage

```luau
PostProcessing.init()

-- On damage
PostProcessing.flash("damage", 0.2)

-- Low health warning
PostProcessing.setPreset("lowHealth")

-- Enter horror area
PostProcessing.setPreset("horror", 1.5)

-- Heartbeat effect
PostProcessing.pulse("damage", 1, 3)

-- Custom effect
PostProcessing.custom({
    saturation = 0.3,
    contrast = 0.1,
    brightness = 0.1,
    tintColor = Color3.new(1, 1, 0.9),
    blur = 0,
}, 0.5)
```

---

## Screen Vignette

Darken screen edges for focus or danger indication.

```luau
-- Client: Vignette.luau
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Vignette = {}

local vignetteFrame: Frame
local currentIntensity = 0
local targetIntensity = 0

function Vignette.init()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    -- Create vignette UI
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "VignetteGui"
    screenGui.IgnoreGuiInset = true
    screenGui.DisplayOrder = 100
    screenGui.Parent = playerGui

    vignetteFrame = Instance.new("Frame")
    vignetteFrame.Name = "Vignette"
    vignetteFrame.Size = UDim2.new(1, 0, 1, 0)
    vignetteFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    vignetteFrame.BackgroundTransparency = 1
    vignetteFrame.BorderSizePixel = 0
    vignetteFrame.Parent = screenGui

    -- Radial gradient for vignette effect
    local gradient = Instance.new("UIGradient")
    gradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 1),
        NumberSequenceKeypoint.new(0.8, 0.5),
        NumberSequenceKeypoint.new(1, 0),
    })
    gradient.Parent = vignetteFrame

    -- Update loop
    RunService.RenderStepped:Connect(function(dt)
        Vignette.update(dt)
    end)
end

function Vignette.setIntensity(intensity: number)
    targetIntensity = math.clamp(intensity, 0, 1)
end

function Vignette.pulse(intensity: number, duration: number)
    Vignette.setIntensity(intensity)
    task.delay(duration, function()
        Vignette.setIntensity(0)
    end)
end

function Vignette.update(dt: number)
    currentIntensity = currentIntensity + (targetIntensity - currentIntensity) * math.min(1, dt * 5)

    if vignetteFrame then
        -- Intensity 0 = fully transparent, 1 = strong vignette
        vignetteFrame.BackgroundTransparency = 1 - (currentIntensity * 0.7)
    end
end

return Vignette
```

---

## Screen Flash

Quick screen flash for impacts, lightning, explosions.

```luau
-- Client: ScreenFlash.luau
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local ScreenFlash = {}

local flashFrame: Frame

function ScreenFlash.init()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ScreenFlashGui"
    screenGui.IgnoreGuiInset = true
    screenGui.DisplayOrder = 99
    screenGui.Parent = playerGui

    flashFrame = Instance.new("Frame")
    flashFrame.Name = "Flash"
    flashFrame.Size = UDim2.new(1, 0, 1, 0)
    flashFrame.BackgroundColor3 = Color3.new(1, 1, 1)
    flashFrame.BackgroundTransparency = 1
    flashFrame.BorderSizePixel = 0
    flashFrame.Parent = screenGui
end

function ScreenFlash.flash(color: Color3?, intensity: number?, duration: number?)
    color = color or Color3.new(1, 1, 1)
    intensity = intensity or 0.8
    duration = duration or 0.3

    flashFrame.BackgroundColor3 = color
    flashFrame.BackgroundTransparency = 1 - intensity

    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(flashFrame, tweenInfo, {
        BackgroundTransparency = 1,
    }):Play()
end

-- Presets
function ScreenFlash.white(duration: number?)
    ScreenFlash.flash(Color3.new(1, 1, 1), 0.9, duration)
end

function ScreenFlash.red(duration: number?)
    ScreenFlash.flash(Color3.new(1, 0.2, 0.2), 0.6, duration or 0.2)
end

function ScreenFlash.damage()
    ScreenFlash.red(0.15)
end

function ScreenFlash.heal()
    ScreenFlash.flash(Color3.new(0.3, 1, 0.3), 0.4, 0.3)
end

function ScreenFlash.lightning()
    ScreenFlash.white(0.1)
end

return ScreenFlash
```

---

## Combining Effects

Example of using multiple effects together:

```luau
-- Client: EffectsController.luau
local CameraShake = require(script.Parent.CameraShake)
local PostProcessing = require(script.Parent.PostProcessing)
local ScreenFlash = require(script.Parent.ScreenFlash)
local Vignette = require(script.Parent.Vignette)

local EffectsController = {}

function EffectsController.init()
    CameraShake.init()
    PostProcessing.init()
    ScreenFlash.init()
    Vignette.init()
end

function EffectsController.onDamage(damagePercent: number)
    CameraShake.impact()
    ScreenFlash.damage()
    PostProcessing.flash("damage", 0.2)

    -- Scale vignette with health
    Vignette.setIntensity(damagePercent)
end

function EffectsController.onExplosion(distance: number)
    local intensity = math.clamp(1 - (distance / 50), 0, 1)
    CameraShake.shake(1 * intensity, 8, 0.8)
    ScreenFlash.white(0.2)
end

function EffectsController.onDeath()
    PostProcessing.setPreset("death", 1)
    Vignette.setIntensity(0.8)
    CameraShake.heavy()
end

function EffectsController.onRespawn()
    PostProcessing.setPreset("normal", 0.5)
    Vignette.setIntensity(0)
end

return EffectsController
```

---

## Pitfalls

### ❌ Applying shake directly to CFrame without accumulation
**Problem:** Multiple shakes don't stack properly.
**Fix:** Sum all shake offsets before applying to camera.

### ❌ No transition between post-processing states
**Problem:** Jarring visual changes.
**Fix:** Always tween effect changes over 0.3-1s.

### ❌ Overusing effects
**Problem:** Visual fatigue, effects lose impact.
**Fix:** Use sparingly. Effects should punctuate moments, not be constant.

### ❌ Not respecting user preferences
**Problem:** Some players are sensitive to screen shake or flashing.
**Fix:** Add settings to disable/reduce effects. Respect accessibility.
