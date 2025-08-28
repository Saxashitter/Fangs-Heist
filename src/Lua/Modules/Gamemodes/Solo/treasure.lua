local gamemode = {}

function gamemode:spawnTreasure(thing)
	FangsHeist.Carriables:new("Treasure", thing.x, thing.y, thing.z)
end

return gamemode