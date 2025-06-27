local B = CBW_Battle

local ground_special = 1
local air_special = 10
local cooldown = TICRATE
local swirl1 = S_LHRT
local swirl2 = S_LHRT
local tornado_speed = FRACUNIT*10

B.Action.PikoTornado_Priority = function(player)
	if player.actionstate == ground_special or player.actionstate == air_special then
		B.SetPriority(player,2,3,nil,2,3,"piko spin technique")
	end
end

local function sparkle(mo)
	local spark = P_SpawnMobj(mo.x,mo.y,mo.z,MT_SPARK)
	if spark and spark.valid then
		B.AngleTeleport(spark,{mo.x,mo.y,mo.z},mo.player.drawangle,0,mo.scale*64)
		end
end

local function spinhammer(mo)
	mo.state = S_PLAY_MELEE
	mo.frame = 0
	mo.sprite2 = SPR2_MLEL
end

B.Action.PikoTornado = function(mo,doaction)
	local player = mo.player
	if P_PlayerInPain(player) then
		player.actionstate = 0
		player.actiontime = 0
	end
	if not(B.CanDoAction(player)) and not(player.actionstate) 
		if player.actiontime and mo.state == S_PLAY_MELEE_FINISH
			if mo.tics == -1
				mo.tics = 15
			else
				mo.tics = min($,15)
			end
			player.actiontime = 0
		end
	return end
	player.actiontime = $+1
	//Action Info
	if P_IsObjectOnGround(mo) and not(player.dustdevil and player.dustdevil.valid)
		player.actiontext = "Piko Tornado"
	else
		player.actiontext = "Piko Spin"
	end
	player.actionrings = 10
	//Neutral
	if player.actionstate == 0
		//Trigger
		if (doaction == 1) then
			if not(P_IsObjectOnGround(mo)) //Air
				B.PayRings(player)
				player.actionstate = air_special
				player.pflags = $|PF_THOKKED
				P_SetObjectMomZ(mo,FixedMul(player.jumpfactor,FRACUNIT*10/B.WaterFactor(mo)),0)
				player.actiontime = 0
				S_StartSound(mo,sfx_s3ka0)
			else //Ground
				B.PayRings(player)
				player.actionstate = ground_special
				B.ControlThrust(mo,mo.scale/4)
				player.actiontime = 0
				S_StartSound(mo,sfx_s3ka0)
			end
		end
	end
	//Ground Special
	if player.actionstate == ground_special then
		spinhammer(mo)

		player.powers[pw_nocontrol] = max($,2)
		sparkle(mo)
		if player.actiontime < 16 then
			player.drawangle = mo.angle+ANGLE_22h*player.actiontime
			P_Thrust(mo,mo.angle,mo.scale)
			if player.actiontime == 8 then
				S_StartSound(mo,sfx_s3k42)
			end
		else
			player.drawangle = mo.angle+ANGLE_45*(player.actiontime&7)
			P_Thrust(mo,mo.angle,mo.scale)
			if player.actiontime&7 == 4 then
				S_StartSound(mo,sfx_s3k42)
			end
		end
		if not(player.actiontime > TICRATE) then return end
		player.actionstate = $+1
		player.actiontime = 0
		player.drawangle = mo.angle
		//Do Missile
		if not(player.dustdevil and player.dustdevil.valid)
			local missile = P_SPMAngle(mo,MT_DUSTDEVIL_BASE,mo.angle)
			if missile and missile.valid then
				missile.color = player.skincolor
				if not(player.mo.flags2&MF2_TWOD or twodlevel) then
					missile.fuse = TICRATE*5
				else
					missile.fuse = 45
				end
				S_StartSound(missile,sfx_s3kb8)
				S_StartSound(missile,sfx_s3kcfl)	

				if G_GametypeHasTeams() then
					missile.color = mo.color
				end
-- 				if P_MobjFlip(mo) == -1 then
-- 					missile.z = $-missile.height
-- 					missile.flags2 = $|MF2_OBJECTFLIP
-- 					missile.eflags = $|MFE_VERTICALFLIP
-- 				end
				if missile.tracer and missile.tracer.valid then
					missile.tracer.target = player.mo
					if P_MobjFlip(mo) == -1 then 
						missile.tracer.z = $-missile.tracer.height
						missile.tracer.flags2 = $|MF2_OBJECTFLIP
						missile.tracer.eflags = $|MFE_VERTICALFLIP
					end					
				end
				player.dustdevil = missile
			end
		end
	end
	//End lag
	if player.actionstate == ground_special+1 
		player.powers[pw_nocontrol] = max($,2)
		if player.actiontime < TICRATE return end
		//Neutral
		B.ApplyCooldown(player,cooldown)
		player.actionstate = 0
		player.actiontime = 0
		mo.state = S_PLAY_WALK
	end
	//Air Special
	if player.actionstate == air_special then
		player.drawangle = mo.angle+ANGLE_45*(player.actiontime&7)
		if player.actiontime&7 == 4 then
			S_StartSound(mo,sfx_s3k7e)
		end
		spinhammer(mo)
		sparkle(mo)
		//Air control
		if player.pflags&PF_JUMPDOWN then
			P_SetObjectMomZ(mo,FRACUNIT/8,1)
		end
		//Neutral
		if P_IsObjectOnGround(mo) or player.actiontime > TICRATE*3/2 
		or mo.z+mo.momz < mo.floorz
			then
			mo.state = S_PLAY_FALL
			player.actionstate = 0
			player.actiontime = 0
			B.ApplyCooldown(player,cooldown)
			player.drawangle = player.mo.angle
		end
	end

end

B.DustDevilThinker = function(mo)
	local owner = mo.target
	local hurtbox = mo.tracer
	if not(owner and owner.valid and hurtbox and hurtbox.valid) then 
		P_RemoveMobj(mo)
	return end
	
	mo.angle = R_PointToAngle2(0,0,mo.momx,mo.momy)
-- 	local p = B.GetNearestPlayer(owner,nil,-1,nil,false)
-- 	if p then
-- 		mo.angle = R_PointToAngle2(mo.x,mo.y,p.mo.x,p.mo.y)
-- 	end
	local speed = FixedMul(tornado_speed,mo.scale)/B.WaterFactor(mo)
	if twodlevel or mo.flags2&MF2_TWOD then
		speed = $/2
	end
	hurtbox.angle = mo.angle
	hurtbox.hurtheight = min(FRACUNIT,$+FRACUNIT/35)
	P_Thrust(mo,mo.angle,speed)
	B.ControlThrust(mo,FRACUNIT,speed)
	if P_MobjFlip(mo) == 1 then
		P_TeleportMove(hurtbox,mo.x,mo.y,mo.z)
	else
		P_TeleportMove(hurtbox,mo.x,mo.y,mo.z+mo.height-hurtbox.height)
	end
	hurtbox.fuse = mo.fuse
	if not(leveltime&3) then
		for n = 1, 4
			local swirl = P_SpawnMobj(mo.x,mo.y,mo.z,MT_SWIRL)
			if swirl and swirl.valid then
				swirl.target = hurtbox
				swirl.angle = mo.angle+ANGLE_90*n
				swirl.color = B.Choose(mo.color,SKINCOLOR_SILVER)
				if P_MobjFlip(mo) == -1 then 
					swirl.flags2 = $|MF2_OBJECTFLIP
					swirl.eflags = $|MFE_VERTICALFLIP
				end
				if n&1 then
					swirl.swirltype = 1
					swirl.state = swirl1
					swirl.scale = $/4
-- 					swirl.rotatespeed = $*2
				else
					swirl.state = swirl2
					swirl.colorized = true
	-- 				swirl.flags2 = MF2_SHADOW
				end
				if n&2
					swirl.reach = 32*mo.scale
				end

-- 				swirl.reach = P_RandomRange(32,64)*mo.scale
-- 				swirl.rotatespeed = P_RandomRange(10,30)*ANG1
			end
		end
	end
end

B.SwirlSpawn = function(mo)
-- 	mo.rotatespeed = ANG15
	mo.rotatespeed = ANG30
-- 	mo.fusetime = TICRATE*2
	mo.fusetime = TICRATE
	mo.scale = $*3/4
	mo.fuse = mo.fusetime
	mo.reach = 0
	mo.swirltype = 0
end

B.SwirlThinker = function(mo)
	if not(mo and mo.valid and mo.target and mo.target.valid) then 
		P_RemoveMobj(mo)
	return end
	
	//Blink
	if mo.target.fuse < TICRATE then
		mo.flags2 = $^^MF2_DONTDRAW
	end
	//Regulate State
	if mo.swirltype == 0 then
		mo.state = swirl2
	else
		mo.state = swirl1
	end
	//Do swirl
	mo.angle = $+mo.rotatespeed
	local time = FRACUNIT*(mo.fusetime-mo.fuse)/mo.fusetime 
	local dist = B.FixedLerp(mo.target.minradius,mo.reach+mo.target.radius,time)
	local x = P_ReturnThrustX(nil,mo.angle,dist)
	local y = P_ReturnThrustY(nil,mo.angle,dist)
	local z
	if P_MobjFlip(mo) == 1 then 
		z = B.FixedLerp(0,mo.target.height-mo.height,time)
	else
		z = B.FixedLerp(mo.target.height-mo.height,0,time)	
	end
	P_TeleportMove(mo,mo.target.x+x,mo.target.y+y,mo.target.z+z)
end

B.DustDevilSpawn = function(mo)
	mo.tracer = P_SpawnMobj(mo.x,mo.y,mo.z,MT_DUSTDEVIL)
	if mo.tracer and mo.tracer.valid then
		mo.tracer.scale = mo.scale*4
		mo.tracer.minradius = mo.tracer.radius/4
		mo.tracer.hurtheight = 0
		if P_MobjFlip(mo) == -1 then 
			mo.tracer.flags2 = $|MF2_OBJECTFLIP
			mo.tracer.eflags = $|MFE_VERTICALFLIP
		end
	end
end

B.DustDevilTouch = function(dustdevil,collide)
	//Failsafe
	if dustdevil.hurtheight == nil then return end
	if not(dustdevil and dustdevil.valid and dustdevil.target and dustdevil.target.valid) then 
	return true end
	
	local push = false
	if collide.battleobject then push = true end
	local player = nil
	if collide.player then player = collide.player end
	
	//Get cone-like hit dimensions
	local w1 		= dustdevil.radius-dustdevil.minradius //Width of narrow end of cone
	local w2 		= dustdevil.radius //Width of wide end of cone
	local hurtheight	= max(FRACUNIT/35,FixedMul(dustdevil.hurtheight,dustdevil.height))
	
	local z,w //Nearest Z coordinate and its corresponding radius
	if not(dustdevil.flags2&MF2_OBJECTFLIP) then //Regular orientation
		//Z checks
		if dustdevil.z > collide.z+collide.height
		or collide.z > dustdevil.z+hurtheight
		return true end
		z	= //Get nearest z point
			min(dustdevil.z+hurtheight, //Max height: tornado base + hurtbox height
			max(dustdevil.z, //Min height: tornado base
			collide.z)) //Colliding object's lower z position
		w	= B.FixedLerp(w1,w2,FixedDiv(z-dustdevil.z,hurtheight)) //Get the interpolated width value corresponding to the nearest z point on hurtbox
	else //Flipped orientation
		if dustdevil.z+dustdevil.height < collide.z
		or collide.z+collide.height < dustdevil.z+dustdevil.height-hurtheight
		return true end
		z	= 
			min(dustdevil.z+dustdevil.height, //Max height: tornado base + "true" height 
			max(dustdevil.z+dustdevil.height-hurtheight, //Min height: tornado base + "true" height - hurtbox height
			collide.z+collide.height)) //Colliding object's upper z position
		w	= B.FixedLerp(w1,w2,-FixedDiv(z-dustdevil.z-dustdevil.height,hurtheight)) //flip args 1&2 to invert interpolation
	end
	local dist = R_PointToDist2(dustdevil.x,dustdevil.y,collide.x,collide.y)
	//No collision
	if dist > w then 
-- 		print("\x85"..hurtheight*100/dustdevil.height.."%..."..w*100/dustdevil.radius.."%..."..dist/FRACUNIT)
		return true
	end
-- 	print("\x83 "..hurtheight*100/dustdevil.height.."%..."..w*100/dustdevil.radius.."%..."..dist/FRACUNIT)
	//Self collision
	if dustdevil.target == collide and player
		if collide.player.actionstate == air_special then //Air-ground combo
			if not(S_SoundPlaying(collide,sfx_wdjump)) then
				S_StartSound(collide,sfx_wdjump)
			end
			P_SetObjectMomZ(collide,FRACUNIT*24/B.WaterFactor(collide),0)
		end
	return true end
	
	local friendly = collide.player and B.MyTeam(dustdevil.target,collide)
	//Enemy collision
	if not(friendly) then
		local r = R_PointToAngle2(dustdevil.x,dustdevil.y,collide.x,collide.y)
-- 		local damagethrust = not(collide.player or collide.player.powers[pw_flashing]) //or B.PlayerCanBeDamaged(collide.player)
		P_DamageMobj(collide,dustdevil,dustdevil.target)
		if push then
			collide.target = dustdevil.target
		end
		if not(collide.player) or P_PlayerInPain(collide.player)
			P_SetObjectMomZ(collide,FRACUNIT*16/B.WaterFactor(collide),0)
			P_InstaThrust(collide,r,dustdevil.scale*6)
		end
	end
	if(friendly)
		B.AddPinkShield(collide.player,dustdevil.target.player)
	end
	return true
end

