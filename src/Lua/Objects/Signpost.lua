local UNGRABBED_FLAGS = MF_BOUNCE
local GRABBED_FLAGS = MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY

local spawnpos = FangsHeist.require "Modules/Libraries/spawnpos"

mobjinfo[freeslot "MT_FH_SIGN"] = {
	spawnstate = S_SIGN,
	flags = UNGRABBED_FLAGS,
	radius = 40*FU,
	height = mobjinfo[MT_SIGN].height
}

local function select_player(sign, p)
	S_StartSound(sign, sfx_lvpass)

	sign.hold_tween = 0
	sign.holder = p.mo
	sign.hold_pos = {x = sign.x, y = sign.y, z = sign.z}
	if sign.bustmo and sign.bustmo.valid then
		if skins[p.mo.skin].sprites[SPR2_SIGN].numframes then
			sign.bustmo.skin = p.mo.skin
			sign.bustmo.color = p.skincolor
			sign.bustmo.state = S_PLAY_SIGN
		else
			sign.bustmo.skin = "sonic" -- apparently i can't set a skin to nil? sonic shouldn't have highresscale, atleast not in vanilla sooo
			sign.bustmo.color = SKINCOLOR_NONE
			sign.bustmo.state = S_CLEARSIGN
		end
	end

	p.powers[pw_flashing] = TICRATE*2
	local gamemode = FangsHeist.getGamemode()

	if gamemode then
		gamemode:signcapture(true)
	end
end

function FangsHeist.giveSignTo(p) // somewhat of a wrapper function for scripts to access
	local sign = FangsHeist.Net.sign

	if not (sign and sign.valid) then return false end

	select_player(sign, p)
	return true
end

function FangsHeist.teleportSign()
	local sign = FangsHeist.Net.sign

	if not (sign and sign.valid and sign.holder and sign.holder.valid) then return end

	local pos = {
		x = ease.outquad(sign.hold_tween, sign.hold_pos.x, sign.holder.x),
		y = ease.outquad(sign.hold_tween, sign.hold_pos.y, sign.holder.y),
		z = ease.outquad(sign.hold_tween, sign.hold_pos.z,
			sign.holder.z+sign.holder.height+(24*FU*#sign.holder.player.heist.treasures)),
	}

	sign.momx = 0
	sign.momy = 0
	sign.momz = 0

	P_MoveOrigin(sign,
		pos.x,
		pos.y,
		pos.z)
end

--[[@return mobj_t]]
function FangsHeist.spawnSign(signpost_pos)
	local sign = P_SpawnMobj(signpost_pos[1], signpost_pos[2], signpost_pos[3], MT_FH_SIGN)

	local board = P_SpawnMobjFromMobj(sign, 0, 0, 0, MT_OVERLAY)
	board.target = sign
	board.state = S_SIGNBOARD
	board.movedir = ANGLE_90
	sign.boardmo = board

	local bust = P_SpawnMobjFromMobj(board, 0, 0, 0, MT_OVERLAY)
	bust.target = board
	bust.state = S_EGGMANSIGN
	sign.bustmo = bust

	FangsHeist.Net.sign = sign

	return sign
end

function FangsHeist.respawnSign(pos)
	if (FangsHeist.Net.sign
	and FangsHeist.Net.sign.valid) then
		--TODO destroy both parts of the sign
		P_RemoveMobj(FangsHeist.Net.sign)
	end

	FangsHeist.spawnSign(pos)
	print "Sign is back!"
end

local function manage_picked(sign)
	sign.hold_tween = min($+(FU/10), FU)
	sign.flags = GRABBED_FLAGS
	sign.angle = sign.holder.angle
end

local function blacklist(p)
	return P_PlayerInPain(p)
	or p.powers[pw_flashing]
	or not p.heist:isEligibleForSign()
end

local function manage_unpicked(sign)
	sign.flags = UNGRABBED_FLAGS
	sign.hold_tween = 0

	sign.angle = $ + ANG2

	if (sign.eflags & MFE_TOUCHWATER or sign.eflags & MFE_UNDERWATER) then
		sign.z = max($, sign.watertop)
		sign.momz = max($, 0)
	end

	local nearby = FangsHeist.getNearbyPlayers(sign, nil, blacklist)
	if not (#nearby) then return end

	local selected_player = nearby[P_RandomRange(1, #nearby)]
	local gamemode = FangsHeist.getGamemode()

	select_player(sign, selected_player)

	if gamemode then
		gamemode:signcapture(false)
	end
end

addHook("MobjSpawn", function(sign)
	sign.hold_tween = 0
	sign.hold_pos = {}
end, MT_FH_SIGN)

addHook("MobjThinker", function(sign)
	if sign.holder
	and not (sign.holder.valid
	and sign.holder.player.heist:isEligibleForSign()) then
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