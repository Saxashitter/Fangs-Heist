local B = CBW_Battle
local cooldown = TICRATE
local carrytime = TICRATE*16
local carryfall = FRACUNIT/10
local countmax = 6
local speedlimit = FRACUNIT*28
local zaccel = FRACUNIT*6/35
local zmax = FRACUNIT*10

B.Action.RoboMissile=function(mo,doaction)
	local player = mo.player

	//Run checks
	if not(B.CanDoAction(player)) then
		return
	end
	//initialize count variable
	if mo.rccount == nil then
		mo.rccount = 0
	end
	local missilecount = 3
	local twod = mo.flags2&MF2_TWOD or twodlevel
	if twod then
		missilecount = 2
	end
	
	//Aim control visuals
	if B.PlayerButtonPressed(player,player.battleconfig_special,true) then
		local angle = B.GetInputAngle(player)
		if angle != nil then
			B.DrawAimLine(player,angle)
		end
	end
	//Action Info
	player.actiontext = "RC Missile"
	player.actionrings = 10
	if mo.rccount >= countmax then
		player.actiontextflags = 2
		player.actiontext = "Max!"
	end
	
	if mo.rccount > 0 then
		player.action2text = "Hold: Aim ("..mo.rccount..")"
		if doaction == 2 then
			player.action2textflags = 2
		end
	end
	//Launch missiles
	if doaction == 1 and mo.rccount < countmax
		player.actionstate = 1
		player.actiontime = 0
		B.PayRings(player,player.actionrings)
-- 		S_StartSound(missile,sfx_s3kb8)
		S_StartSound(missile,sfx_cdfm16)
		
		//Get missile type
		local t
		if mo.eflags&MFE_UNDERWATER then t = MT_JETJAWMISSILE
		elseif P_IsObjectOnGround(mo) then t = MT_CRAWLAMISSILE
		else t = MT_BASHMISSILE end		
		for n = 1, missilecount
			if mo.rccount >= countmax then continue end
			mo.rccount = $+1
			//Spawn missile
			local missile = P_SPMAngle(mo,t,mo.angle,0)
			//Missile properties
			if missile and missile.valid then
				missile.color = player.skincolor
				//Thrust values
				if twod
					if n == 1 then
						P_Thrust(missile,0,mo.scale*4)
						P_SetObjectMomZ(missile,FRACUNIT*2,1)
					end
					if n == 2 then
						P_Thrust(missile,ANGLE_180,mo.scale*4)
						P_SetObjectMomZ(missile,FRACUNIT*2,1)
					end
				else
					if n == 1 then
						P_SetObjectMomZ(missile,FRACUNIT*4,1)
					end
					if n == 2 then
						P_Thrust(missile,mo.angle+ANGLE_157h,mo.scale*8)
					end
					if n == 3 then
						P_Thrust(missile,mo.angle-ANGLE_135,mo.scale*4)
						P_SetObjectMomZ(missile,FRACUNIT,1)
					end
				end
				//Send carried player onto the first robo missile
				B.RoboMissileTransferCarry(player,missile)
			end
		end
	return end

	//Hold state
	if player.actionstate == 1 then
		if doaction == 2 then
			player.actiontime = $+1
		else
			B.ApplyCooldown(player,max(0,cooldown-player.actionstate))
			player.actiontime = 0
			player.actionstate = 0
		end
	end
	
	//Reset count for next frame
	mo.rccount = 0
end

B.RoboMissileTransferCarry=function(player,missile)
	local carried = player.carry_id
	if not(carried) then return end
	if not(missile.flags&MF_MISSILE) then return end
	B.DebugPrint("carry_id "..tostring(carried),DF_PLAYER)
	carried.tracer = missile
	if carried.player then
		carried.player.powers[pw_carry] = CR_GENERIC
	end
-- 	P_TeleportMove(carried,missile.x,missile.y,missile.z-carried.height)
	player.carry_id = nil
	missile.target = carried
	missile.carry = true
end

B.RoboMissileSpawn=function(mo)
	mo.robomissile_init = true
	mo.phase = 1
	mo.time = 0
	P_SetObjectMomZ(mo,FRACUNIT*4,true)
	mo.flags = $|MF_NOCLIPTHING
	mo.shadowscale = FRACUNIT
end

B.RoboMissileThinker=function(mo)
	if not(mo.valid) then return end
	if not(mo.flags&MF_MISSILE) then
		mo.shadowscale = 0
	return end
	if mo.launchtime == nil then 
		mo.launchtime = P_RandomRange(20,25)
	end
	mo.time = $+1
	if mo.phase == 1
		if mo.type != MT_CRAWLAMISSILE then
			mo.momz = $*95/100
		end
		if P_IsObjectOnGround(mo) then
			mo.phase = 2
			mo.time = 0
-- 			mo.flags = $&~(MF_GRENADEBOUNCE)
			S_StartSound(mo,sfx_s3k48)
		elseif mo.time > mo.launchtime and not(mo.type == MT_CRAWLAMISSILE) then
			mo.time = 0
			mo.phase = 2
			S_StartSound(mo,sfx_s3ka0)
		end
	end
	local w = B.WaterFactor(mo)
	if twodlevel then w = $*2 end
	if mo.phase == 2 then
		mo.flags = $&~MF_NOCLIPTHING
		B.RoboMissileRemoteControl(mo)
		P_Thrust(mo,mo.angle,mo.scale*2/w)
		B.ControlThrust(mo,FRACUNIT*97/100,speedlimit/w)
	end
	if (mo.type == MT_CRAWLAMISSILE) then
		B.CrawlaMissileGravity(mo)
	end
	if mo.phase == 2 and not(mo.time&3) then
		local thrust = mo.scale*4
		local ang = P_RandomRange(170,190)*ANG1+mo.angle
		local x = mo.x+P_ReturnThrustX(mo,ang,thrust)
		local y = mo.y+P_ReturnThrustY(mo,ang,thrust)
		if w == 1 then
			P_SpawnMobj(x,y,mo.z,MT_DUST)
		else
			P_SpawnMobj(x,y,mo.z,MT_SMALLBUBBLE)
		end
	end
end

B.CrawlaMissileGravity = function(mo)
	if mo.floorz > mo.z then
		mo.z = mo.floorz
		mo.momz = 0
	end
	if mo.ceilingz < mo.z+mo.height then
		mo.z = mo.ceilingz-mo.height
		mo.momz = 0
	end
end

B.RoboMissileFuse=function(mo)
	if not(mo.valid and mo.health) then return end
	P_KillMobj(mo)
	return true
end

B.RoboMissileRemoteControl = function(mo)
	if not(mo.target and mo.target.valid and mo.target.player) then return end //Owner invalid
	if mo.carry and mo.target.tracer != mo then return end //No longer carrying
	local target = mo.target
	local player = target.player
	if not(mo.tracer and mo.tracer.valid)
		local bestmo
		local bestdist
		for foe in players.iterate
			if B.MyTeam(foe, player) 
			or foe.spectator
			or foe.playerstate != PST_LIVE
			or not(foe.mo)
			continue end
			local dist = R_PointToDist2(mo.x, mo.y, foe.mo.x, foe.mo.y)
			if not(bestmo)
			or dist < bestdist
				bestmo = foe.mo
				bestdist = dist
			end
		end
		mo.tracer = bestmo
	end
-- 	local remote = B.PlayerButtonPressed(player,player.battleconfig_special) and B.CanDoAction(player)
	local remote = mo.tracer and mo.tracer.valid
	local cmd = player.cmd
	local water = B.WaterFactor(mo)
	if target.rccount != nil then
		target.rccount = $+1
	end
	//Disallow RC if player is in pain
	if P_PlayerInPain(player) or not(player.playerstate == PST_LIVE) then return end
	local pointangle
	if remote
		pointangle = R_PointToAngle2(mo.x, mo.y, mo.tracer.x, mo.tracer.y)
	end
	//Crawla Jump
	if mo.type == MT_CRAWLAMISSILE and P_IsObjectOnGround(mo) then
-- 		if B.PlayerButtonPressed(player,BT_JUMP,false) then
		if remote 
		and R_PointToDist2(0, 0, mo.momx, mo.momy) > mo.scale * 8
		and P_MobjFlip(mo)*mo.tracer.z > P_MobjFlip(mo)*(mo.z + 32*mo.scale)
		and abs(pointangle-mo.angle) < ANGLE_22h
			S_StartSound(mo,sfx_cdfm02)
			P_SetObjectMomZ(mo,FRACUNIT*10/water,true)
			mo.phase = 1
		end
	end
	
	if mo.phase == 2 then
		local exposed = (
			(mo.type == MT_CRAWLAMISSILE and not(P_IsObjectOnGround(mo)))
			or (mo.type == MT_BASHMISSILE and water==2)
			or (mo.type == MT_JETJAWMISSILE and water==1)
		)
		if not(exposed) or (mo.type == MT_CRAWLAMISSILE) then 
			mo.fuse = 0
		elseif not(mo.fuse) then
			mo.fuse = TICRATE
			if(mo.type == MT_JETJAWMISSILE) then
				mo.flags = $&~MF_NOGRAVITY
			end
		end
		//Air vertical control
		if not(mo.type == MT_CRAWLAMISSILE) and not(mo.carry) and remote then
			local zmove = max(-zmax,min(zmax,P_MobjFlip(mo)*B.FixedLerp(0,mo.tracer.z-mo.z+mo.tracer.height/2-mo.height/2,zaccel)))
			P_SetObjectMomZ(mo,zmove,0)
		end
		
		//Terrain avoidance
		if not(mo.type == MT_CRAWLAMISSILE) and mo.z > mo.floorz and mo.z+mo.height < mo.ceilingz
			mo.z = min(mo.ceilingz-mo.height*3/2,max(mo.floorz+mo.height/2,$))
		end

		//Carrier controls
		if mo.carry then
			mo.angle = mo.target.angle
			local zmove = FRACUNIT*cmd.forwardmove/50/water
			if mo.time > carrytime 
				P_SetObjectMomZ(mo,-carryfall,true)
				mo.colorized = true
				if mo.time&1 then
					mo.color = SKINCOLOR_CARBON
				else
					mo.color = SKINCOLOR_RUST
				end
			end
		elseif remote //Remote controls
			mo.angle = $ + (pointangle - $)/16
-- 			local angle = B.GetInputAngle(player)
-- 			if angle != nil
-- 				local dist = min(mo.scale/4*mo.scale,R_PointToDist2(mo.x,mo.y,target.x,target.y))*2
-- 				local x2 = target.x+P_ReturnThrustX(nil,angle,dist)
-- 				local y2 = target.y+P_ReturnThrustY(nil,angle,dist)
-- 				mo.angle = R_PointToAngle2(mo.x,mo.y,x2,y2)
-- 			end
		end
	end
end

B.RoboMissileCollide=function(mo,other)
-- 	if 1 then return false end
	//Not valid missile state?
	if not(mo.flags&MF_MISSILE) then return false end //No collision
	//Not valid collision height?
	if B.CheckHeightCollision(mo,other) == false then return false end //No collision
	//Check for peer robo missiles
	if (mo.robomissile_init and other.robomissile_init and mo.target == other.target and mo.phase == 2 and other.phase == 2) then 
		//Apply spacing
		local angle = R_PointToAngle2(mo.x,mo.y,other.x,other.y)
		local thrust = mo.scale
		P_Thrust(mo,angle+ANGLE_180,thrust)
		P_Thrust(other,angle,thrust)
	return false end //No collision
	//Check for enemy missile
	if other.flags&MF_MISSILE
	and not(other.target and other.target.player and B.MyTeam(mo.target.player,other.target.player))
	return true end //Collision confirmed
	//Check for ally
	if other.player and mo.target and mo.target.player 
	and B.MyTeam(mo.target.player,other.player)
	then return false end //No collision
	//For the rest, we'll just rely on default rules.
end

B.RoboMissileResetCarry=function(mo)
	if mo.target and mo.target.player
	and mo.target.player.powers[pw_carry] == CR_GENERIC
		mo.target.player.powers[pw_carry] = 0
		mo.target = nil
	end
end