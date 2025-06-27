addHook("PlayerMsg", function(player, audience, target, message)
	if audience == 1 and player.ctfteam != 0 and consoleplayer != nil
		if player.ctfteam != consoleplayer.ctfteam
			return true
		end
	end
end)