rawset(_G, "FangsHeist", {
	Net = {},
	Objects = {},
	Save = {},
	PlayerMT = {}
})

// FANGS HEIGHT IS BY SAXASHITTER
// OFFICIAL SEQUEL TO NICK'S PIZZA TIME!

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

dofile "modsupport"

dofile "Compat/S3 Sonic"
dofile "Compat/Bean"
dofile "Compat/Eggman"
dofile "Compat/DeltaChars"