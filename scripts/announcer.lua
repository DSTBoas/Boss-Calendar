local StatusAnnouncer = Class(function(self)
	self.cooldown = false
	self.cooldowns = {}
end,
nil,
{
})

function StatusAnnouncer:CanAnnounce(npc)
	return not self.cooldown and not self.cooldowns[npc]
end

function StatusAnnouncer:Announce(message, npc)
	if not self.cooldown and not self.cooldowns[npc] then
		local whisper = TheInput:IsKeyDown(KEY_CTRL)
		self.cooldown = ThePlayer:DoTaskInTime(3, function() self.cooldown = false end)
		self.cooldowns[npc] = ThePlayer:DoTaskInTime(10, function() self.cooldowns[npc] = nil end)
		TheNet:Say(STRINGS.LMB .. " " .. message, whisper)
	end
	return true
end

return StatusAnnouncer