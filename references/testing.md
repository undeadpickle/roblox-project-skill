# Testing in Roblox

Unit testing and integration testing patterns for Roblox games.

## Jest Lua

**Jest Lua** is the standard testing framework for Roblox, maintained by jsdotlua and used internally by Roblox. It uses a BDD-style syntax identical to JavaScript Jest.

### Installation

```toml
# wally.toml
[dev-dependencies]
Jest = "jsdotlua/jest@3.10.0"
JestGlobals = "jsdotlua/jest-globals@3.10.0"
```

Then `wally install`.

### File Naming Convention

Test files use `.spec.luau` suffix:

```
src/
├── shared/
│   ├── MathUtils.luau
│   └── MathUtils.spec.luau  ← Tests for MathUtils
├── server/
│   └── modules/
│       ├── DataManager.luau
│       └── DataManager.spec.luau
```

The `default.project.json` already excludes spec files from production builds:
```json
"globIgnorePaths": ["**/*.spec.luau", "**/*.test.luau"]
```

### Basic Syntax

```luau
--!strict
local JestGlobals = require("@DevPackages/JestGlobals")
local describe = JestGlobals.describe
local expect = JestGlobals.expect
local it = JestGlobals.it

local MathUtils = require(script.Parent.MathUtils)

return function()
    describe("MathUtils", function()
        describe("add", function()
            it("should add two positive numbers", function()
                expect(MathUtils.add(2, 3)).toBe(5)
            end)

            it("should handle negative numbers", function()
                expect(MathUtils.add(-1, 1)).toBe(0)
            end)
        end)

        describe("clamp", function()
            it("should clamp values within range", function()
                expect(MathUtils.clamp(5, 0, 10)).toBe(5)
                expect(MathUtils.clamp(-5, 0, 10)).toBe(0)
                expect(MathUtils.clamp(15, 0, 10)).toBe(10)
            end)
        end)
    end)
end
```

### Common Matchers

```luau
-- Equality
expect(value).toBe(expected)          -- strict equality
expect(value).toEqual(expected)       -- deep equality for tables
expect(value).never.toBe(unexpected)  -- negation

-- Truthiness
expect(value).toBeTruthy()            -- truthy
expect(value).toBeFalsy()             -- falsy (nil or false)
expect(value).toBeNil()               -- nil check

-- Numbers
expect(value).toBeGreaterThan(3)
expect(value).toBeGreaterThanOrEqual(3)
expect(value).toBeLessThan(5)
expect(value).toBeLessThanOrEqual(5)
expect(0.1 + 0.2).toBeCloseTo(0.3)    -- float comparison

-- Strings
expect("Christoph").toMatch("stop")   -- pattern match
expect("Christoph").toContain("stop") -- substring

-- Arrays/Tables
expect({"a", "b"}).toContain("a")
expect({1, 2, 3}).toHaveLength(3)

-- Error throwing
expect(function()
    errorFunction()
end).toThrow()

expect(function()
    errorFunction()
end).toThrow("specific error message")

expect(function()
    safeFunction()
end).never.toThrow()
```

### Setup and Teardown

```luau
local JestGlobals = require("@DevPackages/JestGlobals")
local describe = JestGlobals.describe
local it = JestGlobals.it
local beforeAll = JestGlobals.beforeAll
local afterAll = JestGlobals.afterAll
local beforeEach = JestGlobals.beforeEach
local afterEach = JestGlobals.afterEach

return function()
    describe("PlayerManager", function()
        local manager

        beforeAll(function()
            -- Runs once before all tests in this describe block
        end)

        afterAll(function()
            -- Runs once after all tests
        end)

        beforeEach(function()
            -- Runs before each test
            manager = PlayerManager.new()
        end)

        afterEach(function()
            -- Runs after each test
            manager:destroy()
        end)

        it("should track players", function()
            -- Test using manager
        end)
    end)
end
```

### Async Testing

Jest Lua supports async operations by returning promises:

```luau
local JestGlobals = require("@DevPackages/JestGlobals")
local it = JestGlobals.it
local expect = JestGlobals.expect

return function()
    describe("async operations", function()
        it("should handle promises", function()
            return someAsyncFunction():andThen(function(result)
                expect(result).toBe("expected")
            end)
        end)

        it("should work with task.wait", function()
            local completed = false
            task.spawn(function()
                task.wait(0.1)
                completed = true
            end)

            -- Wait for completion
            local timeout = os.clock() + 1
            while not completed and os.clock() < timeout do
                task.wait()
            end

            expect(completed).toBe(true)
        end)
    end)
end
```

### Skip and Focus

```luau
-- Skip a test (won't run)
it.skip("broken test", function() end)
xit("also skipped", function() end)

-- Focus on specific tests (only focused tests run)
it.only("important test", function() end)
fit("also focused", function() end)

-- Same for describe blocks
describe.skip("skipped suite", function() end)
xdescribe("also skipped suite", function() end)

describe.only("focused suite", function() end)
fdescribe("also focused suite", function() end)
```

---

## Running Tests

### Option 1: In Studio (Quick Testing)

Create a test runner script:

```luau
-- scripts/run-tests.luau (don't commit to prod)
local runCLI = require("@DevPackages/Jest").runCLI

local processServiceExists, ProcessService = pcall(function()
    return game:GetService("ProcessService")
end)

local status, result = runCLI(game.ReplicatedStorage.Shared, {
    verbose = false,
    ci = false
}, { game.ReplicatedStorage.Shared }):awaitStatus()

if status == "Rejected" then
    print(result)
end

if processServiceExists then
    if status == "Resolved" and result.results.numFailedTestSuites == 0 and result.results.numFailedTests == 0 then
        ProcessService:ExitAsync(0)
    else
        ProcessService:ExitAsync(1)
    end
end
```

### Option 2: run-in-roblox (CI/CD)

[run-in-roblox](https://github.com/rojo-rbx/run-in-roblox) executes scripts in a headless Roblox instance:

```bash
# Install
rokit add rojo-rbx/run-in-roblox

# Run tests
run-in-roblox --place test-place.rbxl --script scripts/run-tests.luau
```

### Option 3: Lune (Faster, Limited)

[Lune](https://lune-org.github.io/docs) runs Luau outside Roblox. Great for pure logic tests, but no Roblox APIs:

```bash
# Install
rokit add lune-org/lune

# Run test file
lune run tests/math-utils.spec.luau
```

---

## Test Patterns

### Testing Pure Functions

Pure functions (no side effects) are easiest to test:

```luau
-- MathUtils.luau
local MathUtils = {}

function MathUtils.lerp(a: number, b: number, t: number): number
    return a + (b - a) * t
end

return MathUtils

-- MathUtils.spec.luau
local JestGlobals = require("@DevPackages/JestGlobals")
local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local MathUtils = require(script.Parent.MathUtils)

return function()
    describe("lerp", function()
        it("returns start value at t=0", function()
            expect(MathUtils.lerp(0, 100, 0)).toBe(0)
        end)

        it("returns end value at t=1", function()
            expect(MathUtils.lerp(0, 100, 1)).toBe(100)
        end)

        it("interpolates at t=0.5", function()
            expect(MathUtils.lerp(0, 100, 0.5)).toBe(50)
        end)
    end)
end
```

### Testing with Dependencies (Mocking)

Inject dependencies to make code testable:

```luau
-- NotificationService.luau
local NotificationService = {}

function NotificationService.new(remoteEvent)
    return {
        _remote = remoteEvent,
        send = function(self, player, message)
            self._remote:FireClient(player, message)
        end
    }
end

return NotificationService

-- NotificationService.spec.luau
local JestGlobals = require("@DevPackages/JestGlobals")
local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local NotificationService = require(script.Parent.NotificationService)

return function()
    describe("NotificationService", function()
        it("fires remote with correct arguments", function()
            -- Create mock remote
            local firedArgs = nil
            local mockRemote = {
                FireClient = function(self, player, message)
                    firedArgs = { player = player, message = message }
                end
            }

            local service = NotificationService.new(mockRemote)
            local mockPlayer = { Name = "TestPlayer" }

            service:send(mockPlayer, "Hello!")

            expect(firedArgs).toBeTruthy()
            expect(firedArgs.player).toBe(mockPlayer)
            expect(firedArgs.message).toBe("Hello!")
        end)
    end)
end
```

### Testing State Changes

```luau
local JestGlobals = require("@DevPackages/JestGlobals")
local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect
local beforeEach = JestGlobals.beforeEach

local Inventory = require(script.Parent.Inventory)

return function()
    describe("Inventory", function()
        local inventory

        beforeEach(function()
            inventory = Inventory.new()
        end)

        it("starts empty", function()
            expect(#inventory:getItems()).toBe(0)
        end)

        it("adds items", function()
            inventory:addItem("sword")
            expect(inventory:hasItem("sword")).toBe(true)
        end)

        it("removes items", function()
            inventory:addItem("sword")
            inventory:removeItem("sword")
            expect(inventory:hasItem("sword")).toBe(false)
        end)
    end)
end
```

---

## What NOT to Test

Testing everything isn't practical. Skip these:

1. **Roblox engine behavior** — Don't test that `Part.Position` works
2. **Third-party libraries** — Trust ProfileStore, Promise, etc.
3. **Simple getters/setters** — No logic = nothing to break
4. **UI layout** — Visual testing is better done manually

**Do test:**
- Business logic (damage calculation, inventory management)
- Data transformations
- State machines
- Edge cases in algorithms

---

## Tips

1. **Test behavior, not implementation** — Tests shouldn't break when you refactor internals
2. **One assertion per test** — Makes failures easier to diagnose
3. **Descriptive test names** — `"should reject invalid input"` not `"test1"`
4. **Test edge cases** — Empty arrays, nil values, max/min numbers
5. **Keep tests fast** — Slow tests don't get run

---

## Further Reading

- [Jest Lua Documentation](https://jsdotlua.github.io/jest-lua/)
- [run-in-roblox](https://github.com/rojo-rbx/run-in-roblox)
- [Lune](https://lune-org.github.io/docs)
