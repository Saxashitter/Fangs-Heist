local B = CBW_Battle
local S = B.SkinVars

B.TailsFlightTrigger = function(player, button, variable)
	if player.pflags & PF_SHIELDABILITY
	or player.pflags & PF_THOKKED and not(player.charflags & SF_MULTIABILITY)
	or player.buttonhistory & button
		return true
	end

	S_StartSound(player.mo, sfx_dash)
	
	player.pflags = $|PF_THOKKED|PF_STARTJUMP
	player.mo.state = S_PLAY_TAILSFLY
-- 	player.mo.momx = $/2
-- 	player.mo.momy = $/2
-- 	player.mo.momz = $/2
	player.mo.battleflight = FRACUNIT
	return true
end

B.TailsFlightControl = function(player, button, variable)
	if not(player.mo.state == S_PLAY_TAILSFLY)
		player.mo.battleflight = nil
		return false
	end
	if player.mo.battleflight == 0
		return true
	end

	local actionspd = player.mo.battleflight << 2
	local friction = FRACUNIT - player.mo.battleflight/10
	if player.mo.eflags & MFE_UNDERWATER
		actionspd = $*11/20
	end
	player.mo.momx = FixedMul($, friction)
	player.mo.momy = FixedMul($, friction)
	P_SetObjectMomZ(player.mo, actionspd, true)
	player.mo.momz = $*4/5
	if player.pflags & PF_STARTJUMP
		player.mo.battleflight = max(0, $ - FRACUNIT/40)
	else
		player.mo.battleflight = max(0, $ - FRACUNIT/20)
	end
	player.mo.tics = max($, 1)
	--FX
	local r = player.mo.radius>>FRACBITS
	local h = player.mo.height>>FRACBITS
	local f = FRACUNIT
	local p = P_RandomRange
	local x, y, z = 
		p(-r, r)*f,
		p(-r, r)*f,
		p(h/2, h)*f
	local dust = P_SpawnMobjFromMobj(player.mo, x, y, z, MT_SPINDUST)
	dust.scale = $>>1
	return true
end