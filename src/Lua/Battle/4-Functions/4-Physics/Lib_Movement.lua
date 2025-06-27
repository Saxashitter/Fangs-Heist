local B = CBW_Battle

B.AngleTeleport = function(mo,coords,xyangle,zangle,distance)
	local x = coords[1]
	local y = coords[2]
	local z = coords[3]
	local xythrust = P_ReturnThrustX(nil,zangle,distance)
	local xthrust = P_ReturnThrustX(nil,xyangle,xythrust)
	local ythrust = P_ReturnThrustY(nil,xyangle,xythrust)
	local zthrust = P_ReturnThrustY(nil,zangle,distance)
	P_TeleportMove(mo,x+xthrust,y+ythrust,z+zthrust)
	return {xythrust/FRACUNIT,zthrust/FRACUNIT}
end

B.InstaThrustZAim = function(mo,xyangle,zangle,speed,relative)
	local xythrust = P_ReturnThrustX(nil,zangle,speed)
	local zthrust = P_ReturnThrustY(nil,zangle,speed)
	if relative then
		P_Thrust(mo,xyangle,xythrust)		
		mo.momz = $+zthrust	
	else
		P_InstaThrust(mo,xyangle,xythrust)		
		mo.momz = zthrust	
	end
	return {xythrust/FRACUNIT,zthrust/FRACUNIT}
end

B.ControlThrust = function(mo,friction,limit,zfriction,zlimit)
	//Friction
	if friction == nil then friction = mo.friction end
	if limit == nil then limit = FRACUNIT*80 end
	
	if P_IsObjectOnGround(mo) then
		mo.friction = friction
		limit = FixedMul(mo.scale,$)
		local spd = min(limit,max(-limit,
			FixedHypot(mo.momx,mo.momy)
		))
		local ang = R_PointToAngle2(0,0,mo.momx,mo.momy)
		mo.momx = P_ReturnThrustX(nil,ang,spd)
		mo.momy = P_ReturnThrustY(nil,ang,spd)
	else
		//XY movement
		limit = FixedMul(mo.scale,$)
		local spd = min(limit,max(-limit,
			FixedHypot(mo.momx,mo.momy)
		))
-- 		friction = FixedDiv($,mo.scale)
		spd = FixedMul(spd,friction)
		local ang = R_PointToAngle2(0,0,mo.momx,mo.momy)
		mo.momx = P_ReturnThrustX(nil,ang,spd)
		mo.momy = P_ReturnThrustY(nil,ang,spd)
		//Z movement
		if zfriction == nil then zfriction = friction end
		if zlimit == nil then zlimit = limit end
		zlimit = FixedDiv($,mo.scale)
		mo.momz = min(zlimit,max(-zlimit,
			FixedMul($,zfriction)
		))
	end
end

B.InstaThrustSpread = function(mo,aim,spread,angle,speed)
	local xyangle = (angle-90)*ANG1*2
	local zangle = angle*ANG1*2
	local xymul = FRACUNIT/180*spread
	local zmul = FRACUNIT/180*spread
	if sin(angle*ANG1) < 0 then zmul = $*-1 end
	if cos(angle*2*ANG1) < 0 then xymul = -1*zmul end
	xyangle = FixedMul($,xymul)
	zangle = FixedMul(abs($),zmul)
	B.InstaThrustZAim(mo,xyangle+aim,zangle,speed)
end

B.ZLaunch = function(mo,thrust,relative)
	if mo.eflags&MFE_UNDERWATER
		thrust = $*3/5
	end
	P_SetObjectMomZ(mo,thrust,relative)
end

B.XYLaunch = function(mo, angle, thrust, relative)
	if mo.eflags & MFE_UNDERWATER
		thrust = $*11/20
	end
	if twodlevel or mo.flags2 & MF2_TWOD
		thrust = $*3/4
	end
	thrust = FixedMul(mo.scale, $)
	if relative
		P_Thrust(mo, angle, thrust)
	else
		P_InstaThrust(mo, angle, thrust)
	end
end