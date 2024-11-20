// Handle player hook.
addHook("PlayerThink", function(p)
	if not FangsHeist.isMode() then return end

	if not (p and p.heist) then
		FangsHeist.initPlayer(p)
	end

	print(FangsHeist.returnProfit(p))
end)

local function return_score(mo)
	if mo.flags & MF_MONITOR then
		return 12
	end

	if mo.flags & MF_ENEMY then
		return 35
	end

	return 0
end

addHook("MobjDeath", function(t,i,s)
	if not FangsHeist.isMode() then return end

	if not (s and s.player and s.player.heist) then return end

	s.player.heist.scraps = $+return_score(t)
end)