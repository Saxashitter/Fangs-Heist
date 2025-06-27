local B = CBW_Battle
local CV = B.Console
local autotime = TICRATE*15 //time before auto spectator camera takes effect
local rate = 10 //speed of cam dist adjustment
local resettime = TICRATE*25 //time before auto spectator resets to new player

B.PreAutoSpectator = function(player)
	if not(player.spectator) then return end
	//Campaign control
	if gametyperules & GTR_CAMPAIGN
		if not(player.bot)
			//Humans must go onto blue team
			COM_BufInsertText(server, "serverchangeteam "..#player.." 2")
			return
		elseif not(netgame) and player.realmo
			//Fix for strange SP-related spectator visibility bug
			player.realmo.state = S_INVISIBLE
		end
	end
	//3D auto camera control
	if not(twodlevel) 
		if player.cmd.forwardmove != 0 or player.cmd.buttons & (BT_ATTACK|BT_SPIN|BT_JUMP) then
			player.spectatortime = 0
		end
	return end
	//2D auto camera control
	if (twodlevel) 
		if player.cmd.forwardmove != 0 or player.cmd.sidemove != 0 or player.cmd.buttons & (BT_ATTACK|BT_SPIN|BT_JUMP) then
			player.spectatortime = 0
		end
	end
end

B.AutoSpectator = function(player)
	if not(player.spectator) then return end
	local mo = player.realmo

	//Must be allowed via player config settings
	if player.battleconfig_autospectator != true then return end
	
	if mo.specID == nil
		mo.specID = 0
	end
	
	local cycle = false
	//autospectator cycle controls
	if B.ButtonCheck(player,BT_WEAPONNEXT) == 1
		player.spectatortime = autotime
		mo.spectarget = nil
		mo.specID = $ + 1
		cycle = true
	elseif B.ButtonCheck(player,BT_WEAPONPREV) == 1
		player.spectatortime = autotime
		mo.spectarget = nil
		mo.specID = $ - 1
		cycle = true
	end
	
	//No autospectate until idle time has reached a certain threshold
	if player.spectatortime < autotime then
	return end
	
	local reset = false
	//Update target
	if mo.spectarget == nil 
	or not(mo.spectarget.valid) 
	or (mo.spectarget.playerstate != PST_LIVE and mo.spectarget.deadtimer >2*TICRATE)
	or mo.spectarget.revenge
		mo.spectarget = nil
		reset = true
	end
	//Reset target
	if player.spectatortime > autotime+resettime or reset == true or mo.spectarget == nil
		local options = {}
		for p in players.iterate
			if p != mo.spectarget and p.mo and p.mo.valid and p.mo.health and not(p.revenge)
			and (not(G_TagGametype()) or p.pflags&PF_TAGIT)
				options[#options+1] = p
			end
		end
		if #options then
			if cycle
				S_StartSound(nil, sfx_menu1, player)
				if mo.specID < 0
					mo.specID = #options
				elseif mo.specID > #options
					mo.specID = 0
				end
				mo.spectarget = options[(mo.specID % #options) + 1]
			else
				mo.spectarget = options[P_RandomRange(1,#options)]
			end
			local t = mo.spectarget.mo
			if not(twodlevel) then
				P_TeleportMove(mo,t.x,t.y,t.z)
			end
			player.spectatortime = autotime
		end
	end
	//Check if target exists or not
	if not(mo.spectarget and mo.spectarget.valid and mo.spectarget.mo and mo.spectarget.mo.valid) then return end
	local t = mo.spectarget.mo
	
	
	//3D cam
	if not(twodlevel) then 
		//Stay in view of target
		if P_CheckSight(mo,t) == false and R_PointToDist2(mo.x,mo.y,t.x,t.y)+abs(t.z-mo.z) > t.scale*480
			P_TeleportMove(mo,t.x,t.y,t.z)
		end
		//Adjust aim
		mo.angle = R_PointToAngle2(mo.x,mo.y,t.x,t.y)
		player.aiming = 0
		//Follow XY position
		local closedist = t.scale*256
		local realdist = R_PointToDist2(mo.x,mo.y,t.x,t.y)
		local thrust = (realdist-closedist)*rate/35
		P_InstaThrust(mo,mo.angle,thrust)
		//Follow Z position
		local closedistz = t.scale*48
		local realdistz = t.z-mo.z+closedistz
		local thrustz = realdistz*rate/35
		mo.z = min(mo.ceilingz,max(mo.floorz,$+thrustz))
	end
	//2D cam
	if (twodlevel) then 
		//Keep aim in static position
		mo.angle = ANGLE_90
		player.aiming = 0
		//Follow X position
		local dist = t.x-mo.x
		mo.momx = dist*rate/35
		//Follow Z position
		local closedistz = t.scale*48
		local realdistz = t.z-mo.z+closedistz
		local thrustz = realdistz*rate/35
		mo.z = min(mo.ceilingz,max(mo.floorz,$+thrustz))	
	end
end

B.SpectatorControl = function(player)
	if player.spectatortime != nil
		player.spectatortime = $+1
	else
		player.spectatortime = 0
	end
	if player.playerstate then return end
	if not(player.spectator and player.realmo and player.realmo.valid) then return end
	local mo = player.realmo
	local devcam = CV.DevCamera.value
	//Set 2D start orientation/position
	if twodlevel and not(mo.twod) and not(devcam) then
		P_TeleportMove(mo,mo.x,mo.y-mo.scale*640,mo.z)
		B.DebugPrint("Teleported 2D spectator",DF_PLAYER)
-- 		mo.angle = ANGLE_90
		mo.twod = true
	end
	//Movement physics beyond this line
	local fwd = player.cmd.forwardmove
	local sid = player.cmd.sidemove
	//Before we go any further, let's compensate for 2D fuckery
	if mo.twod and not(devcam) then
		player.cmd.angleturn = 1
		player.cmd.aiming = 0
		if sid > 20
			player.cmd.buttons = $|BT_JUMP
		elseif sid < -20
			player.cmd.buttons = $|BT_SPIN
		end
		sid = 0
	end
	local xymult = 2
	local zmult = 2
	local move = FixedHypot(fwd*FRACUNIT,sid*FRACUNIT)
	local anglemove
	if twodlevel and devcam then
		anglemove = R_PointToAngle2(0,0,sid*FRACUNIT,-fwd*FRACUNIT)
	else
		anglemove = R_PointToAngle2(0,0,fwd*FRACUNIT,-sid*FRACUNIT)
	end

	local redirect = mo.angle+anglemove
	if (mo.mom==nil) then
		mo.mom = {0,0,0}
	end
	local zmom = 0
	if player.cmd.buttons&BT_JUMP then zmom = $+zmult*FRACUNIT end
	if player.cmd.buttons&BT_SPIN then zmom = $-zmult*FRACUNIT end
	local accel = move/25*xymult
	//Translate movement vectors
	mo.mom[1] = $+P_ReturnThrustX(nil,redirect,accel)
	mo.mom[2] = $+P_ReturnThrustY(nil,redirect,accel)
	//Enforce speed cap
	local limit = FRACUNIT*48
	local spd = min(limit,max(-limit,
		FixedHypot(mo.mom[1],mo.mom[2])
		))
	//Friction
	local friction = FRACUNIT*9/10
		spd = FixedMul(spd,friction)
	//Reapply vectors
	local ang = R_PointToAngle2(0,0,mo.mom[1],mo.mom[2])
	mo.mom[1] = P_ReturnThrustX(nil,ang,spd)
	mo.mom[2] = P_ReturnThrustY(nil,ang,spd)
	//Execute Movement
	if not(devcam)
		local moved = P_TryMove(mo,
			mo.x+mo.mom[1],
			mo.y+mo.mom[2],
			true)
		if not(moved) then
			P_InstaThrust(mo,ang,spd)
			P_SlideMove(mo)
		end
	else
		P_TeleportMove(mo,mo.x+mo.mom[1],mo.y+mo.mom[2],mo.z)
	end
	//More 2D garbage
	if mo.twod 
		player.aiming = 0
		mo.angle = ANGLE_90
		limit = $*2
	end
	
	//Z movement
	mo.mom[3] = min(limit,max(-limit,$+zmom))
	mo.mom[3] = FixedMul($,friction)
	mo.z = max(mo.floorz,min(mo.ceilingz,$+mo.mom[3]))
	
	//Avoid redudant movement from P_SpectatorMove
	player.cmd.forwardmove = 0
	player.cmd.sidemove = 0
	player.cmd.buttons = $&~(BT_JUMP|BT_SPIN)
end

B.SpectatorLives = function(player)
	if B.ArenaGametype() and G_GametypeUsesLives() and CV.Revenge.value
	and player.lives == 0 then
		player.lives = 1
		player.revenge = true
		player.lifeshards = 0
	end
end

B.TwoDSeeName = function(player)
	if not twodlevel then return end

	if netgame and player.spectator and player.realmo and player.realmo.valid -- paranoia
		and p == displayplayer and not (leveltime % (TICRATE/5))
		and CV_FindVar("seenames").value and CV_FindVar("allowseenames").value
	then
		player.twodchecknames = true
		local namecheck = P_SpawnMobjFromMobj(player.realmo, 0, 0, 0, MT_NAMECHECK)
		if namecheck and namecheck.valid -- paranoia
			namecheck.target = player.realmo
			namecheck.scale = $<<2
			namecheck.z = $ - (namecheck.height>>1) + (player.realmo.height>>1) -- this calls P_CheckPosition for us, thanks Lua!
		end
		player.twodchecknames = false
	end
end