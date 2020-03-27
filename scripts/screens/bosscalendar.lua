local Screen = require "widgets/screen"
local Widget = require "widgets/widget"
local Text = require "widgets/text"
local Image = require "widgets/image"
local PersistentData = require("persistentdata")
local PersistentMapIcons = require("widgets/persistentmapicons")
local Announcer = require("bosscalendar_announcer")()
local IsValidJson = require "validJson"

local BossCalendar = Class(Screen)
local DataContainer = PersistentData("BossCalendar")
local WalrusCamps, Settings, NpcImages = {}, {}, {}
local RespawnDurations = 
{
    toadstool_dark = TUNING.TOADSTOOL_RESPAWN_TIME,
    stalker_atrium = TUNING.ATRIUM_GATE_COOLDOWN + TUNING.ATRIUM_GATE_DESTABILIZE_TIME,
    malbatross = 7200
}
local DeathAnimations =
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
local Npcs = 
{   
    "Dragonfly", "Bee Queen", "Toadstool", "Malbatross", 
    "Fuelweaver", "MacTusk", "MacTusk II", "MacTusk III", 
    "MacTusk IV", "Klaus"
}
local Session, Sayfn

---
--- Helper
---

local function GetServerTime()
    return (TheWorld.state.cycles + TheWorld.state.time) * TUNING.TOTAL_DAY_TIME
end

local function SecondsToDays(seconds)
    local formattedString = string.format("%.1f", (seconds - GetServerTime()) / TUNING.TOTAL_DAY_TIME)
    local formattedStringToNum = tonumber(formattedString)

    if formattedString == "0.0" then
        formattedString = "0.1"
    elseif formattedStringToNum % 1 == 0 then
        formattedString = tostring(formattedStringToNum)
    end

    return formattedString
end

local function SecondsToTime(seconds, announce)
    seconds = seconds - GetServerTime()

    local hours = math.floor(seconds / 3600)
    local minutes = math.floor(seconds % 3600 / 60)
    local str = ""

    if hours > 0 then
        local hours_str = not announce and "h" or hours == 1 and " hour" or " hours"
        str = hours..hours_str
    end

    if minutes > 0 then
        str = str == "" and str or str.." "
        local minutes_str = not announce and "m" or minutes == 1 and " minute" or " minutes"
        str = str..minutes..minutes_str
    end

    if hours < 1 and minutes < 1 then
        local seconds_str = not announce and "s" or seconds == 1 and " second" or " seconds"
        return math.ceil(seconds)..seconds_str
    end

    return str
end

function string:trim()
    return self:gsub("%sI+%a", "")
end

---
--- Reminder
---

function BossCalendar:Say(message, time)
    if self.talking then 
        return 
    end
    self.talking = true
    ThePlayer.components.talker.lineduration = time
    ThePlayer.components.talker:Say(message, time, 0, true, false, Settings.REMINDER_COLOR)
    ThePlayer.components.talker.Say = function() end
    ThePlayer:DoTaskInTime(time, function()
        ThePlayer.components.talker.lineduration = 2.5
        ThePlayer.components.talker.Say = Sayfn
        self.talking = false
    end)
end

local function OnTimerDone(inst, data)
    local npc = data.name
    BossCalendar.trackers[npc].timer = nil
    BossCalendar:Save()

    if npc:trim() == "MacTusk" and not TheWorld.state.iswinter then 
        return 
    end 

    BossCalendar:Say(string.format("%s has just respawned.", npc), Settings.REMINDER_DURATION)
end

---
--- Map icons / igloo
---

function BossCalendar:AddMapIcons(widget)
    widget.camp_icons = widget:AddChild(PersistentMapIcons(widget, 0.85))

    for i = 1, #WalrusCamps do
        widget.camp_icons:AddMapIcon(string.format("images/%s.xml", Settings.IGLOO_ICON), string.format("%s%s.tex", Settings.IGLOO_ICON, i), WalrusCamps[i])
    end
end

local function SaveCampPositions()
    local camps = {}

    for i = 1, #WalrusCamps do
        camps[i] = Vector3(WalrusCamps[i].x, WalrusCamps[i].y, WalrusCamps[i].z)
    end

    DataContainer:SetValue("igloos_"..tostring(TheWorld.meta.seed), camps)
    DataContainer:Save()
end

local function CeilVector(pos)
    pos.x = math.ceil(pos.x)
    pos.y = math.ceil(pos.y)
    pos.z = math.ceil(pos.z)
    return pos
end

local function GetCampNumber(pos)
    for i = 1, #WalrusCamps do
        if WalrusCamps[i]:__eq(pos) then
            return i
        end
    end
    return
end

local function InsertCamp(pos)
    table.insert(WalrusCamps, pos)
    SaveCampPositions()
    return GetCampNumber(pos)
end

function BossCalendar:AddCamp(inst)
    if inst and inst:IsValid() then
        local ceilVector = CeilVector(inst:GetPosition())
        local iglooNumber = GetCampNumber(ceilVector) or InsertCamp(ceilVector)

        if Settings.IGLOO_NUMBERS then
            inst.entity:AddLabel()
            inst.Label:SetFont(CHATFONT_OUTLINE)
            inst.Label:SetFontSize(35)
            inst.Label:SetWorldOffset(0, 5, 0)
            inst.Label:SetText(iglooNumber)
            inst.Label:Enable(true)
        end

        if Settings.IGLOO_ICON then
            inst.MiniMapEntity:SetIcon(string.format("%s%s.tex", Settings.IGLOO_ICON, iglooNumber))
        end
    end
end

---
--- Initialisation
---

function BossCalendar:SetSettings(settings)
    local function RGB(r, g, b)
        return {r / 255, g / 255, b / 255, 1}
    end

    local ColorToRGB = 
    {
        White               = RGB(255, 255 ,255),
        Red                 = RGB(255, 0, 0),
        Green               = RGB(0, 255, 0),
        Blue                = RGB(0, 0, 255),
        Yellow              = RGB(255, 255, 0),
        Crimsom             = RGB(220, 20, 60),
        Coral               = RGB(255, 127, 80),
        Orange              = RGB(255, 165, 0),
        Khaki               = RGB(240, 230, 140),
        Chocolate           = RGB(210, 105, 30),
        Brown               = RGB(165, 42, 42),
        ["Light Green"]         = RGB(144, 238, 144),
        Cyan                = RGB(0, 255, 255),
        ["Light Blue"]          = RGB(173, 216, 230),
        Purple              = RGB(128, 0, 128),
        Pink                = RGB(255, 192, 203)
    }

    Settings = settings
    Settings.IGLOO_ICON = "igloo"
    Settings.REMINDER_COLOR = ColorToRGB[Settings.REMINDER_COLOR]
    print(Settings.ANNOUNCE_UNITS and self["Announce"..tostring(Settings.ANNOUNCE_STYLES):gsub("%.", "_")] or self.AnnounceTime)
    Settings.ANNOUNCE_STYLES = Settings.ANNOUNCE_UNITS and self["Announce"..tostring(Settings.ANNOUNCE_STYLES):gsub("%.", "_")] or self.AnnounceTime
end

function BossCalendar:LoadIgloos()
    DataContainer:Load()
    local camps = DataContainer:GetValue(tostring("igloos_"..TheWorld.meta.seed))
    if camps then
        for i = 1, #camps do
            WalrusCamps[i] = Vector3(camps[i].x, camps[i].y, camps[i].z)
        end
    end
end

function BossCalendar:Setup()
    Session = tostring(TheWorld.net.components.shardstate:GetMasterSessionId())
    local SavedData = DataContainer:GetValue(Session.."_data")
    local absenceReminder = {}

    for i = 1, #Npcs do
        NpcImages[i] = Npcs[i].."_img"
    end

    self.trackers = {}
    if SavedData then
        self.trackers = SavedData
        for i = 1, #Npcs do
            if self.trackers[Npcs[i]].timer then 
                local time = self.trackers[Npcs[i]].timer - GetServerTime()
                if time > 0 then
                    ThePlayer.components.timer:StartTimer(Npcs[i], time)
                else
                    self.trackers[Npcs[i]].timer = nil
                    table.insert(absenceReminder, Npcs[i])
                end
            end
        end
    else
        for i = 1, #Npcs do
            self.trackers[Npcs[i]] =
            {
                timer = nil,
                deaths = 0
            }
        end
    end

    if #absenceReminder > 0 then
        ThePlayer:DoTaskInTime(5, function()
            local glue = #absenceReminder == 2 and " & " or ", "
            self:Say(table.concat(absenceReminder, glue)..(#absenceReminder == 1 and " has" or " have").." respawned.", 5)
            self:Save()
        end)
    end

    self.init = true
end

function BossCalendar:Init(inst)
    if inst == ThePlayer then
        Sayfn = ThePlayer.components.talker.Say
        ThePlayer:AddComponent("timer")
        ThePlayer:ListenForEvent("timerdone", OnTimerDone)

        self.mode = "timer"
        self.talking = false
        self:Setup()
    end
end

---
--- Networking 
---

local NetworkData = {}

local function DataPack(npc, timer, player, camp)
    NetworkData["npc"] = npc
    NetworkData["timer"] = timer
    NetworkData["player"] = player
    NetworkData["camp"] = camp
    return json.encode(NetworkData)
end

local function DataUnpack(data)
    if IsValidJson(data) then
        NetworkData = json.decode(data)
        return (NetworkData["npc"] and NetworkData["timer"] and NetworkData["player"] and NetworkData["camp"])
    end
    return
end

local function NetworkWalrus(campPosition)
    if #WalrusCamps == 0 then 
        return 
    end

    local closest_camp = GetClosestCamp(Vector3(campPosition.x, campPosition.y, campPosition.z))

    return GetTableName(closest_camp)
end

local function ShouldNotify(campPosition)
    local pos = Vector3(campPosition.x, campPosition.y, campPosition.z)
    local playerVector = Vector3(ThePlayer.Transform:GetWorldPosition())
    return pos:Dist(playerVector) > 30
end

function BossCalendar:NetworkBossKilled(data)
    if not DataUnpack(data) then 
        return 
    end
    
    local npc = NetworkData["npc"]
    if npc:trim() == "MacTusk" then
        npc = NetworkWalrus(NetworkData["camp"])
        if not npc then 
            return 
        end
    end
    
    if npc and not self.trackers[npc]["timer"] then
        self.trackers[npc]["timer"] = NetworkData["timer"]
        ThePlayer.components.timer:StartTimer(npc, self.trackers[npc]["timer"])
        self:Save()
        
        local doer = NetworkData["player"]
        if Settings.NETWORK_NOTIFICATIONS and ShouldNotify(NetworkData["camp"]) then
            self:Say(string.format("%s has just killed %s.", doer, npc), 3)
        end
    end
end

local _Networking_Say = Networking_Say
Networking_Say = function(guid, userid, name, prefab, message, colour, whisper, isemote, user_vanity)
    if string.sub(message, 1, 6) == "{BSSC}" then
        if userid ~= ThePlayer.userid then
            ThePlayer:DoTaskInTime(.1, function() BossCalendar:NetworkBossKilled(message:sub(7)) end)
        end
    else
        _Networking_Say(guid, userid, name, prefab, message, colour, whisper, isemote, user_vanity)
    end
end

---
--- General
---

local function GetNpc(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 5, 0, 0, {"epic", "walrus"})
    return ents[1]
end

function BossCalendar:ValidateDeath(inst)
    local npc = GetNpc(inst)
    if npc and npc:IsValid() then
        for i = 1, #DeathAnimations[inst.prefab].death_anim do
            if npc.AnimState:IsCurrentAnimation(DeathAnimations[inst.prefab].death_anim[i]) then
                self:KilledMonster(DeathAnimations[inst.prefab].npc, npc)
                return
            end
        end
    end
end

local function GetTableName(walrus)
    local c = 1

    for i = 1, #Npcs do
        if Npcs[i]:trim() == "MacTusk" then
            if walrus == c then
                return Npcs[i]
            end
            c = c + 1
        end
    end

    return "MacTusk"
end

local function GetClosestCamp(pos)
    local closest, closeness

    for i = 1, #WalrusCamps do
        if not BossCalendar.trackers[GetTableName(i)].timer then
            if closeness == nil or pos:Dist(WalrusCamps[i]) < closeness then
                closest = i
                closeness = pos:Dist(WalrusCamps[i])
            end
        end
    end

    return closest
end

local function LinkWalrus(inst)
    local iglooNumber = GetClosestCamp(inst:GetPosition())
    return iglooNumber and GetTableName(iglooNumber) or inst.name
end

local function GetRespawnTime(inst)
    local respawnTime, instName = 0, inst.prefab:upper()

    if RespawnDurations[inst.prefab] then
        respawnTime = RespawnDurations[inst.prefab]
    elseif TUNING[instName.."_RESPAWN_TIME"] then
        respawnTime = TUNING[instName.."_RESPAWN_TIME"] 
    elseif TUNING[instName.."_REGEN_PERIOD"] then
        respawnTime = TUNING[instName.."_REGEN_PERIOD"]
    end

    return respawnTime
end

function BossCalendar:Save()
    DataContainer:SetValue(Session.."_data", self.trackers)
    DataContainer:Save()
    self:Update()
end

function BossCalendar:AddKill(npc)
    self.trackers[npc]["deaths"] = self.trackers[npc]["deaths"] + 1
end

function BossCalendar:KilledMonster(npc, inst)
    if not self.init then 
        return 
    end

    if npc == "MacTusk" then
        npc = LinkWalrus(inst)
    elseif npc == "Klaus" and WORLD_SPECIAL_EVENT ~= SPECIAL_EVENTS["WINTERS_FEAST"] then
        self:AddKill(npc)
        return
    end

    if not self.trackers[npc]["timer"] then
        local respawnTime = GetRespawnTime(inst)

        if respawnTime > 0 then
            local serverRespawnTime = GetServerTime() + respawnTime
            self.trackers[npc]["timer"] = serverRespawnTime
            ThePlayer.components.timer:StartTimer(npc, respawnTime)
            self:AddKill(npc)
            self:Save()

            -- Networking
            local query = "{BSSC}"..DataPack(npc, serverRespawnTime, ThePlayer.name, CeilVector(inst:GetPosition()))
            TheNet:Say(query, false, true)
        end
    end
end

---
--- Announce
---

local NpcToObject = 
{
    ["Bee Queen"] = "Gigantic Beehive",
    MacTusk = "Walrus Camp",
    Fuelweaver = "Ancient Gateway"
}

local function IsNearby(npc)
    if NpcToObject[npc] then 
        npc = NpcToObject[npc]
    end

    local x, y, z = ThePlayer.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 30, 0, 
        {"lava", "tree", "FX", "NOCLICK", "DECOR", "INLIMBO", "burnt", "boulder", "structure"}, 
        {"stargate", "epic", "blocker", "antlion_sinkhole_blocker"}
    )

    for i = 1, #ents do
        if ents[i].name == npc then
            if ents[i].prefab == "toadstool_cap" then 
                return ents[i].AnimState:IsCurrentAnimation("mushroom_toad_idle_loop")
            end
            return true
        end
    end

    return
end

function BossCalendar:OnAnnounce(npc)
    local announcement = ""
    
    if self.mode == "timer" then
        if self.trackers[npc]["timer"] then
            announcement = Settings.ANNOUNCE_STYLES(self, npc)
        else
            announcement = self:AnnounceToKill(npc)
        end
    elseif self.mode == "deaths" then
        announcement = self:AnnounceDeaths(npc)
    end 

    Announcer:Announce(announcement, npc)
end

function BossCalendar:AnnounceToKill(npc)
    return  
        IsNearby(npc:trim()) and string.format("I am at %s.", npc) or
        string.format("Let's kill %s.", npc)
end

function BossCalendar:GetTotalMacTuskKilled()
    local t = 0

    for i = 1, #Npcs do
        if Npcs[i]:trim() == "MacTusk" then
            t = t + self.trackers[Npcs[i]]["deaths"]
        end
    end

    return t
end

function BossCalendar:AnnounceDeaths(npc)
    local amountOfKills = npc == "MacTusk" and self:GetTotalMacTuskKilled() or self.trackers[npc]["deaths"]
    return      
        amountOfKills > 1 and string.format("I killed %s %d times.", npc, amountOfKills) or
        amountOfKills == 1 and string.format("I killed %s.", npc, amountOfKills) or
        string.format("I haven't killed %s yet.", npc)
end

function BossCalendar:AnnounceTime(npc)
    local respawnDay = SecondsToTime(self.trackers[npc]["timer"], true)
    return string.format("%s respawns in %s.", npc, respawnDay)
end

function BossCalendar:Announce1(npc)
    local respawnDay = math.floor(self.trackers[npc]["timer"] / TUNING.TOTAL_DAY_TIME)
    respawnDay = respawnDay + 1
    return string.format("%s respawns on day %d.", npc, respawnDay)
end

function BossCalendar:Announce2(npc)
    local respawnDay = SecondsToDays(self.trackers[npc]["timer"])
    local plural = tonumber(respawnDay) > 1 and "days" or "day"
    return
        tonumber(respawnDay) <= 1 and string.format("%s respawns today.", npc) or 
        string.format("%s respawns in %d %s.", npc, respawnDay, plural)
end

function BossCalendar:Announce2_5(npc)
    local respawnDay = SecondsToDays(self.trackers[npc]["timer"])
    respawnDay = respawnDay..(tonumber(respawnDay) > 1 and " days" or " day")
    return string.format("%s respawns in %s.", npc, respawnDay)
end

---
--- GUI
---

function BossCalendar:Get_timer(npc, img)
    local str = ""
    if self.trackers[npc][self.mode] then
        self[img]:SetTint(0,0,0,1)
        self[npc]:SetColour(1,0,0,1)
        str =   Settings.CALENDAR_UNITS and SecondsToDays(self.trackers[npc][self.mode]).."d" or
                SecondsToTime(self.trackers[npc][self.mode])
    else
        self[img]:SetTint(1,1,1,1)
        self[npc]:SetColour(1,1,1,1)
        str = npc
    end
    return str
end

function BossCalendar:Get_deaths(npc, img)
    self[img]:SetTint(1,1,1,1)
    self[npc]:SetColour(1,1,1,1)
    local amountOfKills = npc == "MacTusk" and self:GetTotalMacTuskKilled() or self.trackers[npc][self.mode]
    return string.format("Killed: %d", amountOfKills)
end

function BossCalendar:Update()
    if not self.open or not self.init then 
        return 
    end

    for i = 1, #Npcs do
        self[Npcs[i]]:SetString(self:GetGuiString(Npcs[i], NpcImages[i]))
    end
end

function BossCalendar:SetMode(mode)
    self.mode = mode
    self.GetGuiString = self["Get_"..self.mode]

    if self.mode == "deaths" then
        self.Klaus:SetPosition(-135, -10)
        self.Klaus_img:SetPosition(-135, -55)
        self.Klaus:Show()
        self.Klaus_img:Show()
        self.compass:SetTint(0, 0, 0, 1)
        self.skull:SetTint(1, 1, 1, 1)
    else
        self.compass:SetTint(1, 1, 1, 1)
        self.skull:SetTint(0, 0, 0, 1)
        self.Klaus:SetPosition(225, -10)
        self.Klaus_img:SetPosition(225, -55)
        if WORLD_SPECIAL_EVENT ~= SPECIAL_EVENTS["WINTERS_FEAST"] then
            self.Klaus_img:Hide()
            self.Klaus:Hide()
        end
    end

    for i = 7, 9 do
        if self.mode == "deaths" then
            self[NpcImages[i]]:Hide()
            self[Npcs[i]]:Hide()
        else
            self[NpcImages[i]]:Show()
            self[Npcs[i]]:Show()
        end
    end

    self:Update()
end

function BossCalendar:Close()
    if self.open then

        if self.updateTask then 
            self.updateTask:Cancel()
            self.updateTask = nil 
        end

        TheFrontEnd:PopScreen(self)
        self.open = false
    end
end

function BossCalendar:Open()
    if self.open or not self.init then 
        return 
    end

    Screen._ctor(self, "Boss Calendar")
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
    self.bg = self.root:AddChild(Image( "images/scoreboard.xml", "scoreboard_frame.tex"))
    self.bg:SetScale(.96,.9)

    if self.title then self.title:Kill() end
    self.title = self.root:AddChild(Text(UIFONT,45))
    self.title:SetColour(1,1,1,1)
    self.title:SetPosition(0,215)
    self.title:SetString("Boss Calendar")

    self.skull = self.root:AddChild(Image("images/skull.xml", "skull.tex"))
    self.skull:SetSize(34, 34)
    self.skull:SetPosition(325, 200)
    self.skull.OnMouseButton = function(_, button, down)
        if button == 1000 and down then
            self:SetMode("deaths")
        end
    end

    self.compass = self.root:AddChild(Image("images/inventoryimages1.xml", "compass.tex"))
    self.compass:SetSize(21, 21)
    self.compass:SetPosition(300, 200)
    self.compass.OnMouseButton = function(_, button, down)
        if button == 1000 and down then
            self:SetMode("timer")
        end
    end

    for i = 1, #Npcs do
        local x, y = (i - 1) % 5 * 120 - 255, math.floor(i / 6) * -150
        local npc, img = Npcs[i], NpcImages[i]
        self[npc] = self.root:AddChild(Text(UIFONT, 25))
        self[npc]:SetPosition(x, y + 140)
        self[npc]:SetString(npc)
        self[img] = self.root:AddChild(Image("images/npcs.xml", npc:trim()..".tex"))
        self[img]:SetSize(68, 68)
        self[img]:SetPosition(x, y + 95)
        self[img].OnMouseButton = function(_, button, down) 
            if button == 1000 and down and TheInput:IsControlPressed(CONTROL_FORCE_INSPECT) and Announcer:CanAnnounce(npc:trim()) then
                self:OnAnnounce(npc)
            end
        end
    end

    self:SetMode(self.mode)
    self.updateTask = ThePlayer:DoPeriodicTask(1, self.Update)
    
    return true
end

return BossCalendar
