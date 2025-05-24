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
        tics = -1
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

local function zpos(posmo, item)
	return (posmo.z + (posmo.height - mobjinfo[item].height)/2)
end

local function newGunslinger(player)
	local mo = player.mo
	local onground = P_IsObjectOnGround(mo)
	local canstand = true
	
	//State: ready to gunsling
	if not ((player.pflags & (PF_SLIDING|PF_BOUNCING|PF_THOKKED)) or (player.exiting) or (P_PlayerInPain(player)))
	--and not (player.powers[pw_flashing]) -- i HATE player.powers[pw_flashing] >:( -pac
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
					bullet.momx = $*3/5
					bullet.momy = $*3/5
					bullet.momz = 2*FU*P_MobjFlip(bullet)
				end
			// end
			player.drawangle = mo.angle
			S_StartSoundAtVolume(mo,sfx_s1c4,150)
			//Air function
			if not(P_IsObjectOnGround(mo))
				player.pflags = $|PF_THOKKED
				if not p.heist:hasSign(player) then
					player.pflags = $ & ~PF_JUMPED|PF_STARTJUMP
					P_SetObjectMomZ(mo,max(mo.momz*P_MobjFlip(mo)*5/4, FRACUNIT*6))
					if mo.momz*P_MobjFlip(mo) > FRACUNIT*10 then
						player.pflags = $|PF_JUMPED|PF_STARTJUMP
					end
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

return module