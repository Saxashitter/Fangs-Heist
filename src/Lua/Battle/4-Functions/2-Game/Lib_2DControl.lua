local B = CBW_Battle

B.TwoDFactor = function(value)
	return value*3/2
end

B.TwoDMissile = function(mo)
	//Set 2D physics
	if twodlevel and not(mo.twodslow) then
		mo.twodslow = true
		P_InstaThrust(mo,R_PointToAngle2(0,0,mo.momx,mo.momy),FixedHypot(mo.momx,mo.momy)/2)
		if mo.flags&MF_NOGRAVITY
			mo.momz = $/2
		end
	end
end

B.PlayerMovementControl = function(player)
	local mo = player.mo
	local skin = skins[mo.skin]
	local grounded = P_IsObjectOnGround(mo)
	
	//In 2D!
	if twodlevel
		player.battleintwod = true
		
		//Running curve values
		if (player.cmd.forwardmove|player.cmd.sidemove)
			local spd = FixedHypot(player.rmomx,player.rmomy)
			local thrust = skin.thrustfactor
			local maxspd = player.normalspeed
			player.runspeed = skin.runspeed*3/5
			if mo.angle != 0 then maxspd = -$ end
 			thrust = B.FixedLerp($+2,1,min(FRACUNIT,max(0,FixedDiv(player.rmomx,maxspd))))
			player.thrustfactor = thrust
		end
		
		//Spindash speed limit
		if player.charability2 == CA2_SPINDASH and player.pflags&PF_STARTDASH then
			player.dashspeed = min($,B.FixedLerp(player.mindash,player.maxdash,FRACUNIT/2))
		end
		
		//Vertical movement
		if not(player.iseggrobo or player.isjettysyn)
			player.jumpfactor = B.TwoDFactor(skin.jumpfactor*3/4)
			if not(grounded or player.powers[pw_tailsfly] or player.climbing)
				P_SetObjectMomZ(mo,-(B.TwoDFactor(FRACUNIT/2)-(FRACUNIT/2)),1)
			end
		end
		
	//In 3D...
	elseif player.battleintwod
		player.battleintwod = false
		player.jumpfactor = skin.jumpfactor
		player.thrustfactor = skin.thrustfactor
		player.runspeed = skin.runspeed
	end
end