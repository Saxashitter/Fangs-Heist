local UNGRABBED_FLAGS = 0
local GRABBED_FLAGS = MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY

mobjinfo[freeslot "MT_FH_SIGN"] = {
	spawnstate = S_SIGN,
	flags = UNGRABBED_FLAGS,
	radius = 40*FU,
	height = mobjinfo[MT_SIGN].height
}

local function select_player(sign, p)
	sign.hold_tween = 0
	sign.holder = p.mo
	sign.hold_pos = {x = sign.x, y = sign.y, z = sign.z}
end

local function manage_picked(sign)
	sign.hold_tween = min($+(FU/10), FU)
	sign.flags = GRABBED_FLAGS

	local pos = {
		x = ease.outquad(sign.hold_tween, sign.hold_pos.x, sign.holder.x),
		y = ease.outquad(sign.hold_tween, sign.hold_pos.y, sign.holder.y),
		z = ease.outquad(sign.hold_tween, sign.hold_pos.z, sign.holder.z+sign.holder.height),
	}

	sign.momx = 0
	sign.momy = 0
	sign.momz = 0
	P_MoveOrigin(sign,
		pos.x,
		pos.y,
		pos.z)
end

local function blacklist(p)
	return P_PlayerInPain(p)
end

local function manage_unpicked(sign)
	sign.flags = UNGRABBED_FLAGS
	sign.hold_tween = 0

	local nearby = FangsHeist.getNearbyPlayers(sign, nil, blacklist)
	if not (#nearby) then return end

	local selected_player = nearby[P_RandomRange(1, #nearby)]

	select_player(sign, selected_player)
end

addHook("MobjSpawn", function(sign)
	sign.hold_tween = 0
	sign.hold_pos = {}

	FangsHeist.Net.sign = sign
end, MT_FH_SIGN)

addHook("MobjThinker", function(sign)
	if (sign.holder
	and not (sign.holder.valid
	and FangsHeist.isPlayerAlive(sign.holder.player)
	and not P_PlayerInPain(sign.holder.player))) then
		sign.holder = nil

		local launch_angle = FixedAngle(P_RandomRange(0, 360)*FU)

		P_InstaThrust(sign, launch_angle, 8*FU)
		P_SetObjectMomZ(sign, 4*FU)
	end

	if not (sign.holder) then
		manage_unpicked(sign)
		return
	end

	manage_picked(sign)
end, MT_FH_SIGN)