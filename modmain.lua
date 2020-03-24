local TOGGLE_MODE = GetModConfigData("TOGGLE_MODE")

local GLOBAL = GLOBAL
local require, TheInput = GLOBAL.require, GLOBAL.TheInput
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
		death_anim =
		{
			"death_ocean", 
			"death"
		}
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
	inst:DoTaskInTime(0, BossCalendar.AddCamp, inst, IGLOO_ICON, IGLOO_NUMBERS)
end
AddPrefabPostInit("walrus_camp", WalrusCampPostInit)

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