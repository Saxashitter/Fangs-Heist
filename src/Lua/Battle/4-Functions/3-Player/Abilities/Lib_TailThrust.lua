local B = CBW_Battle
local S = B.SkinVars

B.TailThrust = function(player, button, variable)
	if player.pflags & PF_SHIELDABILITY
	or (player.pflags & PF_THOKKED and not(player.charflags & SF_MULTIABILITY) and player.mo.state != S_PLAY_TAILSFLY)
	or player.buttonhistory & button
		return true
	end
	local actionspd = 30
	if player.mo.eflags & MFE_UNDERWATER
		actionspd = $*11/20
	end
	P_InstaThrust(player.mo, player.mo.angle, actionspd * player.mo.scale)
	P_SetObjectMomZ(player.mo, actionspd * FRACUNIT>>2,false)
	P_SpawnThokMobj(player)
	
	S_StartSound(player.mo, sfx_dash)
	
	player.pflags = $|PF_THOKKED|PF_STARTJUMP
	player.mo.state = S_TAILS_SWIPE
	return true
end