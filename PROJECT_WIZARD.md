# Project Setup Wizard

**Use this when a user asks to set up a new Roblox project.**

This wizard asks foundation questions FIRST, then generates a scaffold tailored to the user's needs. The goal: surface critical decisions early so they don't become painful refactors later.

---

## How to Use This Wizard

1. **Ask the foundation questions** (Phase 1) — 7 required + 1 optional
2. **Adapt as you go** — clarify freeform answers, skip irrelevant questions, frame based on context
3. **Summarize what the answers imply** — speak this, don't write to a file
4. **Auto-select modules** based on the profile
5. **Proceed to scaffolding** (Phase 2 in SKILL.md)

Ask questions in clusters of 2-3 at a time. Don't dump all questions at once. See [Adaptive Flow Guidelines](#adaptive-flow-guidelines) for how to make the conversation feel natural.

---

## Phase 1: Foundation Questions

### Question 1: Project Intent

**Ask:**
> What are we optimizing for right now?
> - **(A) Prototype** — experimenting, might throw this away
> - **(B) MVP** — shipping something real with a small team
> - **(C) Long-lived** — building a project that will grow and be maintained

**Why it matters:** Determines how strict the tooling setup should be. Prototypes don't need CI and strict linting; long-lived projects do.

**Records:** `intent` = `prototype` | `mvp` | `long-lived`

---

### Question 2: Source of Truth

**Ask:**
> What should be the "source of truth" for your project?
> - **(A) Git repo + Rojo** — VS Code edits, Studio syncs/builds from files
> - **(B) Studio-first** — work primarily in Studio, external tools optional

**Why it matters:** This is the single most important decision. Retroactively converting a Studio-first project to Rojo is painful.

**If they pick Studio-first:** Warn briefly that migration later is possible but costs time. Then proceed with a lighter scaffold (no Rojo project file, minimal tooling).

**Records:** `sourceOfTruth` = `git-rojo` | `studio-first`

---

### Question 3: Team Shape

**Ask:**
> How many people will touch the code in the next month?
> - **(A) Just me**
> - **(B) 2-5 people**
> - **(C) 5+ people**
>
> And do you want code review / PR workflow? (yes/no)

**Why it matters:** Solo devs can be looser. Teams need formatting/linting enforced, and version pinning matters fast.

**Records:** `teamSize` = `solo` | `small` | `large`, `usePRs` = `true` | `false`

---

### Question 4: Game Loop Category

**Ask:**
> What's the core loop? Pick 1-2 that fit best, or just describe your game and I'll figure it out:
> - **Skill/movement** — obby, platformer, racing
> - **Combat/competition** — arena, shooter, sports, fighting
> - **Economy/building** — tycoon, builder, factory
> - **Progression/collection** — pets, simulator, RPG-lite, idle
> - **Story/exploration** — horror, adventure, mystery
> - **Social/roleplay** — hangout, RP, social deduction
> - **Creation/sandbox** — building tools, user-generated content
>
> Or describe it your own way — "horror tycoon with trading" works too.

**Why it matters:** Different loops have different architecture needs. Combat games need tight server authority. Tycoons need heavy persistence. Social games can be more client-trusted.

**If they give a freeform description:** Map it back to the closest categories for inference purposes. Ask clarifying questions if needed (see [Adaptive Flow Guidelines](#adaptive-flow-guidelines)).

**Records:** `gameLoop` = array of selected categories (even if inferred from freeform)

---

### Question 5: Exploit Sensitivity

**Ask:**
> If someone cheats on their client, how bad is it?
> - **(A) Not a big deal** — it's a casual/single-player experience
> - **(B) Annoying but survivable** — leaderboards exist but aren't critical
> - **(C) Catastrophic** — ranked PvP, trading, real-money value, or competitive integrity matters

**Why it matters:** Determines authority posture. High sensitivity = server-authoritative everything, validation patterns from day 1, transaction logging.

**Records:** `exploitSensitivity` = `low` | `medium` | `high`

---

### Question 6: Persistence Needs

**Ask:**
> Do you need to save player data between sessions right away?
> - **(A) No** — pure arcade experience, nothing persists
> - **(B) Light** — cosmetics, settings, high scores, unlocks
> - **(C) Core economy** — inventory, currency, progression, building state

**Why it matters:** If persistence is needed, you want the data schema and server-authority patterns in place BEFORE content work begins. Adding them later means painful migrations.

**Records:** `persistence` = `none` | `light` | `core`

---

### Question 7: Project Structure

**Ask:**
> How do you want code organized?
> - **(A) Simple** — flat Scripts folder, shared modules, minimal structure (good for prototypes)
> - **(B) Layered** — `shared/`, `server/`, `client/` boundaries (recommended default)
> - **(C) Feature-based** — `features/combat/`, `features/inventory/`, etc. (good for large projects)

**Why it matters:** Structure determines where modules live and how future systems plug in. Layered is the safest default; feature-based scales better but requires more discipline.

**Records:** `structure` = `simple` | `layered` | `feature-based`

---

### Question 8: Anything Else? (Optional)

**Ask:**
> Anything else I should know about this project? Special requirements, constraints, or things you've already decided?

**This is optional.** Skip if the conversation has already covered everything, or if the user seems eager to proceed.

**Why it matters:** Catches edge cases the structured questions missed. Users might mention:
- Specific packages they want (or want to avoid)
- Platform constraints (mobile-first, VR)
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
> - **Exploit sensitivity:** High → server-authoritative for all value changes
> - **Persistence:** Core economy → DataManager with schema versioning
> - **Structure:** Layered (shared/server/client)
>
> Based on this, I'll set up the full Rokit toolchain with strict linting, include DataManager and RateLimiter, and scaffold a layered project structure. Sound good?

Wait for confirmation before proceeding.

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
| Game loop = obby/skill | Persistence Q: "Pure skill games often don't need persistence beyond checkpoints. Do you need to save anything?" |
| Intent = prototype | Compress later Qs: "Since this is a prototype, I'll assume light persistence and skip strict tooling. Let me know if that's wrong." |
| Exploit sensitivity = high | Structure Q: "Given exploit concerns, I'd lean toward layered structure with clear server/client boundaries. Sound good, or prefer feature-based?" |
| Team = solo, no PRs | De-emphasize strictness: "Since it's just you, I'll keep linting optional. You can always enforce it later." |
| Source of truth = Studio-first | Simplify remaining Qs: "With Studio as source of truth, tooling options are limited anyway. Let's focus on game architecture." |

---

### Smart Skipping

Some questions become irrelevant based on earlier answers. Skip or compress them.

| If... | Then... |
|-------|---------|
| `intent` = `prototype` | Compress persistence/tooling Qs — assume light defaults, offer to include more if they want |
| `sourceOfTruth` = `studio-first` | Skip tooling strictness Qs — limited options anyway |
| `teamSize` = `solo` AND `usePRs` = `false` | Skip linting enforcement discussion |
| `gameLoop` = pure skill (obby, racing) AND no economy mentioned | Ask persistence Q but expect "none" — don't belabor it |
| User already mentioned specifics (e.g., "with ProfileStore") | Skip questions that are already answered — acknowledge what you inferred |

**Example — User provides context upfront:**
> User: "Set up a competitive PvP arena game with ranked matchmaking"
>
> Claude: "Got it — competitive PvP with ranked. I'm inferring:
> - Exploit sensitivity: High (ranked = integrity matters)
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
- Structure (default to layered)

**If the conversation goes off track:** Gently redirect:
> "Before we dive into [tangent], let me make sure I have the foundation right. Are you planning to use Git+Rojo, or work primarily in Studio?"

The goal is flexibility without losing the critical decisions that prevent day-zero mistakes.
