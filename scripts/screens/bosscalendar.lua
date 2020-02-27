local Screen = require "widgets/screen"
local Widget = require "widgets/widget"
local Text = require "widgets/text"
local Image = require "widgets/image"
local PersistentData = require("persistentdata")
local PersistentMapIcons = require("widgets/persistentmapicons")
local StatusAnnouncer = require("announcer")()

local DataContainer = PersistentData("BossCalendar")
local SavedTrackersTab, WalrusCamps = {}, {}
local npcs = {"Dragonfly", "Bee Queen", "Toadstool", "Malbatross", "Fuelweaver","MacTusk","MacTusk II","MacTusk III","MacTusk IV"}
local Step, Session, Sayfn, SayColor, TimeInDays, AnnounceStyle, AnnounceTimeInDays = 1/255
local BossCalendar = Class(Screen)

if IsSpecialEventActive(SPECIAL_EVENTS.WINTERS_FEAST) then -- WORLD_SPECIAL_EVENT
	table.insert(npcs, "Klaus")
end

local function RGB(r, g, b)
	return {r * Step, g * Step, b * Step, 1}
end

local NameToColor = {
	White			= RGB(255, 255 ,255),
	Red				= RGB(255, 0, 0),
	Green			= RGB(0, 255, 0),
	Blue			= RGB(0, 0, 255),

	Yellow			= RGB(255, 255, 0),
	Crimsom			= RGB(220, 20, 60),
	Coral			= RGB(255, 127, 80),
	Orange			= RGB(255, 165, 0),
	Khaki			= RGB(240, 230, 140),
	Chocolate		= RGB(210, 105, 30),
	Brown			= RGB(165, 42, 42),
	["Light Green"] = RGB(144, 238, 144),
	Cyan			= RGB(0, 255, 255),
	["Light Blue"]	= RGB(173, 216, 230),
	Purple			= RGB(128, 0, 128),
	Pink			= RGB(255, 192, 203)
}

local RespawnDurations = {
	["MacTusk"] = TUNING.WALRUS_REGEN_PERIOD,
	["Malbatross"] = 7200,
}

local function Trim(s)
	return s:gsub("%sI+%a","")
end

local function GetServerTime()
	return (TheWorld.state.cycles + TheWorld.state.time) * TUNING.TOTAL_DAY_TIME
end

function BossCalendar:Say(message, time)
	ThePlayer.components.talker.lineduration = time
	ThePlayer.components.talker:Say(message, time, 0, true, false, SayColor)
	ThePlayer.components.talker.Say = function() end
	ThePlayer:DoTaskInTime(time, function()
		ThePlayer.components.talker.lineduration = 2.5
		ThePlayer.components.talker.Say = Sayfn
	end)
end

local function OnTimerDone(inst, data)
	local npc = data.name
	BossCalendar.trackers[npc] = nil
	BossCalendar:Save()
	if Trim(npc) == "MacTusk" and not TheWorld.state.iswinter then return end 
	BossCalendar:Say(string.format("%s has just respawned.", npc), 5)
end

function BossCalendar:AddMapIcons(widget, icon)
	widget.camp_icons = widget:AddChild(PersistentMapIcons(widget, 0.85))
	for i, pos in ipairs(WalrusCamps) do
		widget.camp_icons:AddMapIcon("images/"..icon..".xml", icon.."_".. i ..".tex", pos)
	end
end

function BossCalendar:LoadCampPositions()
	DataContainer:Load()
	local s_camps = DataContainer:GetValue(tostring(TheWorld.meta.seed))
	if s_camps then
		for i, pos in ipairs(s_camps) do
			WalrusCamps[i] = Vector3(pos.x, pos.y, pos.z)
		end
	end
end

local function SaveCampPositions()
	local s_camps = {}
	for i, pos in ipairs(WalrusCamps) do
		s_camps[i] = {x = pos.x, y = pos.y, z = pos.z}
	end
	DataContainer:SetValue(tostring(TheWorld.meta.seed), s_camps)
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
	if not campExists then
		InsertCamp(pos)
		campExists = Walrus_CampPositionExists(CeilVector(pos))
		SaveCampPositions()
	end
	if iglonumbers then
		local label = inst.entity:AddLabel()
		label:SetFont(CHATFONT_OUTLINE)
		label:SetFontSize(35)
		label:SetWorldOffset(0, 5, 0)
		label:SetText(" " .. campExists .. " ")
		label:Enable(true)
	end
	if mapicons then
		inst.MiniMapEntity:SetIcon("iglo_" .. campExists .. ".tex")
	end
end

function BossCalendar:Load(color, indays, announce_style, announce_indays)
	AnnounceStyle = announce_style
	AnnounceTimeInDays = announce_indays
	TimeInDays = indays
	Sayfn = ThePlayer.components.talker.Say
	SayColor = NameToColor[color]
	ThePlayer:AddComponent("timer")
	ThePlayer:ListenForEvent("timerdone", OnTimerDone)
	DataContainer:Load()
	Session = tostring(TheWorld.net.components.shardstate:GetMasterSessionId())
	self.trackers = {}
	SavedTrackersTab = DataContainer:GetValue(Session .. "timers") or SavedTrackersTab
	if #SavedTrackersTab > 0 then
		local s = {}
		for k,v in pairs(SavedTrackersTab) do
			if v > 0 then
				local time = v - GetServerTime()
				if time > 0 then
					self.trackers[npcs[k]] = v
					ThePlayer.components.timer:StartTimer(npcs[k], time)
				else
					SavedTrackersTab[k] = 0
					table.insert(s, npcs[k])
				end
			end
		end
		if #s == 0 then return end
		ThePlayer:DoTaskInTime(5, function()
			BossCalendar:Say(table.concat(s,", ") .. (#s == 1 and " has" or " have") .. " respawned.", 5)
			self:Save()
		end)        
	end
end

function BossCalendar:Save()
	for i, npc in pairs(npcs) do
		SavedTrackersTab[i] = self.trackers[npc] or 0
	end
	DataContainer:SetValue(Session .. "timers", SavedTrackersTab)
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

local function SecondsToTime(seconds, announce)
	seconds = seconds - GetServerTime()
	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local str = ""
	if hours > 0 then
		local hours_str = not announce and "h" or hours == 1 and " hour" or " hours"
		str = hours .. hours_str
	end
	if minutes > 0 then
		str = str == "" and str or str .. " "
		local minutes_str = not announce and "m" or minutes == 1 and " minute" or " minutes"
		str = str .. minutes .. minutes_str
	end
	if hours < 1 and minutes < 1 or seconds < 0 then
		return "soon" 
	end
	return str -- return string.format("%02d:%02d", hours, minutes)
end

function BossCalendar:Update()
	if not self.open or not self.trackers then return end
	for i, npc in pairs(npcs) do
		if self.trackers[npc] then
			self[npc.."img"]:SetTint(0,0,0,1)
			self[npc]:SetColour(1,0,0,1)
			local str
			if TimeInDays then
				str = SecondsToDays(self.trackers[npc]) .. "d"
			else
				str = SecondsToTime(self.trackers[npc])
			end
			self[npc]:SetString(str)
		else
			self[npc]:SetColour(1,1,1,1)
			self[npc.."img"]:SetTint(1,1,1,1)
			self[npc]:SetString(npc)
		end
	end
end

local function GetTableName(walrus)
	local c = 1
	for i, npc in pairs(npcs) do
		if Trim(npc) == "MacTusk" then
			if walrus == c then
				return npc
			end
			c = c + 1
		end
	end
	return "MacTusk"
end

local function GetCamp(pos, npc)
	local closest, closeness
	for k,v in pairs(WalrusCamps) do
		if not BossCalendar.trackers[GetTableName(k)] then
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
		return GetTableName(walrus)
	end
	return inst.name
end

function BossCalendar:KilledMonster(npc, inst)
	if npc == "MacTusk" and inst then
		npc = LinkWalrus(npc, inst)
	end
	if self.trackers and not self.trackers[npc] then
		local respawnDuration = RespawnDurations[Trim(npc)] or 9600
		local respawnServerTime = GetServerTime() + respawnDuration
		self.trackers[npc] = respawnServerTime
		ThePlayer.components.timer:StartTimer(npc, respawnDuration)
		self:Save()
	end
end

function BossCalendar:ImageOnClick(npc)
	local say = string.format("Let's kill %s.", npc)
	if self.trackers[npc] then
		if AnnounceTimeInDays then
			if AnnounceStyle == 1 then
				local respawnDay = math.floor(self.trackers[npc] / TUNING.TOTAL_DAY_TIME)
				respawnDay = respawnDay + 1
				say = string.format("%s respawns on day %d.", npc, respawnDay)
			else
				local respawnDay = SecondsToDays(self.trackers[npc])
				local plural = tonumber(respawnDay) > 1 and "days" or "day"
				if AnnounceStyle == 2 then
					if (tonumber(respawnDay) < 1) then
						say = string.format("%s respawns today.", npc)
					else
						say = string.format("%s respawns in %d %s.", npc, respawnDay, plural)
					end
				else
					say = string.format("%s respawns in %s %s.", npc, respawnDay, plural)
				end
			end
		else
			local respawnDay = SecondsToTime(self.trackers[npc], true)
			local glue = respawnDay == "soon" and "" or "in "
			say = string.format("%s respawns %s%s.", npc, glue, respawnDay)
		end
	end
	StatusAnnouncer:Announce(say)
end

function BossCalendar:Close()
	if self.open then
		if self.refresh_task then self.refresh_task:Cancel() self.refresh_task = nil end
		TheFrontEnd:PopScreen(self)
		self.open = false
	end
end

function BossCalendar:Open()
	if self.open or not self.trackers then return end

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

	for i, npc in pairs(npcs) do
		if self[npc] then self[npc]:Kill() end
		self[npc] = self.root:AddChild(Text(UIFONT, 25))
		self[npc]:SetPosition(-255 + ((i-1) % 5 * 120), 140 + (math.floor(i / 6) * -150)) -- 300
		self[npc]:SetString(npc)
		local imgName = npc .. "img"
		if self[imgName] then self[imgName]:Kill() end
		self[imgName] = self.root:AddChild(Image("images/npcs.xml", Trim(npc)..".tex"))
		self[imgName]:SetSize(68,68)
		self[imgName]:SetPosition(-255 + ((i-1) % 5 * 120), 95 + (math.floor(i / 6) * -150)) -- -120
		self[imgName].OnMouseButton = function(image, button) 
			if button == 1000 and TheInput:IsControlPressed(CONTROL_FORCE_INSPECT) then
				self:ImageOnClick(npc)
			end
		end
	end

	self.refresh_task = ThePlayer:DoPeriodicTask(FRAMES * 15, function()
		self:Update()
	end)

	self:Update()
	return true
end

return BossCalendar