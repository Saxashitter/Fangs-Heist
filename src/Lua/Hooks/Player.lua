local dialogue = FangsHeist.require "Modules/Handlers/dialogue"
local movement = FangsHeist.require "Modules/Handlers/movement"

local fang = FangsHeist.require "Modules/Movesets/fang"

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

	for sp,_ in pairs(p.heist.team) do
		if sp == "leader" then continue end

		if not (sp and sp.valid and sp.heist) then
			p.heist.team[sp] = nil
			if p.heist.team.leader == sp then
				p.heist.team.leader = p
			end
		end
	end

	if FangsHeist.Net.pregame
	and not p.heist.confirmed_skin then
		local deadzone = 10
		if abs(p.heist.sidemove) >= deadzone
		and abs(p.heist.lastside) < deadzone then
			local sign = p.heist.sidemove >= 0 and 1 or -1
	
			p.heist.locked_skin = max(0, min($+sign, #skins-1))
		end

		if p.heist.buttons & BT_JUMP
		and not (p.heist.lastbuttons & BT_JUMP) then
			p.heist.confirmed_skin = true
		end
	end

	if p.skin ~= p.heist.locked_skin then
		R_SetPlayerSkin(p, p.heist.locked_skin)
	end

	if p.heist.spectator then
		p.heist.treasure_time = 0
		return
	end

	local data = FangsHeist.getTypeData()

	p.heist.treasure_time = max(0, $-1)
	p.dashmode = 0
	if data.bullet_mode then
		if p.cmd.buttons & BT_ATTACK
		and not (p.lastbuttons & BT_ATTACK) then
			local ring = P_SpawnPlayerMissile(p.mo, MT_REDRING)
			if ring and ring.valid then
				local speed = 24
				ring.momx = FixedMul(speed*cos(ring.angle), cos(p.aiming))
				ring.momy = FixedMul(speed*sin(ring.angle), cos(p.aiming))
				ring.momz = speed*sin(p.aiming)
			end
		end
	end

	if leveltime % TICRATE*5 == 0 then
		local count = #p.heist.treasures

		p.heist.generated_profit = min(500, $+12*count)
	end

	local spindash_limit = 45*FU
	if FangsHeist.playerHasSign(p) then
		p.heist.corrected_speed = false
		p.normalspeed = min(24*FU, $)
		p.runspeed = min(16*FU, $)
		p.mindash = min($, spindash_limit)
		p.maxdash = min($, spindash_limit)
	elseif not p.heist.corrected_speed then
		p.heist.corrected_speed = true
		p.normalspeed = skins[p.skin].normalspeed
		p.mindash = skins[p.skin].mindash
		p.maxdash = skins[p.skin].maxdash
		p.runspeed = skins[p.skin].runspeed
	end

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

	fang.playerThinker(p)

	if not (p.heist.exiting) then
		p.score = FangsHeist.returnProfit(p)
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
			continue
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

	if t.flags & MF_ENEMY then
		s.player.heist.enemies = $+1
	end
	if t.flags & MF_MONITOR then
		s.player.heist.monitors = $+1
	end
end)

addHook("MobjDeath", function(t,i,s)
	if not FangsHeist.isMode() then return end
	if not (FangsHeist.Net.escape or FangsHeist.Net.is_boss) then return end
	if not (t and t.player and t.player.heist) then return end

	t.player.heist.spectator = true
end, MT_PLAYER)

addHook("ShouldDamage", function(t,i,s,dmg,dt)
	if not FangsHeist.isMode() then return end
	if not (t and t.player and t.player.heist) then return end
	

	if t.player.heist.exiting then
		return false
	end

	if i
	and i.valid
	and i.type == MT_CORK then
		if t.player.powers[pw_flashing] then
			return false
		end
		if t.player.powers[pw_invulnerability] then
			return false
		end
	end
end, MT_PLAYER)

addHook("MobjDamage", function(t,i,s,dmg,dt)
	if not FangsHeist.isMode() then return end
	if not (t and t.player and t.player.heist) then return end

	for _,tres in pairs(t.player.heist.treasures) do
		if not (tres.mobj.valid) then continue end

		local angle = FixedAngle(P_RandomRange(1, 360)*FU)

		P_InstaThrust(tres.mobj, angle, 12*FU)
		P_SetObjectMomZ(tres.mobj, 4*FU)

		tres.mobj.target = nil
	end
	t.player.heist.treasures = {}

	if dt & DMG_DEATHMASK then return end

	if s
	and s.player
	and s.player.heist then
		if FangsHeist.playerHasSign(t.player) then
			FangsHeist.giveSignTo(s.player)
		end

		if not (t.player.rings)
		and not (t.player.powers[pw_shield]) then
			s.player.heist.deadplayers = $+1
		else
			s.player.heist.hitplayers = $+1
		end
	end

	if t.player.powers[pw_shield] then return end
	if not t.player.rings then return end


	local rings_spill = min(5, t.player.rings)

	S_StartSound(t, sfx_s3kb9)

	P_PlayerRingBurst(t.player, rings_spill)
	
	t.player.rings = $-rings_spill
	t.player.powers[pw_shield] = 0

	P_DoPlayerPain(t.player, s, i)

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
	and p.charability == CA_THOK
	and not (p.pflags & PF_THOKKED) then
		p.actionspd = 40*FU
	end

	return not FangsHeist.canUseAbility(p)
end)