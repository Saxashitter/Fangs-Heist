local B = CBW_Battle

B.FixedLerp = function(val1,val2,amt)
	return FixedMul(FRACUNIT-amt,val1) + FixedMul(amt,val2)
end

B.ZCollide = function(mo1,mo2)
	if mo1.z > mo2.height+mo2.z then return false end
	if mo2.z > mo1.height+mo1.z then return false end
	return true
end

B.GetZAngle = function(x1,y1,z1,x2,y2,z2)
	local xydist = R_PointToDist2(x1,y1,x2,y2)
	local zdist = z2-z1
	return R_PointToAngle2(0,0,xydist,zdist)
end

-- Distance functions
local X = 1<<0
local Y = 1<<1
local Z = 1<<2
local distfunc = {}
-- One-dimensional distance checks
distfunc[X] = function(x1,y1,z1,x2,y2,z2)
	return abs(x1 - x2)
end
distfunc[Y] = function(x1,y1,z1,x2,y2,z2)
	return abs(y1 - y2)
end
distfunc[Z] = function(x1,y1,z1,x2,y2,z2)
	return abs(z1 - z2)
end
-- Two-dimensional distance checks
distfunc[X|Y] = function(x1,y1,z1,x2,y2,z2)
	return R_PointToDist2(x1, y1, x2, y2)
end
distfunc[X|Z] = function(x1,y1,z1,x2,y2,z2)
	return R_PointToDist2(x1, z1, x2, z2)
end
distfunc[Y|Z] = function(x1,y1,z1,x2,y2,z2)
	return R_PointToDist2(y1, z1, y2, z2)
end
-- Three-dimensional distance checks
distfunc[X|Y|Z] = function(x1,y1,z1,x2,y2,z2)
	return R_PointToDist2(z1, 0, z2, R_PointToDist2(x1, y1, x2, y2))
end



B.GetPointDistance = function(...) -- Get the XYZ distance between two sets of points.
	-- This is optimized to call the least performance-heavy function based on which coordinate equivalencies are found.
	local flags = (x1 != x2 and X or 0) | (y1 != y2 and Y or 0) | (z1 != z2 and Z or 0)
	return flags and distfunc[flags](...)
end
B.GetMobjDistance = function(mo1, mo2, _3d, roundxy1, roundxy2, roundz1, roundz2) -- Get the spherical distance between two objects, accounting for hitbox widths
	--!! Not implemented: round collision checks
	
	local r1, r2, h1, h2 = 
		mo1.radius,
		mo2.radius,
		mo1.height,
		mo2.height
	local x1,x2,y1,y2,z1,z2
		= mo1.x,
		mo2.x,
		mo1.y,
		mo2.y,
		mo1.z,
		mo2.z
	-- Bounding box checks
	if x1 - r1 > x2 + r2
		x1 = $ - r1
		x2 = $ + r2
	elseif x2 - r2 > x2 + r1
		x1 = $ + r1
		x2 = $ - r2
	else
		x1 = 0
		x2 = 0
	end
	if y1 - r1 > y2 + r2
		y1 = $ - r1
		y2 = $ + r2
	elseif y2 - r2 > y1 + r1
		y1 = $ + r1
		y2 = $ - r2
	else
		y1 = 0
		y2 = 0
	end
	-- 3d bounding box checks
	if _3d
		if z1 > z2 + h2
			z2 = $ + h2
		elseif z2 > z1 + h1
			z1 = $ + h1
		else
			z1 = 0
			z2 = 0
		end
	else
		z1 = 0
		z2 = 0
	end
		
	return B.GetPointDistance(x1, y1, z1, x2, y2, z2)
end

local baseChars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz!@"

/*
B.BaseConv = function(number, base, chars)
    if not chars then
        chars = baseChars
    end

    local outstring = ""

    if (number == 0) then
        return "0";
    end

    local i = 0

    while (number > 0) do
        local index = number % base
        outstring[i] = chars[index]
        number = $ / base

        i = i + 1
    end

    string.reverse(outstring)

    return outstring
end
*/