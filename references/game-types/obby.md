# Obby / Platformer Games

Skill-based games where players navigate obstacles, race, or complete platforming challenges.

**Examples:** Tower of Hell, Escape Room Obby, Speed Run 4, Parkour games, Racing obbies

---

## Implied Decisions

When you say "obby" or "platformer," you're usually implying:

| Decision | Typical Answer | Why |
|----------|---------------|-----|
| Session format | Runs/attempts | Players try, fail, retry — discrete attempts |
| Persistence | Light or None | Checkpoints, maybe cosmetics/unlocks, not economy |
| Exploit sensitivity | Low-Medium | Cheating affects leaderboards but not other players directly |
| Authority model | Client-trusted for movement | Server can't validate every jump in real-time |
| Structure | Simple or Layered | Less server logic needed than economy games |

**If these don't match your vision, adjust during wizard setup.** But this is the default.

---

## Recommended Packages

```toml
[dependencies]
Promise = "evaera/promise@^4.0.0"        # Async operations
GoodSignal = "stravant/goodsignal@^0.3.1" # Custom events
Trove = "sleitnick/trove@^1.8.0"         # Cleanup management
```

**Optional:**
```toml
[server-dependencies]
ProfileStore = "lm-loleris/profilestore@^1.0.3"  # Only if saving progress/unlocks
```

**Often not needed:** Heavy data persistence, rate limiters (unless competitive)

---

## MVP Checklist

Build these in order for a playable vertical slice:

### Phase 1: Core Loop (build first)
- [ ] **Spawn point** — Player starts at beginning
- [ ] **3-5 obstacles** — Enough variety to test the feel
- [ ] **Death/reset handling** — Fall detection, respawn at start
- [ ] **Finish detection** — Reaching the end triggers completion
- [ ] **Basic timer** — Show elapsed time (even if not saved)

**Milestone:** Player can attempt the obby, die, retry, and complete it with a time shown.

### Phase 2: Progression
- [ ] Checkpoint system (touch checkpoint → respawn there)
- [ ] Stage selection or level progression
- [ ] Time saved to leaderboard
- [ ] Personal best tracking

### Phase 3: Engagement
- [ ] Multiple difficulty paths or stages
- [ ] Cosmetic rewards (trails, effects)
- [ ] Daily/weekly challenges
- [ ] Multiplayer racing mode

---

## Reusable Patterns

See [patterns/](../patterns/INDEX.md) for code that applies across game types.

| Pattern | Use in Obby Games |
|---------|-------------------|
| [Trigger Systems](../patterns/trigger-systems.md) | Checkpoint triggers, finish line detection, kill zones |
| [Anti-Exploit](../patterns/anti-exploit.md) | Completion time validation, movement sanity checks |
| [Audio Systems](../patterns/audio-systems.md) | Checkpoint sounds, completion fanfare, ambient music |
| [Camera Effects](../patterns/camera-effects.md) | Screen shake on death, completion effects |

---

## Common Patterns

### Architecture Overview

```
Server                          Client
──────                          ──────
LeaderboardService              ObbyController
  └─ validates completions        ├─ checkpoint tracking
                                  ├─ timer display
CheckpointManager                 └─ death detection
  ├─ tracks player progress
  └─ handles respawns           TimerUI
                                  └─ shows elapsed time
    ↕ Remotes ↕
                                SpawnController
StageManager (optional)           └─ handles respawning
  └─ unlocks/progression
```

### Checkpoint System Pattern

```luau
-- Server: CheckpointManager.luau
local CheckpointManager = {}

local playerCheckpoints = {}  -- Player -> checkpointNumber

function CheckpointManager.setCheckpoint(player: Player, checkpoint: number)
    local current = playerCheckpoints[player] or 0
    -- Only allow forward progress (prevent exploits)
    if checkpoint > current then
        playerCheckpoints[player] = checkpoint
    end
end

function CheckpointManager.getCheckpoint(player: Player): number
    return playerCheckpoints[player] or 0
end

function CheckpointManager.getSpawnLocation(player: Player): CFrame
    local checkpoint = playerCheckpoints[player] or 0
    if checkpoint == 0 then
        return workspace.SpawnLocation.CFrame
    end
    local checkpointPart = workspace.Checkpoints:FindFirstChild("Checkpoint" .. checkpoint)
    return checkpointPart and checkpointPart.CFrame or workspace.SpawnLocation.CFrame
end

return CheckpointManager
```

### Timer Pattern

```luau
-- Client: TimerController.luau
local TimerController = {}

local startTime = 0
local isRunning = false

function TimerController.start()
    startTime = tick()
    isRunning = true
end

function TimerController.stop(): number
    isRunning = false
    return tick() - startTime
end

function TimerController.getElapsed(): number
    if not isRunning then return 0 end
    return tick() - startTime
end

function TimerController.reset()
    startTime = 0
    isRunning = false
end

return TimerController
```

### Death/Reset Detection

```luau
-- Client: DeathDetector.luau
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local DEATH_HEIGHT = -50  -- Y position that counts as "fell off"

local function onCharacterAdded(character)
    local humanoid = character:WaitForChild("Humanoid")
    local rootPart = character:WaitForChild("HumanoidRootPart")

    -- Detect falling off
    local connection
    connection = game:GetService("RunService").Heartbeat:Connect(function()
        if rootPart.Position.Y < DEATH_HEIGHT then
            humanoid.Health = 0
        end
    end)

    humanoid.Died:Connect(function()
        connection:Disconnect()
        -- Request respawn at checkpoint
        Remotes.RequestRespawn:FireServer()
    end)
end

player.CharacterAdded:Connect(onCharacterAdded)
```

### Completion Validation (Anti-Cheat)

```luau
-- Server: CompletionValidator.luau
local CompletionValidator = {}

-- Track when players started (prevents instant completion exploits)
local playerStartTimes = {}

local MINIMUM_COMPLETION_TIME = 10  -- Seconds - adjust based on your obby

function CompletionValidator.onPlayerStart(player: Player)
    playerStartTimes[player] = tick()
end

function CompletionValidator.validateCompletion(player: Player): (boolean, number?)
    local startTime = playerStartTimes[player]
    if not startTime then
        return false, nil  -- Never started
    end

    local completionTime = tick() - startTime

    -- Basic sanity check - can't complete faster than humanly possible
    if completionTime < MINIMUM_COMPLETION_TIME then
        warn(`{player.Name} completed suspiciously fast: {completionTime}s`)
        return false, nil
    end

    return true, completionTime
end

return CompletionValidator
```

---

## Pitfalls

### ❌ Server-authoritative movement
**Problem:** Trying to validate every jump on the server adds latency and feels bad.
**Fix:** Trust client for movement. Validate completions server-side with sanity checks (minimum time, checkpoint order).

### ❌ No minimum completion time
**Problem:** Exploiters teleport to the end instantly.
**Fix:** Track start time server-side, reject completions faster than humanly possible.

### ❌ Checkpoints that can be skipped
**Problem:** Player touches checkpoint 5 without touching 1-4.
**Fix:** Either validate checkpoint order server-side, or design levels where skipping is physically impossible.

### ❌ Timer runs on server only
**Problem:** Network latency makes timer feel unresponsive.
**Fix:** Run display timer on client, validate final time on server. Small discrepancies are acceptable.

### ❌ Leaderboard shows exploited times
**Problem:** "0.001 seconds" at the top of every leaderboard.
**Fix:** Server-side validation with minimum time threshold. Consider manual review for top times.

### ❌ No respawn protection
**Problem:** Player respawns inside a kill brick or obstacle.
**Fix:** Spawn points should have a safe zone. Add brief invincibility on respawn if needed.

---

## Variations

### Tower Obby (Vertical)
- Checkpoint every few floors
- Camera considerations for looking up
- Fall distance = major progress loss (more checkpoints needed)

### Racing Obby
- No checkpoints (single run)
- Multiplayer sync considerations
- Ghost replays for competing against self

### Escape Room / Puzzle Obby
- State management for puzzle progress
- May need more persistence (puzzle solutions)
- Often instanced rather than continuous

### Infinite/Procedural Obby
- Stage generation logic
- Score-based rather than completion-based
- Session format is "runs" with high scores saved
