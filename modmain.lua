local DST = GLOBAL.TheSim:GetGameID() == "DST"
if not DST then return end
if DST and GLOBAL.TheNet:IsDedicated() then return end
local require = GLOBAL.require
local BossCalendar = require"screens/bosscalendar"
_G = GLOBAL
local KEY_OPENCALENDAR = GetModConfigData("OPEN_CALENDAR")
if type(KEY_OPENCALENDAR) == "string" then KEY_OPENCALENDAR = KEY_OPENCALENDAR:lower():byte() end

Assets = {
		Asset("ATLAS", "images/Dragonfly.xml"),
		Asset("ATLAS", "images/Bee Queen.xml"),
		--Asset("ATLAS", "images/Klaus.xml"),
		Asset("ATLAS", "images/Mac Tusk.xml"),
		Asset("ATLAS", "images/Toadstool.xml"),
		Asset("ATLAS", "images/Malbatross.xml"),
		Asset("ATLAS", "images/Fuelweaver.xml"),
		Asset("ATLAS", "images/PlaceHolder.xml"),
}

local function findPrefabs(prefab)
	local x,y,z = GLOBAL.ThePlayer.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x,y,z, 10)
	for _,v in pairs(ents) do
		if (v.prefab == prefab) then
			return v
		end
	end
	return nil
end

local function countPrefabs(prefab)
	if not GLOBAL.ThePlayer then return end
	local x,y,z = GLOBAL.ThePlayer.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x,y,z, 10)
    local c = 0
	for _,v in pairs(ents) do
		if (v.prefab == prefab) then
			c = c + 1
		end
	end
	return c
end

local function onRemove(inst)
	BossCalendar:KilledNpc(inst.prefab)
end

local function validateDeath(prefab, bypass)
	if not GLOBAL.ThePlayer then return end
	local npc = findPrefabs(prefab)
	if not npc then return end
	if bypass then BossCalendar:KilledNpc("fuelweaver") return end
	npc:ListenForEvent("onremove", onRemove)
	GLOBAL.ThePlayer:DoTaskInTime(6, function(inst)
		if npc then
			npc:RemoveEventCallback("onremove", onRemove)
		end
	end)
end

AddPrefabPostInit("yellowgem", function(inst)
	if GLOBAL.TheWorld:HasTag("cave") then return end
	inst:DoTaskInTime(1/30, function(inst)
		if countPrefabs("dragon_scales") > 0 then validateDeath("dragonfly") end
	end)
end)
AddPrefabPostInit("hivehat", function() validateDeath("beequeen") end)
AddPrefabPostInit("klaussackkey", function() validateDeath("klaus") end)
AddPrefabPostInit("blowdart_pipe", function() validateDeath("walrus") end)
AddPrefabPostInit("shroom_skin", function() if not GLOBAL.TheWorld:HasTag("cave") then return end validateDeath("toadstool") end)
AddPrefabPostInit("malbatross_beak", function() validateDeath("malbatross") end)
AddPrefabPostInit("deerclops_eyeball", function() validateDeath("deerclops") end)
AddPrefabPostInit("skeletonhat", function() if not GLOBAL.TheWorld:HasTag("cave") then return end validateDeath("atrium_gate", true) end)

local function CanToggle()
	if  TheFrontEnd and 
		TheFrontEnd:GetActiveScreen() and 
		TheFrontEnd:GetActiveScreen().name and 
		type(TheFrontEnd:GetActiveScreen().name) == "string" then 
		return TheFrontEnd:GetActiveScreen().name == "HUD" or TheFrontEnd:GetActiveScreen().name == "BossCalendar"
	end
	return
end

local function ToggleBossCalendar()
	if not CanToggle() then return end
	if BossCalendar:Open() then 
		TheFrontEnd:PushScreen(BossCalendar) 
	else
		BossCalendar:Close()
	end
end
GLOBAL.TheInput:AddKeyUpHandler(KEY_OPENCALENDAR, ToggleBossCalendar)

local function Init(inst)
	BossCalendar:Load(inst, GLOBAL.TheWorld)
end
AddPlayerPostInit(Init)