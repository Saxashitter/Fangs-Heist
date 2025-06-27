local B = CBW_Battle
local S = B.SkinVars

B.SonicDoubleJump = function(player, button, variable)
	if player.pflags & PF_SHIELDABILITY
	or player.pflags & PF_THOKKED and not(player.charflags & SF_MULTIABILITY)
	or player.buttonhistory & button
		return true
	end
	local mo = player.mo
	mo.sonicdoublejump = {tics = 12}
	mo.state = S_PLAY_ROLL
	mo.momx = $/2
	mo.momy = $/2
	P_SetObjectMomZ(mo, player.actionspd / 2, false)
	S_StartSound(mo, sfx_zoom)
	
	player.pflags = $|PF_THOKKED|PF_STARTJUMP
	return true
end

local deactivate = function(player)
	player.mo.state = S_PLAY_FALL
	player.mo.sonicdoublejump = nil
	player.pflags = ($|PF_NOJUMPDAMAGE) &~ PF_SPINNING
end
B.SonicDoubleJumpControl = function(player, button, variable)
	local mo = player.mo	
	if (mo.sonicdoublejump)
-- 		if not(B.GetSkinVarsFlags(player)&SKINVARS_ROSY)
		if mo.state != S_PLAY_ROLL
			mo.sonicdoublejump = nil
-- 		elseif not (player.cmd.buttons & button)
-- 			mo.momz = $/2
-- 			deactivate(player)
		else
			P_SpawnThokMobj(player)

			player.lockaim = true
			player.lockmove = true
			mo.sonicdoublejump.tics = $-1
			mo.momz = $ * 9/10
-- 			mo.momx = $ * 9/10
-- 			mo.momy = $ * 9/10
			
			if mo.sonicdoublejump.tics <= 0
				deactivate(player)
			end
		end
	end
	return (mo.sonicdoublejump != nil)
end
