local OPENKEY = GetModConfigData("OPENKEY")
local SAYCOLOR = GetModConfigData("SAYCOLOR")
local TIME_UNITS = GetModConfigData("TIME_UNITS")
local ANNOUNCE_STYLE = GetModConfigData("ANNOUNCE_STYLES")
local ANNOUNCE_UNITS = GetModConfigData("ANNOUNCE_UNITS")
local TOGGLEMODE = GetModConfigData("TOGGLEMODE")
local IGLOICON = GetModConfigData("IGLO_ICON_SIZE")
local MAPICONS_ENABLED = GetModConfigData("MAPICONS_ENABLED")
local IGLO_NUMBERS = GetModConfigData("IGLO_NUMBERS")
local GLOBAL, require, TheWorld, Player = GLOBAL, GLOBAL.require
local BossCalendar = require("screens/bosscalendar")
local Prefabs =
{
	yellowgem = {
		npc = "dragonfly",
		death_anim = true
	},
	hivehat = {
		npc = "beequeen",
		death_anim = true
	},
	shroom_skin = {
		npc = "toadstool",
		death_anim = true
	},
	klaussackkey = {
		npc = "klaus",
		death_anim = true
	},
	blowdart_pipe = {
		npc = "walrus"
	},
	malbatross_beak = {
		npc = "malbatross"
	},
	skeletonhat = {
		npc = "stalker_atrium",
		override = true
	}
}

Assets = {
	Asset("ATLAS", "images/npcs.xml"),
	Asset("ATLAS", "images/"..IGLOICON..".xml"),
}
AddMinimapAtlas("images/"..IGLOICON..".xml")

if MAPICONS_ENABLED then
	AddClassPostConstruct("widgets/mapwidget", function(self)
		BossCalendar:AddMapIcons(self, IGLOICON)
	end)
end

AddPrefabPostInit("walrus_camp", function(inst)
	inst:DoTaskInTime(0, function()
		if inst and inst:IsValid() then
			BossCalendar:AddCamp(inst, inst:GetPosition(), IGLOICON, IGLO_NUMBERS)
		end
	end)
end)

AddSimPostInit(function() BossCalendar:LoadCampPositions() end)

local function GetNpc(inst, prefab)
	local x, y, z = inst.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x, y, z, 15, 0, 0, {"epic", "walrus"})
	return #ents > 0 and ents[1]
end

local function OnRemove(inst)
	BossCalendar:KilledMonster(inst.name, inst)
end

local function ValidateDeath(inst)
	local npc = GetNpc(inst, Prefabs[inst.prefab].npc)
	if not npc then return end
	if Prefabs[inst.prefab].override then
		BossCalendar:KilledMonster("Fuelweaver")
		return
	end
	if Prefabs[inst.prefab].death_anim then 
		if npc.AnimState:IsCurrentAnimation("death") then
			BossCalendar:KilledMonster(npc.name)
		end
		return
	end
	npc:ListenForEvent("onremove", OnRemove)
	Player:DoTaskInTime(10, function() 
		if npc then 
			npc:RemoveEventCallback("onremove", OnRemove) 
		end
	end)
end

for prefab in pairs(Prefabs) do
	AddPrefabPostInit(prefab, function(inst)
		if Player then
			Player:DoTaskInTime(0, function() ValidateDeath(inst) end)
		end
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
	if CanToggle() and BossCalendar:Open() then 
		TheFrontEnd:PushScreen(BossCalendar)
	elseif TOGGLEMODE and CanToggle() then
		BossCalendar:Close()
	end
end

local function Hide()
	if CanToggle() then
		BossCalendar:Close()
	end
end

if OPENKEY then
	if not TOGGLEMODE then
		GLOBAL.TheInput:AddKeyDownHandler(OPENKEY, Display)
		GLOBAL.TheInput:AddKeyUpHandler(OPENKEY, Hide)
	else
		GLOBAL.TheInput:AddKeyUpHandler(OPENKEY, Display)
	end
end

local function ModInit(inst)
	inst:DoTaskInTime(0, function()
		if inst == GLOBAL.ThePlayer then
			Player = GLOBAL.ThePlayer
			BossCalendar:Load(SAYCOLOR, TIME_UNITS, ANNOUNCE_STYLE, ANNOUNCE_UNITS)
		end
	end)
end
AddPlayerPostInit(ModInit)