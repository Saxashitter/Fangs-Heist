local SPIN_TICS = 35
local FADED_OUT_MUSIC = false

addHook("MapChange", do FADED_OUT_MUSIC = false end)

local function ManageMusicFade(sign)
	if FangsHeist.Net.escape then return end
	if FangsHeist.Net.pregame then return end
	if FangsHeist.Net.game_over then return end

	local p = displayplayer
	if not (p and p.valid and p.mo and p.mo.valid) then
		return
	end

	local dist = R_PointToDist2(p.mo.x, p.mo.y, sign.x, sign.y)

	return dist < 750*FU
end

local function OnSpawn(sign, _, _, _, angle)
	sign.angle = angle or 0
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
	return p.heist:isEligibleForSign()
end

local function OnCapture(sign, pmo)
	local gamemode = FangsHeist.getGamemode()
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
		if not gamemode:signcapture(pmo.player, false) then
			FangsHeist.playVoiceline(pmo.player, "signpost")
		end
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
	local result = ManageMusicFade(sign)
	if result == true
	and not FADED_OUT_MUSIC then
		FADED_OUT_MUSIC = result
		S_FadeMusic(0, MUSICRATE)
	end
	if result == false
	and FADED_OUT_MUSIC then
		FADED_OUT_MUSIC = result
		S_FadeMusic(100, MUSICRATE)
	end
		

	if not (sign.settings.target and sign.settings.target.player and sign.settings.target.player == consoleplayer) then
		sign.bustmo.frame = $ & ~FF_TRANS80
		sign.boardmo.frame = $ & ~FF_TRANS80
		return
	end

	sign.bustmo.frame = $|FF_TRANS80
	sign.boardmo.frame = $|FF_TRANS80
end

local function _draw(self, v,p,c, result, trans)
	local spr = v.getSpritePatch(SPR_SIGN, G, 0)
	local scale = FU/4

	local x = result.x + spr.leftoffset*scale
	local y = result.y + spr.topoffset*scale

	v.drawScaled(x - spr.width*scale/2, y, scale, spr, trans)
end

local function Track(sign)
	FangsHeist.trackObject(sign, {color=SKINCOLOR_RED}, _draw)
end

return {
	profit = 600,
	priority = 2,
	multiplier = 2,
	radius = 128*FU,
	height = 54*FU,
	giveToDamager = true,
	state = S_SIGN,
	canPickUp = CanPickUp,
	onSpawn = OnSpawn,
	onPickUp = OnCapture,
	onGrabThink = Grabbed,
	onUngrabThink = Track,
	onPostThink = PostThink
}