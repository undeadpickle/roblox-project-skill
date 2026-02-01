--!strict
--[[
	MathUtils: Common math helper functions.

	Example module demonstrating testable utility functions.
	See MathUtils.spec.luau for corresponding tests.
]]

local MathUtils = {}

--[[
	Clamp a value between min and max.
]]
function MathUtils.clamp(value: number, min: number, max: number): number
	return math.max(min, math.min(max, value))
end

--[[
	Linear interpolation between two values.
]]
function MathUtils.lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

--[[
	Round a number to the specified decimal places.
]]
function MathUtils.round(value: number, decimals: number?): number
	local mult = 10 ^ (decimals or 0)
	return math.floor(value * mult + 0.5) / mult
end

--[[
	Check if a value is within a range (inclusive).
]]
function MathUtils.inRange(value: number, min: number, max: number): boolean
	return value >= min and value <= max
end

--[[
	Map a value from one range to another.
]]
function MathUtils.map(value: number, inMin: number, inMax: number, outMin: number, outMax: number): number
	return outMin + (value - inMin) * (outMax - outMin) / (inMax - inMin)
end

return MathUtils
