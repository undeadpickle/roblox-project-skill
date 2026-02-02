# Horror / Exploration Games

Story-driven games with survival elements, chase mechanics, and atmospheric exploration.

**Examples:** Doors, The Mimic, Apeirophobia, Piggy, Flee the Facility, Rainbow Friends, Evade, 3008, Identity Fraud, Dead Silence, The Backrooms, Pressure

---

## Quick Reference

| Sub-Genre | Examples | Core Mechanic | Key Systems |
|-----------|----------|---------------|-------------|
| Chase Horror | Doors, Evade | Outrun/hide from pursuers | AI state machine, hiding spots, stamina |
| Puzzle Horror | Identity Fraud, Apeirophobia | Solve puzzles while avoiding threats | Encryption puzzles, item collection, safe zones |
| Survival Horror | 3008, Pressure | Survive waves/cycles | Day/night cycles, resource management, base building |
| Story-Driven | The Mimic, Dead Silence | Progress through narrative chapters | Cutscenes, dialogue, chapter unlocks |
| Asymmetric | Piggy, Flee the Facility | Survivors vs player-controlled hunter | Role systems, infection mechanics, team coordination |

---

## Implied Decisions

When you say "horror," "escape," or "story game," you're usually implying:

| Decision | Typical Answer | Why |
|----------|---------------|-----|
| Session format | Chapters/rounds | Discrete episodes with clear start, escape goal, end |
| Persistence | Medium | Chapter unlocks, skins, stats — not heavy economy |
| Exploit sensitivity | Medium-High | Speed/noclip exploits ruin tension; progression exploits less critical |
| Authority model | Server-authoritative | NPC positions, item states, progression all validated server-side |
| Structure | Layered | Complex server logic for AI behavior, puzzle states, progression |

**If these don't match your vision, adjust during wizard setup.** But this is the default.

---

## Genre Variations

### Chase Horror (Doors, Evade)

**Core Loop:** Navigate environments while being pursued by entities with learnable patterns.

**Key Mechanics:**
- **Entity patterns** — Each monster has exploitable behavior (hide from Seek, don't look at Figure, run from Rush)
- **Audio cues** — Heartbeat/sound warnings before entity appears
- **Procedural layouts** — Randomized rooms prevent memorization
- **Limited resources** — Hiding spots, stamina, healing items

**Pacing:** Sustained tension with brief safe moments between entity encounters. Players learn patterns through repeated deaths.

**Key Patterns:** [AI Systems](../patterns/ai-systems.md) (state machine, detection), [Audio Systems](../patterns/audio-systems.md) (intensity layers)

---

### Puzzle Horror (Identity Fraud, Apeirophobia)

**Core Loop:** Solve environmental puzzles while avoiding intermittent threats.

**Key Mechanics:**
- **Encryption puzzles** — Morse code, base64, hexadecimal, color codes
- **Item collection** — Find keys, codes, tools to progress
- **Safe vs danger zones** — Puzzles in safe areas, entities patrol between
- **Difficulty scaling** — Later puzzles require multiple steps

**Pacing:** Calm puzzle-solving interrupted by entity presence. Tension comes from time pressure and fear of interruption.

**Key Patterns:** [Trigger Systems](../patterns/trigger-systems.md) (zones, pickups), [AI Systems](../patterns/ai-systems.md) (patrol routes)

---

### Survival Horror (3008, Pressure)

**Core Loop:** Survive escalating threats through resource management and environmental mastery.

**Key Mechanics:**
- **Day/night cycles** — Safe gathering phase, dangerous survival phase
- **Resource management** — Food, health, stamina, crafting materials
- **Base building** — Construct defenses, safe zones
- **Wave escalation** — Each cycle more dangerous than the last
- **Procedural elements** — Random spawns, layouts, enemy types

**Pacing:** Cyclical tension (safe → danger → safe). Players develop strategies over multiple runs.

**Key Patterns:** [AI Systems](../patterns/ai-systems.md) (AI Director for difficulty), [Trigger Systems](../patterns/trigger-systems.md) (damage zones)

---

### Story-Driven Horror (The Mimic, Dead Silence)

**Core Loop:** Progress through narrative chapters, experiencing curated scares and story beats.

**Key Mechanics:**
- **Chapter structure** — Linear progression with unlocks
- **Cutscenes** — Story delivery between gameplay
- **Environmental storytelling** — Lore through exploration
- **Unique chapter mechanics** — Each chapter introduces new rules
- **Multiple endings** — Choices or secrets affect outcome

**Pacing:** Cinematic with clear peaks and valleys. Quiet exploration → tension build → scare → release → story beat.

**Key Patterns:** [Trigger Systems](../patterns/trigger-systems.md) (cutscene triggers), [Camera Effects](../patterns/camera-effects.md) (atmosphere)

---

### Asymmetric Horror (Piggy, Flee the Facility)

**Core Loop:** Survivors complete objectives while one or more players hunt them.

**Key Mechanics:**
- **Role asymmetry** — Survivors escape, hunters capture
- **Objective completion** — Hack computers, find keys, unlock exits
- **Infection** — Caught survivors become hunters (Piggy)
- **Time pressure** — Escape before time runs out
- **Team coordination** — Survivors must cooperate

**Pacing:** Constant threat from unpredictable human player. Tension from social dynamics, not just AI.

**Key Patterns:** [Multiplayer Systems](../patterns/multiplayer-systems.md) (spectate, teams), [Anti-Exploit](../patterns/anti-exploit.md) (validation)

---

## Design Principles

### Psychology of Fear

**Types of Fear:**

| Type | Trigger | Duration | Example |
|------|---------|----------|---------|
| **Jump Scare** | Sudden loud/visual shock | Instant (0.5s) | Entity appears with loud noise |
| **Tension** | Anticipation of threat | Sustained (minutes) | Hearing footsteps, not seeing source |
| **Dread** | Knowing something bad will happen | Long-term | Walking toward known danger |
| **Unease** | Something feels "off" | Ambient | Slightly wrong geometry, off-key music |

**The Fear Curve:**
- Build tension → deliver scare → provide relief → repeat with escalation
- Never deliver scares when players expect them — subvert anticipation
- Too many scares = habituation (players stop being scared)
- Too few = boredom

**Safe vs Unsafe Spaces:**
- Players need perceived safety to appreciate danger
- Safe rooms (like Resident Evil) create contrast
- Even brief safe moments matter (hallways between rooms)

**Player Agency:**
- Helplessness is scary, but total helplessness is frustrating
- Give players options: hide, run, distract, outmaneuver
- Pattern-based enemies let skilled players feel competent
- Death should feel fair, not random

---

### Atmosphere Building

**Lighting Design:**
- Darkness obscures both threats AND escape routes
- Flickering lights create uncertainty and visual discomfort
- Use pools of light as navigation landmarks
- Sudden blackouts before scares amplify impact
- Use "Future is Bright" technology (Lighting.Technology = "Future")

**Audio Design (Most Important Element):**
- Sound design has stronger effect on horror than visuals
- Layer ambient sounds: base drone + random creaks + distant events
- Crescendo scores telegraph rising threat
- Silence is equally powerful — absence of expected sound raises anxiety
- Use new Audio API — see [Audio Systems](../patterns/audio-systems.md)

**Environmental Storytelling:**
- Tell stories through environment, not exposition
- Broken objects, cryptic symbols, ominous stains
- Notes/journals for optional lore
- Less explicit = more imagination = more fear

**Camera Manipulation:**
- See [Camera Effects](../patterns/camera-effects.md) for shake, post-processing, vignette
- Tight corners and obscured sightlines increase stress
- Lock camera during jumpscares for maximum impact

---

### Monster/Antagonist Design

**AI Behavior Principles:**
- Monsters should feel intelligent, not scripted
- Learnable patterns reward player skill
- Unpredictability within boundaries (randomized patrol routes, varied speeds)
- See [AI Systems](../patterns/ai-systems.md) for state machine and AI Director patterns

**Telegraphing:**
- Players should sense danger before seeing it
- Audio cues: footsteps, breathing, growls
- Visual cues: shadows, flickering lights, environmental changes
- Give enough warning to feel fair, not enough to feel safe

**Pattern-Based Behavior:**
- Each entity should have distinct, learnable rules
- Examples from Doors: Rush (hide), Seek (run), Figure (sound-based), Screech (look at it)
- Learning mechanics = progress feeling (not just luck)
- Document patterns in-game through notes or death messages

---

### Level Design

**Sightlines and Corridors:**
- Long corridors create dread (you see the monster coming)
- Tight corners create jump scares (you don't see it coming)
- Mix both for variety
- Slightly off-symmetry triggers subconscious unease

**Safe Rooms:**
- Place between intense sequences
- Should feel visually distinct (different lighting, music)
- Often contain save points, resources, story elements

**Navigation:**
- Players should feel lost without being stuck
- Landmarks help orientation
- Breadcrumb items guide progression
- Backtracking through "cleared" areas with new threats

---

## Recommended Packages

```toml
[dependencies]
Promise = "evaera/promise"        # Async operations (cutscenes, timed events)
GoodSignal = "stravant/goodsignal" # Custom events (AI state changes, triggers)
Trove = "sleitnick/trove"         # Cleanup between chapters

[server-dependencies]
ProfileStore = "lm-loleris/profilestore"  # Chapter progress, unlocks
```

**Custom modules to build** (see [patterns/](../patterns/INDEX.md)):
- **NPCManager** — Use [AI Systems](../patterns/ai-systems.md) state machine
- **AtmosphereController** — Use [Audio Systems](../patterns/audio-systems.md) + [Camera Effects](../patterns/camera-effects.md)
- **TriggerManager** — Use [Trigger Systems](../patterns/trigger-systems.md)
- **ChapterManager** — Progression and save states
- **SpectateController** — Use [Multiplayer Systems](../patterns/multiplayer-systems.md)

---

## MVP Checklist

Build these in order for a playable vertical slice:

### Phase 1: Core Loop (build first)
- [ ] **One playable map** — Escape-room scale, 3-5 rooms minimum
- [ ] **Working AI pursuer** — Use [AI Systems](../patterns/ai-systems.md) state machine with Patrol/Chase/Search states
- [ ] **Key/door puzzle** — Collect item → unlock path → progress
- [ ] **Win/lose conditions** — Escape = win, caught = lose
- [ ] **Basic atmosphere** — Dim lighting, ambient audio using [Audio Systems](../patterns/audio-systems.md)

**Milestone:** Player spawns, AI hunts them, they find a key, unlock a door, escape (or get caught). The experience feels tense.

### Phase 2: Depth
- [ ] Multiple chapters with unique layouts
- [ ] Chapter progression persistence (unlock chapter 2 after beating chapter 1)
- [ ] NPC behavior variations (patrol vs. chase vs. ambush)
- [ ] Additional puzzle types (codes, sequence puzzles, item combinations)
- [ ] Cutscene system for story beats

### Phase 3: Engagement
- [ ] Multiplayer support (co-op survival) — see [Multiplayer Systems](../patterns/multiplayer-systems.md)
- [ ] Cosmetic unlocks (skins, effects)
- [ ] Difficulty modes — use [AI Director](../patterns/ai-systems.md#ai-director-dynamic-difficulty)
- [ ] Endless/survival mode (post-story replayability)
- [ ] Chapter badges and achievements

---

## Architecture Overview

```
Server                          Client
------                          ------
NPCManager                      NPCController
  |- state machine                |- visual/audio feedback
  |- pathfinding logic            |- proximity warnings
  |- detection system             |- animation triggers
  '- chase/catch detection
                   <-> Remotes <->
ChapterManager                  ChapterUI
  |- chapter state                |- objective display
  |- puzzle validation            |- inventory UI
  '- win/lose conditions          '- cutscene player

DataManager                     AtmosphereController
  |- ProfileStore                 |- dynamic lighting
  '- chapter/unlock schema        |- audio layers (new API)
                                  |- post-processing
TriggerManager                    '- camera effects
  |- proximity detection
  '- scare/audio triggers       SpectateController
                                  |- death detection
AntiExploit                       |- camera switching
  |- movement validation          '- spectate UI
  '- position verification
```

---

## Horror-Specific Patterns

These patterns build on the generic patterns for horror-specific use cases.

### Chapter Progress Data Schema

```luau
-- Shared: DataTemplate.luau
return {
    schemaVersion = 1,

    -- Chapter progression
    chaptersCompleted = {},  -- { chapter1 = true, chapter2 = true }
    currentChapter = "chapter1",

    -- Stats
    totalEscapes = 0,
    totalDeaths = 0,
    fastestTimes = {},  -- { chapter1 = 145.2, chapter2 = 203.8 }
    totalPlaytime = 0,

    -- Unlocks
    skins = { "default" },
    equippedSkin = "default",

    -- Achievements
    achievements = {},

    -- Settings
    settings = {
        musicVolume = 0.5,
        sfxVolume = 0.8,
        screenShake = true,
    },

    -- Timestamps
    lastPlayed = 0,
    firstPlayed = 0,
}
```

### Horror AI State Configuration

Configure the [AI state machine](../patterns/ai-systems.md) for horror:

```luau
-- Horror-specific states
export type HorrorNPCState = "Idle" | "Patrol" | "Investigate" | "Chase" | "Search" | "Stunned" | "Ambush"

-- Horror-specific detection config
local HORROR_DETECTION = {
    close = { range = 15, angle = 180 },   -- Can sense behind at close range
    medium = { range = 35, angle = 90 },   -- Normal vision
    far = { range = 60, angle = 45 },      -- Narrow focus
}

-- Horror AI Director config (see patterns/ai-systems.md)
AIDirector.configure({
    baseDifficulty = 30,      -- Start lower for horror (build tension)
    maxDifficulty = 90,       -- Cap below 100 (always beatable)
    decayRate = 1,            -- Slow decay (maintain tension)
    decayDelay = 45,          -- Long calm period before easing
    onSuccess = 8,            -- Moderate increase on escape
    onFailure = -25,          -- Significant mercy on death
})
```

### Jumpscare Trigger Pattern

Combine [Trigger Systems](../patterns/trigger-systems.md) with [Camera Effects](../patterns/camera-effects.md):

```luau
-- Server: Setup jumpscare trigger
TriggerManager.registerHandler("jumpscare", function(player, data)
    Remotes.TriggerJumpscare:FireClient(player, data.data.scareId)
end)

-- Client: Handle jumpscare
Remotes.TriggerJumpscare.OnClientEvent:Connect(function(scareId)
    local scareConfig = JumpscareConfigs[scareId]
    if not scareConfig then return end

    -- Combine all effects
    CameraShake.jumpscare()
    PostProcessing.flash("jumpscare", 0.2)
    ScreenFlash.white(0.1)

    -- Play scare sound
    PositionalAudio.playAt(scareConfig.position, {
        assetId = scareConfig.soundId,
        volume = 1,
    })

    -- Show scare image if configured
    if scareConfig.imageId then
        showScareImage(scareConfig.imageId, 0.5)
    end
end)
```

---

## Pitfalls

### Horror-Specific Issues

### ❌ Over-relying on jump scares
**Problem:** First playthrough is scary, replays become tedious. Players habituate quickly.
**Fix:** Build sustained tension through audio, lighting, and unpredictable AI. Use jump scares sparingly (2-3 per chapter max). Randomize some scare triggers for replayability.

### ❌ Predictable AI patterns
**Problem:** After a few runs, players know exactly where monsters spawn and patrol.
**Fix:** Randomize patrol routes. Use [AI Director](../patterns/ai-systems.md#ai-director-dynamic-difficulty) to vary behavior based on player performance. Add random delays to spawns.

### ❌ Breaking immersion with UI
**Problem:** Gamey UI elements (health bars, objective markers, score displays) undermine horror atmosphere.
**Fix:** Use diegetic UI where possible (in-world objects). Minimize HUD. Make UI elements contextual (only show when relevant).

### ❌ Multiplayer diluting tension
**Problem:** Co-op makes the game less scary because players feel safer together.
**Fix:** Design mechanics that split the party. Add limited resources that create tension. Consider asymmetric modes where one player is the threat.

### ❌ Cutscene escape exploits
**Problem:** Players jump, reset, or teleport during cutscenes to skip content.
**Fix:** During cutscenes: disable controls, anchor the character. Validate cutscene completion server-side before unlocking progression.

### General Issues (see pattern files for more)

- **NPC stuck on geometry** — See [AI Systems pitfalls](../patterns/ai-systems.md#pitfalls)
- **Speed/noclip exploits** — See [Anti-Exploit](../patterns/anti-exploit.md)
- **Audio desync in multiplayer** — See [Audio Systems pitfalls](../patterns/audio-systems.md#pitfalls)
- **Client-trusted progression** — See [Anti-Exploit action validation](../patterns/anti-exploit.md#action-validation)

---

## When This Profile Doesn't Fit

Consider adjustments if:

- **Solo-only experience** — Exploit sensitivity can be lower. Focus more on atmosphere, less on anti-cheat.
- **No chapter structure** — Endless/wave survival uses "runs" session format instead of chapters.
- **Asymmetric multiplayer** — One player is the monster (like Piggy infected mode). Needs different authority model for the hunter player.
- **Heavy story focus** — May need more cutscene infrastructure, dialogue systems, and longer session times.
- **Casual horror** — Games like Rainbow Friends are horror for kids. Tone down intensity, use cartoonish art, simpler puzzles.

---

## Learning from Popular Games

### Doors: Procedural Chase Horror

**What works:**
- Procedural room layouts → every run feels fresh
- Distinct entity patterns → Rush (hide), Seek (run), Figure (sound), Screech (look)
- Audio cues telegraph danger → players learn to "read" the game
- Frequent checkpoints → death doesn't feel punishing

**Key takeaway:** Entity patterns should be learnable but not trivial. Each monster teaches a different skill.

---

### The Mimic: Story-Driven Atmosphere

**What works:**
- Japanese folklore aesthetic → unique, memorable
- Chapter structure → clear progression
- Deep lore → rewards exploration
- Environmental storytelling → show don't tell

**Key takeaway:** Atmosphere and lore create investment. Players fear losing progress in a world they care about.

---

### Piggy: Asymmetric Tension

**What works:**
- Human-controlled threat → unpredictable, social
- Infection mechanic → escalating danger
- Simple objectives → find keys, escape
- Short rounds → low commitment, high replayability

**Key takeaway:** Human players create more tension than any AI. Social dynamics drive replayability.

---

### 3008: Survival Loop

**What works:**
- Day/night cycle → predictable but tense rhythm
- Base building → players invest in defense
- Endless mode → no "end," just survival records
- Familiar setting (IKEA) → uncanny valley horror

**Key takeaway:** Survival loops work when players build investment (bases, resources) that they fear losing.

---

### Apeirophobia: Puzzle Integration

**What works:**
- Varied puzzle types → codes, patterns, exploration
- Difficulty scaling → later levels harder
- Safe zones between puzzles → tension/release
- Backrooms aesthetic → recognizable horror setting

**Key takeaway:** Puzzles create natural pacing. Solving a puzzle feels like progress and provides relief.
