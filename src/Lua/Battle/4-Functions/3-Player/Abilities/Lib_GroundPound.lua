local B = CBW_Battle
local S = B.SkinVars

B.StartGroundPound = function(player, button, variable)
	if player.pflags & PF_SHIELDABILITY
	or player.pflags & PF_THOKKED and not(player.charflags & SF_MULTIABILITY)
	or player.buttonhistory & button
		return true
	end
	local actionspd = 30
	if player.mo.eflags & MFE_UNDERWATER
		actionspd = $*11/20
	end
	P_InstaThrust(player.mo, player.mo.angle, actionspd * player.mo.scale)
	P_SetObjectMomZ(player.mo, -actionspd * FRACUNIT/2, true)
	P_SpawnThokMobj(player)
	
	S_StartSound(player.mo, sfx_zoom)
	
	player.pflags = ($|PF_THOKKED|PF_JUMPED) &~ PF_GLIDING
	player.mo.state = S_PLAY_ROLL
	player.mo.groundpound = true
	return true
end

local groundpound = function(mo)
	local player = mo.player
	player.lockjumpframe = 2
	S_StartSound(mo,sfx_s3k5f)
	local blastspeed = 4
	local reboundthrust = 7
	local fuse = 10
	local water = mo.eflags & MFE_UNDERWATER and 1 or 2
	//Create projectile blast
	for n = 0, 23 do
		local p = P_SPMAngle(mo,MT_GROUNDPOUND,mo.angle+n*ANG15,0)
		if p and p.valid then
			p.momz = mo.scale*P_MobjFlip(mo)*blastspeed/water
			p.fuse = fuse
		end
	end
	
	P_InstaThrust(mo,R_PointToAngle2(0,0,mo.momx,mo.momy),FixedHypot(mo.momx,mo.momy)/5)
	B.ZLaunch(mo,reboundthrust*FRACUNIT,true)
	mo.state = S_PLAY_SPRING
	player.pflags = ($|PF_THOKKED)&~PF_SPINNING
end

B.DoGroundPound = function(player, button, variable)
	local mo = player.mo
	if P_PlayerInPain(player) or not(player.playerstate == PST_LIVE)
		mo.groundpound = false
	end
	if not(mo.groundpound)
		return false
	end
	P_SpawnThokMobj(player)
	if P_IsObjectOnGround(mo)
		groundpound(mo)
	end
	if player.pflags & (PF_THOKKED|PF_JUMPED) != PF_THOKKED|PF_JUMPED
	or mo.state != S_PLAY_ROLL
	or mo.momz*P_MobjFlip(mo) > 0 --If we're moving upward, then something must have interrupted us.
		mo.groundpound = false
	end
	return mo.groundpound
end