--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)
local Logger = require(Shared.Logger)

local log = Logger.new("Client")
local player = Players.LocalPlayer

local function initialize(): ()
	log:info("Initializing...")
	
	-- TODO: Initialize client systems
	-- Example: require(script.modules.InputHandler).init()
end

local function onCharacterAdded(character: Model): ()
	log:debug("Character spawned")
	
	-- TODO: Character setup
end

-- Connect character events
player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
	task.spawn(onCharacterAdded, player.Character)
end

initialize()
log:info("Ready")
