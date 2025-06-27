local B = CBW_Battle
local F = B.CTF

F.HUD = function(v, player, cam)
	if not (B.HUDMain) then return end
	if not hud.enabled("teamscores") then return end -- Gateway.
	
	local redflag = F.RedFlag
	local blueflag = F.BlueFlag
	
	for p in players.iterate
		if p.valid and p.mo and p.mo.valid and p.gotflag
			if p.ctfteam == 1
				blueflag = p.mo
			elseif p.ctfteam == 2
				redflag = p.mo
			end
		end
	end
	
	local flags = V_HUDTRANS|V_SNAPTOTOP|V_PERPLAYER
	local xoffsetred = 152 + 20
	local xoffsetblue = 152 - 20
	local yoffset = 25
	local angle
	local cmpangle
	local compass
	local color
	
	local xx = cam.x
	local yy = cam.y
	local zz = cam.z
	local lookang = cam.angle
	if (player.spectator or not cam.chase) and (player.realmo and player.realmo.valid)//Use the realmo coordinates when not using chasecam
		xx = player.realmo.x
		yy = player.realmo.y
		zz = player.realmo.z
		lookang = player.cmd.angleturn<<16
	end
	
	color = v.getColormap(TC_DEFAULT,SKINCOLOR_RED)
	if redflag and redflag.valid and not (player.mo and player.mo == redflag)
		if twodlevel then
			angle = R_PointToAngle2(xx, zz, redflag.x, redflag.z) - ANGLE_90 + ANGLE_22h
		else
			angle = R_PointToAngle2(xx, yy, redflag.x, redflag.y) - lookang + ANGLE_22h
		end
		
		local cmpangle = 8
		if (angle >= 0) and (angle < ANGLE_45)
			cmpangle = 1
		elseif (angle >= ANGLE_45) and (angle < ANGLE_90)
			cmpangle = 2
		elseif (angle >= ANGLE_90) and (angle < ANGLE_135)
			cmpangle = 3
		elseif (angle >= ANGLE_135)// and (angle < ANGLE_180)
			cmpangle = 4
		elseif (angle >= ANGLE_180) and (angle < ANGLE_225)
			cmpangle = 5
		elseif (angle >= ANGLE_225) and (angle < ANGLE_270)
			cmpangle = 6
		elseif (angle >= ANGLE_270) and (angle < ANGLE_315)
			cmpangle = 7
		end
		
		compass = v.getSpritePatch("CMPS",A,max(min(cmpangle,8),1))

		v.draw(xoffsetred,yoffset,compass,flags,color)
		
	elseif player.mo and player.mo == redflag
		compass = v.cachePatch("FLAGICO")
		v.draw(xoffsetred,yoffset,compass,flags,color)
	end
	
	color = v.getColormap(TC_DEFAULT,SKINCOLOR_BLUE)
	if blueflag and blueflag.valid and not (player.mo and player.mo == blueflag)
		if twodlevel then
			angle = R_PointToAngle2(xx, zz, blueflag.x, blueflag.z) - ANGLE_90 + ANGLE_22h
		else
			angle = R_PointToAngle2(xx, yy, blueflag.x, blueflag.y) - lookang + ANGLE_22h
		end
		
		local cmpangle = 8
		if (angle >= 0) and (angle < ANGLE_45)
			cmpangle = 1
		elseif (angle >= ANGLE_45) and (angle < ANGLE_90)
			cmpangle = 2
		elseif (angle >= ANGLE_90) and (angle < ANGLE_135)
			cmpangle = 3
		elseif (angle >= ANGLE_135)// and (angle < ANGLE_180)
			cmpangle = 4
		elseif (angle >= ANGLE_180) and (angle < ANGLE_225)
			cmpangle = 5
		elseif (angle >= ANGLE_225) and (angle < ANGLE_270)
			cmpangle = 6
		elseif (angle >= ANGLE_270) and (angle < ANGLE_315)
			cmpangle = 7
		end
		
		compass = v.getSpritePatch("CMPS",A,max(min(cmpangle,8),1))

		v.draw(xoffsetblue,yoffset,compass,flags,color)

	elseif player.mo and player.mo == blueflag
		compass = v.cachePatch("FLAGICO")
		v.draw(xoffsetblue,yoffset,compass,flags,color)
	end
end