--!strict
--[[
	RateLimiter: Protect RemoteEvents from spam/exploits.

	Uses a token bucket algorithm - each player gets N tokens that refill over time.
	Requests consume tokens; if empty, requests are rejected.

	Usage:
		local RateLimiter = require(ServerModules.RateLimiter)

		-- Create a limiter: 10 requests per second, burst of 15
		local attackLimiter = RateLimiter.new({
			rate = 10,      -- Tokens added per second
			capacity = 15,  -- Max tokens (burst capacity)
		})

		-- In your RemoteEvent handler:
		Remote.OnServerEvent:Connect(function(player, ...)
			if not attackLimiter:check(player) then
				warn("Rate limited:", player.Name)
				return
			end
			-- Process request...
		end)
]]

local Players = game:GetService("Players")

-- Types
export type RateLimiterConfig = {
	rate: number, -- Tokens per second
	capacity: number, -- Max tokens (burst)
}

export type RateLimiter = {
	check: (self: RateLimiter, player: Player) -> boolean,
	reset: (self: RateLimiter, player: Player) -> (),
	destroy: (self: RateLimiter) -> (),
}

type PlayerBucket = {
	tokens: number,
	lastRefill: number,
}

-- Module
local RateLimiter = {}
RateLimiter.__index = RateLimiter

--[[
	Create a new rate limiter.

	@param config.rate - Tokens added per second
	@param config.capacity - Maximum tokens (burst capacity)
]]
function RateLimiter.new(config: RateLimiterConfig): RateLimiter
	local self = setmetatable({}, RateLimiter)

	self._rate = config.rate
	self._capacity = config.capacity
	self._buckets = {} :: { [Player]: PlayerBucket }

	-- Clean up when players leave
	self._connection = Players.PlayerRemoving:Connect(function(player)
		self._buckets[player] = nil
	end)

	return self :: any
end

--[[
	Check if a player can make a request. Consumes 1 token if allowed.

	@param player - The player making the request
	@return true if allowed, false if rate limited
]]
function RateLimiter:check(player: Player): boolean
	local now = os.clock()
	local bucket = self._buckets[player]

	-- Initialize bucket for new players
	if not bucket then
		bucket = {
			tokens = self._capacity,
			lastRefill = now,
		}
		self._buckets[player] = bucket
	end

	-- Refill tokens based on time elapsed
	local elapsed = now - bucket.lastRefill
	local refill = elapsed * self._rate
	bucket.tokens = math.min(self._capacity, bucket.tokens + refill)
	bucket.lastRefill = now

	-- Check if request can proceed
	if bucket.tokens >= 1 then
		bucket.tokens -= 1
		return true
	end

	return false
end

--[[
	Reset a player's rate limit (full tokens).
	Useful after penalties or special circumstances.
]]
function RateLimiter:reset(player: Player)
	self._buckets[player] = {
		tokens = self._capacity,
		lastRefill = os.clock(),
	}
end

--[[
	Clean up the rate limiter.
]]
function RateLimiter:destroy()
	if self._connection then
		self._connection:Disconnect()
		self._connection = nil
	end
	table.clear(self._buckets)
end

return RateLimiter
