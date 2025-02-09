G_AddGametype({
    name = "Fang's Heist",
    identifier = "FANGSHEIST",
    typeoflevel = freeslot"TOL_HEIST",
    intermissiontype = int_none,
    rules = GTR_FRIENDLYFIRE|GTR_SPAWNINVUL|GTR_DEATHPENALTY|GTR_SPAWNENEMIES,
    headerleftcolor = 222,
    headerrightcolor = 84,
	description = "w.i.p mode, sequel to nick's pizza time"
})

rawset(_G, "FangsHeist", {Net = {}, HUD = {}, Objects = {}, Save = {}})

// FANGS HEIGHT IS BY SAXASHITTER
// OFFICIAL SEQUEL TO NICK'S PIZZA TIME!

rawset(_G, "FH_ATTACKCOOLDOWN", TICRATE)
rawset(_G, "FH_ATTACKTIME", G)
rawset(_G, "FH_BLOCKCOOLDOWN", 5)
rawset(_G, "FH_BLOCKTIME", 5*TICRATE)
rawset(_G, "FH_BLOCKDEPLETION", FH_BLOCKTIME/3)

dofile "gametypes"
dofile "files"
dofile "characters"

dofile "Functions/Inits"
dofile "Functions/Getters"
dofile "Functions/Checks"
dofile "Functions/Starters"
dofile "Functions/Triggers"

dofile "Hooks/Player/init"
dofile "Hooks/Game"
dofile "Hooks/HUD"
dofile "Hooks/Titlescreen"

dofile "Objects/Exit"
dofile "Objects/Treasures"
dofile "Objects/Signpost"
dofile "Objects/Bean"
dofile "Objects/Tails"
dofile "Objects/Hell Stage"

dofile "Objects/Bosses/GFZ3 Eggman"
dofile "Objects/Bosses/Missile"

dofile "Movesets/Fang"
dofile "Movesets/Amy"

dofile "modsupport"