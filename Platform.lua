------>> Player: Platform @module <<------
-----// Detects user platform (Desktop, Mobile, Tablet, Console, VR) and console type
----// Provides callback functions for platform changes
---// @manee_too (2026)
--// License: MIT

--!strict
-- Types: Platform, ConsoleType, CallbackPlatformConnection, PlatformModule
-- Patterns: Singleton Class, Observer (OnPlatformChanged/OnConsoleTypeChanged)
-- @GitHub link: https://github.com/maneetoo/Roblox-Platform-Detection
-- Version: 2.0


--[[ 📕 CHANGES  ]]

--// New Features:
-- Added Tablet Detection
-- Added Configurable Detection
-- Proper Connection Objects

--// Improvements:
-- Added Attribute
-- Type Safety (strict - on)
-- Added pcall wrappers
-- Optimized Updates
-- Added _initialized flag
-- Better Documentation

--// Bug Fixes
-- Fixed safeCallback variadic argument handling in spawned threads
-- Fixed duplicate shared state updates in Compute() and Update()

--// API Changes:
--@added: IsTablet(): boolean; CallbackPlatformConnection type with Disconnect() method
--@deprecated: RemoveCallback() - Use connection:Disconnect() instead
--@changed: OnPlatformChanged()/OnConsoleTypeChanged() now returns CallbackPlatformConnection instead of number

-- and much more...

--[[ 📕 END ]]--	





--[[ ⚠️ WARNING ⚠️ ]]--
---// The module is designed to determine the type of device (console, tablet, PC, etc.), rather than to check the available input methods. 
--// If your task requires to know whether the user has a keyboard, mouse or touch screen at the moment, it is better to directly address the UserInputService properties (for example, UIS.TouchEnabled).

-- @docs: https://create.roblox.com/docs/reference/engine/classes/UserInputService?ref=BestEasyCooking (UserInputService)
--[[ ⚠️ END ⚠️ ]]--


-->> Types <<--
export type Platform = "Console" | "Mobile" | "Tablet" | "VR" | "Desktop"
export type ConsoleType = "Xbox" | "PlayStation" | nil

export type CallbackPlatformConnection = {
	Disconnect: () -> (),
	_id: number,
	_type: "platform" | "consoleType"
}

export type PlatformModule = {
	Compute: (player: Player?) -> (Platform, ConsoleType),
	OnPlatformChanged: (callback: (Platform, ConsoleType) -> ()) -> CallbackPlatformConnection,
	OnConsoleTypeChanged: (callback: (ConsoleType) -> ()) -> CallbackPlatformConnection,
	Update: (player: Player?) -> Platform,
	GetConsoleType: () -> ConsoleType,
	GetPlatform: () -> Platform,
	IsConsole: () -> boolean,
	IsMobile: () -> boolean,
	IsTablet: () -> boolean,
	IsVR: () -> boolean,
	IsDesktop: () -> boolean,
	_connections: {CallbackPlatformConnection}?, -- Internal use only!!!
	_initialized: boolean
}

-->> Services <<--
local UIS: UserInputService = game:GetService("UserInputService")
local GuiService: GuiService = game:GetService("GuiService")
local Players: Players = game:GetService("Players")
local RunService: RunService = game:GetService("RunService")

-->> Module Variables <<--
local module = {} :: PlatformModule
local platformChangedCallbacks: {[number]: (Platform, ConsoleType) -> ()} = {}
local consoleTypeChangedCallbacks: {[number]: (ConsoleType) -> ()} = {}
local callbackIdCounter: number = 0
local activeConnections: {CallbackPlatformConnection} = {}

-->> Constants <<--
local TEN_FOOT_CHECK_INTERVAL: number = 2

--// ⚠️ It may malfunction on some foldable phones or very large phones. Roblox does not have a perfect way to correctly determine whether a device is a Tablet or not
local TABLET_CHECK: boolean = true -- Set to false to disable Tablet detection
local TABLET_ASPECT_RATIO_THRESHOLD: number = 1.5 -- Aspect ratio to differentiate tablets from phones (You can change it based on your game's design)




-->> Internal Functions <<--
--[[
    Computes the current platform and console type for a player
    @param player: The player to compute platform for (defaults to LocalPlayer)
    @return Platform, ConsoleType
]]
function module.Compute(player: Player?): (Platform, ConsoleType)
	if not Players then
		warn("[Platform]: Players service not available")
		return "Desktop", nil
	end

	player = player or Players.LocalPlayer

	if not player then 
		warn("[Platform]: Can't get Player, return defaults...") 
		return "Desktop", nil 
	end

	local newPlatform: Platform = "Desktop"
	local consoleType: ConsoleType = nil
	
	local function TabletCheck(): ()
		-- Try to differentiate between phone and tablet based on screen aspect ratio
		local viewportSize = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
		if viewportSize then
			local aspectRatio = math.max(viewportSize.X, viewportSize.Y) / math.min(viewportSize.X, viewportSize.Y)
			if aspectRatio < TABLET_ASPECT_RATIO_THRESHOLD then
				newPlatform = "Tablet"
			else
				newPlatform = "Mobile"
			end
		else
			newPlatform = "Mobile" -- Default to mobile if can't determine
		end
	end

	-- VR detection
	if UIS and UIS.VREnabled then
		newPlatform = "VR"
		
		-- Console detection
	elseif (UIS and UIS.GamepadEnabled) or (GuiService and GuiService:IsTenFootInterface() and not (UIS and UIS.MouseEnabled)) then
		newPlatform = "Console"
		
		-- Determine console type by button mapping (the fastest option)
		if UIS then
			consoleType = if UIS:GetStringForKeyCode(Enum.KeyCode.ButtonX) == "ButtonSquare" then "PlayStation" else "Xbox"
		end
		
		
		
		-- Mobile/Tablet detection
	elseif UIS and UIS.TouchEnabled and not (UIS.KeyboardEnabled or UIS.MouseEnabled) then
		if TABLET_CHECK then
			TabletCheck() -- only if TABLET_CHECK is enabled
		else
			newPlatform = "Mobile"
		end
		
		
		
		-- Fallback to mobile if gyroscope or accelerometer is enabled
	elseif (UIS and (UIS.GyroscopeEnabled or UIS.AccelerometerEnabled)) then
		if TABLET_CHECK then
			TabletCheck() -- only if TABLET_CHECK is enabled
		else
			newPlatform = "Mobile"
		end
	end

	-->> Update shared state <<--
	shared._Platform = newPlatform
	shared._ConsoleType = consoleType
	
	return newPlatform, consoleType :: ConsoleType
end





-->> Callback Registration Functions <<--
--[[
    Registers a callback for platform changes
    @param callback: Function to call when platform changes
    @return CallbackConnection object with Disconnect method
]]
function module.OnPlatformChanged(callback: (Platform, ConsoleType) -> ()): CallbackPlatformConnection
	if type(callback) ~= "function" then
		error("[Platform]: callback must be a function")
	end

	callbackIdCounter += 1
	local callbackId = callbackIdCounter

	platformChangedCallbacks[callbackId] = callback

	local connection: CallbackPlatformConnection = {
		Disconnect = function()
			if platformChangedCallbacks[callbackId] then
				platformChangedCallbacks[callbackId] = nil
			end
			
			-- Remove from active connections
			for i = #activeConnections, 1, -1 do
				if activeConnections[i] and activeConnections[i]._id == callbackId then
					table.remove(activeConnections, i)
					break
				end
			end
		end,
		_id = callbackId,
		_type = "platform"
	}

	table.insert(activeConnections, connection)
	return connection
end

--[[
    Registers a callback for console type changes
    @param callback: Function to call when console type changes
    @return CallbackConnection object with Disconnect method
]]
function module.OnConsoleTypeChanged(callback: (ConsoleType) -> ()): CallbackPlatformConnection
	if type(callback) ~= "function" then
		error("[Platform]: callback must be a function")
	end

	callbackIdCounter += 1
	local callbackId = callbackIdCounter

	consoleTypeChangedCallbacks[callbackId] = callback

	local connection: CallbackPlatformConnection = {
		Disconnect = function()
			if consoleTypeChangedCallbacks[callbackId] then
				consoleTypeChangedCallbacks[callbackId] = nil
			end
			-- Remove from active connections
			for i = #activeConnections, 1, -1 do
				if activeConnections[i] and activeConnections[i]._id == callbackId then
					table.remove(activeConnections, i)
					break
				end
			end
		end,
		_id = callbackId,
		_type = "consoleType"
	}

	table.insert(activeConnections, connection)
	return connection
end







-->> Internal Trigger Functions <<--
local function safeCallback<T...>(callback: (T...) -> (), ...)
	if type(callback) ~= "function" then
		return
	end


	local args = {...}
	task.spawn(function()
		local success = pcall(callback, table.unpack(args))
		if not success then
			warn("[Platform]: Callback error")
		end
	end)
end

local function triggerPlatformChanged(newPlatform: Platform, newConsoleType: ConsoleType)
	for callbackId, callback in pairs(platformChangedCallbacks) do
		if callback then
			safeCallback(callback, newPlatform, newConsoleType)
		end
	end
end

local function triggerConsoleTypeChanged(newConsoleType: ConsoleType)
	for callbackId, callback in pairs(consoleTypeChangedCallbacks) do
		if callback then
			safeCallback(callback, newConsoleType)
		end
	end
end






-->> Update Function <<--
--[[
    Updates the platform state and triggers callbacks if changed
    @param player: Player to update for (optional)
    @return Current platform
]]
function module.Update(player: Player?): Platform
	local oldPlatform: Platform? = shared._Platform
	local oldConsoleType: ConsoleType? = shared._ConsoleType

	local newPlatform, newConsoleType = module.Compute(player)
	if oldPlatform == newPlatform and oldConsoleType == newConsoleType then
		return newPlatform
	end
	
	if oldPlatform ~= newPlatform then
		triggerPlatformChanged(newPlatform, newConsoleType)
	end

	if newPlatform == "Console" and oldConsoleType ~= newConsoleType then
		triggerConsoleTypeChanged(newConsoleType)
	end

	return newPlatform
end







-->> Utility Functions <<--
--[[
    Gets the current console type
    @return ConsoleType or nil
]]
function module.GetConsoleType(): ConsoleType
	if not shared._Platform then
		module.Compute()
	end
	return shared._ConsoleType
end

--[[
    Gets the current platform
    @return Platform
]]
function module.GetPlatform(): Platform
	if not shared._Platform then
		module.Compute()
	end
	return shared._Platform
end

--[[
    Checks if current platform is Console
    @return boolean
]]
function module.IsConsole(): boolean
	return shared._Platform == "Console"
end

--[[
    Checks if current platform is Mobile
    @return boolean
]]
function module.IsMobile(): boolean
	return shared._Platform == "Mobile"
end

--[[
    Checks if current platform is Tablet
    @return boolean
]]
function module.IsTablet(): boolean
	return shared._Platform == "Tablet"
end

--[[
    Checks if current platform is VR
    @return boolean
]]
function module.IsVR(): boolean
	return shared._Platform == "VR"
end

--[[
    Checks if current platform is Desktop
    @return boolean
]]
function module.IsDesktop(): boolean
	return shared._Platform == "Desktop"
end




-->> Initialization <<--
if not pcall(function() module.Compute() end) then
	warn("[Platform]: Failed to initialize platform detection")
	shared._Platform = "Desktop"
	shared._ConsoleType = nil
end


-->> Event Listeners <<--
task.defer(function()
	if module._initialized then
		return
	end
	module._initialized = true
	
	-->> FastUse <<--
	local function Update() module.Update() end

	-->> Gamepad Connections <<--
	if UIS then
		UIS.GamepadConnected:Connect(function()
			task.wait(0.1) -- Give system time to update (Don't delete)
			Update()
		end)

		UIS.GamepadDisconnected:Connect(Update)
	end

	-->> Monitor 10-foot interface checking <<--
	local lastTenFoot: boolean = false
	if GuiService then
		lastTenFoot = GuiService:IsTenFootInterface()
	end

	local timeSinceLastCheck: number = 0

	if RunService then
		RunService.Heartbeat:Connect(function(dt: number)
			timeSinceLastCheck += dt
			if timeSinceLastCheck >= TEN_FOOT_CHECK_INTERVAL then
				timeSinceLastCheck = 0
				if GuiService then
					local currentTenFoot = GuiService:IsTenFootInterface()
					if currentTenFoot ~= lastTenFoot then
						lastTenFoot = currentTenFoot
						Update()
					end
				end
			end
		end)
	end

	-->> Track input property changes <<--
	local propertySignals = {
		"VREnabled", "TouchEnabled", 
		"KeyboardEnabled", "MouseEnabled",
		"GyroscopeEnabled", "AccelerometerEnabled"
	} -- Change it, if you needed

	for _, property in ipairs(propertySignals) do
		local success, signal = pcall(function()
			return UIS:GetPropertyChangedSignal(property)
		end)

		if success and signal then
			signal:Connect(Update)
		end
	end
	
	-->> Attribute (MIT) <<--
	if not RunService:IsStudio() then
		print(`💻 Running PlatformDetection [v2] by @manee_too`)
	end
	-->> End Attribute <<--

	--module._connections = activeConnections -- USE ONLY IN QA OR AS NEEDED!
end)

-->> Export module <<--
shared.PlatformUtils = module

-->> Return Main <<--
return module :: PlatformModule
