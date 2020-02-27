--[[
PersistentData v1.2
By Blueberrys
http://forums.kleientertainment.com/files/file/1150-persistent-data/
]]

local PersistentData = Class(function(self, id)
	self.persistdata = {}
	self.dirty = true
	self.id = id
end)

local function trim(s)
	return s:match'^%s*(.*%S)%s*$' or ''
end

function PersistentData:GetSaveName()
	return BRANCH == "release" and self.id or self.id .. BRANCH
end

function PersistentData:SetValue(key, value)
	self.persistdata[key] = value
	self.dirty = true
end

function PersistentData:GetValue(key)
	return self.persistdata[key]
end

function PersistentData:Save(callback)
	if self.dirty then
		local str = json.encode(self.persistdata)
		local insz, outsz = SavePersistentString(self:GetSaveName(), str, ENCODE_SAVES, callback)
	elseif callback then
		callback(true)
	end
end

function PersistentData:Load(callback)
	TheSim:GetPersistentString(self:GetSaveName(),
		function(load_success, str)
			-- Can optionally ignore the successfulness cause we check the string
			if load_success then
				self:Set(str, callback)
			end
		end, false)
end

function PersistentData:Set(str, callback)
	if str and trim(str) ~= "" then
		self.persistdata = json.decode(str)
		self.dirty = false
	end

	if callback then
		callback(true)
	end
end

return PersistentData
