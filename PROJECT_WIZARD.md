# Project Setup Wizard

**Use this when a user asks to set up a new Roblox project.**

This wizard asks foundation questions FIRST, then generates a scaffold tailored to the user's needs. The goal: surface critical decisions early so they don't become painful refactors later.

---

## How to Use This Wizard

1. **Use the `AskUserQuestion` tool** to gather input at each decision point (see format below)
2. **Ask in clusters of 2-3 questions** — don't dump all questions at once
3. **Adapt as you go** — clarify freeform answers, skip irrelevant questions, frame based on context
4. **Summarize what the answers imply** — speak this, don't write to a file
5. **Auto-select modules** based on the profile
6. **Proceed to scaffolding** (Phase 2 in SKILL.md)

See [Adaptive Flow Guidelines](#adaptive-flow-guidelines) for how to make the conversation feel natural.

---

## Using AskUserQuestion Tool

**Always use the `AskUserQuestion` tool** to collect user input. This provides a better UX than asking users to type answers.

**Tool constraints:**
- 1-4 questions per call
- 2-4 options per question (users can always type "Other" for custom input)
- `header`: short label, max 12 characters
- `multiSelect: true` for questions where multiple selections make sense (e.g., game loop)

**Suggested question clusters:**

| Cluster | Questions | Notes |
|---------|-----------|-------|
| 0 | Game Type (if detected) | Front-load inference when user mentions a genre |
| 1 | Intent, Source of Truth | Core decisions that affect everything else |
| 2 | Team Shape | Team affects tooling and strictness |
| 3 | Session Format, Platform | How players experience the game |
| 4 | Exploit Sensitivity, Persistence, Structure | Security and data decisions |

Adapt clusters based on context — if earlier answers make some questions irrelevant, skip them.

---

## Quick-Start: Game Type Detection

**When a user mentions a game type up front** (e.g., "Set up a tycoon," "I want to make an obby"), front-load the inference instead of asking detailed questions first.

### Detecting Game Type

| User says... | Load profile... |
|--------------|-----------------|
| "tycoon", "factory", "base builder" | `references/game-types/tycoon.md` |
| "obby", "parkour", "platformer", "racing" | `references/game-types/obby.md` |
| "simulator", "pet game", "clicker", "idle" | `references/game-types/simulator.md` |
| "arena", "pvp", "shooter", "fighting", "competitive" | `references/game-types/combat-arena.md` |

### Quick-Start Flow

1. **Read the matching profile** from `references/game-types/`
2. **Present the implied decisions** from the profile:
   > "Tycoons typically need:
   > - Continuous world (players return to their plot)
   > - Core economy persistence (plots, currency, upgrades save)
   > - Medium-high exploit sensitivity (currency exploits break the game)
   > - Server-authoritative purchases
   >
   > Sound right, or do you want to adjust any of these?"

3. **If they confirm**, use profile defaults and skip to remaining questions (Intent, Source of Truth, Team)
4. **If they want changes**, ask targeted follow-ups only for what differs

This reduces cognitive load — users thinking "I want a tycoon" shouldn't have to answer "What's your exploit sensitivity?" without context.

### Example Quick-Start Conversation

```
User: "Set up a tycoon game"

Claude: "Tycoons typically need continuous-world persistence, server-authoritative
purchases, and medium-high exploit protection. I'll set those as defaults.

A few quick questions to customize:
- What are we optimizing for? (Prototype / MVP / Long-lived)
- Git+Rojo or Studio-first workflow?
- Just you or a team?"

User: "MVP, Git+Rojo, just me"

Claude: "Got it. Here's what I'll create: [profile summary]. Starting setup..."
```

### When Quick-Start Doesn't Apply

If the user's request is:
- **Ambiguous** ("Set up a Roblox project") — Use the full wizard
- **Hybrid** ("horror tycoon with trading") — Ask clarifying questions, may combine patterns
- **Not a recognized type** — Use the full wizard, may need custom discussion

---

## Phase 1: Foundation Questions

### Question 1: Project Intent

**AskUserQuestion format:**
```json
{
  "question": "What are we optimizing for right now?",
  "header": "Intent",
  "options": [
    { "label": "Prototype", "description": "Experimenting, might throw this away" },
    { "label": "MVP", "description": "Shipping something real with a small team" },
    { "label": "Long-lived", "description": "Building a project that will grow and be maintained" }
  ],
  "multiSelect": false
}
```

**Why it matters:** Determines how strict the tooling setup should be. Prototypes don't need CI and strict linting; long-lived projects do.

**Records:** `intent` = `prototype` | `mvp` | `long-lived`

---

### Question 2: Source of Truth

**AskUserQuestion format:**
```json
{
  "question": "What should be the source of truth for your project?",
  "header": "Source",
  "options": [
    { "label": "Git + Rojo", "description": "VS Code edits, Studio syncs/builds from files" },
    { "label": "Studio-first", "description": "Work primarily in Studio, external tools optional" }
  ],
  "multiSelect": false
}
```

**Why it matters:** This is the single most important decision. Retroactively converting a Studio-first project to Rojo is painful.

**If they pick Studio-first:** Warn briefly that migration later is possible but costs time. Then proceed with a lighter scaffold (no Rojo project file, minimal tooling).

**Records:** `sourceOfTruth` = `git-rojo` | `studio-first`

---

### Question 3: Team Shape

**AskUserQuestion format (ask both in one call):**
```json
{
  "questions": [
    {
      "question": "How many people will touch the code in the next month?",
      "header": "Team size",
      "options": [
        { "label": "Just me", "description": "Solo development" },
        { "label": "2-5 people", "description": "Small team collaboration" },
        { "label": "5+ people", "description": "Larger team with coordination needs" }
      ],
      "multiSelect": false
    },
    {
      "question": "Do you want code review / PR workflow?",
      "header": "PRs",
      "options": [
        { "label": "Yes", "description": "Changes go through pull requests" },
        { "label": "No", "description": "Direct commits to main branch" }
      ],
      "multiSelect": false
    }
  ]
}
```

**Why it matters:** Solo devs can be looser. Teams need formatting/linting enforced, and version pinning matters fast.

**Records:** `teamSize` = `solo` | `small` | `large`, `usePRs` = `true` | `false`

---

### Question 4: Game Loop Category

**AskUserQuestion format:**
```json
{
  "question": "What's the core loop? Pick 1-2 that fit best (or type your own description):",
  "header": "Game loop",
  "options": [
    { "label": "Skill/movement", "description": "Obby, platformer, racing" },
    { "label": "Combat/competition", "description": "Arena, shooter, sports, fighting" },
    { "label": "Economy/building", "description": "Tycoon, builder, factory" },
    { "label": "Progression/collection", "description": "Pets, simulator, RPG-lite, idle" }
  ],
  "multiSelect": true
}
```

**Note:** Tool only supports 4 options. If user selects "Other", they can type freeform (e.g., "horror tycoon with trading"). Additional categories to recognize from freeform input:
- **Story/exploration** — horror, adventure, mystery
- **Social/roleplay** — hangout, RP, social deduction
- **Creation/sandbox** — building tools, user-generated content

**Why it matters:** Different loops have different architecture needs. Combat games need tight server authority. Tycoons need heavy persistence. Social games can be more client-trusted.

**If they give a freeform description:** Map it back to the closest categories for inference purposes. Ask clarifying questions if needed (see [Adaptive Flow Guidelines](#adaptive-flow-guidelines)).

**Records:** `gameLoop` = array of selected categories (even if inferred from freeform)

---

### Question 5: Session Format

**AskUserQuestion format:**
```json
{
  "question": "How do players experience your game?",
  "header": "Session",
  "options": [
    { "label": "Continuous world", "description": "Players join an ongoing world, no distinct start/end" },
    { "label": "Rounds/matches", "description": "Discrete games with clear start, end, and winners" },
    { "label": "Runs/attempts", "description": "Roguelike, obby attempts, or 'try until you win' loops" },
    { "label": "Instanced levels", "description": "Dungeons, story chapters, or separate play areas" }
  ],
  "multiSelect": false
}
```

**Why it matters:** Session format determines whether you need RoundService/MatchService, spawn handling, join-in-progress logic, lobby systems, and how you structure game state.

**Records:** `sessionFormat` = `continuous` | `rounds` | `runs` | `instanced`

---

### Question 6: Platform Target

**AskUserQuestion format:**
```json
{
  "question": "What's your primary platform?",
  "header": "Platform",
  "options": [
    { "label": "Mobile-first", "description": "Touch controls, smaller UI, performance-sensitive" },
    { "label": "PC-first", "description": "Keyboard/mouse, larger UI, more complex controls" },
    { "label": "Cross-platform", "description": "Both mobile and PC equally important" },
    { "label": "Gamepad important", "description": "Console or controller players are a priority" }
  ],
  "multiSelect": false
}
```

**Why it matters:** Platform choice affects UI constraints, camera/input conventions, performance budgets, and what your "MVP slice" should look like. Mobile-first means bigger buttons, simpler menus, and more aggressive optimization.

**Records:** `platform` = `mobile` | `pc` | `cross-platform` | `gamepad`

---

### Question 7: Exploit Sensitivity

**AskUserQuestion format:**
```json
{
  "question": "If someone cheats on their client, how bad is it?",
  "header": "Exploits",
  "options": [
    { "label": "Not a big deal", "description": "Casual/single-player experience" },
    { "label": "Annoying but survivable", "description": "Leaderboards exist but aren't critical" },
    { "label": "Catastrophic", "description": "Ranked PvP, trading, real-money value, competitive integrity" }
  ],
  "multiSelect": false
}
```

**Why it matters:** Determines authority posture. High sensitivity = server-authoritative everything, validation patterns from day 1, transaction logging.

**Records:** `exploitSensitivity` = `low` | `medium` | `high`

---

### Question 8: Persistence Needs

**AskUserQuestion format:**
```json
{
  "question": "Do you need to save player data between sessions right away?",
  "header": "Persistence",
  "options": [
    { "label": "No", "description": "Pure arcade experience, nothing persists" },
    { "label": "Light", "description": "Cosmetics, settings, high scores, unlocks" },
    { "label": "Core economy", "description": "Inventory, currency, progression, building state" }
  ],
  "multiSelect": false
}
```

**Why it matters:** If persistence is needed, you want the data schema and server-authority patterns in place BEFORE content work begins. Adding them later means painful migrations.

**Records:** `persistence` = `none` | `light` | `core`

---

### Question 9: Project Structure

**AskUserQuestion format:**
```json
{
  "question": "How do you want code organized?",
  "header": "Structure",
  "options": [
    { "label": "Simple", "description": "Flat Scripts folder, shared modules, minimal structure" },
    { "label": "Layered", "description": "shared/, server/, client/ boundaries (recommended)" },
    { "label": "Feature-based", "description": "features/combat/, features/inventory/, etc." }
  ],
  "multiSelect": false
}
```

**Why it matters:** Structure determines where modules live and how future systems plug in. Layered is the safest default; feature-based scales better but requires more discipline.

**Records:** `structure` = `simple` | `layered` | `feature-based`

---

### Question 10: Anything Else? (Optional)

**AskUserQuestion format:**
```json
{
  "question": "Anything else I should know? (Special requirements, packages, constraints)",
  "header": "Notes",
  "options": [
    { "label": "No, let's go", "description": "Ready to proceed with setup" },
    { "label": "Yes", "description": "I have additional requirements (type in 'Other')" }
  ],
  "multiSelect": false
}
```

**This is optional.** Skip if the conversation has already covered everything, or if the user seems eager to proceed.

**Why it matters:** Catches edge cases the structured questions missed. Users might mention:
- Specific packages they want (or want to avoid)
- VR support
- Existing code they're migrating
- Specific features they know they'll need

**If they mention something relevant:** Factor it into the profile summary and scaffold plan.

**Records:** `notes` = freeform string (or empty)

---

## Phase 1 Complete: Summarize the Profile

After all questions are answered, **speak a summary** (don't write to a file):

**Template:**
> Here's what I understood:
> - **Intent:** [prototype/MVP/long-lived]
> - **Source of truth:** [Git + Rojo / Studio-first]
> - **Team:** [solo / small team / large team], [with/without] PR workflow
> - **Core loop:** [categories]
> - **Session format:** [continuous/rounds/runs/instanced]
> - **Platform:** [mobile/PC/cross-platform/gamepad]
> - **Exploit sensitivity:** [low/medium/high] → [authority implication]
> - **Persistence:** [none/light/core] → [data implication]
> - **Structure:** [simple/layered/feature-based]
>
> Based on this, I'll [summary of what scaffold will include].

**Example:**
> Here's what I understood:
> - **Intent:** MVP with a small team
> - **Source of truth:** Git + Rojo (VS Code as primary editor)
> - **Team:** 2-5 people with PR workflow
> - **Core loop:** Economy/building + Progression
> - **Session format:** Continuous world
> - **Platform:** Cross-platform (mobile + PC)
> - **Exploit sensitivity:** High → server-authoritative for all value changes
> - **Persistence:** Core economy → DataManager with schema versioning
> - **Structure:** Layered (shared/server/client)
>
> Based on this, I'll set up the full Rokit toolchain with strict linting, include DataManager and RateLimiter, and scaffold a layered project structure. Sound good?

### Confirmation Behavior

**For prototypes and MVPs:** Proceed by default unless the user objects.
> "I'll start setting this up. Let me know if you want to change anything."

**For long-lived projects or teams with PRs:** Ask for explicit confirmation before proceeding.
> "Does this look right? I want to make sure the foundation is solid before I scaffold."

### Generating the Build Roadmap

The CLAUDE.md template includes `PROJECT_ROADMAP_PHASE1`, `PROJECT_ROADMAP_PHASE2`, and `PROJECT_ROADMAP_PHASE3` placeholders. Fill these based on the game type profile.

**If a game type profile was used** (tycoon, obby, simulator, combat-arena):
1. Read the MVP Checklist from `references/game-types/{type}.md`
2. Copy the phase items as markdown task lists

**Example for tycoon:**
```markdown
PROJECT_ROADMAP_PHASE1:
- [ ] Plot claiming — Player joins → gets assigned a plot
- [ ] Basic dropper/collector — One income source that works
- [ ] Currency + UI — Show the number going up
- [ ] One purchasable upgrade — Button that costs currency
- [ ] Data persistence — Progress saves when player leaves

PROJECT_ROADMAP_PHASE2:
- [ ] Multiple dropper types or tiers
- [ ] Upgrade paths (faster droppers, better collectors)
- [ ] Offline income calculation (optional)
- [ ] Plot expansion or new areas

PROJECT_ROADMAP_PHASE3:
- [ ] Rebirth/prestige system
- [ ] Daily rewards or login bonuses
- [ ] Quests or achievements
- [ ] Social features (visiting other plots)
```

**If no game type profile applies** (generic project):
```markdown
PROJECT_ROADMAP_PHASE1:
- [ ] Core gameplay mechanic working
- [ ] Basic UI showing game state
- [ ] One complete player flow (join → play → result)

PROJECT_ROADMAP_PHASE2:
- [ ] Additional content/variety
- [ ] Polish and feedback (sounds, effects)
- [ ] Edge case handling

PROJECT_ROADMAP_PHASE3:
- [ ] Progression systems
- [ ] Social features
- [ ] Monetization hooks (if applicable)
```

The roadmap is advisory, not prescriptive — users can reorder or skip items based on their vision.

---

## Inference Rules

Use these rules to determine what the profile implies:

### Authority Posture

| Exploit Sensitivity | Authority Posture |
|---------------------|-------------------|
| Low | Client-trusted for most actions (prototype OK) |
| Medium | Hybrid — server validates value changes, client handles UI/cosmetics |
| High | Server-authoritative for ALL value changes, transaction logging recommended |

### Tooling Strictness

| Intent | Tooling Level |
|--------|---------------|
| Prototype | Minimal — Rojo + Wally only, linting optional |
| MVP | Standard — Full toolchain, linting recommended |
| Long-lived | Strict — Full toolchain, linting enforced, CI-ready, ErrorReporter |

### Data Patterns

| Persistence | Data Pattern |
|-------------|--------------|
| None | No DataManager, skip persistence questions |
| Light | DataManager optional, simple schema |
| Core | DataManager required, schema versioning, migration stubs |

### Session Architecture

| Session Format | Architecture Implications |
|----------------|---------------------------|
| Continuous | Simple player join/leave, world state persists |
| Rounds/matches | RoundService/MatchService, lobby system, join-in-progress handling |
| Runs/attempts | Run state management, checkpoint systems, attempt tracking |
| Instanced | Instance management, level loading, isolated game states |

### Platform Considerations

| Platform | Considerations |
|----------|----------------|
| Mobile-first | Larger touch targets, simplified UI, aggressive optimization, no hover states |
| PC-first | Keyboard shortcuts, smaller UI elements, mouse interactions |
| Cross-platform | Responsive UI, input abstraction layer, test on both |
| Gamepad | Button prompts, radial menus, no mouse-dependent UI |

---

## Auto-Selected Modules

Based on the profile, auto-suggest these modules (don't ask individually):

| Profile Condition | Auto-Include |
|-------------------|--------------|
| `persistence` = `core` | DataManager (ProfileStore + schema versioning) |
| `exploitSensitivity` = `high` | RateLimiter |
| `exploitSensitivity` = `medium` AND `persistence` != `none` | RateLimiter |
| `intent` = `long-lived` | ErrorReporter |
| `intent` = `long-lived` AND `persistence` != `none` | Analytics |
| `teamSize` != `solo` AND `usePRs` = `true` | Stricter lint/format defaults |
| `sessionFormat` = `rounds` | Suggest RoundService pattern in architecture notes |

**When presenting the scaffold plan, list what will be included:**
> I'll include these modules based on your profile:
> - **DataManager** — you need persistent economy data
> - **RateLimiter** — exploit sensitivity is high
> - **ErrorReporter** — long-lived project benefits from error tracking

---

## Scaffold Variations

### Minimal Scaffold (Prototype / Studio-first)

**When:** `intent` = `prototype` OR `sourceOfTruth` = `studio-first`

- Skip Rokit setup if Studio-first
- Skip linting/formatting if prototype
- Simpler folder structure
- No optional modules unless requested
- Quick to set up, easy to throw away

### Standard Scaffold (MVP)

**When:** `intent` = `mvp` AND `sourceOfTruth` = `git-rojo`

- Full Rokit toolchain (Rojo, Wally, Selene, StyLua)
- Standard folder structure (layered or as selected)
- Include auto-selected modules based on profile
- Recommended Wally packages based on game loop
- VS Code tasks configured

### Full Scaffold (Long-lived)

**When:** `intent` = `long-lived`

- Everything in Standard, plus:
- ErrorReporter included by default
- Analytics stubs if persistence exists
- Stricter lint rules
- CI workflow suggestions (but don't create CI files unless asked)
- Documentation stubs in CLAUDE.md

---

## Exit Points

### "I just want to start coding"

If the user wants to skip the wizard:

> No problem. I'll create a standard layered project with the default toolchain. You can always adjust later.

Proceed with Standard Scaffold, layered structure, no optional modules (user can add later).

### "I already know what I want"

If the user provides details upfront (e.g., "Set up a tycoon game with ProfileStore"):

Extract what you can from their request:
- "tycoon" → `gameLoop` = `economy-building`, `persistence` likely = `core`
- "ProfileStore" → they want DataManager

Ask only the questions that aren't answered by context. Skip redundant questions.

---

## Proceed to Phase 2

After the profile is confirmed, proceed to the **Project Setup Workflow** in `SKILL.md`:

1. Skip Step 1 (info gathering) — you already have it
2. Start at Step 2 (Create Folder Structure)
3. Apply scaffold variation based on profile
4. Include auto-selected modules at the appropriate steps
5. Complete through Step 12

---

## Quick Reference: Question → Consequence

| Question | Key Consequence |
|----------|-----------------|
| Intent | Tooling strictness, whether to include ErrorReporter |
| Source of Truth | Whether to set up Rojo at all |
| Team Shape | Linting enforcement, version pinning strictness |
| Game Loop | Package recommendations, architecture hints |
| Session Format | Round/match services, lobby systems, state management |
| Platform | UI constraints, input handling, performance budget |
| Exploit Sensitivity | Authority posture, RateLimiter inclusion |
| Persistence | DataManager inclusion, schema setup |
| Structure | Folder layout, Rojo project mapping |

---

## Adaptive Flow Guidelines

The wizard should feel like a conversation, not a form. Use these guidelines to adapt based on context.

### Clarifying Questions on Freeform Input

When a user gives a freeform or ambiguous answer, ask follow-up questions to get the info you need for inference.

**Example — Freeform game description:**
> User: "It's kind of a horror tycoon with trading"
>
> Claude: "Interesting combo — a few quick clarifications:
> - Is the trading player-to-player (item exchanges between players) or NPC-based (shop purchases)?
> - Is the tycoon element the core loop, or more of a progression layer on top of the horror?"

**Example — Ambiguous exploit sensitivity:**
> User: "Medium, I guess? There's a leaderboard but it's not super competitive"
>
> Claude: "Got it. Are there any systems where cheating would give unfair advantages — like trading, currency, or unlocks that affect gameplay? That's what bumps it to 'high.'"

**Goal:** Get enough info to correctly infer exploit sensitivity, persistence needs, and authority posture — then move on.

---

### Adaptive Question Framing

Later questions should acknowledge and build on earlier answers. This makes the wizard feel aware of context.

| Previous Answer | How to Adapt Next Questions |
|-----------------|----------------------------|
| Game loop = tycoon/economy | Persistence Q: "Tycoons usually need to save building state and currency — are you thinking full persistence, or keeping it lighter for now?" |
| Game loop = obby/skill | Persistence Q: "Pure skill games often don't need persistence beyond checkpoints. Do you need to save anything?" Session Q: "Obbies are usually runs/attempts — is that right, or is it a continuous checkpoint world?" |
| Game loop = arena/combat | Session Q: "Arena games are usually round-based. Do you have matches with a lobby, or is it drop-in continuous?" |
| Intent = prototype | Compress later Qs: "Since this is a prototype, I'll assume light persistence and skip strict tooling. Let me know if that's wrong." |
| Exploit sensitivity = high | Structure Q: "Given exploit concerns, I'd lean toward layered structure with clear server/client boundaries. Sound good, or prefer feature-based?" |
| Team = solo, no PRs | De-emphasize strictness: "Since it's just you, I'll keep linting optional. You can always enforce it later." |
| Source of truth = Studio-first | Simplify remaining Qs: "With Studio as source of truth, tooling options are limited anyway. Let's focus on game architecture." |
| Platform = mobile-first | Note implications: "Mobile-first means we'll want bigger UI elements and touch-friendly controls. I'll keep that in mind for any UI recommendations." |

---

### Smart Skipping

Some questions become irrelevant based on earlier answers. Skip or compress them.

| If... | Then... |
|-------|---------|
| `intent` = `prototype` | Compress persistence/tooling Qs — assume light defaults, offer to include more if they want |
| `sourceOfTruth` = `studio-first` | Skip tooling strictness Qs — limited options anyway |
| `teamSize` = `solo` AND `usePRs` = `false` | Skip linting enforcement discussion |
| `gameLoop` = pure skill (obby, racing) AND no economy mentioned | Ask persistence Q but expect "none" — don't belabor it |
| `gameLoop` = obby | Default `sessionFormat` to `runs` unless they say otherwise |
| `gameLoop` = arena/shooter | Default `sessionFormat` to `rounds` unless they say otherwise |
| `gameLoop` = tycoon/social | Default `sessionFormat` to `continuous` unless they say otherwise |
| User already mentioned specifics (e.g., "with ProfileStore") | Skip questions that are already answered — acknowledge what you inferred |
| User mentions "mobile game" | Set `platform` = `mobile` and skip the platform question |

**Example — User provides context upfront:**
> User: "Set up a competitive PvP arena game with ranked matchmaking"
>
> Claude: "Got it — competitive PvP with ranked. I'm inferring:
> - Exploit sensitivity: High (ranked = integrity matters)
> - Session format: Rounds/matches
> - Persistence: At least light (ranks, stats)
> - Authority: Server-authoritative for match outcomes
>
> Let me confirm a few things: Git+Rojo workflow, or Studio-first? And is this just you or a team?"

Only ask what you don't already know.

---

### Staying on Rails

Even with freeform input and adaptive skipping, the wizard should still cover the key decisions:

**Must be answered (explicitly or inferred):**
1. Source of truth (Git+Rojo vs Studio)
2. Exploit sensitivity (determines authority posture)
3. Persistence needs (determines DataManager inclusion)

**Can be inferred or defaulted:**
- Intent (default to MVP if unclear)
- Team shape (default to solo if not mentioned)
- Session format (infer from game loop if not asked)
- Platform (default to cross-platform if not mentioned)
- Structure (default to layered)

**If the conversation goes off track:** Gently redirect:
> "Before we dive into [tangent], let me make sure I have the foundation right. Are you planning to use Git+Rojo, or work primarily in Studio?"

The goal is flexibility without losing the critical decisions that prevent day-zero mistakes.
