local Screen = require "widgets/screen"
local Widget = require "widgets/widget"
local Text = require "widgets/text"
local Image = require "widgets/image"
local Menu = require "widgets/menu"
local PersistentData = require("persistentdata")
local StatusAnnouncer = require("announcer")()

local DataContainer = PersistentData("BossCalendar")
local SavedTrackersTab = {}
local npcs = {"Dragonfly", "Bee Queen", "Mac Tusk", "Toadstool", "Malbatross", "Fuelweaver"}
local announce_message = "BossCalendar!"
local TheWorld
local Seed

local RespawnDurations = {
    ["Mac Tusk"] = TUNING.WALRUS_REGEN_PERIOD,
    ["Malbatross"] = 7200,
}

local BossCalendar = Class(Screen, function(self)
    Screen._ctor(self, "BossCalendar")
end)

local function GetServerTime()
    return (TheWorld.state.cycles + TheWorld.state.time) * TUNING.TOTAL_DAY_TIME
end

local function OnTimerDone(inst, data)
    local npc = data.name
    BossCalendar.trackers[npc] = nil
    BossCalendar:Save()
    _G.ThePlayer.components.talker:Say( string.format(announce_message .. " %s has just respawned.", npc) )
end

function BossCalendar:Load(inst, world)
    inst:AddComponent("timer")
    inst:ListenForEvent("timerdone", OnTimerDone)
    TheWorld = world
	Seed = TheWorld:HasTag("cave") and tostring(TheWorld.meta.seed + 1) or tostring(TheWorld.meta.seed)
    DataContainer:Load()
    self.trackers = {}
    SavedTrackersTab = DataContainer:GetValue(Seed) or {}
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
    DataContainer:SetValue(Seed, SavedTrackersTab)
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
			self[npc]:SetColour(0,1,0,1)
            self[npc.."img"]:SetTint(1,1,1,1)
            self[npc]:SetString(npc)
		end
	end
end

local translate =
{
    ["beequeen"] = "Bee Queen",
    ["walrus"] = "Mac Tusk",
}

function BossCalendar:KilledNpc(npc)
    if translate[npc] then
        self:KilledMonster(translate[npc])
        return
    end
    for k, v in pairs(npcs) do
        if (v:lower() == npc) then
            self:KilledMonster(v)
            break
        end
    end
end

function BossCalendar:KilledMonster(npc)
    if self.trackers and not self.trackers[npc] then
        local respawnDuration = RespawnDurations[npc] or 9600
        local respawnServerTime = GetServerTime() + respawnDuration
        self.trackers[npc] = respawnServerTime
        _G.ThePlayer.components.timer:StartTimer(npc, respawnDuration)
        self:Save()
    end
end

function BossCalendar:Image_ClickHandle(npc)
    local say = string.format("Wanna kill %s?", npc)
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
		self[npc] = self.root:AddChild(Text(NEWFONT, 25))
		self[npc]:SetPosition(-300 + ((i-1) % 6 * 120), 140 + (math.floor(i / 7) * -120))
		self[npc]:SetString(npc)
		local imgName = npc.."img"
		if self[imgName] then self[imgName]:Kill() end
		self[imgName] = self.root:AddChild(Image("images/"..npc..".xml", npc..".tex"))
		self[imgName]:SetPosition(-300 + ((i-1) % 6 * 120), 95 + (math.floor(i / 7) * -120))

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