--!strict
--[[
	Tests for MathUtils module.

	Example test file demonstrating Jest Lua patterns.
	Run with: lune run scripts/run-tests.luau (or via Studio test runner)
]]

-- selene: allow(incorrect_standard_library_use)
local JestGlobals = require("@DevPackages/JestGlobals")
local describe = JestGlobals.describe
local expect = JestGlobals.expect
local it = JestGlobals.it

local MathUtils = require(script.Parent.MathUtils)

return function()
	describe("MathUtils", function()
		describe("clamp", function()
			it("should return value when within range", function()
				expect(MathUtils.clamp(5, 0, 10)).toBe(5)
			end)

			it("should clamp to min when below range", function()
				expect(MathUtils.clamp(-5, 0, 10)).toBe(0)
			end)

			it("should clamp to max when above range", function()
				expect(MathUtils.clamp(15, 0, 10)).toBe(10)
			end)

			it("should handle equal min and max", function()
				expect(MathUtils.clamp(5, 3, 3)).toBe(3)
			end)
		end)

		describe("lerp", function()
			it("should return start value at t=0", function()
				expect(MathUtils.lerp(0, 100, 0)).toBe(0)
			end)

			it("should return end value at t=1", function()
				expect(MathUtils.lerp(0, 100, 1)).toBe(100)
			end)

			it("should return midpoint at t=0.5", function()
				expect(MathUtils.lerp(0, 100, 0.5)).toBe(50)
			end)

			it("should handle negative values", function()
				expect(MathUtils.lerp(-10, 10, 0.5)).toBe(0)
			end)
		end)

		describe("round", function()
			it("should round to nearest integer by default", function()
				expect(MathUtils.round(3.7)).toBe(4)
				expect(MathUtils.round(3.2)).toBe(3)
			end)

			it("should round to specified decimal places", function()
				expect(MathUtils.round(3.14159, 2)).toBe(3.14)
				expect(MathUtils.round(3.14159, 3)).toBe(3.142)
			end)

			it("should handle negative numbers", function()
				expect(MathUtils.round(-3.7)).toBe(-4)
			end)
		end)

		describe("inRange", function()
			it("should return true when value is within range", function()
				expect(MathUtils.inRange(5, 0, 10)).toBe(true)
			end)

			it("should return true when value equals min", function()
				expect(MathUtils.inRange(0, 0, 10)).toBe(true)
			end)

			it("should return true when value equals max", function()
				expect(MathUtils.inRange(10, 0, 10)).toBe(true)
			end)

			it("should return false when value is outside range", function()
				expect(MathUtils.inRange(-1, 0, 10)).toBe(false)
				expect(MathUtils.inRange(11, 0, 10)).toBe(false)
			end)
		end)

		describe("map", function()
			it("should map value from one range to another", function()
				-- Map 5 from [0,10] to [0,100] = 50
				expect(MathUtils.map(5, 0, 10, 0, 100)).toBe(50)
			end)

			it("should handle inverted output range", function()
				-- Map 0 from [0,10] to [100,0] = 100
				expect(MathUtils.map(0, 0, 10, 100, 0)).toBe(100)
			end)

			it("should handle values at range boundaries", function()
				expect(MathUtils.map(0, 0, 10, 0, 100)).toBe(0)
				expect(MathUtils.map(10, 0, 10, 0, 100)).toBe(100)
			end)
		end)
	end)
end
