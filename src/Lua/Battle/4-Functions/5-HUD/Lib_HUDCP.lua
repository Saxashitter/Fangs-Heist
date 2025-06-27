local B = CBW_Battle
local CP = B.ControlPoint

CP.HUD = function(v, player, cam)
	if not (player.realmo and CP.Mode and server) then return end
	if not (B.HUDMain) then return end -- What's this for?
	if B.PreRoundWait() then return end
	local flags = V_HUDTRANS|V_SNAPTOTOP|V_PERPLAYER
-- 	local xoffset = 152
	local yoffset = 4
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
	local t = {}
	for n,pid in ipairs(CP.ID) do --Determine which CPs to make space for on the HUD
		if pid.capture_status != CP_INERT or (pid.fuse <= 10*TICRATE and pid.fuse)
			table.insert(t, pid)
		end
	end
	local center = 8
	local left = -1
	local right = 19
	local blue = center-1
	local red = center+1
	local bottom = 12
	local scale = FRACUNIT
	local centeralign = "center"
	local leftalign = "thin-right"
	local rightalign = "thin"
	if #t > 2
		center = $/2
		left = $/2
		right = $/2
		blue = $-center
		red = $-center
		bottom = $/2
		scale = $/2
		centeralign = "small-center"
		leftalign = "small-thin-right"
		rightalign = "small-thin"		
	end
	for n,pid in ipairs(t)
		local xoffset = 120 + 200*n/(#t+1) - center
		local time = pid.fuse
		local leader = pid.capture_leader and players[pid.capture_leader-1] or nil
		if (pid.capture_status != CP_INERT or (time <= 10*TICRATE and time&1))
			and pid and pid.valid then
					-- Use the angle based off x and z rather than x and y
			if twodlevel then
				angle = R_PointToAngle2(xx, zz, pid.x, pid.z) - ANGLE_90 + ANGLE_22h
			else
				angle = R_PointToAngle2(xx, yy, pid.x, pid.y) - lookang + ANGLE_22h
			end
			
			local cmpangle = 8
			if (angle >= 0) and (angle < ANGLE_45)
				cmpangle = 1
			elseif (angle >= ANGLE_45) and (angle < ANGLE_90)
				cmpangle = 2
			elseif (angle >= ANGLE_90) and (angle < ANGLE_135)
				cmpangle = 3
			elseif (angle >= ANGLE_135)
				cmpangle = 4
			elseif (angle >= ANGLE_180) and (angle < ANGLE_225)
				cmpangle = 5
			elseif (angle >= ANGLE_225) and (angle < ANGLE_270)
				cmpangle = 6
			elseif (angle >= ANGLE_270) and (angle < ANGLE_315)
				cmpangle = 7
			end
			
			compass = v.getSpritePatch("CMPS",A,max(min(cmpangle,8),1))
			local pcol = pid.color
			if (G_GametypeHasTeams() and pid.capture_status <= CP_ACTIVE or pcol == SKINCOLOR_JET)
				pcol = SKINCOLOR_SILVER
			end
			color = v.getColormap(TC_DEFAULT,pcol)
			//Draw
			v.drawScaled(FRACUNIT*xoffset,FRACUNIT*yoffset,scale,compass,flags,color)
		end
		local text = ""
		//Waiting for CP to open
		if time then
			text = time/TICRATE
			v.drawString(xoffset+center,yoffset+bottom,text,flags,centeralign) //Draw timer
		elseif pid.capture_status != CP_INERT then //CP is active
			if not(G_GametypeHasTeams()) then //Free-for-all
				//Get lead capper
				if leader and leader.valid and leader.mo and leader.mo.valid
-- 					and leader.captureamount == CP.LeadCapAmt and leader.playerstate == PST_LIVE
					then
					v.drawScaled(FRACUNIT*(xoffset+right+center*2), FRACUNIT*(yoffset+bottom), scale, v.getSprite2Patch(leader.mo.skin, SPR2_LIFE),
						flags|V_FLIP, v.getColormap(leader.mo.skin, leader.mo.color))
				end
				text = "\x82"..pid.capture_highscore*100/pid.cp_meter.."%" //Suppose it doesn't hurt to draw this either way...
				v.drawString(xoffset+right,yoffset+4,text,flags,rightalign)
				//Get our player
				if player.mo and pid.capture_status != CP_INERT
					if player.capturing == pid.cpnum
						v.drawScaled(FRACUNIT*(xoffset+left-center*2), FRACUNIT*(yoffset+bottom), scale, v.getSprite2Patch(player.mo.skin, SPR2_LIFE),
							flags, v.getColormap(player.mo.skin, player.mo.color))
					end
					text = pid.capture_amount[#player+1]*100/pid.cp_meter.."%"
					v.drawString(xoffset+left,yoffset+4,text,flags,leftalign)
				end
			else //Team CP
				text = pid.capture_amount[2]*100/pid.cp_meter.."%"
				v.drawString(xoffset+blue,yoffset+4+bottom,text,flags,leftalign)
				text = pid.capture_amount[2]*100/pid.cp_meter.."%"
				v.drawString(xoffset+red,yoffset+4+bottom,text,flags,rightalign)
			end		
		end
	end
end