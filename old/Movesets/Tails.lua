FangsHeist.makeCharacter("tails", {
	pregameBackground = "FH_PREGAME_TAILS"
})

local FLY_WINDUP_FRICTION = tofixed("0.896")

local FLY_TICS = 40
local FLY_MOM = 24
local FLY_GRAVITY = FU/2

local function HasControl(p)
	if p.pflags & PF_STASIS then return false end
	if p.pflags & PF_FULLSTASIS then return false end
	if p.pflags & PF_SLIDING then return false end
	if p.powers[pw_nocontrol] then return false end
	if P_PlayerInPain(p) then return false end
	if not (p.mo.health) then return false end

	return true
end

local function Valid(p)
	return FangsHeist.isMode()
	and p.heist
	and p.heist:isAlive()
	and p.mo.skin == "tails"
end

local function GetPickupablePlayers(tails)
	local list = {}

	local radius = 240*tails.mo.scale
	local height = 160*tails.mo.scale

	local x = tails.mo.x
	local y = tails.mo.y
	local z = tails.mo.z
	local team = tails.heist:getTeam()

	for sonic in players.iterate do
		if sonic == tails then
			continue
		end
		if not (sonic.heist and sonic.heist:isAlive()) then
			continue
		end
		
		if sonic.mo.state == S_FH_STUN then
			continue
		end
		if sonic.heist:getTeam() ~= team then
			continue
		end

		local dist = R_PointToDist2(x, y, sonic.mo.x, sonic.mo.y)
		if dist > radius then
			continue
		end

		local flip = P_MobjFlip(tails.mo)

		if flip == 1
		and sonic.mo.z > tails.mo.z+tails.mo.height then
			continue
		end

		if flip == -1
		and sonic.mo.z+sonic.mo.height < tails.mo.z then
			continue
		end

		table.insert(list, sonic)
	end

	return list
end

local function RemoveCarry(p)
	if p.powers[pw_carry] == CR_ROLLOUT then
		local rollout = p.mo.tracer

		if rollout and rollout.valid and rollout.tracer == p.mo then
			rollout.tracer = nil
			rollout.flags = $|MF_PUSHABLE
		end

		p.mo.tracer = nil
	else
		local mo = p.mo.tracer

		if mo and mo.valid and mo.tracer == p.mo then
			mo.tracer = nil
		end

		p.mo.tracer = nil
	end

	p.powers[pw_carry] = CR_NONE
end

local function DoFlight(mo)
	local tails = mo.tails
	local fixed = FixedMul(mo.scale, FLY_GRAVITY)

	mo.player.pflags = $|PF_THOKKED|PF_STARTJUMP

	P_SetObjectMomZ(mo, FLY_MOM*fixed)
	S_StopSoundByID(mo, sfx_spndsh)
	S_StartSound(mo, sfx_zoom)

	local list = GetPickupablePlayers(mo.player)
	local carryPlayer = mo.player

	for _, p in ipairs(list) do
		if P_MobjFlip(mo) == 1 and carryPlayer.mo.z-p.mo.height < p.mo.floorz
		or P_MobjFlip(mo) == -1 and carryPlayer.mo.z+carryPlayer.mo.height+p.mo.height > p.mo.ceilingz then
			continue
		end

		P_ResetPlayer(p)
		if p.powers[pw_carry] then
			RemoveCarry(p)
		end

		local z = carryPlayer.mo.z-p.mo.height
		if P_MobjFlip(p.mo) == -1 then
			z = carryPlayer.mo.z+carryPlayer.mo.height+p.mo.height
		end

		P_SetOrigin(p.mo,
			carryPlayer.mo.x,
			carryPlayer.mo.y,
			z)

		carryPlayer.pflags = $|PF_CANCARRY

		p.mo.tracer = carryPlayer.mo
		p.powers[pw_carry] = CR_PLAYER

		carryPlayer = p
	end
end

states[S_FH_FLYRELEASE].action = DoFlight

addHook("PlayerThink", function(p)
	if not Valid(p) then
		return
	end

	if p.mo.state == S_FH_FLYRELEASE
	or p.mo.state == S_FH_FLYRELEASE_HOLD then
		P_SpawnGhostMobj(p.mo)

		if not S_SoundPlaying(p.mo, sfx_putput) then
			S_StartSound(p.mo, sfx_putput)
		end

		local gravity = P_GetMobjGravity(p.mo)

		p.mo.momz = $ - gravity
		p.mo.momz = $ + FixedMul(gravity, FLY_GRAVITY)

		if p.mo.momz*P_MobjFlip(p.mo) < 0
		or p.pflags & PF_STARTJUMP == 0 then
			p.mo.momz = min($*P_MobjFlip(p.mo), 0)*P_MobjFlip(p.mo)
			p.mo.state = S_PLAY_FALL
			S_StartSound(p.mo, sfx_skid)
			S_StartSound(p.mo, sfx_s3k51)
		end
	end
end)

addHook("AbilitySpecial", function(p)
	if not Valid(p)
	or p.pflags & PF_THOKKED then
		return
	end

	p.mo.state = S_FH_FLYRELEASE
	p.pflags = $|PF_THOKKED

	S_StartSound(p.mo, sfx_zoom)
end)