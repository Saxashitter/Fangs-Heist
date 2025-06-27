local B = CBW_Battle
local CV = B.Console
local A = B.Arena

local attack_lag1 = TICRATE/2 //Start-up lag
local attack_lag2 = TICRATE/2 //End lag
local attack_lag3 = TICRATE //Firing cooldown
local state_attacking = 1
local state_endlag = 2

A.CheckRevenge = function(player)
	if B.BattleCampaign() return false end //Campaign does not allow revenge mechanics
	if not(CV.Revenge.value) then return false end //revenge must be enabled by server
	if not(player) then return true end //Above is the only check necessary if the player isn't defined
	local mo = player.mo
	if not(mo and mo.valid) then return false end //validity check
	if not(player.revenge) then return false end //revenge gate
	return true //All checks passed
end

A.PlayerIsJettySyn = function(player)
	local mo = player.mo
	if not(mo and mo.valid) then return false end //validity check
	return (player.isjettysyn) 
end

A.JettySynFlags = function(player,stat)
	//Enable
	if(stat) then
		player.isjettysyn = true
		if player.mo and player.mo.valid then
			player.mo.flags = $|MF_NOGRAVITY|MF_SLIDEME
		end
		player.pflags = $|PF_THOKKED
		player.charflags = $&~SF_DASHMODE
		player.charability = CA_NONE
		player.charability2 = CA2_NONE
		player.jumpfactor = 0
		player.normalspeed = FRACUNIT*12
		player.powers[pw_shield] = SH_PROTECTWATER
		player.powers[pw_carry] = -1
	return true end
	//Disable
	player.isjettysyn = false
	player.revenge = false
	if player.mo and player.mo.valid  then
		local skin = skins[player.mo.skin]
		player.charflags = skin.flags
		player.charability = skin.ability
		player.charability2 = skin.ability2
		player.jumpfactor = skin.jumpfactor
		player.normalspeed = skin.normalspeed
		player.mo.flags = $&~(MF_NOGRAVITY|MF_SLIDEME)
		player.powers[pw_shield] = 0
		player.powers[pw_carry] = 0
	end
	return false
end

A.JettySynThinker = function(player)
	if CV.Revenge.value == 0 and player.revenge then 
		A.JettySynFlags(player,false)
	end
	
	if not(A.PlayerIsJettySyn(player) or A.CheckRevenge(player)) then 
	return end
	//Set flags
	A.JettySynFlags(player,true)
	
	//Pinch/Sudden Death
	local mo = player.mo
	if player.mo and player.mo.valid then player.mo.flags2 = $|MF2_DONTDRAW end
	if mo and mo.valid and (B.Overtime) then
		mo.flags = ($|MF_NOCLIPTHING)&~MF_SPECIAL
		player.powers[pw_nocontrol] = $|2
		player.powers[pw_flashing] = $|2
		mo.momx = 0
		mo.momy = 0
		mo.momz = 0
	return end
	
	//In Pain
	if P_PlayerInPain(player) or not(player.playerstate == PST_LIVE) then 
		player.battle_atk = 0
		player.actionstate = 0
		if player.mo.tics > TICRATE*2 then
			player.mo.tics = TICRATE*2
		end
		player.drawangle = player.mo.angle+ANGLE_180+player.mo.tics*ANG30
		A.JettySynPhysics(player,FRACUNIT*99/100)
	return end
	
	//Spawning
	if player.battlespawning then
		player.drawangle = player.battlespawning*ANG30
	return end
	
	local mo = player.mo
	
	//Physics

	A.JettySynAir(player)

	//Attack function
	A.JettySynAttack(player)

	//Aesthetic
	if B.PlayerButtonPressed(mo.player,BT_JUMP,false)
		S_StartSound(mo,sfx_s3ka0)
	end
end

A.JettySynAttack = function(player)
	local mo = player.mo
	player.actiontime = $+1
	//Default state
	if player.actionstate == 0 then
		//Set up the gates
		if player.powers[pw_flashing] then return end
		if player.actiontime < 0 then return end
		//Pull the trigger
		if B.PlayerButtonPressed(player,BT_SPIN,false)
		or B.PlayerButtonPressed(player,player.battleconfig_special,false)
		
		then
			player.actionstate = state_attacking
			player.actiontime = 0
		else return end
	end
	
	//Attack telegraph
	if player.actionstate == state_attacking then
		//Hold the player still
-- 		player.lockaim = true
		B.DrawAimLine(player)
		player.powers[pw_nocontrol] = $|2
		A.JettySynPhysics(player,FRACUNIT*95/100)//Apply friction
		//Time to fire shot
		if player.actiontime >= attack_lag1
			player.actiontime = 0
			player.actionstate = state_endlag
			player.lockaim = true
			player.lockmove = true
			P_SPMAngle(mo,MT_JETTBULLET,mo.angle,0)
			P_InstaThrust(mo,mo.angle,-FRACUNIT*10) //Blow-back
			S_StartSound(mo,sfx_s3k4d)
		else return end
	end
	
	//Post-attack
	if player.actionstate == state_endlag then
		//Continue holding the player still (allow recoil to take effect)
		player.lockaim = true
		player.lockmove = true
		player.powers[pw_nocontrol] = $|2
		A.JettySynPhysics(player,FRACUNIT*95/100)
		//Back to neutral
		if player.actiontime >= attack_lag2 then
			player.actionstate = 0
			player.actiontime = -attack_lag3 //Set the amount of time before player can fire again
		end
	end
end

A.JettySynAir = function(player)
	//Control gate
	if player.powers[pw_nocontrol] > 0 or P_PlayerInPain(player) then return end
	//Set values
	local mo = player.mo
	local water = B.WaterFactor(mo)
	local zaccel = FRACUNIT/2/water
	local limit = FRACUNIT*8/water
	//Apply Z thrusts
	if player.cmd.buttons&BT_JUMP then
		P_SetObjectMomZ(mo,zaccel,1)
	elseif not(P_IsObjectOnGround(mo))
		P_SetObjectMomZ(mo,-zaccel,1)
	end
	//Apply air speed limit
	mo.momz = min(limit,max(-limit,$))
end

A.JettySynPhysics = function(player,friction,limit)
	local mo = player.mo
	//Friction
	if friction == nil then friction = mo.friction end
	if P_IsObjectOnGround(mo) then
		mo.friction = friction
	else
		//Enforce speed cap
		if limit == nil then
			limit = player.normalspeed
		end
		limit = FixedMul(FRACUNIT,$)
		local spd = min(limit,max(-limit,
			FixedHypot(mo.momx,mo.momy)
		))
		friction = FixedMul(mo.scale,$)
		//XY movement
		spd = FixedMul(spd,friction)
		local ang = R_PointToAngle2(0,0,mo.momx,mo.momy)
		mo.momx = P_ReturnThrustX(nil,ang,spd)
		mo.momy = P_ReturnThrustY(nil,ang,spd)
		//Z movement
		mo.momz = min(limit,max(-limit,
			FixedMul($,friction)
		))
	end
end

A.Avenge = function(player)
	if player.playerstate != PST_LIVE then return end //Can't revive players who have just been killed
	B.PrintGameFeed(player," was brought back into the game!")
	A.JettySynFlags(player,false)
	player.actionstate = 0
	player.actiontime = 0
	if player.mo and player.mo.valid then
		S_StartSound(player.mo,sfx_cdfm73)
		B.PlayerBattleSpawnStart(player)
-- 		player.mo.state = S_PLAY_ROLL
-- 		player.pflags = ($|PF_JUMPED)&~PF_THOKKED
-- 		P_SetObjectMomZ(player.mo,FRACUNIT*20,0)
-- 		S_StartSound(player.mo,sfx_spin)
	end
end

A.RevengeDamage = function(target,inflictor,source)
	if not(target.player) then return end //Inflicted must be a player
	//Inflicted is a revenge jettysyn
	if target.player.isjettysyn then
		target.player.powers[pw_shield] = SH_PITY //Grant pity so we don't die but still do the whole pain routine
	return end
	if CV.Revenge.value != 2 then return end
	
	//Inflictor/Source is a revenge jettysyn
	if inflictor and inflictor.valid and inflictor.type == MT_PLAYER and inflictor.player then
		if inflictor.player.revenge and not(target.player.revenge) then 
			A.Avenge(inflictor.player)
		end
	end
	
	if source and source.valid and source.type == MT_PLAYER and source.player then
		if source.player.revenge and not(target.player.revenge) then
			A.Avenge(source.player)
		end
	end
end