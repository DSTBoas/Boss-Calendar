local OPENKEY = GetModConfigData("OPENKEY")
local TOGGLEMODE = GetModConfigData("TOGGLEMODE")
local IGLOICON = GetModConfigData("IGLO_ICON_SIZE")
local MAPICONS_ENABLED = GetModConfigData("MAPICONS_ENABLED")
local IGLO_NUMBERS = GetModConfigData("IGLO_NUMBERS")
local require = GLOBAL.require
local BossCalendar = require("screens/bosscalendar")
local TheWorld, Player
_G = GLOBAL

Assets = {
	Asset("ATLAS", "images/npcs.xml"),
	Asset("ATLAS", "images/"..IGLOICON..".xml"),
}

if MAPICONS_ENABLED then
	AddMinimapAtlas("images/"..IGLOICON..".xml")
	AddClassPostConstruct("widgets/mapwidget", function(self)
		BossCalendar:AddMapIcons(self, IGLOICON)
	end)
end

AddSimPostInit(function()
	TheWorld = GLOBAL.TheWorld
    BossCalendar:LoadCampPositions()
end)

local function FindNpc(prefab)
	local x,y,z = Player.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x,y,z, 20)
	for _,v in pairs(ents) do
		if v.prefab == prefab then
			return v
		end
	end
	return
end

local function OnRemove(inst)
	BossCalendar:KilledMonster(inst.name, inst)
end

local CanConfirm = {toadstool = true, dragonfly = true, beequeen = true}

local function ValidateDeath(prefab, bypass)
	if Player then
		local npc = FindNpc(prefab)
		if not npc then return end
		if bypass then BossCalendar:KilledMonster("Fuelweaver") return end
		if CanConfirm[prefab] and npc.AnimState:IsCurrentAnimation("death") then
			BossCalendar:KilledMonster(npc.name)
			return
		elseif CanConfirm[prefab] then
			return
		end
		npc:ListenForEvent("onremove", OnRemove)
		Player:DoTaskInTime(10, function()
			if npc then
				npc:RemoveEventCallback("onremove", OnRemove)
			end
		end)
	end
end

AddPrefabPostInit("walrus_camp", function(inst)
	inst:DoTaskInTime(.3, function()
		if inst:IsValid() then
			BossCalendar:AddCamp(inst, inst:GetPosition(), MAPICONS_ENABLED, IGLO_NUMBERS)
		end
	end)
end)
AddPrefabPostInit("yellowgem", function(inst)
	if TheWorld and not TheWorld:HasTag("cave") then
		ValidateDeath("dragonfly")
	end
end)
AddPrefabPostInit("hivehat", function()
	ValidateDeath("beequeen")
end)
AddPrefabPostInit("klaussackkey", function()
	ValidateDeath("klaus") 
end)
AddPrefabPostInit("blowdart_pipe", function()
	ValidateDeath("walrus")
end)
AddPrefabPostInit("shroom_skin", function() 
	if TheWorld and TheWorld:HasTag("cave") then 
		ValidateDeath("toadstool")
	end
end)
AddPrefabPostInit("malbatross_beak", function()
	ValidateDeath("malbatross")
end)
AddPrefabPostInit("deerclops_eyeball", function()
	ValidateDeath("deerclops")
end)
AddPrefabPostInit("skeletonhat", function() 
	if TheWorld and TheWorld:HasTag("cave") then
		ValidateDeath("atrium_gate", true)
	end
end)

local function CanToggle()
	if  TheFrontEnd and 
		TheFrontEnd:GetActiveScreen() and 
		TheFrontEnd:GetActiveScreen().name then 
		return TheFrontEnd:GetActiveScreen().name == "HUD" or TheFrontEnd:GetActiveScreen().name == "BossCalendar"
	end
	return
end

local function Display()
	if CanToggle() and BossCalendar:Open() then 
		TheFrontEnd:PushScreen(BossCalendar)
	elseif TOGGLEMODE and CanToggle()  then
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
		GLOBAL.TheInput:AddKeyUpHandler(OPENKEY, Hide)
	end
	GLOBAL.TheInput:AddKeyDownHandler(OPENKEY, Display)
end

local function ModInit(inst)
	inst:DoTaskInTime(0, function()
		if inst == GLOBAL.ThePlayer then
			Player = GLOBAL.ThePlayer
			BossCalendar:Load(Player)
		end
	end)
end
AddPlayerPostInit(ModInit)