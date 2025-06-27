local B = CBW_Battle

local flipdummy = function(mo,target)
	if P_MobjFlip(target) == -1
		mo.flags2 = $|MF2_OBJECTFLIP
		mo.eflags = $|MFE_VERTICALFLIP
	else
		mo.flags2 = $&~MF2_OBJECTFLIP
		mo.eflags = $&~MFE_VERTICALFLIP
	end
end
//Master overlay script
B.TargetDummyThinker = function(mo)
	local target = mo.target
	//Validity check
	if not(target and target.valid and target.player)
		P_RemoveMobj(mo)
	return end //end of function
	//Spectator flicky overlay
	if (target.player.spectator) and (target.player.playerstate == PST_LIVE) then
		B.DummyFlicky(mo,target)
	return end //end of function
	//Revenge jetty-syn overlay
	if ((target.player.revenge) or (target.player.isjettysyn))
	and (not(B.Overtime) or (B.Overtime and B.PinchTics)) then
		B.DummyJettySyn(mo,target)
		flipdummy(mo,target)
	else
		mo.flags2 = $|MF2_DONTDRAW
	end
	//Lock-on behavior for popgun, homing, etc.
	B.DummyLockOn(mo,target)
end


B.DummyTeleport = function(mo)
	if not(mo.target and mo.target.valid) then return end
	local t = mo.target
	local a = mo.target.angle
	local d = FRACUNIT
	local x = t.x + P_ReturnThrustX(t,a+ANGLE_180,d)
	local y = t.y + P_ReturnThrustY(t,a+ANGLE_180,d)
	local z = t.z
	P_TeleportMove(mo,x,y,z)
end

B.SpawnTargetDummy = function(player)
-- 	if (not(player.realmo) or not(player.realmo.valid)) then
-- 		local p = B.UpdatePlayerTrueMobjs()
-- 	end
	local ptmo = player.realmo
	if not(ptmo and ptmo.valid) then return end
	//Game modes
	if B.BattleGametype() and (player.targetdummy == nil or not(player.targetdummy.valid)) then
		//Create target dummy
		player.targetdummy = P_SpawnMobj(ptmo.x,ptmo.y,ptmo.z,MT_TARGETDUMMY)
		player.targetdummy.target = ptmo
		player.targetdummy.flags2 = $|MF2_DONTDRAW
		player.targetdummy.shadowscale = FRACUNIT
	end
end

//-MobjFlip for Overlays-
B.JetThink = function(mo)
	if not(mo and mo.valid) or mo.health == 0 or (mo.target and mo.target.valid and mo.target.target and mo.target.target.valid and mo.target.target.player and mo.target.target.player.playerstate == PST_DEAD) then
		P_RemoveMobj(mo)
	return end
	if mo.target and mo.target.valid
	and mo.target.target and mo.target.target.valid
	 and (mo.target.target.flags2&MF2_OBJECTFLIP) then
		mo.flags2= $|MF2_OBJECTFLIP
		mo.eflags= $|MFE_VERTICALFLIP
	else
		mo.flags2 = $&~MF2_OBJECTFLIP
		mo.eflags= $&~MFE_VERTICALFLIP
	end
-- 	mo.flags = $&~MF_NOGRAVITY
-- 	mo.momz = 0
end



B.DummyJettySyn = function(mo,target)
	if target.player.playerstate == PST_DEAD then //Set death sprite
		mo.flags2 = MF2_DONTDRAW //Need to figure out what I'm going to do here
	return end //Important that we don't run anything after this line

	//Update overlay position
	B.DummyTeleport(mo)
	//Disappear the player object and make our object the same color
	mo.flags2 = $&~MF2_DONTDRAW 
	target.flags2 = $|MF2_DONTDRAW
	mo.color = target.color
	local player = target.player
	

	//Update sprites
	if (P_PlayerInPain(player) or player.actionstate != 1) and not(mo.state == S_REVENGEGUNNER1 or mo.state == S_REVENGEGUNNER2) then
		mo.state = S_REVENGEGUNNER1
	end
	if player.actionstate == 1 and not(mo.state == S_REVENGEGUNNER3 or mo.state == S_REVENGEGUNNER4) then
		mo.state = S_REVENGEGUNNER3
	end
	//Flashing control
	if mo.target.player.powers[pw_flashing] and (mo.state == S_REVENGEGUNNER2) then
		mo.flags2 = $|MF2_DONTDRAW
	end
	// Angle control
	if mo.target.player.actionstate == 0 then
		mo.angle = player.drawangle
	else
		mo.angle = target.angle
	end
end

//-Spectator Flicky Overlay-
B.DummyFlicky = function(mo,target)
	if not(mo.bird) then
		mo.bird = true
		mo.flags2 = $&~MF2_DONTDRAW
		mo.state = S_SPECBIRD1
		mo.flags = $|MF_NOGRAVITY
	end
	mo.angle = target.angle
	local dist = -FRACUNIT
	P_TeleportMove(mo,
		target.x+P_ReturnThrustX(nil,target.angle,dist),
		target.y+P_ReturnThrustY(nil,target.angle,dist),
		target.z)
	mo.z = $+abs(15-(leveltime&31))*FRACUNIT/2

end

//-Lock on Object-
B.DummyLockOn = function(mo,target)
	mo.height = target.height
	mo.scale = target.scale
	mo.flags = $|MF_NOGRAVITY
	if target.player.playerstate == PST_LIVE then
		B.DummyTeleport(mo) //Reposition
	end
	
	//Get aimable
	if target.player.playerstate == PST_LIVE and not target.player.intangible
		and
		not(target.flags&MF_NOCLIPTHING) then
		mo.flags2 = $|MF2_INVERTAIMABLE //Allow lock-on
	else
		//Target is not alive. Disallow lock-on.
		mo.flags2 = $&~MF2_INVERTAIMABLE
	end
end

B.DamageTargetDummy = function(target,inflictor,source,damage,other)
	local pmo = target.target
	if pmo and pmo.player then
		local player = pmo.player
		if inflictor and inflictor.player
			then
-- 			P_DamageMobj(pmo,inflictor,source,DMG_NUKE)
			P_DamageMobj(pmo,inflictor,source,damage,other)
		end
	end
end