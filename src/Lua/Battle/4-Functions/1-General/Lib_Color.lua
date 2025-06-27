local B = CBW_Battle
B.FlashColor = function(colormin,colormax)
	local N = 32 //Rate of oscillation
-- 	local size = colormax-colormin+1 //Color spectrum
	local scale = 2 //Factor-amount to reduce the oscillation intensity
	local offset = 0 //Offset the origin of oscillation
	local oscillate = abs((leveltime&(N*2-1))-N)/scale //Oscillation cycle
	local c = colormin+oscillate+offset //offset
	c = max(colormin,min(colormax,$)) //Enforce min/max
	return c
end

B.FlashRainbow = function(mo)
	local t = (leveltime&15)>>1
	return B.FlashColor(
		SKINCOLOR_SUPERSILVER1 + t*5,
		SKINCOLOR_SUPERSILVER5 + t*5
	)
end