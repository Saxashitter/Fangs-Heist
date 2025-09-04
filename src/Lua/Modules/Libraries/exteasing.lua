--Extended Easing Libary by RedFoxyBoy :3
/*
Source:
easings.net
*/
local extease = {}
local function pow(x, n)
	local ogx = x
	for i = 1, (n-1) do
		x = FixedMul(x, ogx)
	end
	return x
end

--Circ
extease.incirc = function(t,b,c)
	return ease.linear(FU-FixedSqrt(FU-pow(t,2)),b,c)
end
extease.outcirc = function(t,b,c)
	return ease.linear(FixedSqrt(FU-pow(t-FU,2)),b,c)
end
extease.inoutcirc = function(t,b,c)
	local x = 0
	local h = tofixed("0.5")
	if t <= h
		x = extease.incirc(FixedDiv(t,h),0,h)
	else
		x = extease.outcirc(FixedDiv(t-h,h),h,FU)
	end
	return ease.linear(x,b,c)
end


return extease