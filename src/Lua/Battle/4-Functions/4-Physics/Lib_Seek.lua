local B = CBW_Battle

B.GetNearestPlayer = function(mo,fov,teamcheck,aim,ignorepain) //Note: this returns player, NOT player.mo!
	if not(mo.player) and not (teamcheck == nil or teamcheck == 0) then return nil end //Teamchecks aren't allowed on nonplayer objects
	local nearest
	local neardist
	//Cycle through players
	for player in players.iterate
		//Failchecks
		if not (player.mo and player.playerstate == PST_LIVE) then continue end //Invalid player object
		if player.mo == mo then continue end // Don't count ourselves!
		if (teamcheck == 1 and not(B.MyTeam(player,mo.player))) //Need teammate
			or (teamcheck == -1 and B.MyTeam(player,mo.player)) //Need opponent
			or not(P_CheckSight(player.mo,mo)) //Not in view
			or player.mo.flags&MF_NOCLIPTHING //Can't target!
			then continue
		end
		if ignorepain == true and not(B.PlayerCanBeDamaged(player)) then continue end //Ignore invulnerable players
		if fov != nil then
			if aim == nil then aim = mo.angle end
			//Get angle
			local ang = R_PointToAngle2(mo.x,mo.y,player.mo.x,player.mo.y)-aim
			if ang > 180*ANG1 then ang = $-360*ANG1
			elseif ang < -180*ANG1 then ang = $+360*ANG1
			end
			//Check field of view
			if (ang < -fov/2*ANG1 or ang > fov/2*ANG1) then continue end
		end
		//Get distance
		local dist = R_PointToDist2(player.mo.x,player.mo.y,mo.x,mo.y)
		if nearest == nil or neardist > dist then
			nearest = player
			neardist = dist
		end
	end
	return nearest
end

B.SearchObject = function(mo,aim,fov,range,searchflags,refmo,teamcheck)
		refmo = $ or mo
		aim = $ or mo.angle
		local team
		if teamcheck then
			if (mo.player) then
				team = mo.player.ctfteam
			else
				team = mo.ctfteam
			end
			if not(team)
				team = 0
				teamcheck = 0
			end
		end
		local m = nil
		searchBlockmap('objects',function(mo,found)
			local dist = R_PointToAngle2(mo.x,mo.y,found.x,found.y)
			local angle = abs(dist-aim)
			if found != refmo
				and ((found.flags&searchflags and not(found.flags2&MF2_INVERTAIMABLE))
					or(found.flags2&MF2_INVERTAIMABLE and not(found.flags&searchflags)))
				and P_CheckSight(mo,found) and found.health and (not(fov) or abs(angle) < fov/2*ANG1)
				and (
					(teamcheck == nil or teamcheck == 0) or (teamcheck == 1 and team == found.ctfteam) or (teamcheck == -1 and team != found.ctfteam)
				)
				and
					not(refmo and refmo.type == found.type and refmo.target == found.target)
				and (
					not(m and m.valid) 
					or (R_PointToDist2(mo.x,mo.y,m.x,m.y)+abs(mo.z-m.z) > R_PointToDist2(mo.x,mo.y,found.x,found.y)+abs(mo.z-found.z))
				) then
				m = found
			end
		end,mo,mo.x-range,mo.x+range,mo.y-range,mo.y+range)
		return m
end

B.AutoAim = function(mo,aim,fov,teamcheck,ignorepain,projectile,speed,searchflags)
	local p = B.GetNearestPlayer(mo,fov,teamcheck,aim,ignorepain)
	if p then 
		local dist = FixedHypot(FixedHypot(p.mo.momx,p.mo.momy),p.mo.momz)
		local x1,y1,z1 = projectile.x,projectile.y,projectile.z
		local x2,y2,z2 = p.mo.x+p.mo.momx,p.mo.y+p.mo.momy,p.mo.z+p.mo.height/2+p.mo.momz
		local zang = B.GetZAngle(x1,y1,z1,x2,y2,z2)
		local xyang = R_PointToAngle2(x1,y1,x2,y2)
		B.InstaThrustZAim(projectile,xyang,zang,speed)
		return p.mo
	else
		local p = B.SearchObject(mo,aim,fov,mo.scale*640,searchflags,nil,teamcheck)
		if p then
			local x1,y1,z1 = projectile.x,projectile.y,projectile.z
			local x2,y2,z2 = p.x+p.momx,p.y+p.momy,p.z+p.momz
			local zang = max(-ANG60,min(ANG60,B.GetZAngle(projectile.x,projectile.y,projectile.z,p.x,p.y,p.z+projectile.height/2)))
			local xyang = R_PointToAngle2(x1,y1,x2,y2)
			B.InstaThrustZAim(projectile,xyang,zang,speed)
			return p
		end
	end
	return false
end

