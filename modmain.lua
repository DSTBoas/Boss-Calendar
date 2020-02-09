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
		Asset("ATLAS", "images/MacTusk.xml"),
		Asset("ATLAS", "images/Toadstool.xml"),
		Asset("ATLAS", "images/Malbatross.xml"),
		Asset("ATLAS", "images/Fuelweaver.xml"),
		Asset("ATLAS", "images/iglo.xml"),
}
AddMinimapAtlas("images/iglo.xml")

local Vector3 = _G.Vector3
local tab = {}
local PersistentMapIcons = require("widgets/persistentmapicons")
local PersistentData = require("persistentdata")
local DataContainer = PersistentData("BossCalendar")

local function SaveCampPositions()
    local s_list = {}
    for i, pos in ipairs(tab) do
        s_list[i] = {x = pos.x, y = pos.y, z = pos.z}
    end
    DataContainer:SetValue(GLOBAL.TheWorld.meta.seed.."_ICONS", s_list)
    DataContainer:Save()
end

local function LoadCampPositions()
    DataContainer:Load()
    local s_list = DataContainer:GetValue(GLOBAL.TheWorld.meta.seed.."_ICONS")
    if s_list then
        for i, pos in ipairs(s_list) do
            tab[i] = Vector3(pos.x, pos.y, pos.z)
        end
    end
end

AddSimPostInit(function()
    LoadCampPositions()
end)

AddClassPostConstruct("widgets/mapwidget", function(self)
    self.campicons = self:AddChild(PersistentMapIcons(self, 0.85))
    for i, pos in ipairs(tab) do
        self.campicons:AddMapIcon("images/iglo.xml", "iglo_".. i ..".tex", pos)
    end
end)

local function findPrefabs(prefab, area)
	local x,y,z = GLOBAL.ThePlayer.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x,y,z, 20)
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
    local ents = TheSim:FindEntities(x,y,z, 20)
    local c = 0
	for _,v in pairs(ents) do
		if (v.prefab == prefab) then
			c = c + 1
		end
	end
	return c
end

function distsq(v1, v2, v3, v4)
    if v4 and v3 and v2 and v1 then
        local dx = v1-v3
        local dy = v2-v4
        return dx*dx + dy*dy
    end
end

local function distFromPlayer(p1, p2)
	local x, z = p1.x, p2.z
	local x1, z1 = p2.x, p2.z
    return distsq(x, z, x1, z1)
end

local function LinkWalrus(pos)
	local closest, closeness
	for k,v in pairs(tab) do
		if closeness == nil or pos:Dist(v) < closeness then
			closest = k
			closeness = pos:Dist(v)
		end
	end
	return closest
end

local function onRemove(inst)
	if inst.prefab == "walrus" then
		local walrus = LinkWalrus(inst:GetPosition())
		if walrus ~= 1 then
			BossCalendar:KilledMonster(inst.name.." "..walrus)
			return
		end
	end
	BossCalendar:KilledMonster(inst.name)
end

local function validateDeath(prefab, bypass)
	if not GLOBAL.ThePlayer then return end
	local npc = findPrefabs(prefab)
	if not npc then return end
	if bypass then BossCalendar:KilledMonster("Fuelweaver") return end
	npc:ListenForEvent("onremove", onRemove)
	GLOBAL.ThePlayer:DoTaskInTime(6, function(inst)
		if npc then
			npc:RemoveEventCallback("onremove", onRemove)
		end
	end)
end

function _G.c_removeallcamps()
    for i in ipairs(tab) do
        tab[i] = nil
    end
end

local function Walrus_CampPositionExists(new_pos)	
    for i, pos in ipairs(tab) do
        if pos:__eq(new_pos) then 
        	return i 
       	end
    end
    return false
end

local function CeilVector(pos)
	pos.x = math.ceil(pos.x)
	pos.y = math.ceil(pos.y)
	pos.z = math.ceil(pos.z)
	return pos
end

local function AddCamp(pos)
	table.insert(tab, CeilVector(pos))
end

local function AddLabel(inst, pos)
	local campExists = Walrus_CampPositionExists(CeilVector(pos))
	if not campExists then
		AddCamp(pos)
		campExists = Walrus_CampPositionExists(CeilVector(pos))
	end
    local label = inst.entity:AddLabel()
    label:SetFont(GLOBAL.CHATFONT_OUTLINE)
    label:SetFontSize(35)
    label:SetWorldOffset(0, 2, 0)
    label:SetText(" " .. campExists .. " ")
    label:Enable(true)
    inst.MiniMapEntity:SetIcon("iglo_" .. campExists .. ".tex")
    inst.tracker_done = true
    SaveCampPositions()

end

AddPrefabPostInit("walrus_camp", function(inst)
	inst:DoTaskInTime(0.2, function() AddLabel(inst, inst:GetPosition()) end)
end)
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
		TheFrontEnd:GetActiveScreen().name then 
		return TheFrontEnd:GetActiveScreen().name == "HUD" or TheFrontEnd:GetActiveScreen().name == "BossCalendar"
	end
	return
end

local function ToggleBossCalendar()
	if CanToggle() then
		if BossCalendar:Open() then 
			TheFrontEnd:PushScreen(BossCalendar) 
		else
			BossCalendar:Close()
		end
	end
end
GLOBAL.TheInput:AddKeyUpHandler(KEY_OPENCALENDAR, ToggleBossCalendar)

local function Init(inst)
	BossCalendar:Load(inst, GLOBAL.TheWorld)
end
AddPlayerPostInit(Init)