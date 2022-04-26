-- Events
RegisterNetEvent('HologramSpeed:SetTheme')

-- Constants
local ResourceName       = GetCurrentResourceName()
local HologramURI        = string.format("nui://%s/ui/hologram.html", ResourceName)
local AttachmentOffset   = vec3(2.5, -1, 1)
local AttachmentRotation = vec3(0, 0, -15)
local HologramModel      = `hologram_box_model`
local SettingKey         = string.format("%s:profile", GetCurrentServerEndpoint()) -- The key to store the current theme setting in. As themes are per server, this key is also.
local DBG                = false -- Enables debug information, not very useful unless you know what you are doing!

-- Variables
local duiObject      = false -- The DUI object, used for messaging and is destroyed when the resource is stopped
local duiIsReady     = false -- Set by a callback triggered by DUI once the javascript has fully loaded
local hologramObject = 0 -- The current DUI anchor. 0 when one does not exist
local usingMetric, shouldUseMetric = ShouldUseMetricMeasurements() -- Used to track the status of the metric measurement setting

-- Preferences
local displayEnabled = false
local currentTheme   = GetConvar("hsp_defaultTheme", "default")

local function DebugPrint(...)
	if DBG then
		print(...)
	end
end

local function EnsureDuiMessage(data)
	if duiObject and duiIsReady then
		SendDuiMessage(duiObject, json.encode(data))
		return true
	end

	return false
end

local function SendChatMessage(message)
	TriggerEvent('chat:addMessage', {args = {message}})
end

-- Register a callback for when the DUI JS has loaded completely
RegisterNUICallback("duiIsReady", function(_, cb)
	duiIsReady = true
    cb({ok = true})
end)

local function LoadPlayerProfile()
	local jsonData = GetResourceKvpString(SettingKey)
	if jsonData ~= nil then
		jsonData           = json.decode(jsonData)
		displayEnabled     = jsonData.displayEnabled
		currentTheme       = jsonData.currentTheme
		AttachmentOffset   = vec3(jsonData.attachmentOffset.x, jsonData.attachmentOffset.y, jsonData.attachmentOffset.z)
		AttachmentRotation = vec3(jsonData.attachmentRotation.x, jsonData.attachmentRotation.y, jsonData.attachmentRotation.z)
	end
end

local function SavePlayerProfile()
	local jsonData = {
		displayEnabled     = displayEnabled,
		currentTheme       = currentTheme,
		attachmentOffset   = AttachmentOffset,
		attachmentRotation = AttachmentRotation,
	}
	SetResourceKvp(SettingKey, json.encode(jsonData))
end

local function ToggleDisplay()
	displayEnabled = not displayEnabled
	SavePlayerProfile()
end

local function SetTheme(newTheme)
	if newTheme ~= currentTheme then
		EnsureDuiMessage {theme = newTheme}
		SendChatMessage(newTheme == "default" and HologramSpeedConfig.Lang.speedometer_reset or (HologramSpeedConfig.Lang.speedometer_set .. newTheme .. "^r."))
		currentTheme = newTheme
		SavePlayerProfile()
	end
end

local function UpdateEntityAttach()
	local playerPed, currentVehicle
	playerPed = PlayerPedId()
	if IsPedInAnyVehicle(playerPed) then
		currentVehicle = GetVehiclePedIsIn(playerPed, false)
		-- Attach the hologram to the vehicle
		AttachEntityToEntity(hologramObject, currentVehicle, GetEntityBoneIndexByName(currentVehicle, "chassis"), AttachmentOffset, AttachmentRotation, false, false, false, false, false, true)
		DebugPrint(string.format("DUI anchor %s attached to %s", hologramObject, currentVehicle))
	end
end

local function CheckRange(x, y, z, minVal, maxVal)
	if x == nil or y == nil or z == nil or minVal == nil or maxVal == nil then
		return false
	else
		return not (x < minVal or x > maxVal or y < minVal or y > maxVal or z < minVal or z > maxVal)
	end
end

-- Command Handler

local function CommandHandler(args)

	local msgErr = HologramSpeedConfig.Lang.msg_err
	local msgSuc = HologramSpeedConfig.Lang.msg_succ
	
	if args[1] == "theme" then
		if #args >= 2 then
			TriggerServerEvent('HologramSpeed:CheckTheme', args[2])
		else
			SendChatMessage(HologramSpeedConfig.Lang.invalid_theme)
		end
	elseif args[1] == "offset" then
		local nx, ny, nz = 2.5, -1, 0.85
		if #args >= 4 then
			nx, ny, nz = tonumber(args[2]), tonumber(args[3]), tonumber(args[4])
			if not CheckRange(nx, ny, nz, -5.0, 5.0) then
				nx, ny, nz = 2.5, -1, 0.85
				SendChatMessage(string.format(msgErr, args[1], -5.0, 5.0))
			end
		else
			SendChatMessage(HologramSpeedConfig.Lang.offset_reset)
		end
		AttachmentOffset = vec3(nx, ny, nz)
		UpdateEntityAttach()
		SavePlayerProfile()
		SendChatMessage(string.format(msgSuc, args[1], nx, ny, nz))
	elseif args[1] == "rotate" then
		local nx, ny, nz = 0, 0, -15
		if #args >= 4 then
			nx, ny, nz = tonumber(args[2]), tonumber(args[3]), tonumber(args[4])
			if not CheckRange(nx, ny, nz, -45.0, 45.0) then
				nx, ny, nz = 0, 0, -15
				SendChatMessage(string.format(msgErr, args[1], -45.0, 45.0))
			end
		else
			SendChatMessage(HologramSpeedConfig.Lang.rotation_reset)
		end
		AttachmentRotation = vec3(nx, ny, nz)
		UpdateEntityAttach()
		SavePlayerProfile()
		SendChatMessage(string.format(msgSuc, args[1], nx, ny, nz))
	end
end

-- Network events

AddEventHandler('HologramSpeed:SetTheme', function(theme)
	SetTheme(theme)
end)

-- Register command

RegisterCommand(HologramSpeedConfig.CommandName, function(_, args)	
	if #args == 0 then
	if IsPedInAnyVehicle(PlayerPedId(), true) then
		ToggleDisplay()
	else
		CommandHandler(args)
		end
	end
end, false)

TriggerEvent('chat:addSuggestion', '/' .. HologramSpeedConfig.CommandName, HologramSpeedConfig.Lang.toggle_hologram, {
    { name = "command",  help = HologramSpeedConfig.Lang.allow_command },
})

RegisterKeyMapping(HologramSpeedConfig.CommandName, HologramSpeedConfig.Lang.description_keymapping, "keyboard", "grave") -- default: `

-- Initialise the DUI. We only need to do this once.
local function InitialiseDui()
	DebugPrint("Initialising...")

	duiObject = CreateDui(HologramURI, 512, 512)

	DebugPrint("\tDUI created")

	repeat Wait(0) until duiIsReady

	DebugPrint("\tDUI available")

	EnsureDuiMessage {
		useMetric = usingMetric,
		display = false,
		theme = currentTheme
	}

	DebugPrint("\tDUI initialised")

	local txdHandle  = CreateRuntimeTxd("HologramDUI")
	local duiHandle  = GetDuiHandle(duiObject)
	local duiTexture = CreateRuntimeTextureFromDuiHandle(txdHandle, "DUI", duiHandle)
	DebugPrint("\tRuntime texture created")

	DebugPrint("Done!")
end

local currentVehicle, showHud
local intervalShowHud = 1000

local function deleteHologram()
	showHud = false
	intervalShowHud = 1000

	if hologramObject ~= 0 and DoesEntityExist(hologramObject) then
		DeleteVehicle(hologramObject)
	else
		hologramObject = 0
	end
end

-- Main Loop
CreateThread(function()
	-- Sanity checks
	if string.lower(ResourceName) ~= ResourceName then
		return
	end

	if not IsModelInCdimage(HologramModel) or not IsModelAVehicle(HologramModel) then
		SendChatMessage(HologramSpeedConfig.Lang.error_miss_stream)
		return
	end
	
	LoadPlayerProfile()
	
	InitialiseDui()

	local playerPed
	while true do
		playerPed = PlayerPedId()

		-- This thread watches for changes to the user's preferred measurement system
		shouldUseMetric = ShouldUseMetricMeasurements()
	
		if usingMetric ~= shouldUseMetric and EnsureDuiMessage {useMetric = shouldUseMetric} then
			usingMetric = shouldUseMetric
		end

		if showHud then
			if not DoesEntityExist(currentVehicle) or GetVehiclePedIsIn(playerPed, false) ~= currentVehicle then
				deleteHologram()
			end
		end

		if IsPedInAnyVehicle(playerPed) then
			currentVehicle = GetVehiclePedIsIn(playerPed, false)

			if GetPedInVehicleSeat(currentVehicle, -1) == playerPed then
				if not showHud then
					-- Ensure the display is off before we start
					showHud = true
					EnsureDuiMessage {display = false}

					-- Load the hologram model
					RequestModel(HologramModel)
					repeat Wait(0) until HasModelLoaded(HologramModel)

					-- It seems that once the texture unloads(?) the replacement is also removed and never get's added back.
					-- This will ensure that any time the model is about to be used, the texture will be replaced
					AddReplaceTexture("hologram_box_model", "p_hologram_box", "HologramDUI", "DUI")

					-- Create the hologram object
					hologramObject = CreateVehicle(HologramModel, GetEntityCoords(currentVehicle), 0.0, false, true)

					SetVehicleIsConsideredByPlayer(hologramObject, false)
					SetVehicleEngineOn(hologramObject, true, true)
					SetEntityCollision(hologramObject, false, false)

					SetModelAsNoLongerNeeded(HologramModel)

					-- Attach the hologram to the vehicle
					AttachEntityToEntity(hologramObject, currentVehicle, GetEntityBoneIndexByName(currentVehicle, "chassis"), AttachmentOffset, AttachmentRotation, false, false, false, false, false, true)
							
					intervalShowHud = 1
				end
			elseif showHud then
				deleteHologram()
			end
		elseif showHud then
			deleteHologram()
		end

		-- At this point, the player is no longer driving a vehicle or was never driving a vehicle this cycle 

		-- If there is a hologram object currently created...
		
		-- We don't need to check every single frame for the player being in a vehicle so we check every second
		Wait(1000)
	end
end)

CreateThread(function ()
	while true do
		if showHud then

			local vehicleSpeed = GetEntitySpeed(currentVehicle)

			if DoesEntityExist(currentVehicle) then
				EnsureDuiMessage {
					display  = displayEnabled and IsVehicleEngineOn(currentVehicle),
					rpm      = GetVehicleCurrentRpm(currentVehicle),
					gear     = GetVehicleCurrentGear(currentVehicle),
					abs      = (GetVehicleWheelSpeed(currentVehicle, 0) == 0.0) and (vehicleSpeed > 0.0),
					hBrake   = GetVehicleHandbrake(currentVehicle),
					rawSpeed = vehicleSpeed * 3.6, -- if you want to convert in MPH replace 3.6 by 2.236936
					fuel = GetFuelHologram(currentVehicle)
				}
			end
		end

		Wait(intervalShowHud)
	end
end)

AddEventHandler("hologramspeed:seatbeltUpdate", function(state)
	EnsureDuiMessage{ 
		needBelt = state 
	}
end)
 
-- Resource cleanup
AddEventHandler("onResourceStop", function(resource)
	if resource == ResourceName then
		DebugPrint("Cleaning up...")

		displayEnabled = false
		DebugPrint("\tDisplay disabled")

		if DoesEntityExist(hologramObject) then
			DeleteVehicle(hologramObject)
			DebugPrint("\tDUI anchor deleted "..tostring(hologramObject))
		end

		RemoveReplaceTexture("hologram_box_model", "p_hologram_box")
		DebugPrint("\tReplace texture removed")

		if duiObject then
			DebugPrint("\tDUI browser destroyed")
			DestroyDui(duiObject)
			duiObject = false
		end
	end
end)
