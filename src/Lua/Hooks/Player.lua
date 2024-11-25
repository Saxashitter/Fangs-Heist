local dialogue = FangsHeist.require "Modules/Handlers/dialogue"
local conscious = FangsHeist.require "Modules/Handlers/conscious"

FangsHeist.panicBlacklist = {
	takisthefox = true
}

states[freeslot "S_FH_PANIC"] = {
	sprite = SPR_PLAY,
	frame = SPR2_CNT1,
	tics = 4,
	nextstate = S_FH_PANIC
}

// Handle player hook.
addHook("PlayerThink", function(p)
	if not FangsHeist.isMode() then return end
	if not (p and p.valid) then return end

	if not (p and p.heist) then
		FangsHeist.initPlayer(p)
	end

	if p.heist.spectator then
		p.heist.treasure_time = 0
		return
	end

	p.charflags = $ & ~SF_DASHMODE

	p.heist.treasure_time = max(0, $-1)

	if FangsHeist.Net.escape
	and not FangsHeist.panicBlacklist[p.mo.skin] then
		if p.mo.state == S_PLAY_STND then
			p.mo.state = S_FH_PANIC
		end
		if p.mo.state == S_FH_PANIC then
			if FixedHypot(p.rmomx, p.rmomy) then
				p.mo.state = S_PLAY_WALK
			end
		end
	end

	if not (p.heist.exiting) then
		p.score = FangsHeist.returnProfit(p)
	end

	if not (p.heist.conscious_meter) then
		conscious(p)
	end
end)

addHook("ThinkFrame", do
	if not FangsHeist.isMode() then return end

	for p in players.iterate do
		if not (p and p.heist) then continue end

		if p.heist.spectator then
			if p.mo then
				if p.mo.health then
					p.spectator = true
				end
				continue
			end

			p.spectator = true
		end
	end
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

	if t.flags & MF_ENEMY then
		s.player.heist.enemies = $+1
	end
	if t.flags & MF_MONITOR then
		s.player.heist.monitors = $+1
	end
end)

addHook("MobjDeath", function(t,i,s)
	if not FangsHeist.isMode() then return end
	if not FangsHeist.Net.escape then return end
	if not (t and t.player and t.player.heist) then return end

	t.player.heist.spectator = true
end, MT_PLAYER)

addHook("ShouldDamage", function(t,i,s)
	if not FangsHeist.isMode() then return end
	if not (t and t.player and t.player.heist) then return end

	if t.player.heist.exiting then
		return false
	end

	if t.player.heist.conscious_meter == 0 then
		if not (s and s.player and s.player.heist) then
			return false
		end

		return true
	end
end, MT_PLAYER)

addHook("TouchSpecial", function(s,t)
	if not FangsHeist.isMode() then return end
	if not (t and t.player and t.player.heist) then return end

	if FangsHeist.isPlayerUnconscious(t.player) then
		return true
	end

	t.player.heist.conscious_meter = min($+FU/8, FU)
end, MT_RING)

addHook("TouchSpecial", function(s,t)
	if not FangsHeist.isMode() then return end
	if not (t and t.player and t.player.heist) then return end

	if FangsHeist.isPlayerUnconscious(t.player) then
		return true
	end
end, MT_FLINGRING)

addHook("MobjDamage", function(t,i,s,dmg,dt)
	if not FangsHeist.isMode() then return end
	if not (t and t.player and t.player.heist) then return end

	if s
	and s.player
	and s.player.heist
	and FangsHeist.playerHasSign(t.player) then
		FangsHeist.giveSignTo(s.player)
	end

	if dt & DMG_DEATHMASK then return end
	if t.player.powers[pw_shield] then return end
	if not t.player.rings then return end

	t.player.heist.conscious_meter = max(0, $-FU/2)

	local rings_spill = min(5, t.player.rings)

	S_StartSound(t, sfx_s3kb9)

	if not t.player.heist.conscious_meter then
		rings_spill = min(25, t.player.rings)

		if s
		and s.player then
			s.player.rings = $+rings_spill
		end
	else
		P_PlayerRingBurst(t.player, rings_spill)
	end
	
	t.player.rings = $-rings_spill
	t.player.powers[pw_shield] = 0

	if not FangsHeist.isPlayerUnconscious(t.player) then
		P_DoPlayerPain(t.player, s, i)
	else
		t.player.powers[pw_flashing] = TICRATE/3
	end

	return true
end, MT_PLAYER)

// UNUSED
local function thokNerf(p)
	local speed = FixedHypot(p.rmomx, p.rmomy)
	local angle = (p.cmd.angleturn<<16)+R_PointToAngle2(0, 0, p.cmd.forwardmove*FU, -p.cmd.sidemove*FU)

	P_InstaThrust(p.mo, angle, max(speed, 12*p.mo.scale))
	p.pflags = $|PF_THOKKED & ~PF_JUMPED
	p.mo.state = S_PLAY_FALL
	P_SpawnThokMobj(p)
	S_StartSound(p.mo, sfx_thok)
end

addHook("AbilitySpecial", function (p)
	if FangsHeist.canUseAbility(p)
	and FangsHeist.isPlayerAlive(p)
	and not (p.pflags & PF_THOKKED)
	and p.charability == CA_THOK then
		p.charability = CA_DOUBLEJUMP
	end

	return not FangsHeist.canUseAbility(p)
end)