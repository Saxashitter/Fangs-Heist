local B = CBW_Battle
local S = B.SkinVars

B.SonicDash = function(player, button, variable)
	if player.pflags & PF_SHIELDABILITY
	or player.pflags & PF_THOKKED and not(player.charflags & SF_MULTIABILITY)
	or player.buttonhistory & button
		return true
	end
	local mo = player.mo
	mo.sonicdash = {tics = 12}
	mo.state = S_PLAY_ROLL
	S_StartSound(mo, sfx_zoom)
	B.XYLaunch(mo, mo.angle, player.actionspd, false)	
	player.pflags = $|PF_THOKKED
	return true
end

local deactivate = function(player)
	player.mo.state = S_PLAY_FALL
	player.mo.sonicdash = nil
	player.pflags = ($|PF_NOJUMPDAMAGE) &~ PF_SPINNING
end

B.SonicDashControl = function(player, button, variable)
	local mo = player.mo	
	if (mo.sonicdash)
-- 		if not(B.GetSkinVarsFlags(player)&SKINVARS_ROSY)
		if mo.state != S_PLAY_ROLL
			mo.sonicdash = nil
		elseif not(player.cmd.buttons & button)
			deactivate(player)
			mo.momx = $/2
			mo.momy = $/2
		else
			P_SpawnThokMobj(player)

			player.lockaim = true
			player.lockmove = true
			mo.sonicdash.tics = $-1
			mo.momx = $*9/10
			mo.momy = $*9/10
			P_SetObjectMomZ(mo, gravity, false)
			
			if mo.sonicdash.tics <= 0
				deactivate(player)
			end
		end
	end
	return mo.sonicdash
end