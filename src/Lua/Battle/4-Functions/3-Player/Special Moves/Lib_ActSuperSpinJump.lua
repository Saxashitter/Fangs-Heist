local B = CBW_Battle
local cooldown1 = TICRATE
local cooldown2 = TICRATE * 9/4//2.25s
local state_superspinjump = 1
local state_groundpound_rise = 2
local state_groundpound_fall = 3
local jumpthrust = 42*FRACUNIT
local pound_startthrust = 12*FRACUNIT
local pound_downaccel = FRACUNIT*4//4
local jumpfriction = FRACUNIT*9/10
local poundfriction = FRACUNIT
local reboundthrust = 11
local reboundthrust2 = 16
local reboundthrust3 = 7
local reboundforward = 5
local rebounddropdash = 24

B.Action.SuperSpinJump_Priority = function(player)
	if player.actionstate == state_superspinjump then
		B.SetPriority(player,1,2,"tails_fly",2,2,"super spin jump")
	elseif player.actionstate == state_groundpound_rise or player.actionstate == state_groundpound_fall then
		B.SetPriority(player,1,2,"fang_tailbounce",2,2,"ground pound")
	end
end

B.Action.SuperSpinJump=function(mo,doaction)
	local player = mo.player
	
	if not(B.CanDoAction(player)) then
		player.actionstate = 0
	return end
	//Action info
	if P_IsObjectOnGround(mo) then
		player.actiontext = "Super Spin Jump"
		player.actionrings = 10
	else
		player.actiontext = "Ground Pound"
		player.actionrings = 10
	end
	player.action2text = nil
	if player.actionstate != 0 then player.canguard = false end
	
	local water = B.WaterFactor(mo)
	local thrust
	local jumpflags = (player.pflags|PF_JUMPED|PF_THOKKED)&~(PF_STARTJUMP|PF_NOJUMPDAMAGE|PF_GLIDING|PF_BOUNCING|PF_SPINNING)
	//Neutral
	if player.actionstate == 0
		player.squashstretch = 0
		if doaction == 1 then
			B.PayRings(player)
			//Do high jump
			if P_IsObjectOnGround(mo) then
				mo.spritexscale = FRACUNIT * 4/5
				mo.spriteyscale = FRACUNIT * 5/4
				player.squashstretch = true
		
				player.actionstate = state_superspinjump
-- 				P_DoJump(player,true)
				thrust = FixedMul(jumpthrust,player.jumpfactor)
				P_SetObjectMomZ(mo,thrust,true) //Inherit platform momentum
-- 				P_InstaThrust(mo,mo.angle,0)
				S_StartSound(mo,sfx_s3k3c)
				S_StartSound(mo,sfx_kc5b)
				player.pflags = jumpflags
				mo.state = S_PLAY_ROLL
				player.secondjump = 0
				player.canguard = false
				B.ApplyCooldown(player,cooldown1)
			else//Do ground pound
				B.ApplyCooldown(player,cooldown2)
				thrust = pound_startthrust/water
				player.actionstate = state_groundpound_rise
				P_SetObjectMomZ(mo,thrust,false)
				S_StartSound(mo,sfx_zoom)
				mo.state = S_PLAY_ROLL
				player.pflags = jumpflags
				player.secondjump = 0
			end
		end
	return end
	
	//Ground pound phase 1
	if player.actionstate == state_groundpound_rise 
		B.ControlThrust(mo,poundfriction,nil,FRACUNIT,FixedMul(player.actionspd,mo.scale))
		P_SetObjectMomZ(mo,-pound_downaccel/water,true)
		if mo.momz*P_MobjFlip(mo) < 0 then //If we're moving upward, then move onto the second phase
			player.actionstate = state_groundpound_fall
		end
		player.actiontime = abs(mo.momz)
	end
	//Ground pound phase 2
	if player.actionstate == state_groundpound_fall 
		B.ControlThrust(mo,poundfriction,nil,FRACUNIT,FixedMul(player.actionspd,mo.scale))
		if mo.momz*P_MobjFlip(mo) > 0 then //If we're moving upward, then something must have interrupted us.
			player.actionstate = 0
			player.pflags = $|PF_JUMPED|PF_STARTJUMP|PF_NOJUMPDAMAGE&~PF_SPINNING|PF_JUMPED
			mo.state = S_PLAY_SPRING
		else
			P_SetObjectMomZ(mo,-pound_downaccel/water,true)
			if mo.eflags&MFE_JUSTHITFLOOR then //We have hit a surface
				player.lockjumpframe = 2
				player.actionstate = 0
				
				if player == displayplayer
					P_StartQuake(6*FRACUNIT, 3)
				end
				
				if (player.cmd.buttons & BT_SPIN)
					player.buttonhistory = $ | BT_SPIN
					//B.ZLaunch(mo,reboundthrust3*FRACUNIT,true)
					S_StopSoundByID(mo, sfx_zoom)
					S_StartSound(mo, sfx_zoom)
					S_StartSoundAtVolume(mo, sfx_kc3b, 100)
					P_InstaThrust(mo,R_PointToAngle2(0,0,mo.momx,mo.momy),FixedHypot(mo.momx,mo.momy)/3)
					P_Thrust(mo,mo.angle,rebounddropdash*mo.scale)
					B.ResetPlayerProperties(player,true,true)
					mo.state = S_PLAY_ROLL
					player.pflags = $|PF_SPINNING&~PF_JUMPED
					player.drawangle = mo.angle
					for i = -2, 2
						local dust = P_SpawnMobjFromMobj(mo, 0, 0, 0, MT_SPINDUST)
						P_Thrust(dust, mo.angle + ANG20 * i, mo.scale * -20)
						
						if (mo.eflags & MFE_VERTICALFLIP) // readjust z position if needed
							dust.z = mo.z + mo.height - dust.height
						end
					end
					
					P_SpawnThokMobj(player)
					
				elseif (player.cmd.buttons & BT_JUMP)
					player.buttonhistory = $ | BT_JUMP
					S_StartSound(mo, sfx_jump)
					S_StartSound(mo, sfx_s3kae)
					S_StartSoundAtVolume(mo, sfx_kc3b, 100)
					B.ZLaunch(mo,reboundthrust2*FRACUNIT,true)
					B.ResetPlayerProperties(player,true,false)
					mo.state = S_PLAY_JUMP
					player.pflags = ($|PF_STARTJUMP)&~PF_SPINNING
					P_InstaThrust(mo,R_PointToAngle2(0,0,mo.momx,mo.momy),FixedHypot(mo.momx,mo.momy)/8)
					P_Thrust(mo,mo.angle,reboundforward*mo.scale)
					player.drawangle = mo.angle
					
					for i = 0, 9 do
						local dust = P_SpawnMobjFromMobj(mo, 0, 0, 0, MT_SPINDUST)
						P_Thrust(dust, mo.angle + (ANG1 * 36 * i), mo.scale * -20)
						
						if (mo.eflags & MFE_VERTICALFLIP) // readjust z position if needed
							dust.z = mo.z + mo.height - dust.height
						end
					end
					
					P_SpawnThokMobj(player)
					
				else
					S_StartSound(mo,sfx_s3k5f)
					local blastspeed = 4
					local fuse = 10
					
					//Create projectile blast
					for n = 0, 23
						local p = P_SPMAngle(mo,MT_GROUNDPOUND,mo.angle+n*ANG15,0)
						if p and p.valid then
							p.momz = mo.scale*P_MobjFlip(mo)*blastspeed/water
							p.fuse = fuse
		-- 						P_InstaThrust(p,p.angle,player.actiontime>>1)
						end
					end
					
					P_InstaThrust(mo,R_PointToAngle2(0,0,mo.momx,mo.momy),FixedHypot(mo.momx,mo.momy)/5)
					B.ZLaunch(mo,reboundthrust*FRACUNIT,true)
					mo.state = S_PLAY_SPRING
					player.pflags = ($|PF_THOKKED)&~PF_SPINNING
				end
			else
				player.actiontime = abs(mo.momz)
				mo.spritexscale = max(FRACUNIT * 3/4, min($ - FRACUNIT/100, FRACUNIT))
				mo.spriteyscale = max(FRACUNIT, min($ + FRACUNIT/100, FRACUNIT*4/3))
				player.squashstretch = true
			end
		end
	end
	//SuperSpinJump state
	if player.actionstate == state_superspinjump 
		B.ControlThrust(mo,FRACUNIT,nil,jumpfriction,nil)
		
		mo.spritexscale = max(FRACUNIT * 4/5, min($ + FRACUNIT/30, FRACUNIT))
		mo.spriteyscale = max(FRACUNIT, min($ - FRACUNIT/30, FRACUNIT * 5/4))
		player.squashstretch = true
		
		//Go into fall frames after end-rising
		if mo.momz*P_MobjFlip(mo) < 0 then 
			mo.state = S_PLAY_FALL
			player.pflags = $&~(PF_JUMPED)
			player.actionstate = 0
		end
		if P_IsObjectOnGround(mo) then
			player.actionstate = 0
		end
	end
	if player.actionstate and player.pflags&PF_JUMPED then
		local zheight
		if (mo.eflags & MFE_VERTICALFLIP)
			zheight = mo.z + mo.height + FixedDiv(P_GetPlayerHeight(player) - mo.height, 3*FRACUNIT) - FixedMul(mobjinfo[MT_THOK].height, mo.scale)
		else
			zheight = mo.z - FixedDiv(P_GetPlayerHeight(player) - mo.height, 3*FRACUNIT)
		end
		
		if (not (mo.eflags & MFE_VERTICALFLIP)
		and (zheight < mo.floorz)
		and not (mobjinfo[MT_THOK].flags & MF_NOCLIPHEIGHT))
			zheight = mo.floorz
		elseif (mo.eflags & MFE_VERTICALFLIP and zheight + FixedMul(mobjinfo[MT_THOK].height, mo.scale) > mo.ceilingz and not (mobjinfo[MT_THOK].flags & MF_NOCLIPHEIGHT))
			zheight = mo.ceilingz - FixedMul(mobjinfo[MT_THOK].height, mo.scale)
		end
		
		local trail = P_SpawnGhostMobj(mo)
		P_TeleportMove(trail, trail.x, trail.y, zheight)
		trail.fuse = 30
		trail.state = S_THOK
		trail.frame = TR_TRANS70|A
		trail.destscale = 0
		trail.spritexscale = mo.spritexscale
		trail.spriteyscale = mo.spriteyscale
		
		/*if leveltime % 4 == 0
			trail = P_SpawnGhostMobj(mo)
			P_TeleportMove(trail, trail.x, trail.y, zheight)
			trail.fuse = 30
			trail.color = SKINCOLOR_WHITE
			trail.state = S_THOK
			trail.frame = TR_TRANS60|A
			trail.flags2 = MF2_SPLAT
			trail.destscale = trail.scale * 5
		end*/
		
		player.pflags = $|PF_THOKKED
	end
	
	if mo.state != S_PLAY_ROLL
		player.squashstretch = false
	end
end