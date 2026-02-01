# Combat Arena Games

PvP and competitive games with round-based matches, rankings, and skill-based gameplay.

**Examples:** Arsenal, Phantom Forces, Murder Mystery, Battle Royale games, Fighting games, Sports games

---

## Implied Decisions

When you say "arena," "PvP," or "competitive," you're usually implying:

| Decision | Typical Answer | Why |
|----------|---------------|-----|
| Session format | Rounds/matches | Discrete games with clear start, end, winners |
| Persistence | Light-Medium | Stats, ranks, unlocks — not core economy |
| Exploit sensitivity | High | Cheating ruins the experience for everyone |
| Authority model | Server-authoritative | Hit detection, scoring, match outcomes all server-validated |
| Structure | Layered | Complex server logic for match management |

**If these don't match your vision, adjust during wizard setup.** But this is the default.

---

## Recommended Packages

```toml
[dependencies]
Promise = "evaera/promise"        # Async operations
GoodSignal = "stravant/goodsignal" # Custom events (critical for match events)
Trove = "sleitnick/trove"         # Cleanup between rounds

[server-dependencies]
ProfileStore = "lm-loleris/profilestore"  # For persistent stats/ranks
```

**Consider adding:**
- RateLimiter module — Prevent ability/action spam
- Custom networking solution for high-frequency updates (advanced)

---

## MVP Checklist

Build these in order for a playable vertical slice:

### Phase 1: Core Loop (build first)
- [ ] **Lobby/waiting area** — Where players gather before match
- [ ] **Match start trigger** — Minimum players → countdown → begin
- [ ] **Basic combat** — One way to damage/eliminate opponents
- [ ] **Win condition** — Last standing, most kills, or objective
- [ ] **Match end + reset** — Results shown, return to lobby

**Milestone:** 2+ players can join lobby, start a match, fight, someone wins, everyone returns to lobby.

### Phase 2: Depth
- [ ] Multiple weapons/abilities/characters
- [ ] Map rotation or selection
- [ ] Kill feed and scoreboard
- [ ] Spectator mode for eliminated players

### Phase 3: Engagement
- [ ] Ranked matchmaking (ELO/MMR)
- [ ] Cosmetic unlocks (skins, effects)
- [ ] Seasonal leaderboards
- [ ] Battle pass progression

---

## Common Patterns

### Architecture Overview

```
Server                          Client
──────                          ──────
MatchService                    MatchUI
  ├─ state machine                ├─ lobby/match/results views
  ├─ player management            └─ countdown display
  └─ round transitions
                    ↕ Remotes ↕
CombatService                   CombatController
  ├─ damage calculation           ├─ input handling
  ├─ hit validation               ├─ local prediction
  └─ kill attribution             └─ effects/feedback

SpawnService                    Scoreboard
  ├─ spawn point selection        └─ live stats display
  └─ respawn timers

LeaderboardService              WeaponController
  └─ stats persistence            └─ weapon switching/firing
```

### Match State Machine

```luau
-- Server: MatchService.luau
local MatchService = {}

export type MatchState = "Waiting" | "Starting" | "InProgress" | "Ending"

local state: MatchState = "Waiting"
local matchPlayers = {}  -- Players in current match
local scores = {}  -- Player -> score

local MIN_PLAYERS = 2
local COUNTDOWN_TIME = 5
local MATCH_DURATION = 180  -- 3 minutes

function MatchService.getState(): MatchState
    return state
end

function MatchService.addPlayer(player: Player)
    if state ~= "Waiting" then return end

    table.insert(matchPlayers, player)
    scores[player] = 0

    -- Check if we can start
    if #matchPlayers >= MIN_PLAYERS then
        MatchService.startCountdown()
    end
end

function MatchService.startCountdown()
    if state ~= "Waiting" then return end
    state = "Starting"

    -- Broadcast countdown
    Remotes.MatchCountdown:FireAllClients(COUNTDOWN_TIME)

    task.delay(COUNTDOWN_TIME, function()
        MatchService.beginMatch()
    end)
end

function MatchService.beginMatch()
    state = "InProgress"

    -- Teleport players to spawn points
    for i, player in matchPlayers do
        SpawnService.spawnPlayer(player, i)
    end

    -- Start match timer
    task.delay(MATCH_DURATION, function()
        if state == "InProgress" then
            MatchService.endMatch("TimeUp")
        end
    end)

    Remotes.MatchStarted:FireAllClients()
end

function MatchService.endMatch(reason: string)
    state = "Ending"

    -- Determine winner
    local winner = getHighestScorer()

    -- Broadcast results
    Remotes.MatchEnded:FireAllClients({
        reason = reason,
        winner = winner,
        scores = scores,
    })

    -- Reset after delay
    task.delay(5, function()
        MatchService.reset()
    end)
end

function MatchService.reset()
    state = "Waiting"
    matchPlayers = {}
    scores = {}

    -- Teleport everyone back to lobby
    for _, player in Players:GetPlayers() do
        SpawnService.teleportToLobby(player)
    end
end

return MatchService
```

### Server-Side Hit Validation

```luau
-- Server: CombatService.luau
local CombatService = {}

local WEAPON_RANGE = 100  -- studs
local WEAPON_DAMAGE = 25

function CombatService.processHit(attacker: Player, targetPlayer: Player, weaponId: string)
    -- Validate attacker is alive and in match
    if not isPlayerInMatch(attacker) then return end
    if not isPlayerAlive(attacker) then return end

    -- Validate target is alive and in match
    if not isPlayerInMatch(targetPlayer) then return end
    if not isPlayerAlive(targetPlayer) then return end

    -- Validate weapon exists
    local weapon = GameConfig.Weapons[weaponId]
    if not weapon then return end

    -- Validate range (server-side position check)
    local attackerPos = getPlayerPosition(attacker)
    local targetPos = getPlayerPosition(targetPlayer)

    if not attackerPos or not targetPos then return end

    local distance = (attackerPos - targetPos).Magnitude
    if distance > weapon.range * 1.5 then  -- 1.5x for latency tolerance
        warn(`{attacker.Name} hit from too far: {distance} studs`)
        return
    end

    -- Apply damage
    applyDamage(targetPlayer, weapon.damage, attacker)
end

local function applyDamage(target: Player, amount: number, source: Player)
    local humanoid = target.Character and target.Character:FindFirstChild("Humanoid")
    if not humanoid then return end

    humanoid.Health -= amount

    if humanoid.Health <= 0 then
        -- Credit kill to source
        MatchService.addScore(source, 1)
        Remotes.PlayerKilled:FireAllClients(source, target)
    end
end

return CombatService
```

### Spawn Point Management

```luau
-- Server: SpawnService.luau
local SpawnService = {}

local spawnPoints = {}  -- Array of CFrames
local usedSpawns = {}   -- Recently used (for spread)

function SpawnService.initialize()
    for _, spawn in workspace.SpawnPoints:GetChildren() do
        table.insert(spawnPoints, spawn.CFrame)
    end
end

function SpawnService.spawnPlayer(player: Player, preferredIndex: number?)
    local character = player.Character
    if not character then return end

    local spawnCFrame

    if preferredIndex and spawnPoints[preferredIndex] then
        spawnCFrame = spawnPoints[preferredIndex]
    else
        -- Find spawn furthest from enemies
        spawnCFrame = findSafestSpawn(player)
    end

    character:SetPrimaryPartCFrame(spawnCFrame)

    -- Brief spawn protection
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid:SetAttribute("SpawnProtection", true)
        task.delay(2, function()
            humanoid:SetAttribute("SpawnProtection", nil)
        end)
    end
end

local function findSafestSpawn(player: Player): CFrame
    local bestSpawn = spawnPoints[1]
    local bestDistance = 0

    for _, spawnCFrame in spawnPoints do
        local minEnemyDistance = math.huge

        for _, otherPlayer in MatchService.getPlayers() do
            if otherPlayer ~= player then
                local pos = getPlayerPosition(otherPlayer)
                if pos then
                    local dist = (spawnCFrame.Position - pos).Magnitude
                    minEnemyDistance = math.min(minEnemyDistance, dist)
                end
            end
        end

        if minEnemyDistance > bestDistance then
            bestDistance = minEnemyDistance
            bestSpawn = spawnCFrame
        end
    end

    return bestSpawn
end

return SpawnService
```

### Ranked/ELO System (Basic)

```luau
-- Server: RankingService.luau
local RankingService = {}

local K_FACTOR = 32  -- How much ratings change per match

function RankingService.calculateNewRatings(winnerRating: number, loserRating: number): (number, number)
    -- Expected scores based on current ratings
    local expectedWinner = 1 / (1 + 10^((loserRating - winnerRating) / 400))
    local expectedLoser = 1 - expectedWinner

    -- New ratings (winner gets 1.0 score, loser gets 0.0)
    local newWinnerRating = winnerRating + K_FACTOR * (1 - expectedWinner)
    local newLoserRating = loserRating + K_FACTOR * (0 - expectedLoser)

    return math.floor(newWinnerRating), math.floor(newLoserRating)
end

function RankingService.updateRatings(winner: Player, loser: Player)
    local winnerData = DataManager.getPlayerData(winner)
    local loserData = DataManager.getPlayerData(loser)

    if not winnerData or not loserData then return end

    local newWinner, newLoser = RankingService.calculateNewRatings(
        winnerData.rating,
        loserData.rating
    )

    winnerData.rating = newWinner
    loserData.rating = newLoser
end

return RankingService
```

---

## Pitfalls

### ❌ Client-authoritative hit detection
**Problem:** Exploiters send fake "I hit everyone" messages.
**Fix:** Client sends "I fired at position X." Server validates position, range, line of sight.

### ❌ No spawn protection
**Problem:** Player spawns directly into enemy fire, dies instantly.
**Fix:** Brief invincibility on spawn (2-3 seconds) with visual indicator. Spawn point selection algorithm.

### ❌ Match continues with disconnected players
**Problem:** Player disconnects, match becomes 2v1 permanently.
**Fix:** Handle `PlayerRemoving`. Add bots, adjust scoring, or end match early if too imbalanced.

### ❌ No latency compensation
**Problem:** High-ping players can't hit anything.
**Fix:** Either favor shooter (with sanity checks) or implement lag compensation. Complex topic — start simple.

### ❌ Stats visible during match
**Problem:** Players target the lowest-ranked player.
**Fix:** Hide detailed stats during match. Show after results.

### ❌ Instant respawn
**Problem:** No consequence for dying, gameplay becomes chaotic.
**Fix:** Respawn timer (3-5 seconds). Spectate mode while waiting.

### ❌ Winner determined client-side
**Problem:** Exploiter declares themselves winner.
**Fix:** Server tracks all scores and determines winner. Client only displays.

---

## Variations

### Battle Royale
- Single-life per match (no respawns)
- Shrinking play area
- Loot/item pickup systems
- Higher match duration, lower match frequency

### Team-Based (FPS/TPS)
- Team balancing on join
- Objective modes (capture point, payload)
- Class/loadout systems
- Team-wide scoring

### Fighting Game
- 1v1 focused
- Health bars and rounds within a match
- Combo systems and frame data considerations
- Input prediction more critical

### Sports/Racing
- Position-based scoring
- Physics-heavy gameplay
- Real-time sync challenges
- Lap/checkpoint systems
