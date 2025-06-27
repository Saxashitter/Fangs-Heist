local B = CBW_Battle

local st_idle = 0
local st_hold = 1
local st_release = 2
local st_jump = 3

local function twin(player, battletwin)
	if not(battletwin)
		player.panim = PA_ABILITY
		player.mo.state = S_PLAY_TWINSPIN
		player.pflags = $|PF_THOKKED|PF_NOJUMPDAMAGE
		S_StartSound(player.mo,sfx_s3k42)
	else
		player.mo.state = S_PLAY_BATTLETWINSPINJUMP
		player.pflags = ($|PF_THOKKED|PF_JUMPED|PF_SPINNING) &~ PF_NOJUMPDAMAGE
		S_StartSound(player.mo,sfx_zoom)
	end
	player.frame = 0
	
	//Angle adjustment
	player.drawangle = player.mo.angle
end

B.TwinSpinJump = function(player, lastbutton, variable) --Double jump function
	if player.pflags&PF_THOKKED
	or not(player.pflags&PF_JUMPED)
	or lastbutton and player.buttonhistory & lastbutton
		return
	end
	
	local mo = player.mo
	mo.momx = $ * 2/3
	mo.momy = $ * 2/3
	
-- 	local jumpthrust = FRACUNIT*39/4
-- 	B.ZLaunch(mo,jumpthrust,false)
	
-- 	S_StartSound(mo,sfx_cdfm02)
	S_StopSoundByID(mo,sfx_jump)
	player.drawangle = mo.angle
	mo.twinspinjump = {tics = 12}
	twin(player, true)
	player.pflags = $|PF_JUMPED|PF_STARTJUMP
	return true
end

B.TwinSpin = function(player, lastbutton, variable)
	if player.pflags&PF_THOKKED
	or not(player.pflags&PF_JUMPED)
	or lastbutton and player.buttonhistory & lastbutton
		return
	end
	local mo = player.mo
	
	twin(player)
	
	for n = -2,2 do
		local msl = P_SpawnMobjFromMobj(mo, 0, 0, 0, MT_LHRT)
		if msl and msl.valid
			msl.target = mo
			msl.extravalue2 = FRACUNIT*95/100
			msl.fuse = 15
			msl.flags = $
			local speed = mo.scale * 20
			local xyangle = mo.angle
			local zangle = n*ANG1*5
			B.InstaThrustZAim(msl,xyangle,zangle,speed,false)
			msl.momx = $ + mo.momx
			msl.momy = $ + mo.momy
			msl.momz = $ + mo.momz			
			if n == 0
				S_StartSound(msl, sfx_hoop1)
			end
		end
	end
	return true
end

B.TwinSpinControl = function(player, lastbutton, variable)
	local mo = player.mo	
	if mo.state == S_PLAY_TWINSPIN
		player.reflectarmor = max($, 1)
	end
	if (mo.twinspinjump)
		if mo.state != S_PLAY_BATTLETWINSPINJUMP
			mo.twinspinjump = nil
		else
			player.reflectarmor = max($, 1)
			player.lockaim = true
			player.lockmove = true
			mo.twinspinjump.tics = $-1
			mo.momz = 0
			B.XYLaunch(mo, mo.angle, FRACUNIT*30, false)
			P_SetObjectMomZ(mo, gravity, false)
			
			if mo.twinspinjump.tics <= 0
				-- Deactivate
				B.XYLaunch(mo, mo.angle, FRACUNIT*10, false)
				mo.state = S_PLAY_FALL
				mo.twinspinjump = nil
				player.pflags = ($|PF_NOJUMPDAMAGE) &~ PF_SPINNING
			end
		end
	end
end

//Wave spawning function
local function SpawnWave(player,angle_offset,mute)
	local mo = player.mo
	local wave = P_SPMAngle(mo,MT_PIKOWAVE,player.drawangle + angle_offset)
	if wave and wave.valid
		if G_GametypeHasTeams() and player.ctfteam == 2
			wave.teamcolor = SKINCOLOR_SAPPHIRE
		else
			wave.teamcolor = SKINCOLOR_RUBY
		end
		wave.mute = mute
		if not(wave.mute)
			S_StartSound(wave,sfx_nbmper)
		end
		wave.color = SKINCOLOR_GOLD
		wave.fuse = 18
		wave.scale = mo.scale
	end
end

local function hammerjump(player,power)
	local h = power and 6 or 2
	local v = power and 13 or 10
		
	local mo = player.mo
	//P_DoJump(player,false)
	B.ZLaunch(mo,FRACUNIT*v,true)
	P_Thrust(mo,player.drawangle,h*mo.scale)
	S_StartSound(mo,sfx_cdfm37)
	S_StartSoundAtVolume(mo,sfx_s3ka0,power and 255 or 100)
	player.pflags = ($ | PF_JUMPED | PF_STARTJUMP) & ~(PF_NOJUMPDAMAGE | PF_THOKKED)
	mo.state = S_PLAY_ROLL
	player.panim = PA_ROLL
end

//Hammer ticframe control
B.HammerControl = function(player, lastbutton, variable)
	//Initialize variables
	if player.melee_state == nil player.melee_state = 0 end
	if player.melee_charge == nil player.melee_charge = 0 end

	local mo = player.mo
	
	if mo.state == S_PLAY_TWINSPIN
		//Angle adjustment
		player.drawangle = mo.angle
		return
	end
	
	player.charability2 = CA2_MELEE
	if P_PlayerInPain(player) or player.powers[pw_nocontrol] or player.playerstate != PST_LIVE
		player.melee_state = st_idle
		return
	end

	if not(P_IsObjectOnGround(mo))
		if (mo.state != S_PLAY_MELEE and mo.state != S_PLAY_MELEE_FINISH)
			player.melee_state = st_idle
			return
		end
		if (player.melee_state == st_hold)
			player.melee_state = st_idle
			mo.state = S_PLAY_FALL
		end
	end
	
	if player.melee_state == st_hold
		if not(player.cmd.buttons & BT_SPIN)
			S_StartSound(mo,sfx_s3k42)
			if player.melee_charge >= FRACUNIT
				B.ZLaunch(mo, FRACUNIT*4, true)
			else
				B.ZLaunch(mo, FRACUNIT*3, true)
			end
			P_Thrust(mo, mo.angle, 9*mo.scale)
			player.melee_state = st_release
			mo.state = S_PLAY_MELEE
		elseif player.melee_charge >= FRACUNIT
			B.DrawAimLine(player, mo.angle)
		end
	end
	
	if player.melee_state != st_idle and mo.state != S_PLAY_MELEE and P_IsObjectOnGround(mo)
		if player.melee_state == st_jump or player.cmd.buttons&BT_JUMP
			//Hammer jump
			if player.melee_charge >= FRACUNIT
				hammerjump(player,true)
			else
				hammerjump(player,false)
			end
		elseif player.melee_charge >= FRACUNIT
			SpawnWave(player,0,false)
		end
		player.melee_state = st_idle
	end
	
	if player.melee_state != st_hold and player.melee_state != st_idle
		player.reflectarmor = max($, 1)
	end
end

B.ChargeHammer = function(player, lastbutton, variable)	
	local mo = player.mo
	
	if player.melee_state > 1
	or not(P_IsObjectOnGround(mo))
	or not(player.melee_state or not(player.pflags&PF_USEDOWN))
	return end
	
	//Angle adjustment
	player.drawangle = mo.angle

	//Start Charge
	if player.melee_state == st_idle
		player.melee_state = st_hold
		player.melee_charge = 0
	end
	
	//Jump cancel
	if player.melee_state == st_hold and player.cmd.buttons&BT_JUMP
		S_StartSound(mo,sfx_s3k42)
		B.ZLaunch(mo, FRACUNIT*3, true)
		P_Thrust(mo, mo.angle, 9*mo.scale)
		player.melee_state = st_jump
	end	
	
	//Do "skidding" effects
	if leveltime%3 == 1 and player.speed > 3*mo.scale then
		S_StartSound(mo,sfx_s3k7e,player)
		local r = mo.radius/FRACUNIT
		P_SpawnMobj(
			P_RandomRange(-r,r)*FRACUNIT+mo.x,
			P_RandomRange(-r,r)*FRACUNIT+mo.y,
			mo.z,
			MT_DUST
		)
	end
	
	//Hold Charge
	if player.melee_charge < FRACUNIT
		//Add Charge
		local chargetime = 18
		player.melee_charge = $+FRACUNIT/chargetime
		local offset_angle = mo.angle + ANGLE_180
		local offset_dist = mo.radius*3
		local range = 8
		local offset_x = P_ReturnThrustX(nil,offset_angle,offset_dist) + P_RandomRange(-range,range)*FRACUNIT
		local offset_y = P_ReturnThrustY(nil,offset_angle,offset_dist) + P_RandomRange(-range,range)*FRACUNIT
		local offset_z = mo.height/2 + P_RandomRange(-range,range)*FRACUNIT * P_MobjFlip(mo)
		offset_x = FixedMul($, mo.scale)
		offset_y = FixedMul($, mo.scale)
		offset_z = FixedMul($, mo.scale)
		if not(leveltime&3)
			//Do Sparkle
			P_SpawnMobj(
				mo.x+offset_x,
				mo.y+offset_y,
				mo.z+offset_z,
				MT_SPARK
			)
		end
		//Get Charged FX
		if player.melee_charge >= FRACUNIT
			S_StartSound(mo,sfx_hamrc)
			player.melee_charge = FRACUNIT
			local z = mo.z
			if P_MobjFlip(mo) == -1
				z = $+mo.height-mobjinfo[MT_SUPERSPARK].height
			end
			//P_SpawnParaloop(mo.x, mo.y, z, mo.scale<<6,8,MT_SPARK,ANGLE_90,nil,1)
			local spark = P_SpawnMobj(
				mo.x+offset_x,
				mo.y+offset_y,
				mo.z+offset_z - (mo.scale*10),
				MT_SUPERSPARK
			)
			spark.scale = mo.scale * 5/3
			spark.destscale = 0
			spark.color = SKINCOLOR_ROSY
			spark.colorized = true
			P_SpawnParaloop(mo.x, mo.y, z, mo.scale<<8,16,MT_NIGHTSPARKLE,ANGLE_90,nil,1)
		end
	end
	//Visual
	mo.state = S_PLAY_MELEE
	mo.frame = 0
	player.charability2 = CA2_NONE //Make Amy vulnerable during holding frames
	return true
end