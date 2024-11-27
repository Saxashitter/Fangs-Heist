local dialogue = FangsHeist.require "Modules/Handlers/dialogue"
local conscious = FangsHeist.require "Modules/Handlers/conscious"

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

	if p.heist.spectator then
		p.heist.treasure_time = 0
		return
	end

	p.charflags = $ & ~SF_DASHMODE
	p.heist.treasure_time = max(0, $-1)

	if fang.isGunslinger(p) then
		fang.playerThinker(p)
	end

	if leveltime % TICRATE*5 == 0 then
		local count = #p.heist.treasures

		p.heist.generated_profit = min(1000, $+4*count)
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

	if (FangsHeist.isPlayerUnconscious(p)
	and P_IsObjectOnGround(p.mo))
	or not FangsHeist.isPlayerUnconscious(p) then
		p.heist.thrower = nil
	end

	if not (p.heist.exiting) then
		p.score = FangsHeist.returnProfit(p)
	end

	if not (p.heist.conscious_meter) then
		conscious(p)
	end
end)

local function remove_carry_vars(p)
	local sp = p.heist.picked_up_player

	if sp and sp.valid and sp.heist then
		sp.heist.picked_up_by = nil
	end
	p.heist.picked_up_player = nil
end

local function put_down_player(p)
	local sp = p.heist.picked_up_player
	local angle = p.mo.angle

	P_InstaThrust(sp.mo, angle, max(16*FU, FixedHypot(p.mo.momx, p.mo.momy)*3/2))
	P_SetObjectMomZ(sp.mo, 2*FU)

	sp.heist.thrower = p

	remove_carry_vars(p)
end

local function manage_player_carry(p)
	local sp = p.heist.picked_up_player

	local sp = p.heist.picked_up_player
	local angle = p.drawangle

	sp.drawangle = angle

	P_MoveOrigin(sp.mo,
		p.mo.x,
		p.mo.y,
		p.mo.z+p.mo.height)

	sp.mo.momx = 0
	sp.mo.momy = 0
	sp.mo.momz = 0
end

local function find_player_to_carry(p)
	if not (p.cmd.buttons & BT_ATTACK and not (p.lastbuttons & BT_ATTACK)) then
		return
	end

	for sp in players.iterate do
		if not FangsHeist.isPlayerAlive(sp) then continue end
		if not FangsHeist.isPlayerUnconscious(sp) then continue end
		if FangsHeist.isPlayerPickedUp(sp) then continue end

		local dist = R_PointToDist2(p.mo.x, p.mo.y, sp.mo.x, sp.mo.y)
		local heightdist = abs(p.mo.height-sp.mo.height)

		if dist > p.mo.radius+sp.mo.radius
		or heightdist > max(p.mo.height, sp.mo.height) then
			continue
		end

		sp.heist.picked_up_by = p
		p.heist.picked_up_player = sp

		break
	end
end

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

		// CARRYING!!!!!
		if p.heist.picked_up_by then
			local sp = p.heist.picked_up_by
			remove_carry_vars(p)

			if not (sp and sp.valid and FangsHeist.isPlayerAlive(sp) and not FangsHeist.isPlayerUnconscious(sp)) then
				p.heist.picked_up_by = nil
	
				if sp and sp.valid and sp.heist then
					sp.heist.picked_up_player = nil
				end
			else
				continue
			end
		end


		if not FangsHeist.isPlayerAlive(p) then
			remove_carry_vars(p)
			continue
		end

		if P_PlayerInPain(p) then
			remove_carry_vars(p)
			continue
		end

		local sp = p.heist.picked_up_player

		if not (sp
		and sp.valid
		and FangsHeist.isPlayerAlive(sp)
		and FangsHeist.isPlayerUnconscious(sp)) then
			remove_carry_vars(p)
			find_player_to_carry(p)
			continue
		end

		manage_player_carry(p)
		if p.cmd.buttons & BT_ATTACK
		and not (p.lastbuttons & BT_ATTACK) then
			put_down_player(p)
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
	if not FangsHeist.Net.escape then return end
	if not (t and t.player and t.player.heist) then return end

	t.player.heist.spectator = true
end, MT_PLAYER)

addHook("ShouldDamage", function(t,i,s,dmg,dt)
	if not FangsHeist.isMode() then return end
	if not (t and t.player and t.player.heist) then return end
	

	if t.player.heist.exiting then
		return false
	end

	if t.player.heist.conscious_meter == 0 then
		if not (s and s.player and s.player.heist)
		and t.player.rings
		and not (dt & DMG_DEATHMASK) then
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

	t.player.heist.conscious_meter = min($+FU/16, FU)
end, MT_RING)

addHook("TouchSpecial", function(s,t)
	if not FangsHeist.isMode() then return end
	if not (t and t.player and t.player.heist) then return end

	if FangsHeist.isPlayerUnconscious(t.player) then
		return true
	end
end, MT_FLINGRING)

local function thrown_body(i, s)
	return s
	and s.valid
	and s.player
	and FangsHeist.isPlayerAlive(s.player)
	and s ~= i
	and i
	and i.valid
	and i.player
	and FangsHeist.isPlayerAlive(i.player)
	and FangsHeist.isPlayerUnconscious(i.player)
end

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

	if thrown_body(i, s)
	or (s.player and FixedHypot(s.momx-t.momx, s.momy-t.momy) > 20*FU) then
		t.player.heist.conscious_meter = 0
	else
		t.player.heist.conscious_meter = max(0, $-FU/3)
	end

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
		t.player.powers[pw_flashing] = TICRATE
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

addHook("ShieldSpecial", function(p)
	if fang.isGunslinger(p) then
		return true
	end
end)

addHook("AbilitySpecial", function (p)
	if FangsHeist.canUseAbility(p)
	and FangsHeist.isPlayerAlive(p)
	and not (p.pflags & PF_THOKKED)
	and p.charability == CA_THOK then
		p.charability = CA_DOUBLEJUMP
	end

	return not FangsHeist.canUseAbility(p)
end)