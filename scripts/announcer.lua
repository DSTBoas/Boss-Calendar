local StatusAnnouncer = Class(function(self)
	self.cooldown = false
	self.cooldowns = {}
end,
nil,
{
})

function StatusAnnouncer:Announce(message)
	if not self.cooldown and not self.cooldowns[message] then
		local whisper = TheInput:IsKeyDown(KEY_CTRL)
		self.cooldown = ThePlayer:DoTaskInTime(3, function() self.cooldown = false end)
		self.cooldowns[message] = ThePlayer:DoTaskInTime(10, function() self.cooldowns[message] = nil end)
		TheNet:Say(STRINGS.LMB .. " " .. message, whisper)
	end
	return true
end

return StatusAnnouncer