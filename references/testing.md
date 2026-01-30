# Testing in Roblox

Unit testing and integration testing patterns for Roblox games.

## TestEZ

**TestEZ** is the standard testing framework for Roblox, created by Roblox engineers. It uses a BDD-style syntax similar to Jest/Mocha.

### Installation

```toml
# wally.toml
[dev-dependencies]
TestEZ = "roblox/testez@0.4"
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
local MathUtils = require(script.Parent.MathUtils)

return function()
    describe("MathUtils", function()
        describe("add", function()
            it("should add two positive numbers", function()
                expect(MathUtils.add(2, 3)).to.equal(5)
            end)

            it("should handle negative numbers", function()
                expect(MathUtils.add(-1, 1)).to.equal(0)
            end)
        end)

        describe("clamp", function()
            it("should clamp values within range", function()
                expect(MathUtils.clamp(5, 0, 10)).to.equal(5)
                expect(MathUtils.clamp(-5, 0, 10)).to.equal(0)
                expect(MathUtils.clamp(15, 0, 10)).to.equal(10)
            end)
        end)
    end)
end
```

### Common Assertions

```luau
-- Equality
expect(value).to.equal(expected)
expect(value).to.never.equal(unexpected)

-- Truthiness
expect(value).to.be.ok()           -- truthy
expect(value).to.never.be.ok()     -- falsy

-- Type checking
expect(value).to.be.a("string")
expect(value).to.be.a("table")

-- Near equality (for floats)
expect(1.0001).to.be.near(1, 0.001)

-- Error throwing
expect(function()
    errorFunction()
end).to.throw()

expect(function()
    safeFunction()
end).to.never.throw()

-- Table contents
expect({"a", "b"}).to.contain("a")
```

### Setup and Teardown

```luau
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

```luau
local Promise = require(Packages.Promise)

return function()
    describe("async operations", function()
        itFIXME("should handle promises", function()
            -- TestEZ doesn't have great Promise support
            -- Consider using SKIP or manual synchronization
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

            expect(completed).to.equal(true)
        end)
    end)
end
```

### Skip and Focus

```luau
-- Skip a test (won't run)
itSKIP("broken test", function() end)

-- Focus on specific tests (only focused tests run)
itFOCUS("important test", function() end)

-- Same for describe blocks
describeSKIP("skipped suite", function() end)
describeFOCUS("focused suite", function() end)
```

---

## Running Tests

### Option 1: In Studio (Quick Testing)

Create a test runner script:

```luau
-- ServerScriptService/RunTests.server.luau (don't commit to prod)
local TestEZ = require(game.ReplicatedStorage.Packages.TestEZ)

-- Run all tests in a container
TestEZ.TestBootstrap:run({
    game.ReplicatedStorage.Shared,
    game.ServerScriptService.Server.modules,
})
```

### Option 2: run-in-roblox (CI/CD)

[run-in-roblox](https://github.com/rojo-rbx/run-in-roblox) executes scripts in a headless Roblox instance:

```bash
# Install
rokit add rojo-rbx/run-in-roblox

# Run tests
run-in-roblox --place game.rbxl --script tests/run-tests.luau
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
return function()
    describe("lerp", function()
        it("returns start value at t=0", function()
            expect(MathUtils.lerp(0, 100, 0)).to.equal(0)
        end)

        it("returns end value at t=1", function()
            expect(MathUtils.lerp(0, 100, 1)).to.equal(100)
        end)

        it("interpolates at t=0.5", function()
            expect(MathUtils.lerp(0, 100, 0.5)).to.equal(50)
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

            expect(firedArgs).to.be.ok()
            expect(firedArgs.player).to.equal(mockPlayer)
            expect(firedArgs.message).to.equal("Hello!")
        end)
    end)
end
```

### Testing State Changes

```luau
return function()
    describe("Inventory", function()
        local inventory

        beforeEach(function()
            inventory = Inventory.new()
        end)

        it("starts empty", function()
            expect(#inventory:getItems()).to.equal(0)
        end)

        it("adds items", function()
            inventory:addItem("sword")
            expect(inventory:hasItem("sword")).to.equal(true)
        end)

        it("removes items", function()
            inventory:addItem("sword")
            inventory:removeItem("sword")
            expect(inventory:hasItem("sword")).to.equal(false)
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

- [TestEZ Documentation](https://roblox.github.io/testez/)
- [run-in-roblox](https://github.com/rojo-rbx/run-in-roblox)
- [Lune](https://lune-org.github.io/docs)
