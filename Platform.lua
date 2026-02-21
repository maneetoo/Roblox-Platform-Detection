------>> Player: Platform @module <<------
-----// Detects user platform (Desktop, Mobile, Console, VR) and console type
----// Provides callback functions for platform changes
---// @manee_too (2026)
--// License: MIT

-->> Types <<--
export type Platform = "Console" | "Mobile" | "VR" | "Desktop"
export type ConsoleType = "Xbox" | "PlayStation" | nil

-->> Services <<--
local UIS: UserInputService = game:GetService("UserInputService")
local GuiService: GuiService = game:GetService("GuiService")
local Players: Players = game:GetService("Players")
local RunService: RunService = game:GetService("RunService")

-->> Module Variables <<--
local module = {}
local platformChangedCallbacks: {[number]: (Platform, ConsoleType) -> ()} = {}
local consoleTypeChangedCallbacks: {[number]: (ConsoleType) -> ()} = {}
local callbackIdCounter: number = 0

-->> Constants <<--
local PLATFORM_CHANGE_CHECK_INTERVAL: number = 1
local TEN_FOOT_CHECK_INTERVAL: number = 2





-->> Internal Functions <<--

-- Computes the current platform and console type for a player
-- @param player: The player to compute platform for (defaults to LocalPlayer)
-- @return Platform, ConsoleType
function module.Compute(player: Player): (Platform, ConsoleType)
	player = player or Players.LocalPlayer
	if not player then warn("[Platform]: Can't get Player, return defaults...") return "Desktop", nil end
	
	local newPlatform: Platform = "Desktop"
	local consoleType: ConsoleType = nil

	if UIS.VREnabled then
		newPlatform = "VR"
	elseif (UIS.GamepadEnabled) or (GuiService:IsTenFootInterface() and not UIS.MouseEnabled) then
		newPlatform = "Console"
		consoleType = UIS:GetStringForKeyCode(Enum.KeyCode.ButtonX) == "ButtonSquare" and "PlayStation" or "Xbox"
	elseif (UIS.TouchEnabled and not (UIS.KeyboardEnabled or UIS.MouseEnabled)) or
		UIS.GyroscopeEnabled or UIS.AccelerometerEnabled then
		newPlatform = "Mobile"
	end

	shared._Platform = newPlatform
	shared._ConsoleType = consoleType

	return newPlatform, consoleType
end





-->> Callback Registration Functions <<--

-- Registers a callback for platform changes
function module.OnPlatformChanged(callback: (Platform, ConsoleType) -> ()): number
	callbackIdCounter += 1
	platformChangedCallbacks[callbackIdCounter] = callback
	
	return callbackIdCounter
end

-- Registers a callback for console type changes
function module.OnConsoleTypeChanged(callback: (ConsoleType) -> ()): number
	callbackIdCounter += 1
	consoleTypeChangedCallbacks[callbackIdCounter] = callback
	
	return callbackIdCounter
end

-- Removes a callback by ID
function module.RemoveCallback(callbackId: number)
	platformChangedCallbacks[callbackId] = nil
	consoleTypeChangedCallbacks[callbackId] = nil
end






-->> Internal Trigger Functions <<--
local function safeCallback(callback: (...any) -> (), ...: any)
	local args = {...}
	task.spawn(function()
		pcall(callback, unpack(args))
	end)
end

local function triggerPlatformChanged(newPlatform: Platform, newConsoleType: ConsoleType)
	--print("Platform Changed! Platform:", newPlatform, "ConsoleType:", newConsoleType, "| Calling callbacks...")
	for _, callback in pairs(platformChangedCallbacks) do
		safeCallback(callback, newPlatform, newConsoleType)
	end
end

local function triggerConsoleTypeChanged(newConsoleType: ConsoleType)
	--print("ConsoleType Changed! NewConsoleType:", newConsoleType, "| Calling callbacks...")
	for _, callback in pairs(consoleTypeChangedCallbacks) do
		safeCallback(callback, newConsoleType)
	end
end






-->> Update Function <<--
function module.Update(player: Player): Platform
	local oldPlatform = shared._Platform
	local oldConsoleType = shared._ConsoleType

	local newPlatform, newConsoleType = module.Compute(player)

	if oldPlatform ~= newPlatform then
		triggerPlatformChanged(newPlatform, newConsoleType)
	end

	if newPlatform == "Console" and oldConsoleType ~= newConsoleType then
		triggerConsoleTypeChanged(newConsoleType)
	end

	return newPlatform
end





-->> Utility Functions <<--
function module.GetConsoleType(): ConsoleType
	if not shared._Platform then
		module.Compute()
	end
	
	return shared._ConsoleType
end

function module.GetPlatform(): Platform
	if not shared._Platform then
		module.Compute()
	end
	
	return shared._Platform
end

function module.IsConsole(): boolean
	return shared._Platform == "Console"
end

function module.IsMobile(): boolean
	return shared._Platform == "Mobile"
end

function module.IsVR(): boolean
	return shared._Platform == "VR"
end

function module.IsDesktop(): boolean
	return shared._Platform == "Desktop"
end





-->> Event Listeners & Initialization <<--
task.defer(function()
	module.Compute()
	local function Update() module.Update() end
	
	UIS.GamepadConnected:Connect(function()
		task.wait(0.1) 
		module.Update()
	end)
	UIS.GamepadDisconnected:Connect(Update)

	local lastTenFoot: boolean = GuiService:IsTenFootInterface()
	local timeSinceLastCheck: number = 0
	RunService.Heartbeat:Connect(function(dt)
		timeSinceLastCheck += dt
		if timeSinceLastCheck >= TEN_FOOT_CHECK_INTERVAL then
			timeSinceLastCheck = 0
			local currentTenFoot = GuiService:IsTenFootInterface()
			if currentTenFoot ~= lastTenFoot then
				lastTenFoot = currentTenFoot
				module.Update()
			end
		end
	end)

	UIS:GetPropertyChangedSignal("VREnabled"):Connect(Update)
	UIS:GetPropertyChangedSignal("TouchEnabled"):Connect(Update)
	UIS:GetPropertyChangedSignal("KeyboardEnabled"):Connect(Update)
	UIS:GetPropertyChangedSignal("MouseEnabled"):Connect(Update)
	
	shared.GetPlatform = module.GetPlatform
	shared.GetConsoleType = module.GetConsoleType
	shared.OnPlatformChanged = module.OnPlatformChanged
	shared.OnConsoleTypeChanged = module.OnConsoleTypeChanged
	shared.RemovePlatformCallback = module.RemoveCallback
	shared.IsConsole = module.IsConsole
	shared.IsMobile = module.IsMobile
	shared.IsVR = module.IsVR
	shared.IsDesktop = module.IsDesktop
end)


return module