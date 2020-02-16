local Screen = require "widgets/screen"
local Widget = require "widgets/widget"
local Text = require "widgets/text"
local Image = require "widgets/image"
local PersistentData = require("persistentdata")
local PersistentMapIcons = require("widgets/persistentmapicons")
local StatusAnnouncer = require("announcer")()
local Vector3 = _G.Vector3
local DataContainer = PersistentData("BossCalendar")
local SavedTrackersTab = {}
local npcs = {"Dragonfly", "Bee Queen", "Toadstool", "Malbatross", "Fuelweaver","MacTusk","MacTusk 2","MacTusk 3","MacTusk 4"}
local announce_message = "BossCalendar:"
local Session

if IsSpecialEventActive(SPECIAL_EVENTS.WINTERS_FEAST) then --WORLD_SPECIAL_EVENT
    table.insert(npcs, "Klaus")
end

local RespawnDurations = {
    ["MacTusk"] = TUNING.WALRUS_REGEN_PERIOD,
    ["Malbatross"] = 7200,
}

local BossCalendar = Class(Screen, function(self)
    Screen._ctor(self, "BossCalendar")
end)

local function Trim(s)
    return s:gsub("%s%d","")
end

local function GetServerTime()
    return (_G.TheWorld.state.cycles + _G.TheWorld.state.time) * TUNING.TOTAL_DAY_TIME
end

local function OnTimerDone(inst, data)
    local npc = data.name
    BossCalendar.trackers[npc] = nil
    BossCalendar:Save()
    if Trim(npc) == "MacTusk" and not _G.TheWorld.state.iswinter then return end 
     _G.ThePlayer.components.talker:Say( string.format(announce_message .. " %s has just respawned.", npc) )
end

local WalrusCamps = {}

function BossCalendar:AddMapIcons(widget, icon)
    widget.campicons = widget:AddChild(PersistentMapIcons(widget, 0.85))
    for i, pos in ipairs(WalrusCamps) do
        widget.campicons:AddMapIcon("images/"..icon..".xml", icon.."_".. i ..".tex", pos)
    end
end

function BossCalendar:LoadCampPositions()
    DataContainer:Load()
    local s_list = DataContainer:GetValue(tostring(_G.TheWorld.meta.seed))
    if s_list then
        for i, pos in ipairs(s_list) do
            WalrusCamps[i] = Vector3(pos.x, pos.y, pos.z)
        end
    end
end

local function SaveCampPositions()
    local s_list = {}
    for i, pos in ipairs(WalrusCamps) do
        s_list[i] = {x = pos.x, y = pos.y, z = pos.z}
    end
    DataContainer:SetValue(tostring(_G.TheWorld.meta.seed), s_list)
    DataContainer:Save()
end

local function CeilVector(pos)
    pos.x = math.ceil(pos.x)
    pos.y = math.ceil(pos.y)
    pos.z = math.ceil(pos.z)
    return pos
end

local function Walrus_CampPositionExists(new_pos)   
    for i, pos in ipairs(WalrusCamps) do
        if pos:__eq(new_pos) then 
            return i 
        end
    end
    return
end

local function InsertCamp(pos)
    table.insert(WalrusCamps, CeilVector(pos))
end

function BossCalendar:AddCamp(inst, pos, mapicons, iglonumbers)
    local campExists = Walrus_CampPositionExists(CeilVector(pos))
    local save = false
    if not campExists then
        InsertCamp(pos)
        campExists = Walrus_CampPositionExists(CeilVector(pos))
        save = true
    end
    if iglonumbers then
        local label = inst.entity:AddLabel()
        label:SetFont(_G.CHATFONT_OUTLINE)
        label:SetFontSize(35)
        label:SetWorldOffset(0, 5, 0)
        label:SetText(" " .. campExists .. " ")
        label:Enable(true)
    end
    if mapicons then
        inst.MiniMapEntity:SetIcon("iglo_" .. campExists .. ".tex")
    end
    if save then
        SaveCampPositions()
    end
end

function BossCalendar:Load(inst)
    inst:AddComponent("timer")
    inst:ListenForEvent("timerdone", OnTimerDone)
    DataContainer:Load()
    Session = tostring(TheWorld.net.components.shardstate:GetMasterSessionId())
    self.trackers = {}
    SavedTrackersTab = DataContainer:GetValue(Session.."timers") or {}
    if #SavedTrackersTab > 0 then
        local s = {}
        for k,v in pairs(SavedTrackersTab) do
            if v > 0 then
                local time = v - GetServerTime()
                if time > 0 then
                    self.trackers[npcs[k]] = v
                    inst.components.timer:StartTimer(npcs[k], time)
                else
                    SavedTrackersTab[k] = 0
                    table.insert(s, npcs[k])
                end
            end
        end
        if #s == 0 then return end
        inst:DoTaskInTime(5, function()
            inst.components.talker:Say(announce_message .. " " .. table.concat(s,", ") .. (#s == 1 and " has" or " have") .. " respawned.")
            self:Save()
        end)        
    end
end

function BossCalendar:Save()
    for i, npc in pairs(npcs) do
        SavedTrackersTab[i] = self.trackers[npc] or 0
    end
    DataContainer:SetValue(Session.."timers", SavedTrackersTab)
    DataContainer:Save()
    self:Update()
end

local function SecondsToDays(seconds)
    local formattedString = string.format("%.1f", ( (seconds - GetServerTime()) / TUNING.TOTAL_DAY_TIME ) )
    local tonumberString = tonumber(formattedString)
    if formattedString == "0.0" then
        formattedString = "0.1"
    elseif tonumberString % 1 == 0 then
        return tostring(tonumberString)
    end
    return formattedString
end

function BossCalendar:Update()
	if not self.open or not self.trackers then return end
	for i, npc in pairs(npcs) do
		if self.trackers[npc] then
            self[npc.."img"]:SetTint(0,0,0,1)
			self[npc]:SetColour(1,0,0,1)
            self[npc]:SetString(SecondsToDays(self.trackers[npc]) .. "d")
		else
			self[npc]:SetColour(1,1,1,1)
            self[npc.."img"]:SetTint(1,1,1,1)
            self[npc]:SetString(npc)
		end
	end
end

local function GetCamp(pos, npc)
    local closest, closeness
    for k,v in pairs(WalrusCamps) do
    	if k == 1 and not BossCalendar.trackers[npc] or k ~= 1 and not BossCalendar.trackers[npc .. " " .. k] then
	        if closeness == nil or pos:Dist(v) < closeness then
	            closest = k
	            closeness = pos:Dist(v)
	        end
	    end
    end
    return closest
end

local function LinkWalrus(npc, inst)
    if not inst then return npc end
    local walrus = GetCamp(inst:GetPosition(), npc)
    if walrus and walrus ~= 1 then
        return inst.name.." "..walrus
    end
    return inst.name
end

function BossCalendar:KilledMonster(npc, inst)
    if npc == "MacTusk" then
        npc = LinkWalrus(npc, inst)
    end
    if self.trackers and not self.trackers[npc] then
        local respawnDuration = RespawnDurations[Trim(npc)] or 9600
        local respawnServerTime = GetServerTime() + respawnDuration
        self.trackers[npc] = respawnServerTime
        _G.ThePlayer.components.timer:StartTimer(npc, respawnDuration)
        self:Save()
    end
end

function BossCalendar:Image_ClickHandle(npc)
    local say = string.format("Let's kill %s?", npc)
    if self.trackers[npc] then
        local respawnDay = math.floor(self.trackers[npc] / TUNING.TOTAL_DAY_TIME)
        respawnDay = respawnDay + 1
        say = string.format("%s respawns on day %d.", npc, respawnDay)
    end
    StatusAnnouncer:Announce(say)
end

function BossCalendar:Close()
	if self.open then
	    if self.refresh_task then self.refresh_task:Cancel() self.refresh_task = nil end
	    TheFrontEnd:PopScreen()
	    self.open = false
	end
end

function BossCalendar:Open()
	if self.open or not self.trackers then return end

 	Screen._ctor(self, "BossCalendar")
 	self.open = true

	if self.black then self.black:Kill() end
    self.black = self:AddChild(Image("images/global.xml", "square.tex"))
    self.black:SetSize(RESOLUTION_X + 4, RESOLUTION_Y + 4)
    self.black:SetVRegPoint(ANCHOR_MIDDLE)
    self.black:SetHRegPoint(ANCHOR_MIDDLE)
    self.black:SetVAnchor(ANCHOR_MIDDLE)
    self.black:SetHAnchor(ANCHOR_MIDDLE)
    self.black:SetScaleMode(SCALEMODE_FIXEDPROPORTIONAL)
    self.black:SetTint(0,0,0,0)

    if self.root then self.root:Kill() end
    self.root = self:AddChild(Widget("ROOT"))
    self.root:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self.root:SetHAnchor(ANCHOR_MIDDLE)
    self.root:SetVAnchor(ANCHOR_MIDDLE)

    if self.bg then self.bg:Kill() end
    self.bg = self.root:AddChild(Image( "images/scoreboard.xml", "scoreboard_frame.tex" ))
    self.bg:SetScale(.96,.9)

    if self.title then self.title:Kill() end
    self.title = self.root:AddChild(Text(UIFONT,45))
    self.title:SetColour(1,1,1,1)
    self.title:SetPosition(0,215)
    self.title:SetString("Boss Calendar")

    for i, npc in pairs(npcs) do
		if self[npc] then self[npc]:Kill() end
		self[npc] = self.root:AddChild(Text(UIFONT, 25))
		self[npc]:SetPosition(-255 + ((i-1) % 5 * 120), 140 + (math.floor(i / 6) * -150)) --300
		self[npc]:SetString(npc)
		local imgName = npc.."img"
		if self[imgName] then self[imgName]:Kill() end
		self[imgName] = self.root:AddChild(Image("images/npcs.xml", Trim(npc)..".tex"))
        self[imgName]:SetSize(68,68)
		self[imgName]:SetPosition(-255 + ((i-1) % 5 * 120), 95 + (math.floor(i / 6) * -150)) -- -120
		self[imgName].OnMouseButton = function(button, down, ...) 
            if _G.TheInput:IsControlPressed(_G.CONTROL_FORCE_INSPECT) then
                self:Image_ClickHandle(npc)
            end
        end
    end

    self.refresh_task = _G.ThePlayer:DoPeriodicTask(FRAMES * 15, function()
        self:Update()
    end)

    self:Update()
    return true
end

return BossCalendar