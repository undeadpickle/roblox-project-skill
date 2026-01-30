# Technical Planning for Roblox Projects

## Why Plan Technically

Some problems are easy to fix late. Others require rewriting everything. Technical planning identifies the hard problems early so you don't discover them after building 50 hours of content.

## Key Questions Before Building

### Performance Budget

**Target devices matter:**
| Device | Typical Constraints |
|--------|---------------------|
| Low-end mobile | 30 FPS goal, <500MB memory |
| Mid-range mobile | 30-60 FPS, <1GB memory |
| Desktop | 60 FPS, memory less constrained |
| Console | 60 FPS, specific optimization needed |

**Questions to answer:**
- What's your minimum target device?
- How many players per server? (8? 20? 100?)
- How many active parts/instances at once?
- How much of the world is loaded at any time?

**Common performance killers:**
- Too many parts (use MeshParts, reduce unique parts)
- Unoptimized loops (especially in RenderStepped)
- Memory leaks (connections not cleaned up)
- Unnecessary replication (sending everything to everyone)

### Data Persistence

**What needs saving?**
- Player inventory/items
- Progress/levels/unlocks
- Currency/purchases
- Settings/preferences
- Custom creations (if applicable)

**DataStore limits:**
- 4MB per key
- 60 requests/min per key (with throttling)
- 500KB recommended practical limit per save

**Questions to answer:**
- How much data per player?
- How often do you need to save?
- What happens if a save fails?
- Do players need to share data? (trading, leaderboards)

**Common data pitfalls:**
- Saving too frequently (hitting rate limits)
- Saving too infrequently (data loss on crash)
- Not handling DataStore failures gracefully
- Storing redundant data (computed values)

### Network Architecture

**Rule**: Never trust the client.

| What | Where to Handle |
|------|-----------------|
| Currency/economy | Server ONLY |
| Damage/combat | Server authoritative |
| Movement | Client predicted, server validated |
| UI/cosmetics | Client-side fine |
| Admin commands | Server ONLY |

**Questions to answer:**
- What actions can exploit if client-controlled?
- What needs server validation?
- How much latency can you tolerate?
- What happens if server/client disagree?

### Known Hard Problems

Some things are technically complex in Roblox. Know what you're getting into:

| Feature | Difficulty | Notes |
|---------|------------|-------|
| Large open worlds | Hard | Streaming, LOD, chunk loading |
| Physics sync (vehicles) | Hard | Network ownership, client prediction |
| Real-time PvP combat | Medium-Hard | Lag compensation, hit detection |
| Complex inventory | Medium | Data structure, UI, edge cases |
| Procedural generation | Medium | Performance, seeding, saving state |
| Social features | Medium | Friend data, cross-server communication |
| Voice chat | Easy (native) | Roblox handles this now |
| Matchmaking | Medium | Teleporting, lobby management |

### External Dependencies

**Questions to answer:**
- Are you using marketplace assets? (Can they break? Get deleted?)
- Third-party modules? (Who maintains them?)
- External APIs? (Rate limits? Reliability?)
- Roblox features that are in beta? (Can they change?)

**Risk mitigation:**
- Keep local copies of critical dependencies
- Abstract external services behind your own wrapper
- Have fallback plans for service outages

## Architecture Decisions

Make these decisions explicitly, not accidentally:

### Module vs. Script Organization
- Will you use a framework (Knit, Nevermore)?
- How will services communicate?
- Where does shared code live?

### State Management
- Where is game state stored? (single source of truth)
- How do you prevent race conditions?
- How does state sync between server/clients?

### Event Patterns
- RemoteEvents vs. RemoteFunctions?
- How do you prevent remote spam/exploits?
- How do you handle events that arrive out of order?

## Pre-Build Checklist

Before writing game code:

**Performance:**
- [ ] Target device/framerate defined
- [ ] Max player count decided
- [ ] World size/streaming strategy chosen
- [ ] Part budget estimated

**Data:**
- [ ] Data structure designed
- [ ] Save/load strategy chosen
- [ ] Failure handling planned
- [ ] Data migration strategy (for updates)

**Network:**
- [ ] Client/server responsibilities mapped
- [ ] Security-critical systems identified
- [ ] Remote event structure planned

**Dependencies:**
- [ ] External assets inventoried
- [ ] Update/maintenance plan for dependencies
- [ ] Fallbacks for critical dependencies

## Red Flags

Stop and reconsider if:

- You're not sure how the core tech will work
- You're hoping a hard problem "won't be that bad"
- Your architecture assumes perfect network conditions
- You're storing data you can't explain the purpose of
- You're using a library you don't understand

## Prototyping Technical Risk

If you're unsure whether something is technically feasible, prototype THAT specifically before building game content around it.

**Bad order:**
1. Design entire game assuming feature X works
2. Build 20 hours of content
3. Discover feature X has fundamental issues
4. Cry

**Good order:**
1. Identify feature X as risky
2. Build minimal prototype testing X specifically
3. Confirm it works (or learn it doesn't)
4. Design around confirmed technical reality

---

## Quick Reference

**Three questions before any system:**
1. Does this need server authority?
2. How much data does this generate?
3. What happens at scale?
