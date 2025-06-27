//Original scripts by TehRealSalt, modified by CobaltBW

local B = CBW_Battle

local refiretime = 22

local function newGunLook(player) 
	local twod = (twodlevel or player.mo.flags2 & MF2_TWOD)
	local ringdist, span
	if not(twod)
		ringdist = RING_DIST*2
		span = ANG30
	else
		ringdist = RING_DIST
		span = ANG20
	end

	local maxdist = FixedMul(ringdist, player.mo.scale)
	local closestdist = 0
	local closestmo = nil
	local nonenemiesdisregard = MF_SPRING
	searchBlockmap("objects",function(pmo,mo)
		if (mo.flags & MF_NOCLIPTHING) return end
		if (mo.health <= 0) return end -- dead

		if not(mo.player)
		and (!((mo.flags & (MF_ENEMY|MF_BOSS|MF_MONITOR)
		and (mo.flags & MF_SHOOTABLE)) or (mo.flags & MF_SPRING)) == !(mo.flags2 & MF2_INVERTAIMABLE)) -- allows if it has the flags desired XOR it has the invert aimable flag
			return -- not a valid target
		end
		//CTF monitor 
		if mo.type == MT_RING_REDBOX and not(G_GametypeHasTeams() and player.ctfteam == 1) then return end
		if mo.type == MT_RING_BLUEBOX and not(G_GametypeHasTeams() and player.ctfteam == 2) then return end

		if (mo == pmo) return end
		if (mo.flags2 & MF2_FRET) return end
		if (mo.flags & nonenemiesdisregard) return end
		if (mo.type == MT_TARGETDUMMY) return end //We won't be relying on this for player detection
		if (mo.player and (B.MyTeam(player,mo.player) or mo.player.spectator)) then return end //Disallow targeting teammates
		if (mo.player and mo.player.intangible) then return end//Disallow targeting air dodge

		//Do angle/distance checks
		local zdist = (pmo.z + pmo.height/2) - (mo.z + mo.height/2)
		local dist = P_AproxDistance(pmo.x-mo.x, pmo.y-mo.y)
		//CBW: 	Made the angle checks their own locals, for readability purposes
		//		I also unsigned the angle checks, which appears to correct failed OutOfBounds checks above the player.
		local xyz_angle = abs(R_PointToAngle2(0, 0, dist, zdist))
		local xy_angle = abs(R_PointToAngle2(
				pmo.x + P_ReturnThrustX(pmo, pmo.angle, pmo.radius),
				pmo.y + P_ReturnThrustY(pmo, pmo.angle, pmo.radius),
				mo.x, mo.y
			) - pmo.angle)
			
			
		dist = P_AproxDistance(dist, zdist)
		if (dist > maxdist)
			return -- out of range
		end
-- 		print("\x82!!!VERT","# Span check: "..xyz_angle/ANG1,"# Limit: "..span*2/ANG1,"#Within Range: "..tostring(abs(xyz_angle) <= span))
		if (xyz_angle > span)
			return -- Don't home outside of desired angle!
		end


		if (twod
		and abs(pmo.y-mo.y) > pmo.radius)
			return -- not in your 2d plane
		end

		if ((closestmo and closestmo.valid) and (dist > closestdist))
			return
		end
-- 		print("\x82!!!HORZ","# Span check: "..xy_angle/ANG1,"# Limit: "..span*2/ANG1,"#Within Range: "..tostring(abs(xy_angle) <= span))
		if (xy_angle > span)
			return -- behind back
		end

		if not (P_CheckSight(pmo, mo))
			return -- out of sight
		end

		closestmo = mo
		closestdist = dist
	end,player.mo,player.mo.x-maxdist,player.mo.x+maxdist,player.mo.y-maxdist,player.mo.y+maxdist)
	return closestmo
end

local function zpos(posmo, item)
	return (posmo.z + (posmo.height - mobjinfo[item].height)/2)
end

local function newGunslinger(player)
	local mo = player.mo
	local onground = P_IsObjectOnGround(mo)
	local canstand = true
	
	//State: ready to gunsling
	if not ((player.pflags & (PF_SLIDING|PF_BOUNCING|PF_THOKKED)) or (player.exiting) or (P_PlayerInPain(player)))
	and not (player.weapondelay)
	and not (player.panim == PA_ABILITY2)
	and (player.pflags&PF_JUMPED or onground)
		-- Same code as vanilla, but without the clause for speed.
		-- You naturally lose your speed via friction.

		local lockon = newGunLook(player)
		if (lockon and lockon.valid)
			P_SpawnLockOn(player, lockon, mobjinfo[MT_LOCKON].spawnstate)
		end
		//Trigger firing action
		if (player.cmd.buttons & BT_SPIN)
		and not(player.buttonhistory&BT_SPIN)
			local bullet = nil

			mo.state = S_PLAY_FIRE
			player.panim = PA_ABILITY2
			player.weapondelay = refiretime
			mo.momx = $ * 2/3
			mo.momy = $ * 2/3
			S_StartSoundAtVolume(mo,sfx_s1c4,150)
			
			if player == consoleplayer
				P_StartQuake(4*FRACUNIT,1)
			end
			
			if (lockon and lockon.valid)
				mo.angle = R_PointToAngle2(mo.x, mo.y, lockon.x, lockon.y)
				bullet = P_SpawnPointMissile(
					mo,
					lockon.x, lockon.y, zpos(lockon, player.revitem),
					player.revitem,
					mo.x, mo.y, zpos(mo, player.revitem)
				)

			else
				bullet = P_SpawnPointMissile(
					mo,
					mo.x + P_ReturnThrustX(nil, mo.angle, FRACUNIT),
					mo.y + P_ReturnThrustY(nil, mo.angle, FRACUNIT),
					zpos(mo, player.revitem),
					player.revitem,
					mo.x, mo.y, zpos(mo, player.revitem)
				)

				if (bullet and bullet.valid)
					bullet.flags = $1 & ~MF_NOGRAVITY
					bullet.momx = $1 / 2
					bullet.momy = $1 / 2
				end
			end
-- 	 			player.gunheld = true
			player.drawangle = mo.angle
			//Air function
			if not(P_IsObjectOnGround(mo))
				B.ResetPlayerProperties(player,false,true)
				P_Thrust(mo,mo.angle+ANGLE_180,mo.scale*10)
				P_SetObjectMomZ(mo,FRACUNIT*5,true)
				mo.momx = $/2
				mo.momy = $/2
				mo.momz = $/2
				mo.state = S_PLAY_JUMPFIRE
				player.airgun = true
			else
				P_Thrust(mo,mo.angle+ANGLE_180,mo.scale*3)
			end
		end
	end
	//Running and gunning
	local spd = FixedHypot(player.rmomx,player.rmomy)
	local dir = R_PointToAngle2(0,0,player.rmomx,player.rmomy)
	local thres = mo.scale*4
	if (player.panim == PA_ABILITY2) and spd > thres and P_IsObjectOnGround(player.mo)
		//spd = max(thres,$-FRACUNIT)
		//mo.momx = player.cmomx+P_ReturnThrustX(nil,dir,spd)
		//mo.momy = player.cmomy+P_ReturnThrustY(nil,dir,spd)
-- 		mo.frame= min(6,$)
-- 		print(mo.sprite2)
-- 		if mo.frame == 3 then
-- 	 		mo.tics = $+1
-- 		end
		//Do "skidding" effects
		if player.weapondelay%3 == 1 then
			S_StartSound(mo,sfx_s3k7e,player)
			local r = mo.radius/FRACUNIT
			P_SpawnMobj(
				P_RandomRange(-r,r)*FRACUNIT+mo.x,
				P_RandomRange(-r,r)*FRACUNIT+mo.y,
				mo.z,
				MT_DUST
			)
		end
	end
	//Running and jumping
	if player.panim == PA_ABILITY2 and P_IsObjectOnGround(mo) and player.cmd.buttons&BT_JUMP and not(player.buttonhistory&BT_JUMP)
		mo.state = S_PLAY_WALK
	end
	
	//Air gunning
	if not(P_IsObjectOnGround(mo)) and player.airgun == true and player.weapondelay
		player.drawangle = mo.angle
		player.pflags = $|PF_JUMPDOWN
	end	
	if P_IsObjectOnGround(mo) and player.airgun == true
		player.airgun = false
		if (player.weapondelay) then
			mo.state = S_PLAY_FIRE_FINISH
			mo.tics = player.weapondelay
		end
	end
end

B.CustomGunslinger = function(player)
	if not(player.mo) return end
	if not(B.GetSkinVarsFlags(player)&SKINVARS_GUNSLINGER) return end
	//Disallow native CA2_GUNSLINGER functionality
	if player.charability2 == CA2_GUNSLINGER
		player.charability2 = CA2_NONE
	end
	//Player is damaged
	
	if P_PlayerInPain(player)
		player.airgun = false
	return end

	//Unable to use gun during certain states
	if player.powers[pw_nocontrol]
	or player.powers[pw_carry]
	or player.actionstate
	or player.pflags&PF_SPINNING
		player.airgun = false
	return end
	//Get inputs
	if (player.gunheld == nil)
		player.gunheld = false
	end

	if not (player.cmd.buttons & BT_SPIN)
		player.gunheld = false
	end

	//Do Gunslinger
	newGunslinger(player)
end

B.PreGunslinging = function(player)
	if not(player.mo
	and B.GetSkinVarsFlags(player,SKINVARS_GUNSLINGER)
	and player.panim == PA_ABILITY2)
	return end
	if player.pflags&PF_AUTOBRAKE then
		player.cmd.forwardmove = max(-1,min(1,$))
		player.cmd.sidemove = max(-1,min(1,$))
	else
		player.cmd.forwardmove = 0
		player.cmd.sidemove = 0
	end
-- 	player.cmd.buttons = $&~BT_JUMP
end
		


