local B = CBW_Battle

B.DoBackdraft = function(player)
	if B.Console.Slipstream.value == 0 then return false end//Server has disabled the backdraft/slipstream mechanic
	if player.charmed == true then //Charmed players cannot take advantage of the backdraft mechanic
		player.backdraft = 0
		return false 
	end 

	local pmo = player.mo
	local angle = R_PointToAngle2(0,0,player.rmomx,player.rmomy)
	local nearest = CBW_Battle.GetNearestPlayer(pmo,45,0,angle)
	local topspeed = skins[pmo.skin].normalspeed
-- 	local threshold = 60
	local threshold = TICRATE*2
	//Add backdraft
	if nearest and R_PointToDist2(pmo.x,pmo.y,nearest.mo.x,nearest.mo.y) < pmo.scale*1960 and FixedHypot(player.rmomx,player.rmomy) >= player.runspeed then
		if abs(pmo.z-nearest.mo.z) < pmo.scale*256 then  //Prevent meter from going down, but don't let it increase if too far away vertically
			player.backdraft = min(threshold,$+1)
-- 			local dir = B.GetInputAngle(player)
-- 			if player.charflags&SF_DASHMODE
-- 				if player.dashmode < TICRATE*3-1 then
-- 					player.dashmode = $+1
-- 				end
-- 			end
			if not(player.backdraft < 16 or player.backdraft&1) then 
				//Add fx
				local f = FRACUNIT
				local r = pmo.radius/f
				local h = pmo.height/f
				local random1 = P_RandomRange(-r,r)*f
				local random2 = P_RandomRange(-r,r)*f
				local random3 = P_RandomRange(0,h)*f
				local m = P_SpawnMobj(random1+pmo.x,random2+pmo.y,random3+pmo.z,MT_SPINDUST)
				if m and m.valid then m.scale = $/2 end
				if player.backdraft&3 then
					local m = P_SpawnMobj(random1+(pmo.x+nearest.mo.x)/2,random2+(pmo.y+nearest.mo.y)/2,random3+(pmo.z+nearest.mo.z)/2,MT_SPINDUST)
					if m and m.valid then m.scale = $/2 end
				end
			end
		end
	else
		player.backdraft = max(0,$-1)
	end
	if player.backdraft >= threshold// and not(player.charflags&SF_DASHMODE) then
		if not(player.powers[pw_sneakers])
			S_StartSound(player.mo,sfx_s3ka2)
			P_SpawnParaloop(pmo.x,pmo.y,pmo.z+pmo.height/2,pmo.height,16,MT_DUST,pmo.angle*ANGLE_180,nil,false)
		end
		player.powers[pw_sneakers] = max($,TICRATE/2)
	end
end
