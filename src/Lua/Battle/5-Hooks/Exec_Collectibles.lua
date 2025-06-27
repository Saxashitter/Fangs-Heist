local B = CBW_Battle
local F = B.CTF

-- Disallow revenge jettysyns and spawning players from collecting items
for n = 0, #mobjinfo-1 do
	if mobjinfo[n].flags & MF_SPECIAL and n != MT_PLAYER
		addHook("TouchSpecial",function(...)
			return B.TouchSpecial(...)
		end, n)
	end
end

-- Rings
addHook("MobjThinker", function(...)
	return B.Arena.RingLoss(...)
end, MT_FLINGRING)

-- CTF Flags
addHook("MobjSpawn", function(mo)
	F.FlagSpawn(mo)
end, MT_REDFLAG)
addHook("MobjSpawn", function(mo)
	F.FlagSpawn(mo)
end, MT_BLUEFLAG)
addHook("MobjThinker",function(...)
	return F.FlagThinker(...)
end, MT_REDFLAG)
addHook("MobjThinker",function(...)
	return F.FlagThinker(...)
end, MT_BLUEFLAG)
addHook("TouchSpecial", function(...)
	return F.TouchFlag(...)
end, MT_REDFLAG)
addHook("TouchSpecial", function(...)
	return F.TouchFlag(...)
end, MT_BLUEFLAG)