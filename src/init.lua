rawset(_G, "FangsHeist", {
	Net = {},
	Objects = {},
	Save = {},
	HUD = {},
	PlayerMT = {},
	Version = {
	Num = 1,
	String = "1.0.1",
	}
})
/*
FANG'S HEIST BY TEAM FRACTURE 
LED BY TEAM DIRECTOR: SAXASHITTER

Official Sequel of Nick's Pizza Time!
*/
dofile "freeslots"
dofile "hooks.lua"
dofile "constants"
dofile "characters"
dofile "console"

dofile "Metatables/Player/init"

dofile "Functions/Inits"
dofile "Functions/Getters"
dofile "Functions/Checks"
dofile "Functions/Starters"
dofile "Functions/Triggers"
dofile "Functions/HUD"

dofile "gamemodes.lua"

dofile "Hooks/Player/init"
dofile "Hooks/Game/init"
dofile "Hooks/HUD"
dofile "Hooks/Titlescreen"

dofile "Carriables/init"

dofile "Objects/Eggman"
dofile "Objects/Exit"
--dofile "Objects/Treasures"
dofile "Objects/Signpost"
dofile "Objects/Bean"
dofile "Objects/Tails"
dofile "Objects/Hell Stage"
dofile "Objects/Hitbox"

dofile "Objects/Bosses/GFZ3 Eggman"
dofile "Objects/Bosses/Missile"

dofile "Effects/main"

dofile "Movesets/Sonic"
dofile "Movesets/Tails"
dofile "Movesets/Knuckles"
dofile "Movesets/Amy"
dofile "Movesets/Fang"
dofile "Movesets/Metal Sonic"

dofile "Compat/Speed Cap"