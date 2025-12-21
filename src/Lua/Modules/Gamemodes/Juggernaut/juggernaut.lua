states[freeslot("S_FH_JUGGERNAUTSLEEP")] = {
	sprite = SPR_PLAY,
	frame = freeslot("SPR2_OOF_"),
	tics = -1,
	nextstate = S_FH_JUGGERNAUTSLEEP
}

local function isPlayerJuggernaut(p)
	if gametype ~= GT_FANGSHEISTJUGGERNAUT then
		return
	end

	if not (p and p.valid and p.heist and p.heist:isAlive()) then
		return false
	end

	return p.heist:getTeam() == FangsHeist.Net.juggernaut_team
end

FangsHeist.addHook("PlayerShield", function(p)
	if isPlayerJuggernaut(p) then return true end
end)

FangsHeist.addHook("PostPlayerAttackDamage", function(s, p, damage)
	if isPlayerJuggernaut(p) then
		return 0
	elseif isPlayerJuggernaut(s) then
		return FixedMul(damage, tofixed("2.5"))
	end
end)

addHook("MobjDamage", function(t, i, s)
	if not isPlayerJuggernaut(t.player) then return end

	P_DoPlayerPain(t.player, s, i)
	return true
end, MT_PLAYER)

addHook("ShouldDamage", function(t, i, s)
	if not isPlayerJuggernaut(t.player) then return end

	if FangsHeist.Net.juggernaut_awakening then
		return false
	end

	if s and s.valid then
		return s.type == MT_PLAYER
	end
end, MT_PLAYER)