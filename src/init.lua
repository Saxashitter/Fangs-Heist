G_AddGametype({
    name = "Fang's Heist",
    identifier = "FANGSHEIST",
    typeoflevel = TOL_COOP,
    intermissiontype = int_none,
    rules = GTR_FRIENDLYFIRE|GTR_SPAWNINVUL|GTR_DEATHPENALTY|GTR_SPAWNENEMIES,
    headerleftcolor = 222,
    headerrightcolor = 84,
	description = "w.i.p mode, sequel to nick's pizza time"
})

rawset(_G, "FangsHeist", {Net = {}, HUD = {}, Objects = {}, onHook = {}})

// FANGS HEIGHT IS BY SAXASHITTER
// OFFICIAL SEQUEL TO NICK'S PIZZA TIME!

dofile "Functions/Inits"
dofile "Functions/Getters"
dofile "Functions/Checks"
dofile "Functions/Starters"

dofile "Hooks/Player"
dofile "Hooks/Game"
dofile "Hooks/HUD"

dofile "Objects/Treasures"
dofile "Objects/Signpost"
dofile "Objects/Exit"

dofile "modsupport"