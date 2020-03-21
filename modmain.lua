local OPEN_KEY = GetModConfigData("OPEN_KEY")
local TOGGLE_MODE = GetModConfigData("TOGGLE_MODE")
local IGLO_ICON = GetModConfigData("IGLO_ICON_SIZE")
local MAPICONS_ENABLED = GetModConfigData("MAPICONS_ENABLED")
local IGLO_NUMBERS = GetModConfigData("IGLO_NUMBERS")

local GLOBAL, require, TheInput = GLOBAL, GLOBAL.require, GLOBAL.TheInput
local BossCalendar = require("screens/bosscalendar")
local Prefabs =
{
	yellowgem =
	{
		npc = "Dragonfly",
		death_anim = {"death"}
	},
	hivehat =
	{
		npc = "Bee Queen",
		death_anim = {"death"}
	},
	shroom_skin =
	{
		npc = "Toadstool",
		death_anim = {"death"}
	},
	klaussackkey =
	{
		npc = "Klaus",
		death_anim = {"death"}
	},
	blowdart_pipe =
	{
		npc = "MacTusk",
		death_anim = {"death"}
	},
	malbatross_beak =
	{
		npc = "Malbatross",
		death_anim = {"death_ocean", "death"}
	},
	skeletonhat =
	{
		npc = "Fuelweaver",
		death_anim = {"death3"}
	}
}

Assets = 
{
	Asset("ATLAS", "images/skull.xml"),
	Asset("ATLAS", "images/npcs.xml"),
	Asset("ATLAS", IGLO_ICON),
}
AddMinimapAtlas(IGLO_ICON)

if MAPICONS_ENABLED then
	local function MapWidgetPostConstruct(self)
		BossCalendar:AddMapIcons(self, IGLO_ICON)
	end

	AddClassPostConstruct("widgets/mapwidget", MapWidgetPostConstruct) 
end

local function Walrus_Camp_PostInit(inst, recur)
	if recur then
		BossCalendar:AddCamp(inst, IGLO_ICON, IGLO_NUMBERS)
	else
		inst:DoTaskInTime(0, Walrus_Camp_PostInit, true)
	end
end
AddPrefabPostInit("walrus_camp", Walrus_Camp_PostInit)

local function GetNpc(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x, y, z, 5, 0, 0, {"epic", "walrus"})
	return ents[1]
end

local function ValidateDeath(inst)
	local npc = GetNpc(inst)
	if npc and npc:IsValid() then
		for i = 1, #Prefabs[inst.prefab].death_anim do
			if npc.AnimState:IsCurrentAnimation(Prefabs[inst.prefab].death_anim[i]) then
				BossCalendar:KilledMonster(Prefabs[inst.prefab].npc, npc)
				return
			end
		end
	end
end

for prefab in pairs(Prefabs) do
	AddPrefabPostInit(prefab, function(inst)
		inst:DoTaskInTime(0, ValidateDeath)
	end)
end

local function CanToggle()
	if	TheFrontEnd and 
		TheFrontEnd:GetActiveScreen() and 
		TheFrontEnd:GetActiveScreen().name then 
		return TheFrontEnd:GetActiveScreen().name == "HUD" or TheFrontEnd:GetActiveScreen().name == "Boss Calendar"
	end
	return
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

if OPEN_KEY then
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
			local settings = 
			{
				ReminderColor = GetModConfigData("REMINDER_COLOR"),
				ReminderDuration = GetModConfigData("REMINDER_DURATION"),
				CalendarUnits = GetModConfigData("CALENDAR_UNITS"),
				AnnounceStyle = GetModConfigData("ANNOUNCE_STYLES"),
				AnnounceUnits = GetModConfigData("ANNOUNCE_UNITS"),
				NetworkNotifications = GetModConfigData("NETWORK_NOTIFICATIONS")
			} 

			BossCalendar:Init(settings)
		end
	else
		inst:DoTaskInTime(0, Init, true)
	end
end
AddPlayerPostInit(Init)
AddSimPostInit(BossCalendar.LoadIgloos)
