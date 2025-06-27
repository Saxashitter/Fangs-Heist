local B = CBW_Battle
local S = B.SkinVars

B.MomentumThok = function(player, button, variable)
	if player.pflags & PF_SHIELDABILITY
	or player.mo.metalthok
	or player.buttonhistory & button
		return true
	end
	local mo = player.mo
	local actionspd = mo.scale*24
	if mo.eflags & MFE_UNDERWATER
		actionspd = $*11/20
	end
	P_SpawnThokMobj(player)
	player.drawangle = mo.angle
	actionspd = max(R_PointToDist2(0, 0, mo.momx, mo.momy), $)
	P_InstaThrust(mo, mo.angle, actionspd)
-- 	mo.momz = 0
	mo.state = S_PLAY_DASH
	if player.dashmode < TICRATE*3
		S_StartSound(mo, sfx_thok)
	else
		S_StartSound(mo, sfx_msthok)
		for n = 1, 5 do
			local thok = P_SpawnMobjFromMobj(mo, 0, 0, 0, MT_THOK)
			thok.color = SKINCOLOR_WHITE
			thok.momx = mo.momx + P_RandomRange(-10,10)*mo.scale
			thok.momy = mo.momy + P_RandomRange(-10,10)*mo.scale
			thok.scale = $>>2
			thok.blendmode = AST_ADD
		end
	end
	player.pflags = $|PF_NOJUMPDAMAGE
	player.mo.metalthok = true
	return true
end

B.MomentumThokControl = function(player, button, variable)
	player.mo.metalthok = $ and not P_IsObjectOnGround(player.mo)
	return player.mo.metalthok
end