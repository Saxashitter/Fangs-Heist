local B = CBW_Battle
local Bb = B.Battleball
local CV = B.Console

Bb.HUD = function(v, player, cam)
	local id = Bb.ID
	if not (B.HUDMain) then return end
	if not (id and id.valid) then return end
	if not (player.realmo) then return end
-- 	if B.PreRoundWait() then return end
	local flags = V_HUDTRANS|V_SNAPTOTOP|V_PERPLAYER
	local xoffset = 152
	local yoffset = 4
	local angle
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
	
	
	if twodlevel then
		angle = R_PointToAngle2(xx, zz, id.x, id.z) - ANGLE_90 + ANGLE_22h
	else
		angle = R_PointToAngle2(xx, yy, id.x, id.y) - lookang + ANGLE_22h
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
	local pcol = id.color
	color = v.getColormap(TC_DEFAULT,pcol)
	local cflags = flags
	
	//Draw
	v.draw(xoffset,yoffset,compass,cflags,color)
	
	local text = ""
	local center = 8
	local left = -2
	local right = 8
	local blue = center-1
	local red = center+1
	local bottom = 20
	local centeralign = "center"
	local leftalign = "thin-right"
	local rightalign = "thin"
	//Get timer
	if not id.target and id.fuse
		local text = id.fuse/TICRATE
		v.drawString(xoffset+center,yoffset+bottom,text,flags,centeralign) //Draw timer
	end
end