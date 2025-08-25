local modifier = {name = "eggman"}

function modifier:init()
	FangsHeist.getGamemode():spawnEggman("pt")
end

return modifier