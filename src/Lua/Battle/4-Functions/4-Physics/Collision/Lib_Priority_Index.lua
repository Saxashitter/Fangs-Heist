local B = CBW_Battle
local PFunc = B.PriorityFunction

local xyangle = B.GetCollideRelativeAngle
local zangle = B.GetZCollideAngle

B.SPriority_Fly = function(mo,other)
	if zangle(mo,other) > -ANGLE_45 then return false
	else return true end
end

B.SPriority_Glide = function(mo,other)
	if abs(zangle(mo,other)) > ANGLE_45 or abs(xyangle(mo,other,true)) > ANGLE_45 then return false
	else return true end
end

B.SPriority_TwinSpin = function(mo,other)
	if mo.player then mo.player.pflags = $&~PF_THOKKED end
	if xyangle(mo,other,true) > ANGLE_45 then return false
	else return true end
end

B.SPriority_Melee = function(mo,other)
	if abs(xyangle(mo,other,true)) > ANGLE_45 then return false
	else return true end
end

B.SPriority_TailBounce = function(mo,other)
	if (B.GetZCollideAngle(mo,other) < ANGLE_45) then return false end
	S_StartSound(mo, sfx_s3k90)
	return true
end

B.SPriority_SpringDrop = function(mo,other)
	if (B.GetZCollideAngle(mo,other) < ANGLE_22h) then return false end
	S_StartSound(mo, sfx_s3k90)
	return true
end

B.SPriority_Stomp = function(mo,other)
	if (B.GetZCollideAngle(mo,other) < ANGLE_22h) then return false end
	S_StartSound(mo, sfx_s3k90)
	return true
end

/*
B.SPriority_StompDamage = function(mo,other)
	local bottomheight = mo.z
	local topheight = mo.z + mo.height

	if (mo.eflags & MFE_VERTICALFLIP)
		local swap = bottomheight
		bottomheight = topheight
		topheight = swap
	end

	if not ((P_MobjFlip(mo)*(bottomheight - (other.z + other.height/2)) > 0)
	and (P_MobjFlip(mo)*(mo.momz - other.momz) < 0)) then return false
	else return true end
end
*/
B.SPriority_CanDamage = function(mo,other)
	if not (mo.player and P_PlayerCanDamage(mo.player,other)) then return false
	else return true end
end

B.AddPriorityFunction = function(name,func)
	if not(name) then //Invalid name
		B.Warning("Invalid argument #1 provided for CBW_Battle.AddPriorityFunction()")
	return nil end
	if not(type(name) == "string") then //Name isn't a string
		B.Warning("Argument #1 for CBW_Battle.AddPriorityFunction() must be a string!")
	return nil end
	if PFunc[name] != nil then //Name already exists
		B.Warning("CBW_Battle.PriorityFunction['"..name.."'] is already defined!")
	return nil end
	if not(func) then //Invalid function argument
		B.Warning("Invalid argument #2 provided for CBW_Battle.AddPriorityFunction()")
	return nil end
	if not(type(func) == "function") then //argument type is not a function
		B.Warning("Argument #2 for CBW_Battle.AddPriorityFunction() must be a function!")
	return nil end
	PFunc[name] = func
	return name
end

local Add = B.AddPriorityFunction

Add("tails_fly",B.SPriority_Fly)
Add("knuckles_glide",B.SPriority_Glide)
Add("amy_twinspin",B.SPriority_TwinSpin)
Add("amy_melee",B.SPriority_Melee)
Add("fang_tailbounce",B.SPriority_TailBounce)
Add("fang_springdrop",B.SPriority_SpringDrop)
Add("can_damage",B.SPriority_CanDamage)
Add("stomp",B.SPriority_Stomp)