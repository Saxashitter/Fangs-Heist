G_AddGametype({
    name = "Fang's Heist",
    identifier = "FANGSHEIST",
    typeoflevel = freeslot"TOL_HEIST",
    intermissiontype = int_none,
    rules = GTR_FRIENDLYFIRE|GTR_SPAWNINVUL|GTR_DEATHPENALTY|GTR_SPAWNENEMIES,
    headerleftcolor = 195,
    headerrightcolor = 112,
	description = "Grab that \130signpost\128, get more \131profit,\128\nand GO! GO! GO!"
})

rawset(_G, "FangsHeist", {Net = {}, HUD = {}, Objects = {}, Save = {}})

// FANGS HEIGHT IS BY SAXASHITTER
// OFFICIAL SEQUEL TO NICK'S PIZZA TIME!

dofile "HookLib"

dofile "constants"
dofile "files"
dofile "characters"
dofile "console"

dofile "Functions/Inits"
dofile "Functions/Getters"
dofile "Functions/Checks"
dofile "Functions/Starters"
dofile "Functions/Triggers"

dofile "Hooks/Player/init"
dofile "Hooks/Game/init"
dofile "Hooks/HUD"
dofile "Hooks/Titlescreen"

dofile "Objects/Eggman"
dofile "Objects/Exit"
dofile "Objects/Treasures"
dofile "Objects/Signpost"
dofile "Objects/Bean"
dofile "Objects/Tails"
dofile "Objects/Hell Stage"

dofile "Objects/Bosses/GFZ3 Eggman"
dofile "Objects/Bosses/Missile"

dofile "Movesets/Amy"
dofile "Movesets/Fang"

dofile "modsupport"

dofile "Compat/Mario"
dofile "Compat/Soap"
dofile "Compat/S3 Sonic"
dofile "Compat/Bean"
dofile "Compat/Eggman"