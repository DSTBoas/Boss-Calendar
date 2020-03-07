local Screen = require "widgets/screen"
local Widget = require "widgets/widget"
local Text = require "widgets/text"
local Image = require "widgets/image"
local PersistentData = require("persistentdata")
local PersistentMapIcons = require("widgets/persistentmapicons")
local StatusAnnouncer = require("announcer")()
local ValidJson = require "validJson"

local DataContainer = PersistentData("BossCalendar")
local WalrusCamps = {}
local Npcs = {"Dragonfly", "Bee Queen", "Toadstool", "Malbatross", "Fuelweaver", "MacTusk", "MacTusk II", "MacTusk III", "MacTusk IV", "Klaus"}
local Session, Sayfn, Reminder_Color, Reminder_Duration, Calendar_TimeInDays, Announce_Style, Announce_TimeInDays, Network_Notifications
local BossCalendar = Class(Screen)

local function RGB(r, g, b)
	return {r / 255, g / 255, b / 255, 1}
end

local NameToColor = {
	White				= RGB(255, 255 ,255),
	Red 				= RGB(255, 0, 0),
	Green				= RGB(0, 255, 0),
	Blue				= RGB(0, 0, 255),
	Yellow				= RGB(255, 255, 0),
	Crimsom				= RGB(220, 20, 60),
	Coral				= RGB(255, 127, 80),
	Orange				= RGB(255, 165, 0),
	Khaki				= RGB(240, 230, 140),
	Chocolate			= RGB(210, 105, 30),
	Brown				= RGB(165, 42, 42),
	["Light Green"]			= RGB(144, 238, 144),
	Cyan				= RGB(0, 255, 255),
	["Light Blue"]			= RGB(173, 216, 230),
	Purple				= RGB(128, 0, 128),
	Pink				= RGB(255, 192, 203)
}

local RespawnDurations = {
	toadstool_dark = TUNING.TOADSTOOL_RESPAWN_TIME,
	stalker_atrium = TUNING.ATRIUM_GATE_COOLDOWN + TUNING.ATRIUM_GATE_DESTABILIZE_TIME,
	malbatross = 7200
}

function string:trim()
	return self:gsub("%sI+%a", "")
end

local function GetServerTime()
	return (TheWorld.state.cycles + TheWorld.state.time) * TUNING.TOTAL_DAY_TIME
end

function BossCalendar:Say(message, time)
	if self.talking then return end
	self.talking = true
	ThePlayer.components.talker.lineduration = time
	ThePlayer.components.talker:Say(message, time, 0, true, false, Reminder_Color)
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
	if npc:trim() == "MacTusk" and not TheWorld.state.iswinter then return end 
	BossCalendar:Say(string.format("%s has just respawned.", npc), Reminder_Duration)
end

function BossCalendar:AddMapIcons(widget, icon)
	widget.camp_icons = widget:AddChild(PersistentMapIcons(widget, 0.85))
	for i = 1, #WalrusCamps do
		widget.camp_icons:AddMapIcon("images/"..icon..".xml", icon.."_"..i..".tex", WalrusCamps[i])
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

local function Walrus_CampPositionExists(pos)
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
	return Walrus_CampPositionExists(pos)
end

function BossCalendar:AddCamp(inst, map_icons, iglo_numbering)
	local ceilVector = CeilVector(inst:GetPosition())
	local campExists = Walrus_CampPositionExists(ceilVector) or InsertCamp(ceilVector)

	if iglo_numbering then
		inst.entity:AddLabel()
		inst.Label:SetFont(CHATFONT_OUTLINE)
		inst.Label:SetFontSize(35)
		inst.Label:SetWorldOffset(0, 5, 0)
		inst.Label:SetText(campExists)
		inst.Label:Enable(true)
	end

	if map_icons then
		inst.MiniMapEntity:SetIcon(string.format("%s_%s.tex", map_icons, campExists))
	end
end

function BossCalendar:Save()
	DataContainer:SetValue(Session.."_data", self.trackers)
	DataContainer:Save()
	self:Update()
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

function BossCalendar:LoadTimers()
	Session = tostring(TheWorld.net.components.shardstate:GetMasterSessionId())
	local SavedData = DataContainer:GetValue(Session.."_data")
	local reminders = {}
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
					table.insert(reminders, Npcs[i])
				end
			end
		end
	else
		for i = 1, #Npcs do
			self.trackers[Npcs[i]] = {
				timer = nil,
				deaths = 0
			}
		end
	end
	if #reminders > 0 then
		ThePlayer:DoTaskInTime(5, function()
			local glue = #reminders == 2 and " & " or ", " 
			self:Say(table.concat(reminders, glue)..(#reminders == 1 and " has" or " have").." respawned.", 5)
			self:Save()
		end)
	end  
	self.init = true
end


function BossCalendar:Init(reminder_color, reminder_duration, calendar_indays, announce_style, announce_indays, network_notifications)
	Announce_Style = announce_style
	Announce_TimeInDays = announce_indays
	Calendar_TimeInDays = calendar_indays
	Reminder_Color = NameToColor[reminder_color]
	Reminder_Duration = reminder_duration
	Network_Notifications = network_notifications
	Sayfn = ThePlayer.components.talker.Say
	ThePlayer:AddComponent("timer")
	ThePlayer:ListenForEvent("timerdone", OnTimerDone)
	self.mode = "timer"
	self.talking = false
	self:LoadTimers()
end

local function SecondsToDays(seconds)
	local formattedString = string.format("%.1f", (seconds - GetServerTime()) / TUNING.TOTAL_DAY_TIME)
	local formattedStringToNum = tonumber(formattedString)
	if formattedString == "0.0" then
		formattedString = "0.1"
	elseif formattedStringToNum % 1 == 0 then
		return tostring(formattedStringToNum)
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

function BossCalendar:GetTotalMacTuskKilled()
	local t = 0
	for i = 1, #Npcs do
		if Npcs[i]:trim() == "MacTusk" then
			t = t + self.trackers[Npcs[i]]["deaths"]
		end
	end
	return t
end

function BossCalendar:Update()
	if not self.open or not self.init then return end
	for i = 1, #Npcs do
		local str = ""
		if self.trackers[Npcs[i]][self.mode] then
			if self.mode == "timer" then
				self[Npcs[i].."img"]:SetTint(0,0,0,1)
				self[Npcs[i]]:SetColour(1,0,0,1)
				if Calendar_TimeInDays then
					str = SecondsToDays(self.trackers[Npcs[i]][self.mode]).."d"
				else
					str = SecondsToTime(self.trackers[Npcs[i]][self.mode])
				end
			else
				self[Npcs[i].."img"]:SetTint(1,1,1,1)
				self[Npcs[i]]:SetColour(1,1,1,1)
				if Npcs[i] == "MacTusk" then
					str = "Killed: "..self:GetTotalMacTuskKilled()
				else
					str = "Killed: "..self.trackers[Npcs[i]][self.mode]
				end
			end
		else
			self[Npcs[i].."img"]:SetTint(1,1,1,1)
			self[Npcs[i]]:SetColour(1,1,1,1)
			if self.mode == "timer" then
				str = Npcs[i]
			else
				str = "Killed: 0"
			end
		end
		self[Npcs[i]]:SetString(str)
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
	local respawnTime = 0
	local name = inst.prefab:upper()
	if RespawnDurations[inst.prefab] then
		respawnTime = RespawnDurations[inst.prefab]
	elseif TUNING[name.."_RESPAWN_TIME"] then
		respawnTime = TUNING[name.."_RESPAWN_TIME"] 
	elseif TUNING[name.."_REGEN_PERIOD"] then
		respawnTime = TUNING[name.."_REGEN_PERIOD"]
	end
	return respawnTime
end

function BossCalendar:AddKill(npc)
	self.trackers[npc]["deaths"] = self.trackers[npc]["deaths"] + 1
end

local BSSC_Data = {}

local function TrimJson(s)
	return s:match"^%s*(.*%S)%s*$" or ""
end

local function DataPack(npc, timer, player, camp)
	BSSC_Data["npc"] = npc
	BSSC_Data["timer"] = timer
	BSSC_Data["player"] = player
	BSSC_Data["camp"] = camp
	return json.encode(BSSC_Data)
end

local function DataUnpack(str)
	if str and TrimJson(str) ~= "" and ValidJson(str) then
		BSSC_Data = json.decode(str)
		return true
	end
	return
end

local function NetworkWalrus(tab)
	if #WalrusCamps == 0 then return end
	local closest_camp = GetClosestCamp(Vector3(tab.x, tab.y, tab.z))
	return GetTableName(closest_camp)
end

local function ShouldNotify(tab)
	local pos = Vector3(tab.x, tab.y, tab.z)
	local playerVector = Vector3(ThePlayer.Transform:GetWorldPosition())
	local dist = pos:Dist(playerVector)
	return dist > 30
end

function BossCalendar:NetworkBossKilled(data)
	if not DataUnpack(data) then return end
	
	local npc = BSSC_Data["npc"]
	
	if npc:trim() == "MacTusk" then
		npc = NetworkWalrus(BSSC_Data["camp"])
		if not npc then return end
	end
	
	if self.trackers[npc] and not self.trackers[npc]["timer"] then
		self.trackers[npc]["timer"] = BSSC_Data["timer"]
		ThePlayer.components.timer:StartTimer(npc, self.trackers[npc]["timer"])
		self:Save()
		
		local whoKilled = BSSC_Data["player"]
		if Network_Notifications and ShouldNotify(BSSC_Data["camp"]) then
			self:Say(string.format("%s has just killed %s.", whoKilled, npc), 3)
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

function BossCalendar:KilledMonster(npc, inst)
	if not self.init then return end

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
			local cmd = "{BSSC}"..DataPack(npc, serverRespawnTime, ThePlayer.name, CeilVector(inst:GetPosition()))
			TheNet:Say(cmd, false, true)
		end
	end
end

local NpcToObject = {
	["Bee Queen"] = "Gigantic Beehive",
	MacTusk = "Walrus Camp",
	Fuelweaver = "Ancient Gateway"
}

local function IsNearby(npc)
	if NpcToObject[npc] then npc = NpcToObject[npc] end
	local x, y, z = ThePlayer.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x, y, z, 30, 0, 
		{"lava", "tree", "FX", "NOCLICK", "DECOR", "INLIMBO", "burnt", "boulder", "structure"}, 
		{"stargate", "epic", "blocker", "antlion_sinkhole_blocker"}
	)
	for i = 1, #ents do
		if ents[i].name == npc then
			if ents[i].prefab == "toadstool_cap" and not ents[i].AnimState:IsCurrentAnimation("mushroom_toad_idle_loop") then return end
			return true
		end
	end
	return
end

function BossCalendar:OnClickNpc(npc)
	local say = ""
	if self.mode == "timer" then
		if self.trackers[npc]["timer"] then
			if Announce_TimeInDays then
				if Announce_Style == 1 then
					local respawnDay = math.floor(self.trackers[npc]["timer"] / TUNING.TOTAL_DAY_TIME)
					respawnDay = respawnDay + 1
					say = string.format("%s respawns on day %d.", npc, respawnDay)
				else
					local respawnDay = SecondsToDays(self.trackers[npc]["timer"])
					local plural = tonumber(respawnDay) > 1 and "days" or "day"
					if Announce_Style == 2 then
						if tonumber(respawnDay) <= 1 then
							say = string.format("%s respawns today.", npc)
						else
							say = string.format("%s respawns in %d %s.", npc, respawnDay, plural)
						end
					else
						say = string.format("%s respawns in %s %s.", npc, respawnDay, plural)
					end
				end
			else
				local respawnDay = SecondsToTime(self.trackers[npc]["timer"], true)
				say = string.format("%s respawns in %s.", npc, respawnDay)
			end
		else
			if IsNearby(npc:trim()) then
				say = string.format("I am at %s.", npc)
			else
				say = string.format("Let's kill %s.", npc)
			end
		end
	else
		local amountOfKills = 0

		if npc == "MacTusk" then
			amountOfKills = self:GetTotalMacTuskKilled()
		else
			amountOfKills = self.trackers[npc]["deaths"]
		end

		if amountOfKills > 1 then
			say = string.format("I killed %s %d times.", npc, amountOfKills)
		elseif amountOfKills == 1 then
			say = string.format("I killed %s.", npc, amountOfKills)
		else
			say = string.format("I haven't killed %s yet.", npc)
		end
	end
	StatusAnnouncer:Announce(say, npc)
end

function BossCalendar:SetMode(mode)
	if mode == self.mode then return end

	if mode then 
		self.mode = mode
	end
	
	if self.mode == "deaths" then
		self.Klaus:SetPosition(-135, -10)
		self.Klausimg:SetPosition(-135, -55)
		self.Klaus:Show()
		self.Klausimg:Show()
		self.compass:SetTint(0, 0, 0, 1)
		self.skull:SetTint(1, 1, 1, 1)
	else
		self.compass:SetTint(1, 1, 1, 1)
		self.skull:SetTint(0, 0, 0, 1)
		self.Klaus:SetPosition(225, -10)
		self.Klausimg:SetPosition(225, -55)
		if WORLD_SPECIAL_EVENT ~= SPECIAL_EVENTS["WINTERS_FEAST"] then
			self.Klausimg:Hide()
			self.Klaus:Hide()
		end
	end

	for i = 7, 9 do
		if self.mode == "deaths" then
			self[Npcs[i].."img"]:Hide()
			self[Npcs[i]]:Hide()
		else
			self[Npcs[i].."img"]:Show()
			self[Npcs[i]]:Show()
		end
	end

	self:Update()
end

function BossCalendar:Close()
	if self.open then
		if self.updateTask then self.updateTask:Cancel() self.updateTask = nil end
		TheFrontEnd:PopScreen(self)
		self.open = false
	end
end

function BossCalendar:Open()
	if self.open or not self.init then return end

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
	self.bg = self.root:AddChild(Image( "images/scoreboard.xml", "scoreboard_frame.tex" ))
	self.bg:SetScale(.96,.9)

	if self.title then self.title:Kill() end
	self.title = self.root:AddChild(Text(UIFONT,45))
	self.title:SetColour(1,1,1,1)
	self.title:SetPosition(0,215)
	self.title:SetString("Boss Calendar")

	self.skull = self.root:AddChild(Image("images/skull.xml", "skull.tex"))
	self.skull:SetSize(34, 34)
	self.skull:SetPosition(325, 200)
	self.skull.OnMouseButton = function(image, button, down)
		if button == 1000 and down then
			self:SetMode("deaths")
		end
	end

	self.compass = self.root:AddChild(Image("images/inventoryimages1.xml", "compass.tex"))
	self.compass:SetSize(21, 21)
	self.compass:SetPosition(300, 200)
	self.compass.OnMouseButton = function(image, button, down)
		if button == 1000 and down then
			self:SetMode("timer")
		end
	end

	for i = 1, #Npcs do
		local x, y = (i - 1) % 5 * 120 - 255, math.floor(i / 6) * -150
		local npcImage = Npcs[i].."img"
		self[Npcs[i]] = self.root:AddChild(Text(UIFONT, 25))
		self[Npcs[i]]:SetPosition(x, y + 140)
		self[Npcs[i]]:SetString(Npcs[i])

		self[npcImage] = self.root:AddChild(Image("images/npcs.xml", Npcs[i]:trim()..".tex"))
		self[npcImage]:SetSize(68, 68)
		self[npcImage]:SetPosition(x, y + 95)
		self[npcImage].OnMouseButton = function(image, button, down) 
			if button == 1000 and down and TheInput:IsControlPressed(CONTROL_FORCE_INSPECT) and StatusAnnouncer:CanAnnounce(Npcs[i]:trim()) then
				self:OnClickNpc(Npcs[i])
			end
		end
	end

	self:SetMode()
	self.updateTask = ThePlayer:DoPeriodicTask(1, function() self:Update() end)
	
	return true
end

return BossCalendar