local OPENKEY = GetModConfigData("OPENKEY")
local REMINDER_COLOR = GetModConfigData("REMINDER_COLOR")
local REMINDER_DURATION = GetModConfigData("REMINDER_DURATION")
local CALENDAR_UNITS = GetModConfigData("CALENDAR_UNITS")
local ANNOUNCE_STYLE = GetModConfigData("ANNOUNCE_STYLES")
local ANNOUNCE_UNITS = GetModConfigData("ANNOUNCE_UNITS")
local TOGGLEMODE = GetModConfigData("TOGGLEMODE")
local IGLO_ICON = GetModConfigData("IGLO_ICON_SIZE")
local MAPICONS_ENABLED = GetModConfigData("MAPICONS_ENABLED")
local IGLO_NUMBERS = GetModConfigData("IGLO_NUMBERS")
local GLOBAL, require, TheInput = GLOBAL, GLOBAL.require, GLOBAL.TheInput
local BossCalendar = require("screens/bosscalendar")
local Prefabs = {
	yellowgem = {
		npc = "Dragonfly",
		death_anim = {"death"}
	},
	hivehat = {
		npc = "Bee Queen",
		death_anim = {"death"}
	},
	shroom_skin = {
		npc = "Toadstool",
		death_anim = {"death"}
	},
	klaussackkey = {
		npc = "Klaus",
		death_anim = {"death"}
	},
	blowdart_pipe = {
		npc = "MacTusk",
		death_anim = {"death"}
	},
	malbatross_beak = {
		npc = "Malbatross",
		death_anim = {"death_ocean", "death"}
	},
	skeletonhat = {
		npc = "Fuelweaver",
		death_anim = {"death3"}
	}
}

Assets = {
	Asset("ATLAS", "images/skull.xml"),
	Asset("ATLAS", "images/npcs.xml"),
	Asset("ATLAS", "images/"..IGLO_ICON..".xml"),
}
AddMinimapAtlas("images/"..IGLO_ICON..".xml")

if MAPICONS_ENABLED then
	AddClassPostConstruct("widgets/mapwidget", function(self)
		BossCalendar:AddMapIcons(self, IGLO_ICON)
	end)
end

AddPrefabPostInit("walrus_camp", function(inst)
	inst:DoTaskInTime(0, function()
		if inst and inst:IsValid() then
			BossCalendar:AddCamp(inst, IGLO_ICON, IGLO_NUMBERS)
		end
	end)
end)

local function GetNpc(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x, y, z, 15, 0, 0, {"epic", "walrus"})
	return #ents > 0 and ents[1]
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
		inst:DoTaskInTime(0, function() ValidateDeath(inst) end)
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
		elseif TOGGLEMODE then
			BossCalendar:Close()
		end
	end
end

local function Close()
	if CanToggle() then
		BossCalendar:Close()
	end
end

if OPENKEY then
	if TOGGLEMODE then
		TheInput:AddKeyUpHandler(OPENKEY, Display)
	else
		TheInput:AddKeyDownHandler(OPENKEY, Display)
		TheInput:AddKeyUpHandler(OPENKEY, Close)
	end
end

local function ModInit(inst)
	inst:DoTaskInTime(0, function()
		if inst == GLOBAL.ThePlayer then
			BossCalendar:Init(REMINDER_COLOR, REMINDER_DURATION, CALENDAR_UNITS, ANNOUNCE_STYLE, ANNOUNCE_UNITS)
		end
	end)
end
AddPlayerPostInit(ModInit)
AddSimPostInit(function() BossCalendar:LoadIgloos() end)