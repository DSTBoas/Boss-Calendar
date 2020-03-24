local Announcer = Class(function(self)
	self.cooldown = false
	self.cooldowns = {}
end)

function Announcer:CanAnnounce(npc)
	return not self.cooldown and not self.cooldowns[npc]
end

function Announcer:Announce(message, npc)
	if not self.cooldown and not self.cooldowns[npc] then

		self.cooldown = ThePlayer:DoTaskInTime(3, function() 
			self.cooldown = false 
		end)

		self.cooldowns[npc] = ThePlayer:DoTaskInTime(10, function() 
			self.cooldowns[npc] = nil 
		end)

		TheNet:Say(STRINGS.LMB .. " " .. message, TheInput:IsKeyDown(KEY_CTRL))
	end
end

return Announcer