local TOGGLE_MODE = GetModConfigData("TOGGLE_MODE")

local GLOBAL = GLOBAL
local require, TheInput = GLOBAL.require, GLOBAL.TheInput
local BossCalendar = require("screens/bosscalendar")

Assets = 
{
	Asset("ATLAS", "images/skull.xml"),
	Asset("ATLAS", "images/npcs.xml"),
	Asset("ATLAS", "images/igloo.xml"),
}
AddMinimapAtlas("images/igloo.xml")

if GetModConfigData("IGLOO_ICON") then
	local function MapWidgetPostConstruct(self)
		BossCalendar:AddMapIcons(self)
	end

	AddClassPostConstruct("widgets/mapwidget", MapWidgetPostConstruct) 
end

local function WalrusCampPostInit(inst)
	inst:DoTaskInTime(0, BossCalendar.AddCamp, inst)
end
AddPrefabPostInit("walrus_camp", WalrusCampPostInit)

do
	local prefabs =
	{
		"yellowgem", 
		"hivehat", 
		"shroom_skin",
		"klaussackkey",
		"blowdart_pipe",
		"malbatross_beak",
		"skeletonhat"
	}
	for i = 1, #prefabs do
		AddPrefabPostInit(prefabs[i], function(inst)
			inst:DoTaskInTime(0, function() BossCalendar:ValidateDeath(inst) end)
		end)
	end
end

local function CanToggle()
	return 	TheFrontEnd and
		TheFrontEnd:GetActiveScreen() and
		TheFrontEnd:GetActiveScreen().name and 
		(TheFrontEnd:GetActiveScreen().name == "HUD" or TheFrontEnd:GetActiveScreen().name == "Boss Calendar")
end

local function Display()
	if CanToggle() then
		if BossCalendar:Open() then 
			TheFrontEnd:PushScreen(BossCalendar)
		elseif TOGGLE_MODE then
			BossCalendar:Close()
		end
	end
end

local function Close()
	if CanToggle() then
		BossCalendar:Close()
	end
end

if GetModConfigData("OPEN_KEY") then
	local OPEN_KEY = GetModConfigData("OPEN_KEY")

	if TOGGLE_MODE then
		TheInput:AddKeyUpHandler(OPEN_KEY, Display)
	else
		TheInput:AddKeyDownHandler(OPEN_KEY, Display)
		TheInput:AddKeyUpHandler(OPEN_KEY, Close)
	end
end

local function Init(inst, recur)
	if recur then
		if inst == GLOBAL.ThePlayer then
			BossCalendar:Init()
		end
	else
		inst:DoTaskInTime(0, Init, true)
	end
end
AddPlayerPostInit(Init)

AddSimPostInit(BossCalendar.LoadIgloos)

BossCalendar:SetSettings(
	{
		IGLOO_ICON = GetModConfigData("IGLOO_ICON"),
		IGLOO_NUMBERS = GetModConfigData("IGLOO_NUMBERS"),
		REMINDER_COLOR = GetModConfigData("REMINDER_COLOR"),
		REMINDER_DURATION = GetModConfigData("REMINDER_DURATION"),
		CALENDAR_UNITS = GetModConfigData("CALENDAR_UNITS"),
		ANNOUNCE_STYLES = GetModConfigData("ANNOUNCE_STYLES"),
		ANNOUNCE_UNITS = GetModConfigData("ANNOUNCE_UNITS"),
		NETWORK_NOTIFICATIONS = GetModConfigData("NETWORK_NOTIFICATIONS")
	}
)
