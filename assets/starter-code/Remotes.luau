--!strict
--[[
	Remotes: Helper module for RemoteEvent/RemoteFunction management.
	
	Centralizes remote creation and access. Define your event names as
	constants here, then use getEvent() or getFunction() to access them.
	
	Usage:
		-- Define event names
		Remotes.PLAYER_READY = "PlayerReady"
		
		-- Server: Connect
		Remotes.getEvent(Remotes.PLAYER_READY).OnServerEvent:Connect(handler)
		
		-- Client: Fire
		Remotes.getEvent(Remotes.PLAYER_READY):FireServer()
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

-- Define your remote event names here:
-- Remotes.PLAYER_READY = "PlayerReady"
-- Remotes.DATA_LOADED = "DataLoaded"
-- Remotes.ACTION_REQUEST = "ActionRequest"

local remotesFolder: Folder? = nil

local function getRemotesFolder(): Folder
	if remotesFolder then
		return remotesFolder
	end

	local existing = ReplicatedStorage:FindFirstChild("Remotes")
	if existing and existing:IsA("Folder") then
		remotesFolder = existing
		return remotesFolder
	end

	local folder = Instance.new("Folder")
	folder.Name = "Remotes"
	folder.Parent = ReplicatedStorage
	remotesFolder = folder
	return folder
end

--- Get or create a RemoteEvent by name
function Remotes.getEvent(name: string): RemoteEvent
	local folder = getRemotesFolder()
	local event = folder:FindFirstChild(name)

	if event and event:IsA("RemoteEvent") then
		return event
	end

	local newEvent = Instance.new("RemoteEvent")
	newEvent.Name = name
	newEvent.Parent = folder
	return newEvent
end

--- Get or create a RemoteFunction by name
function Remotes.getFunction(name: string): RemoteFunction
	local folder = getRemotesFolder()
	local func = folder:FindFirstChild(name)

	if func and func:IsA("RemoteFunction") then
		return func
	end

	local newFunc = Instance.new("RemoteFunction")
	newFunc.Name = name
	newFunc.Parent = folder
	return newFunc
end

return Remotes
