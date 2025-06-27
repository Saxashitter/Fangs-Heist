local B = CBW_Battle
local CP = B.ControlPoint

-- System
addHook("MapChange", function(...)
	return CP.ResetMode(...)
end)
addHook("MapLoad", function(...)
	CP.Generate(...)
	CP.TryNextPoint()
end)
addHook("PreThinkFrame", do
	for player in players.iterate do
		if player.capturing and not(leveltime&7) then
			P_AddPlayerScore(player,1)
		end
		player.capturing = 0
	end
end)
addHook("ThinkFrame", function(...)
	return CP.ThinkFrame(...)
end)


-- CP object
addHook("MobjSpawn", function(...)
	return CP.MobjSpawn(...)
end, MT_CONTROLPOINT)
addHook("MapThingSpawn", function(...)
	return CP.MapThingSpawn(...)
end, MT_CONTROLPOINT)
addHook("MobjThinker", function(...)
	return CP.MobjThinker(...)
end, MT_CONTROLPOINT)
addHook("MobjFuse", function(...)
	return CP.MobjFuse(...)
end, MT_CONTROLPOINT)

addHook("MobjRemoved",function(mo)
	if mo.target and mo.target.player then P_SpawnMobj(mo.x,mo.y,mo.z,MT_SPARK) end
end, MT_CPBONUS)
