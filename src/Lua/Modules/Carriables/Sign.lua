local SPIN_TICS = 35

local function OnSpawn(sign, _, _, _, angle)
	sign.angle = angle
	sign.spintics = 0

	local board = P_SpawnMobjFromMobj(sign, 0, 0, 0, MT_OVERLAY)
	board.target = sign
	board.state = S_SIGNBOARD
	board.movedir = ANGLE_90
	sign.boardmo = board

	local bust = P_SpawnMobjFromMobj(board, 0, 0, 0, MT_OVERLAY)
	bust.target = board
	bust.state = S_EGGMANSIGN
	sign.bustmo = bust
end

local function CanPickUp(p)
	local team = p.heist:GetTeam()

	return team.had_sign ~= true
end

local function OnCapture(sign, pmo)
	local gamemode = FH:GetGamemode()

	sign.spintics = 0
	S_StartSound(sign, sfx_lvpass)

	if sign.bustmo and sign.bustmo.valid then
		if skins[pmo.skin].sprites[SPR2_SIGN].numframes then
			sign.bustmo.skin = pmo.skin
			sign.bustmo.color = pmo.player.skincolor
			sign.bustmo.state = S_PLAY_SIGN
		else
			sign.bustmo.skin = "sonic" -- apparently i can't set a skin to nil? sonic shouldn't have highresscale, atleast not in vanilla sooo
			sign.bustmo.color = SKINCOLOR_NONE
			sign.bustmo.state = S_CLEARSIGN
		end
	end

	if gamemode then
		gamemode:SignCapture(false)
	end

	pmo.player.powers[pw_flashing] = max($, TICRATE)
end

local function Grabbed(sign, pmo)
	if sign.spintics == SPIN_TICS then
		sign.angle = pmo.angle
		return
	end

	sign.spintics = $+1

	local angle = ease.outquad(FixedDiv(sign.spintics, SPIN_TICS), 0, (360*FU)*2)

	sign.angle = pmo.angle + FixedAngle(angle)
end

local function PostThink(sign)
	if not sign.settings.target then
		sign.bustmo.frame = $ & ~FF_TRANS80
		sign.boardmo.frame = $ & ~FF_TRANS80
		return
	end

	sign.bustmo.frame = $|FF_TRANS80
	sign.boardmo.frame = $|FF_TRANS80
end

return {
	profit = 600,
	priority = 2,
	multiplier = 2,
	height = 54*FU,
	giveToDamager = true,
	state = S_SIGN,
	canPickUp = CanPickUp,
	onSpawn = OnSpawn,
	onPickUp = OnCapture,
	onGrabThink = Grabbed,
	onPostThink = PostThink
}