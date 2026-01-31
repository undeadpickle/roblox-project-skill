--!strict
--[[
	ErrorReporter: Capture and report unhandled errors.

	Hooks into ScriptContext.Error to catch all unhandled errors,
	deduplicates them, and can send to an external service.

	Usage:
		-- In your server init (once):
		local ErrorReporter = require(ServerModules.ErrorReporter)
		ErrorReporter.init()

		-- Manual error reporting:
		ErrorReporter.report("Something went wrong", debug.traceback())

		-- Wrap risky code:
		ErrorReporter.wrap(function()
			riskyOperation()
		end)()

	Configuration:
		ErrorReporter.config.mode = "development" | "production" | "disabled"
		ErrorReporter.config.endpoint = "https://your-error-service.com/errors"
]]

local HttpService = game:GetService("HttpService")
local ScriptContext = game:GetService("ScriptContext")
local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Logger = require(Shared.Logger)

local log = Logger.new("ErrorReporter")

-- Types
export type ErrorReport = {
	message: string,
	stack: string?,
	script: string?,
	line: number?,
	timestamp: number,
	count: number,
	context: string, -- "server" or "client"
	placeId: number,
	placeVersion: number,
}

export type ErrorConfig = {
	mode: "development" | "production" | "disabled",
	endpoint: string?,
	dedupeWindow: number, -- Seconds to dedupe identical errors
	maxQueueSize: number,
	flushInterval: number,
}

-- Module
local ErrorReporter = {}

-- Configuration
ErrorReporter.config: ErrorConfig = {
	mode = "development",
	endpoint = nil,
	dedupeWindow = 60, -- Dedupe same error for 60 seconds
	maxQueueSize = 100,
	flushInterval = 30,
}

-- Private state
local errorQueue: { ErrorReport } = {}
local errorHashes: { [string]: { timestamp: number, report: ErrorReport } } = {}
local initialized = false

--[[
	Generate a hash for error deduplication.
]]
local function hashError(message: string, script: string?): string
	return `{message}:{script or "unknown"}`
end

--[[
	Queue an error for reporting.
]]
local function queueError(report: ErrorReport)
	if ErrorReporter.config.mode == "disabled" then
		return
	end

	-- Dedupe check
	local hash = hashError(report.message, report.script)
	local existing = errorHashes[hash]
	local now = os.time()

	if existing and (now - existing.timestamp) < ErrorReporter.config.dedupeWindow then
		-- Increment count on existing error
		existing.report.count += 1
		return
	end

	-- New error or outside dedupe window
	errorHashes[hash] = { timestamp = now, report = report }

	if #errorQueue < ErrorReporter.config.maxQueueSize then
		table.insert(errorQueue, report)
	end

	-- Always log in development
	if ErrorReporter.config.mode == "development" then
		log:error("[CAPTURED]", report.message)
		if report.stack then
			log:error("Stack:", report.stack)
		end
	end
end

--[[
	Parse error info from ScriptContext.Error signal.
]]
local function parseError(message: string, stack: string, script: LuaSourceContainer?): ErrorReport
	local scriptName = if script then script:GetFullName() else nil

	-- Try to extract line number from stack
	local line: number? = nil
	if stack then
		local lineMatch = stack:match(":(%d+)")
		if lineMatch then
			line = tonumber(lineMatch)
		end
	end

	return {
		message = message,
		stack = stack,
		script = scriptName,
		line = line,
		timestamp = os.time(),
		count = 1,
		context = if RunService:IsServer() then "server" else "client",
		placeId = game.PlaceId,
		placeVersion = game.PlaceVersion,
	}
end

--[[
	Flush errors to the configured endpoint.
]]
function ErrorReporter.flush()
	if #errorQueue == 0 then
		return
	end

	if ErrorReporter.config.mode ~= "production" then
		table.clear(errorQueue)
		return
	end

	local endpoint = ErrorReporter.config.endpoint
	if not endpoint then
		log:warn("Production mode but no endpoint configured")
		table.clear(errorQueue)
		return
	end

	local errors = table.clone(errorQueue)
	table.clear(errorQueue)

	task.spawn(function()
		local success, err = pcall(function()
			HttpService:PostAsync(endpoint, HttpService:JSONEncode({
				errors = errors,
				gameId = game.PlaceId,
				version = game.PlaceVersion,
				timestamp = os.time(),
			}), Enum.HttpContentType.ApplicationJson)
		end)

		if not success then
			log:error("Failed to send error report:", err)
		end
	end)
end

--[[
	Initialize the error reporter. Call once on server start.
]]
function ErrorReporter.init()
	if initialized then
		log:warn("Already initialized")
		return
	end

	if ErrorReporter.config.mode == "disabled" then
		log:info("Error reporting disabled")
		return
	end

	-- Hook into ScriptContext.Error
	ScriptContext.Error:Connect(function(message, stack, script)
		local report = parseError(message, stack, script)
		queueError(report)
	end)

	-- Periodic flush
	task.spawn(function()
		while true do
			task.wait(ErrorReporter.config.flushInterval)
			ErrorReporter.flush()
		end
	end)

	-- Flush on shutdown
	game:BindToClose(function()
		ErrorReporter.flush()
	end)

	-- Clean old dedupe entries periodically
	task.spawn(function()
		while true do
			task.wait(60)
			local now = os.time()
			for hash, data in errorHashes do
				if (now - data.timestamp) > ErrorReporter.config.dedupeWindow * 2 then
					errorHashes[hash] = nil
				end
			end
		end
	end)

	initialized = true
	log:info("Initialized (mode:", ErrorReporter.config.mode, ")")
end

--[[
	Manually report an error.
]]
function ErrorReporter.report(message: string, stack: string?, context: { [string]: any }?)
	queueError({
		message = message,
		stack = stack,
		script = nil,
		line = nil,
		timestamp = os.time(),
		count = 1,
		context = if RunService:IsServer() then "server" else "client",
		placeId = game.PlaceId,
		placeVersion = game.PlaceVersion,
	})
end

--[[
	Wrap a function to automatically report errors.
	Returns a new function that catches and reports errors.
]]
function ErrorReporter.wrap<T...>(fn: (T...) -> ...any): (T...) -> ...any
	return function(...: T...)
		local results = table.pack(xpcall(fn, function(err)
			local stack = debug.traceback(tostring(err), 2)
			ErrorReporter.report(tostring(err), stack)
			return err
		end, ...))

		local success = results[1]
		if not success then
			-- Error was already reported, re-throw
			error(results[2], 0)
		end

		return table.unpack(results, 2, results.n)
	end
end

--[[
	Get current error queue size (for monitoring).
]]
function ErrorReporter.getQueueSize(): number
	return #errorQueue
end

return ErrorReporter
