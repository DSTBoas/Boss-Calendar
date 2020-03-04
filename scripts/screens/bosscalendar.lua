local Screen = require "widgets/screen"
local Widget = require "widgets/widget"
local Text = require "widgets/text"
local Image = require "widgets/image"
local PersistentData = require("persistentdata")
local PersistentMapIcons = require("widgets/persistentmapicons")
local StatusAnnouncer = require("announcer")()

local DataContainer = PersistentData("BossCalendar")
local WalrusCamps = {}
local Npcs = {"Dragonfly", "Bee Queen", "Toadstool", "Malbatross", "Fuelweaver", "MacTusk", "MacTusk II", "MacTusk III", "MacTusk IV", "Klaus"}
local Session, Sayfn, Reminder_Color, Reminder_Duration, Calendar_TimeInDays, Announce_Style, Announce_TimeInDays
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
	stalker_atrium = TUNING.ATRIUM_GATE_COOLDOWN + TUNING.ATRIUM_GATE_DESTABILIZE_TIME;
	malbatross = 7200;
}

function string:trim()
	return self:gsub("%sI+%a","")
end

local function GetServerTime()
	return (TheWorld.state.cycles + TheWorld.state.time) * TUNING.TOTAL_DAY_TIME
end

function BossCalendar:Say(message, time)
	ThePlayer.components.talker.lineduration = time
	ThePlayer.components.talker:Say(message, time, 0, true, false, Reminder_Color)
	ThePlayer.components.talker.Say = function() end
	ThePlayer:DoTaskInTime(time, function()
		ThePlayer.components.talker.lineduration = 2.5
		ThePlayer.components.talker.Say = Sayfn
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

function BossCalendar:AddCamp(inst, map_icons, iglo_numbering)
	local ceilPos = CeilVector(inst:GetPosition())
	local campExists = Walrus_CampPositionExists(ceilPos)
	if not campExists then 
		table.insert(WalrusCamps, ceilPos)
		campExists = Walrus_CampPositionExists(ceilPos)
		SaveCampPositions()
	end
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


function BossCalendar:Init(reminder_color, reminder_duration, calendar_indays, announce_style, announce_indays)
	Announce_Style = announce_style
	Announce_TimeInDays = announce_indays
	Calendar_TimeInDays = calendar_indays
	Reminder_Color = NameToColor[reminder_color]
	Reminder_Duration = reminder_duration
	Sayfn = ThePlayer.components.talker.Say
	ThePlayer:AddComponent("timer")
	ThePlayer:ListenForEvent("timerdone", OnTimerDone)
	self.mode = "timer"
	self:LoadTimers()
end

local function SecondsToDays(seconds)
	local formattedString = string.format("%.1f", (seconds - GetServerTime()) / TUNING.TOTAL_DAY_TIME)
	local num = tonumber(formattedString)
	if formattedString == "0.0" then
		formattedString = "0.1"
	elseif num % 1 == 0 then
		return tostring(num)
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
					str = SecondsToTime(self.trackers[Npcs[i]][self.mode], false)
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

local function LinkWalrus(npc, inst)
	local igloo_number = GetClosestCamp(inst:GetPosition())

	if igloo_number and igloo_number ~= 1 then
		return GetTableName(igloo_number)
	end

	return npc
end

local function GetRespawnTime(inst)
	local respawn_time = 0
	local name = inst.prefab:upper()
	if RespawnDurations[inst.prefab] then
		respawn_time = RespawnDurations[inst.prefab]
	elseif TUNING[name.."_RESPAWN_TIME"] then
		respawn_time = TUNING[name.."_RESPAWN_TIME"] 
	elseif TUNING[name.."_REGEN_PERIOD"] then
		respawn_time = TUNING[name.."_REGEN_PERIOD"]
	end
	return respawn_time
end

function BossCalendar:AddKill(npc)
	self.trackers[npc]["deaths"] = self.trackers[npc]["deaths"] + 1
end

function BossCalendar:KilledMonster(npc, inst)
	if not self.init then return end

	if npc == "MacTusk" then
		npc = LinkWalrus(npc, inst)
	elseif npc == "Klaus" and WORLD_SPECIAL_EVENT ~= SPECIAL_EVENTS["WINTERS_FEAST"] then
		self:AddKill(npc)
		return
	end

	if not self.trackers[npc]["timer"] then
		local respawn_time = GetRespawnTime(inst)
		if respawn_time > 0 then
			local respawnServerTime = GetServerTime() + respawn_time
			self.trackers[npc]["timer"] = respawnServerTime
			ThePlayer.components.timer:StartTimer(npc, respawn_time)
			self:AddKill(npc)
			self:Save()
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
		local deaths = 0

		if npc == "MacTusk" then
			deaths = self:GetTotalMacTuskKilled()
		else
			deaths = self.trackers[npc]["deaths"]
		end

		if deaths > 1 then
			say = string.format("I killed %s %d times.", npc, deaths)
		elseif deaths == 1 then
			say = string.format("I have killed %s.", npc, deaths)
		else
			say = string.format("I haven't killed %s yet.", npc)
		end
	end
	StatusAnnouncer:Announce(say, npc)
end

function BossCalendar:HideNpcs(sender)
	if sender == self.mode then return end

	if sender then self.mode = self.mode == "timer" and "deaths" or "timer" end

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
		if self.refresh_task then self.refresh_task:Cancel() self.refresh_task = nil end
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

	self.skull = self.root:AddChild(Image("images/skull.xml", "skull.tex"))-- self.skull = self.root:AddChild(Image("images/hud.xml", "tab_arcane.tex"))
	self.skull:SetSize(34, 34)
	self.skull:SetPosition(325, 200)
	self.skull.OnMouseButton = function(image, button, down)
		if button == 1000 and down then
			self:HideNpcs("deaths")
		end
	end

	self.compass = self.root:AddChild(Image("images/inventoryimages1.xml", "compass.tex"))
	self.compass:SetSize(21, 21)
	self.compass:SetPosition(300, 200)
	self.compass.OnMouseButton = function(image, button, down)
		if button == 1000 and down then
			self:HideNpcs("timer")
		end
	end

	for i = 1, #Npcs do
		local x, y = (i - 1) % 5 * 120 - 255, math.floor(i / 6) * -150
		local npc_img = Npcs[i].."img"
		self[Npcs[i]] = self.root:AddChild(Text(UIFONT, 25))
		self[Npcs[i]]:SetPosition(x, y + 140)
		self[Npcs[i]]:SetString(Npcs[i])

		self[npc_img] = self.root:AddChild(Image("images/npcs.xml", Npcs[i]:trim()..".tex"))
		self[npc_img]:SetSize(68, 68)
		self[npc_img]:SetPosition(x, y + 95)
		self[npc_img].OnMouseButton = function(image, button, down) 
			if button == 1000 and down and TheInput:IsControlPressed(CONTROL_FORCE_INSPECT) and StatusAnnouncer:CanAnnounce(Npcs[i]:trim()) then
				self:OnClickNpc(Npcs[i])
			end
		end
	end

	self:HideNpcs()
	self:Update()
	self.refresh_task = ThePlayer:DoPeriodicTask(1, function() self:Update() end)
	
	return true
end

return BossCalendar