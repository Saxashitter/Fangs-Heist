//Scripts by CobaltBW, with some code borrowed from TehRealSalt
//Updated by Zippy_Zolton to utilize SPR2.

local module = {}

//Define air shooting sprites
freeslot("SPR2_FAIR","S_PLAY_AIRFIRE1","S_PLAY_AIRFIRE2","S_PLAY_AIRKICK")
states[S_PLAY_AIRFIRE1] = {
        sprite = SPR_PLAY,
        frame = SPR2_FAIR,
        tics = -1,
}
states[S_PLAY_AIRFIRE2] = {
        sprite = SPR_PLAY,
        frame = SPR2_FAIR,
        tics = -1,
}
states[S_PLAY_AIRKICK] = {
        sprite = SPR_PLAY,
        frame = SPR2_FALL,
        tics = -1,
}

local refiretime = 24
local airstate1 = S_PLAY_AIRFIRE1
local airstate2 = S_PLAY_AIRFIRE2
module.isGunslinger = function(player)
	return skins[player.skin].ability2 == CA2_GUNSLINGER
end
module.isBounce = function(player)
	// this wont actually be a bounce, but rather a spinning kick that fang can use for pvp
	return skins[player.skin].ability == CA_BOUNCE
end

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
		if mo.player and 
			(
			mo.player.spectator
			or gametyperules&GTR_FRIENDLY
			or G_GametypeHasTeams() and mo.player.ctfteam == player.ctfteam
			)
		then return end //Disallow targeting teammates


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
	and not (player.powers[pw_flashing])
	and not (player.weapondelay)
	and not (player.panim == PA_ABILITY2)
	and (player.pflags&PF_JUMPED or onground)
		//Trigger firing action
		if (player.cmd.buttons & BT_USE)
		and not(player.lastbuttons&BT_USE)
			local bullet = nil

			mo.state = S_PLAY_FIRE
			player.panim = PA_ABILITY2
			player.weapondelay = refiretime
			/*if (lockon and lockon.valid)
				mo.angle = R_PointToAngle2(mo.x, mo.y, lockon.x, lockon.y)
				bullet = P_SpawnPointMissile(
					mo,
					lockon.x, lockon.y, zpos(lockon, player.revitem),
					player.revitem,
					mo.x, mo.y, zpos(mo, player.revitem)
				)

			else*/
				bullet = P_SpawnPointMissile(
					mo,
					mo.x + P_ReturnThrustX(nil, mo.angle, FRACUNIT*10),
					mo.y + P_ReturnThrustY(nil, mo.angle, FRACUNIT*10),
					zpos(mo, player.revitem),
					player.revitem,
					mo.x, mo.y, zpos(mo, player.revitem)
				)

				if (bullet and bullet.valid)
					bullet.flags = $1 & ~MF_NOGRAVITY
					bullet.momx = $*3/2
					bullet.momy = $*3/2
					bullet.momz = 2*FU*P_MobjFlip(bullet)
				end
			// end
			player.drawangle = mo.angle
			S_StartSoundAtVolume(mo,sfx_s1c4,150)
			//Air function
			if not(P_IsObjectOnGround(mo))
				player.pflags = $|PF_THOKKED
				if not FangsHeist.playerHasSign(player) then
					P_SetObjectMomZ(mo,max(mo.momz*P_MobjFlip(mo)*5/4, FRACUNIT*4))
				end
				P_SetMobjStateNF(mo,airstate1)
				player.mo.sprite2 = SPR2_FAIR
				player.airgun = true
				
			end
		end
	end
	//Running and gunning
	local spd = FixedHypot(player.rmomx,player.rmomy)
	local dir = R_PointToAngle2(0,0,player.rmomx,player.rmomy)
	local thres = mo.scale*4
	if (player.panim == PA_ABILITY2) and spd > thres and P_IsObjectOnGround(player.mo)
		spd = max(thres,$-FRACUNIT)
		mo.momx = player.cmomx+P_ReturnThrustX(nil,dir,spd)
		mo.momy = player.cmomy+P_ReturnThrustY(nil,dir,spd)
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
	if player.panim == PA_ABILITY2 and P_IsObjectOnGround(mo) and player.cmd.buttons&BT_JUMP and not(player.lastbuttons&BT_JUMP)
		mo.state = S_PLAY_WALK
	end
	
	//Air gunning
	if not(P_IsObjectOnGround(mo)) and player.airgun == true and player.weapondelay
		if player.weapondelay < refiretime-1 and player.weapondelay > refiretime-3
			P_SetMobjStateNF(mo,airstate2)
		elseif player.weapondelay < refiretime-4
			P_SetMobjStateNF(mo,airstate1)
		end
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


////
//Hooks

//Input control before movement is handled
-- addHook("PreThinkFrame",do
-- 	for player in players.iterate
-- 		if not(
-- 			module.isGunslinger(player)
-- 			and player.panim == PA_ABILITY2
-- 			)
-- 		return end
-- 		if player.pflags&PF_AUTOBRAKE then
-- 			player.cmd.forwardmove = max(-1,min(1,$))
-- 			player.cmd.sidemove = max(-1,min(1,$))
-- 		else
-- 			player.cmd.forwardmove = 0
-- 			player.cmd.sidemove = 0
-- 			player.cmd.angleturn = player.realmo.angle>>FRACBITS
-- 		end
-- 	end
-- end)

//Main body for popgun firing control	
module.playerThinker = function(player)
	if not(module.isGunslinger(player) and FangsHeist.isPlayerAlive(player))
		player.airgun = false
		return end

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
	or player.pflags&PF_SPINNING
		player.airgun = false
	return end

	//Do Gunslinger
	newGunslinger(player)
	//Make SPR2 behave
	if (player.mo.state == S_PLAY_AIRFIRE1) then
		player.mo.frame = 0
	end
	if (player.mo.state == S_PLAY_AIRFIRE2) then
		player.mo.frame = 1
	end
end

module.kickThinker = function(player)
	if not(module.isBounce(player)) return end
	if not(FangsHeist.isPlayerAlive(player)) return end

	if player.mo.state == S_PLAY_AIRKICK then
		local gravity = P_GetMobjGravity(player.mo)

		player.powers[pw_strong] = $|STR_ATTACK
		player.mo.momz = $-gravity/2
		player.drawangle = player.mo.angle + FixedAngle(((leveltime*45/2)%360)*FU)
		if not (leveltime % 3) then
			P_SpawnGhostMobj(player.mo)
		end
	else
		player.powers[pw_strong] = $ & ~STR_ATTACK
	end
end

module.doAirKick = function(player)
	player.mo.state = S_PLAY_AIRKICK
	player.pflags = $ & ~(PF_JUMPED|PF_STARTJUMP)
	P_SetObjectMomZ(player.mo, 3*FU)
	S_StartSound(player.mo, sfx_spndsh)
	player.pflags = $|PF_THOKKED
end

return module