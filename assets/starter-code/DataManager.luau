--!strict
--[[
	DataManager: Player data persistence using ProfileStore.
	
	Handles loading, saving, and session management for player data.
	Uses Promise for async operations and Trove for cleanup.
	
	Usage:
		local DataManager = require(ServerModules.DataManager)
		
		-- Get player data (waits if still loading)
		DataManager.getDataAsync(player):andThen(function(data)
			print(data.Coins)
		end)
		
		-- Update data
		DataManager.updateData(player, function(data)
			data.Coins += 100
		end)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local ProfileStore = require(Packages.ProfileStore)
local Promise = require(Packages.Promise)
local Trove = require(Packages.Trove)
local GoodSignal = require(Packages.GoodSignal)

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Logger = require(Shared.Logger)
local GameConfig = require(Shared.GameConfig)

local log = Logger.new("DataManager")

-- Types
export type PlayerData = {
	Coins: number,
	Inventory: { string },
	Stats: {
		PlayTime: number,
		JoinDate: number,
	},
	Settings: {
		MusicEnabled: boolean,
		SFXEnabled: boolean,
	},
}

export type Profile = ProfileStore.Profile<PlayerData>

-- Default data template for new players
local DEFAULT_DATA: PlayerData = {
	Coins = 0,
	Inventory = {},
	Stats = {
		PlayTime = 0,
		JoinDate = 0,
	},
	Settings = {
		MusicEnabled = true,
		SFXEnabled = true,
	},
}

-- Module
local DataManager = {}

-- Signals
DataManager.OnDataLoaded = GoodSignal.new() -- (player: Player, data: PlayerData)
DataManager.OnDataChanged = GoodSignal.new() -- (player: Player, data: PlayerData)

-- Private state
local playerStore = ProfileStore.New("PlayerData_v1", DEFAULT_DATA)
local profiles: { [Player]: Profile } = {}
local loadPromises: { [Player]: any } = {} -- Promise<PlayerData>
local playerTroves: { [Player]: any } = {} -- Trove per player
local sessionStarts: { [Player]: number } = {} -- Track session start for PlayTime calculation

--[[
	Load player data. Returns a Promise that resolves with the data.
	Safe to call multiple times - returns cached Promise if already loading.
]]
function DataManager.loadDataAsync(player: Player): any
	-- Return existing promise if already loading
	if loadPromises[player] then
		return loadPromises[player]
	end

	local promise = Promise.new(function(resolve, reject)
		local profile = playerStore:StartSessionAsync(`{player.UserId}`, {
			Cancel = function()
				return player.Parent ~= Players
			end,
		})

		-- Player left during load
		if not profile then
			reject("Profile session failed to start")
			return
		end

		-- Player left after load
		if player.Parent ~= Players then
			profile:EndSession()
			reject("Player left during load")
			return
		end

		-- Set join date if new player
		if profile.Data.Stats.JoinDate == 0 then
			profile.Data.Stats.JoinDate = os.time()
		end

		-- Handle session end (player leaving, server shutdown, etc.)
		profile.OnSessionEnd:Connect(function()
			profiles[player] = nil
			loadPromises[player] = nil
			sessionStarts[player] = nil

			if playerTroves[player] then
				playerTroves[player]:Destroy()
				playerTroves[player] = nil
			end

			-- Kick if still in game (session stolen by another server)
			if player.Parent == Players then
				player:Kick("Data session ended. Please rejoin.")
			end
		end)

		profiles[player] = profile
		sessionStarts[player] = os.time() -- Track session start for PlayTime
		log:info("Data loaded for", player.Name)

		DataManager.OnDataLoaded:Fire(player, profile.Data)
		resolve(profile.Data)
	end)

	loadPromises[player] = promise
	return promise
end

--[[
	Get player data. Returns Promise that resolves immediately if loaded,
	or waits for load to complete.
]]
function DataManager.getDataAsync(player: Player): any
	local profile = profiles[player]
	if profile then
		return Promise.resolve(profile.Data)
	end

	if loadPromises[player] then
		return loadPromises[player]
	end

	return Promise.reject("No data loading for player")
end

--[[
	Get player data synchronously. Returns nil if not loaded yet.
	Use getDataAsync() for safer access.
]]
function DataManager.getData(player: Player): PlayerData?
	local profile = profiles[player]
	return if profile then profile.Data else nil
end

--[[
	Update player data with a transform function.
	The function receives the data table and can modify it directly.
]]
function DataManager.updateData(player: Player, transform: (data: PlayerData) -> ()): boolean
	local profile = profiles[player]
	if not profile then
		log:warn("Cannot update data - profile not loaded for", player.Name)
		return false
	end

	transform(profile.Data)
	DataManager.OnDataChanged:Fire(player, profile.Data)
	return true
end

--[[
	Add coins to player. Convenience wrapper.
]]
function DataManager.addCoins(player: Player, amount: number): boolean
	return DataManager.updateData(player, function(data)
		data.Coins = math.max(0, data.Coins + amount)
	end)
end

--[[
	Check if player has enough coins.
]]
function DataManager.hasCoins(player: Player, amount: number): boolean
	local data = DataManager.getData(player)
	return data ~= nil and data.Coins >= amount
end

--[[
	Get player's Trove for cleanup management.
	Creates one if it doesn't exist.
]]
function DataManager.getTrove(player: Player): any
	if not playerTroves[player] then
		playerTroves[player] = Trove.new()
	end
	return playerTroves[player]
end

-- Player lifecycle
local function onPlayerAdded(player: Player)
	DataManager.loadDataAsync(player)
		:andThen(function(data)
			log:info(player.Name, "has", data.Coins, "coins")
		end)
		:catch(function(err)
			log:error("Failed to load data for", player.Name, "-", err)
			player:Kick("Failed to load your data. Please rejoin.")
		end)
end

local function onPlayerRemoving(player: Player)
	local profile = profiles[player]
	if profile then
		-- Update play time before saving (use session start, not JoinDate)
		local sessionStart = sessionStarts[player] or os.time()
		local sessionTime = os.time() - sessionStart
		profile.Data.Stats.PlayTime += sessionTime

		profile:EndSession()
	end

	-- Cleanup
	profiles[player] = nil
	loadPromises[player] = nil
	sessionStarts[player] = nil

	if playerTroves[player] then
		playerTroves[player]:Destroy()
		playerTroves[player] = nil
	end
end

-- Initialize
local function init()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	-- Handle players already in game (Studio)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	log:info("Initialized")
end

init()

return DataManager
