--!strict
--[[
	Analytics: Track player events for engagement metrics.

	Events are queued locally and can be:
	- Logged to Output (development)
	- Sent to external service via HTTP (production)
	- Stored in DataStore for later analysis

	Usage:
		local Analytics = require(ServerModules.Analytics)

		-- Track a custom event
		Analytics.track(player, "LevelCompleted", {
			level = 5,
			time = 120,
			score = 1500,
		})

		-- Track common events (convenience methods)
		Analytics.trackSessionStart(player)
		Analytics.trackPurchase(player, "sword_01", 100)
		Analytics.trackLevelComplete(player, 5, 120)

	Configuration:
		Set Analytics.config.mode to:
		- "development": Logs to Output only
		- "production": Sends to HTTP endpoint (configure endpoint)
		- "disabled": No tracking

	COPPA Note:
		This module does NOT collect personal information by default.
		Player data uses anonymous UserId. Do not add email, name,
		or other PII without proper consent flows.
]]

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Logger = require(Shared.Logger)

local log = Logger.new("Analytics")

-- Types
export type EventData = { [string]: any }

export type AnalyticsEvent = {
	timestamp: number,
	userId: number,
	sessionId: string,
	eventName: string,
	data: EventData,
}

export type AnalyticsConfig = {
	mode: "development" | "production" | "disabled",
	endpoint: string?, -- HTTP endpoint for production mode
	batchSize: number, -- Events to batch before sending
	flushInterval: number, -- Seconds between auto-flush
}

-- Module
local Analytics = {}

-- Configuration (modify for your project)
Analytics.config: AnalyticsConfig = {
	mode = "development",
	endpoint = nil, -- Set your analytics endpoint here
	batchSize = 10,
	flushInterval = 30,
}

-- Private state
local eventQueue: { AnalyticsEvent } = {}
local sessionIds: { [Player]: string } = {}
local lastFlush = os.clock()

--[[
	Generate a unique session ID for a player.
]]
local function generateSessionId(): string
	return HttpService:GenerateGUID(false)
end

--[[
	Get or create session ID for a player.
]]
local function getSessionId(player: Player): string
	if not sessionIds[player] then
		sessionIds[player] = generateSessionId()
	end
	return sessionIds[player]
end

--[[
	Queue an event for processing.
]]
local function queueEvent(event: AnalyticsEvent)
	if Analytics.config.mode == "disabled" then
		return
	end

	table.insert(eventQueue, event)

	-- Log in development mode
	if Analytics.config.mode == "development" then
		log:debug(
			string.format("[%s] User %d: %s", event.eventName, event.userId, HttpService:JSONEncode(event.data))
		)
	end
end

--[[
	Flush queued events to the configured endpoint.
]]
function Analytics.flush()
	if #eventQueue == 0 then
		return
	end

	if Analytics.config.mode ~= "production" then
		-- In development, just clear the queue (already logged)
		table.clear(eventQueue)
		return
	end

	local endpoint = Analytics.config.endpoint
	if not endpoint then
		log:warn("Production mode but no endpoint configured")
		table.clear(eventQueue)
		return
	end

	-- Copy and clear queue
	local events = table.clone(eventQueue)
	table.clear(eventQueue)

	-- Send to endpoint
	task.spawn(function()
		local success, err = pcall(function()
			HttpService:PostAsync(endpoint, HttpService:JSONEncode({
				events = events,
				gameId = game.PlaceId,
				version = game.PlaceVersion,
			}), Enum.HttpContentType.ApplicationJson)
		end)

		if not success then
			log:error("Failed to send analytics:", err)
			-- Re-queue failed events (with limit to prevent infinite growth)
			if #eventQueue < 1000 then
				for _, event in events do
					table.insert(eventQueue, event)
				end
			end
		end
	end)
end

--[[
	Track a custom event.

	@param player - The player who triggered the event
	@param eventName - Name of the event (e.g., "LevelCompleted")
	@param data - Optional event data
]]
function Analytics.track(player: Player, eventName: string, data: EventData?)
	queueEvent({
		timestamp = os.time(),
		userId = player.UserId,
		sessionId = getSessionId(player),
		eventName = eventName,
		data = data or {},
	})

	-- Auto-flush if batch size reached
	if #eventQueue >= Analytics.config.batchSize then
		Analytics.flush()
	end
end

--[[
	Track session start. Call when player joins/data loads.
]]
function Analytics.trackSessionStart(player: Player)
	Analytics.track(player, "SessionStart", {
		joinTime = os.time(),
	})
end

--[[
	Track session end. Call when player leaves.
]]
function Analytics.trackSessionEnd(player: Player, playTime: number)
	Analytics.track(player, "SessionEnd", {
		playTime = playTime,
	})
end

--[[
	Track a purchase (Robux or in-game currency).
]]
function Analytics.trackPurchase(player: Player, itemId: string, price: number, currency: string?)
	Analytics.track(player, "Purchase", {
		itemId = itemId,
		price = price,
		currency = currency or "Coins",
	})
end

--[[
	Track level/stage completion.
]]
function Analytics.trackLevelComplete(player: Player, level: number, timeSeconds: number, score: number?)
	Analytics.track(player, "LevelComplete", {
		level = level,
		time = timeSeconds,
		score = score,
	})
end

--[[
	Track a tutorial step (for funnel analysis).
]]
function Analytics.trackTutorialStep(player: Player, step: string, completed: boolean)
	Analytics.track(player, "TutorialStep", {
		step = step,
		completed = completed,
	})
end

--[[
	Track a button click or UI interaction.
]]
function Analytics.trackUIInteraction(player: Player, element: string, action: string?)
	Analytics.track(player, "UIInteraction", {
		element = element,
		action = action or "click",
	})
end

-- Periodic flush
task.spawn(function()
	while true do
		task.wait(Analytics.config.flushInterval)
		if os.clock() - lastFlush >= Analytics.config.flushInterval then
			Analytics.flush()
			lastFlush = os.clock()
		end
	end
end)

-- Clean up session IDs when players leave
Players.PlayerRemoving:Connect(function(player)
	-- Flush any pending events for this player
	Analytics.flush()
	sessionIds[player] = nil
end)

-- Flush on server shutdown
game:BindToClose(function()
	Analytics.flush()
end)

log:info("Initialized (mode:", Analytics.config.mode, ")")

return Analytics
