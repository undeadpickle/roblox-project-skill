# Luau Coding Conventions

## Naming

| Style | Use For |
|-------|---------|
| `PascalCase` | Services, classes, modules, types |
| `camelCase` | Variables, functions, parameters |
| `SCREAMING_SNAKE_CASE` | Constants |
| `_camelCase` | Private members |

## File Structure Order

1. `--!strict`
2. Services via `game:GetService()`
3. Module imports via `require()`
4. Type definitions
5. Constants
6. Module-level variables
7. Private functions
8. Public functions
9. Return statement

## Task Library (Required)

| Use This | NOT This |
|----------|----------|
| `task.wait(n)` | `wait(n)` |
| `task.spawn(fn)` | `spawn(fn)` |
| `task.delay(n, fn)` | `delay(n, fn)` |
| `task.defer(fn)` | N/A |
| `task.cancel(thread)` | N/A |

## Service Access

Always use `game:GetService()`:

```luau
-- Correct
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- Avoid
local players = game.Players
local workspace = workspace  -- global
```

## Iteration

Use generalized iteration (no `pairs`/`ipairs`):

```luau
-- Correct
for key, value in dictionary do
for index, item in array do

-- Avoid
for key, value in pairs(dictionary) do
for index, item in ipairs(array) do
```

## Type Annotations

Always annotate function parameters and returns:

```luau
local function calculateDamage(baseDamage: number, multiplier: number): number
    return baseDamage * multiplier
end

local function getPlayer(userId: number): Player?
    return Players:GetPlayerByUserId(userId)
end
```

## Module Pattern

```luau
--!strict
local MyModule = {}

-- Public function
function MyModule.doSomething(value: string): boolean
    return true
end

-- Private function (not in module table)
local function helperFunction(): ()
    -- internal logic
end

return MyModule
```

## Avoid

- `workspace` global → Use `game:GetService("Workspace")`
- `pairs()`/`ipairs()` → Use generalized iteration
- Complex metatables for simple classes → Use typed tables + functions
- Dynamic requires → Use static paths
- `require(game.ReplicatedStorage.Module)` → Use variables: `require(Shared.Module)`
