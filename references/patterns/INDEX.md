# Reusable Patterns

These modules contain patterns that apply across multiple game types. Reference them from game-type profiles rather than duplicating code.

---

## Available Patterns

| Pattern | Description | Common Uses |
|---------|-------------|-------------|
| [AI Systems](ai-systems.md) | State machines, pathfinding, detection, AI director | NPCs, enemies, pets, guards, bosses |
| [Audio Systems](audio-systems.md) | New Audio API, dynamic music, positional audio | Any game with sound design |
| [Camera Effects](camera-effects.md) | Shake, post-processing, vignette, flash | Combat feedback, horror atmosphere, damage indication |
| [Multiplayer Systems](multiplayer-systems.md) | Spectate, revive, event sync, teams | Co-op games, round-based games, team games |
| [Anti-Exploit](anti-exploit.md) | Movement validation, action validation, honeypots | Any multiplayer game |
| [Trigger Systems](trigger-systems.md) | Proximity triggers, interactables, cooldowns | Checkpoints, pickups, doors, zones |

---

## How to Reference

In game-type profiles, link to these patterns instead of duplicating code:

```markdown
### AI System

See [patterns/ai-systems.md](../patterns/ai-systems.md) for:
- State machine implementation
- Line of sight detection
- AI Director for dynamic difficulty

For horror games, configure the state machine with these states:
- Idle → Patrol → Investigate → Chase → Search → Stunned
```

---

## Pattern Structure

Each pattern file includes:

1. **Overview** — What the pattern does and when to use it
2. **Core Implementation** — The main code pattern
3. **Variations** — Adaptations for different use cases
4. **Usage Examples** — How to integrate into a game
5. **Pitfalls** — Common mistakes to avoid

---

## Adding New Patterns

When creating a new pattern:

1. Create file in `references/patterns/`
2. Follow the structure above
3. Add to this index
4. Update relevant game-type profiles to reference it
