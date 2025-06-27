local B = CBW_Battle
local cooldown = TICRATE * 3
local cooldown_bigjump = TICRATE * 4
local cancelcooldown = TICRATE
local state_digging = 1
local state_drilldive = 2
local state_burrowed = 3
local state_rising = 4
local setburrowtime = TICRATE/2 //Time in tics before the player can move after burrowing
local rockblasttime_x = 35 //Time in tics before horizontal rockblast disappears
local rockblasttime_y = 47 //Time in tics before vertical rockblast disappears
local zthreshold = 8 //Z Distance from ground (in fracunits) that will cause Knuckles to resurface

B.Action.Dig_Priority = function(player)
	if player.actionstate == state_drilldive then
		B.SetPriority(player,2,2,nil,2,2,"drill dive")
	end
	if player.actionstate == state_rising then
		B.SetPriority(player,1,1,nil,1,1,"rising drill")
	end
end

local rock_properties = function(rock,rockblasttime)
	rock.fuse = rockblasttime
	if G_GametypeHasTeams() and rock.target and rock.target.valid and rock.target.player then
		rock.color = rock.target.player.skincolor
		rock.colorflash = true
	end
end

local shootrock_grounded = function(mo,ang1,ang2,scale,rockblasttime)
	local rock = P_SPMAngle(mo,MT_ROCKBLAST,0,0)
	if rock and rock.valid then
		B.InstaThrustZAim(rock,ang1,ang2*P_MobjFlip(rock),scale)
		rock_properties(rock,rockblasttime)
	end
end

local shootrock_sidewall = function(mo,ang1,ang2,scale,rockblasttime)
	local rock = P_SPMAngle(mo,MT_ROCKBLAST,0,0)
	if rock and rock.valid then
		B.InstaThrustSpread(rock,mo.angle,ang1,ang2,scale)
		rock_properties(rock,rockblasttime)
	end
end


local rockblast = function(mo,grounded)
	if grounded then
		//Do horizontal debris burst
		//Anti-air Layer
		local m = 4
		for n = 0,m do
			shootrock_grounded(mo,(360/m)*n*ANG1,85*ANG1,mo.scale*18,rockblasttime_y)
		end
		//Second Layer
		local m = 6
		for n = 0,m do
			shootrock_grounded(mo,(360/m)*n*ANG1,80*ANG1,mo.scale*14,rockblasttime_y)
		end
		//Third Layer
		local m = 8
		for n = 0,m do
			shootrock_grounded(mo,(360/m)*n*ANG1,75*ANG1,mo.scale*11,rockblasttime_y)
		end
		//Ground Layer
		local m = 24
		for n = 0,m do
			shootrock_grounded(mo,(360/m)*n*ANG1,1*ANG10,mo.scale*12,rockblasttime_x)
		end
	else
		//Do vertical debris burst
		for n = 0,7 do
			shootrock_sidewall(mo,30,45*n,mo.scale*20,rockblasttime_y)
		end
		//Second Layer
		for n = 0,15 do
			shootrock_sidewall(mo,60,225*n/10,mo.scale*15,rockblasttime_y)
		end
	end
end

B.Action.Dig=function(mo,doaction)
	local player = mo.player

	if P_PlayerInPain(player)
	or player.playerstate != PST_LIVE
	or (player.actionstate == state_drilldive and player.powers[pw_nocontrol])
		if P_PlayerInPain(player) and player.actionstate
			B.ResetPlayerProperties(player,false,false)
		end
	return end
	if not(B.CanDoAction(player))
		if mo.state == S_PLAY_DRILLDIVE or mo.state == S_PLAY_DRILLRISE
			B.ResetPlayerProperties(player,false,false)
		return end
	end

	local dojump = B.PlayerButtonPressed(player,BT_JUMP,false)
	local dospin = B.PlayerButtonPressed(player,BT_SPIN,false)
	local climbing = player.climbing
	local sludge = mo.eflags&MFE_GOOWATER
	local grounded = P_IsObjectOnGround(mo)
	local diggingstates = (player.actionstate == state_digging or player.actionstate == state_burrowed)
	local getcanceltics = player.actiontime
	local floordist
	if P_MobjFlip(mo) == 1 then
		floordist = mo.z-mo.floorz
	else
		floordist = mo.ceilingz-mo.height-mo.z
	end
	local nearground = (floordist < zthreshold*mo.scale)
	
	//****
	//Action properties &HUD
	
	player.actiontextflags = 0

	//Normal state; ready to dig
	if player.actionstate == 0 then
		player.actiontext = "Dig"
		player.actionrings = 10
	//2 = downward air drill; disallow actions.
	elseif not(diggingstates)
		player.actiontext = nil
	//1 = digging, disallow actions. 3 = Burrowed; ready to resurface.
	else
		if player.actionstate == 1 then
			player.actiontextflags = 1

		end
		player.actiontext = "Rock Blast"
		player.actionrings = 0 
		if player.actionrings > player.rings then
			player.actiontextflags = 3
		end
		player.action2text = "Resurface "..player.exhaustmeter*100/FRACUNIT.."%"
	end
	
	//Check rings
	if (diggingstates and dojump) then
		doaction = 1
	end
	
	//Action triggers
	local trigger_dig =
		(doaction == 1 and not(sludge) and player.actionstate == 0 and (grounded or climbing))
		or (grounded and player.actionstate == state_drilldive and not(sludge))
	local trigger_drilldive = (not(grounded and not sludge) and doaction == 1 and player.actionstate == 0)
	local trigger_drilldive_cancel = (player.actionstate == state_drilldive and mo.momz*P_MobjFlip(mo) > 0)
	local trigger_eject =
		(player.exhaustmeter == 0)
		or (grounded and sludge)
		or (player.actionstate == state_burrowed and dospin)
		or not(nearground or climbing)	
	
	
	//Execute dig
	if trigger_dig
		if player.actionstate == 0 then
			B.PayRings(player)
		end
		player.actionstate = state_digging
		player.actiontime = 0
		player.exhaustmeter = min(FRACUNIT,$+FRACUNIT/4)
		mo.flags = $|MF_NOCLIPTHING
		mo.flags2 = $|MF2_DONTDRAW
		player.pflags = ($|PF_JUMPSTASIS) & ~PF_SPINNING
		player.normalspeed = skins[mo.skin].normalspeed*3/5
		S_StartSound(mo,sfx_s3kccs)
		player.canguard = 0
		return
	end
	
	//Execute downward air drill
	if trigger_drilldive
		B.PayRings(player)
		player.actionstate = state_drilldive
		mo.state = S_PLAY_DRILLDIVE
		local dir = R_PointToAngle2(0,0,mo.momx,mo.momy)
		local speed = FixedHypot(mo.momx,mo.momy)
		B.InstaThrustZAim(mo,dir,-ANGLE_90,min(speed,mo.scale*36))
		mo.momz = min(-12*mo.scale,$*P_MobjFlip(mo))*P_MobjFlip(mo)
		player.pflags = $|(PF_JUMPED|PF_THOKKED)&~(PF_GLIDING)
		S_StartSound(mo,sfx_zoom)
		return
	end
	
	//Drill dive
	if player.actionstate == state_drilldive then
		player.actiontime = $+1
		P_SpawnGhostMobj(mo)
		
		if B.ButtonCheck(player, BT_JUMP) == 1 and player.exhaustmeter
			B.ResetPlayerProperties(player,true,false)
			B.ApplyCooldown(player,cancelcooldown)
			
			mo.momz = $ / 3
			
			local glidespeed = FixedMul(player.actionspd, player.mo.scale)
			local playerspeed = player.speed

			if (player.mo.eflags & MFE_UNDERWATER)
				glidespeed = $ >> 1
				playerspeed = 2*playerspeed/3
				if (!(player.powers[pw_super] or player.powers[pw_sneakers]))
					player.mo.momx = (2*(player.mo.momx - player.cmomx)/3) + player.cmomx
					player.mo.momy = (2*(player.mo.momy - player.cmomy)/3) + player.cmomy
				end
			end
			
			player.pflags = $ | PF_GLIDING|PF_THOKKED
			player.glidetime = 0

			player.mo.state  = S_PLAY_GLIDE
			if (playerspeed < glidespeed)
				P_Thrust(player.mo, player.mo.angle, glidespeed - playerspeed)
			end
			player.pflags = $ & ~(PF_SPINNING|PF_STARTDASH)
		end
	end
	//Cancel drill dive
	if trigger_drilldive_cancel then
		mo.state = S_PLAY_FALL
		B.ResetPlayerProperties(player,false,false)
		B.ApplyCooldown(player,cancelcooldown)
	end
	
	//Drill rise
	if player.actionstate == state_rising
		player.actiontime = $+1
		//End rising state
		if P_MobjFlip(mo)*mo.momz <= 0 or P_IsObjectOnGround(mo)
			B.ResetPlayerProperties(player,true,false)
			player.exhaustmeter = FRACUNIT / 3 + 1
		end
	end
	
	//Gate: Digging states only
	if not(diggingstates)
		then return 
	end
	
	//Eject player from burrow state
	if trigger_eject then
		P_SetObjectMomZ(mo,FixedMul(FRACUNIT*6,player.jumpfactor),false)
		B.ResetPlayerProperties(player,false,false)
		mo.state = S_PLAY_FALL
		S_StartSound(mo,sfx_s3k82)
		for n = 0, 10
			B.DoDebris(mo,P_RandomChance(FRACUNIT/2),P_RandomRange(5,10))
		end
		//Apply cooldown
		B.ApplyCooldown(player,cancelcooldown)
		player.powers[pw_nocontrol] = 2
		player.actiontime = 0
		mo.momx = $ / 3
		mo.momy = $ / 3
		return
	end
	
	//Burrowed properties
	mo.flags = $|MF_NOCLIPTHING //Intangibility
	mo.flags2 = $|MF2_DONTDRAW //Invisibility
	player.charability2 = 0 //Disallow spindashing
	player.canguard = false //Disallow guarding
	
	//Clip to ground
	if not(climbing) then
		if P_MobjFlip(mo) == 1 then
			mo.z = mo.floorz
		else
			mo.z = mo.ceilingz-mo.height
		end
	end
	
	//Timers
	player.actiontime = $+1
	if player.exhaustmeter and P_IsObjectOnGround(mo)
		player.exhaustmeter = max(0,$-FRACUNIT/TICRATE/3)
	end
	
	//Smoke
	if (player.exhaustmeter > FRACUNIT/3 and player.actiontime%TICRATE == 0)
	or (player.exhaustmeter <= FRACUNIT/3 and player.actiontime%(TICRATE/3) == 0)
		local smoke = P_SpawnMobj(mo.x,mo.y,mo.z,MT_SMOKE)
		if G_GametypeHasTeams()
			smoke.colorized = true
			smoke.color = player.skincolor
		end
	end
	
	//Digging state
	if player.actionstate == state_digging
		player.pflags = $|PF_JUMPSTASIS//|PF_STASIS
		if player.actiontime >= setburrowtime
			player.actionstate = state_burrowed
		end
		B.DoDebris(mo,P_RandomChance(FRACUNIT/2),P_RandomRange(5,20))
		return
	end
	player.pflags = ($|PF_JUMPSTASIS)//&~PF_STASIS

	//Moving while burrowed
	if abs(player.cmd.forwardmove) or abs(player.cmd.sidemove) then
		if not(player.actiontime&3) then
			//Do Debris
			B.DoDebris(mo,P_RandomChance(FRACUNIT/2),P_RandomRange(3,5))
			S_StartSound(mo,sfx_s3k67)
		end
	end
	
	grounded = P_IsObjectOnGround(player.mo)
	//Rock blast attack
	if (doaction == 1)
		then
		player.exhaustmeter = 0
		B.PayRings(player)
		player.pflags = $&~PF_JUMPSTASIS
		P_DoJump(player,false)
		B.ResetPlayerProperties(player,true,true)
		if grounded
			player.actionstate = state_rising
			mo.state = S_PLAY_DRILLRISE
		end
		if player.cmd.buttons&BT_JUMP then
			mo.momx = $ / 3
			mo.momy = $ / 3
			player.pflags = $|PF_STARTJUMP|PF_JUMPDOWN
			B.ZLaunch(mo, FRACUNIT*9/2, true)
			B.ApplyCooldown(player,cooldown_bigjump)
			S_StartSound(mo, sfx_s3ka0)
		else
			B.ApplyCooldown(player,cooldown)
		end
		S_StartSound(mo,sfx_s3k59)
		for n = 0, 7
			B.DoDebris(mo,P_RandomChance(FRACUNIT/2),P_RandomRange(3,20))
		end
		rockblast(mo,grounded)
	end
end

B.DoDebris=function(mo,large,speed)
	local scale
	if large then scale = mo.scale/2
	else scale = mo.scale/3
	end
	local debris = P_SpawnMobj(mo.x,mo.y,mo.z,MT_ROCKCRUMBLE2)
	if debris and debris.valid then
		if G_GametypeHasTeams() and mo.player
			debris.colorized = true
			debris.color = mo.player.skincolor
		end
		debris.scale = scale
		debris.flags2 = $|(mo.flags2&MF2_OBJECTFLIP)
		debris.z = $+FRACUNIT
		if P_IsObjectOnGround(mo) then
			P_InstaThrust(debris,P_RandomRange(0,259)*ANG1,speed*scale)
			debris.momz = speed*scale*P_MobjFlip(mo)
		else
			B.InstaThrustZAim(debris,mo.angle+ANGLE_180+P_RandomRange(-89,89)*ANG1,P_RandomRange(-89,89)*ANG1,speed*scale)
		end
	end
	return debris
end

B.RockBlastObject = function(mo)
	if mo.colorflash == true then
		mo.colorized = (mo.fuse%8 == 0)
	end
end

B.Knuckles_Collide = function(n1,n2,plr,mo,atk,def,weight,hurt,pain,ground,angle,thrust,thrust2,collisiontype)
	if plr[n1] and mo[n1].health and not(pain[n1])
		and (plr[n1].pflags&PF_GLIDING or plr[n1].climbing 
			or (plr[n1].charability == CA_GLIDEANDCLIMB) and collisiontype > 1 and P_IsObjectOnGround(mo[n1]) and not(plr[n1].pflags&PF_SPINNING)
		) then
		plr[n1].pflags = $&~(PF_GLIDING|PF_JUMPED)
		if not(P_IsObjectOnGround(mo[n1])) and not(plr[n1].climbing) then
			plr[n1].panim = PA_FALL
			mo[n1].state = S_PLAY_FALL
			plr[n1].climbing = 0
			plr[n1].lastsidehit = -1
			plr[n1].lastlinehit = -1
			
			P_Thrust(mo[n1],mo[n1].angle + ANGLE_180, 6*FRACUNIT)
			P_SetObjectMomZ(mo[n1], 2*FRACUNIT/B.WaterFactor(mo[n1]), true)
		elseif (atk[n2])
			mo[n1].state = S_PLAY_GLIDE_LANDING
		end
	end
	return false
end