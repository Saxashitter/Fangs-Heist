G_AddGametype({
    name = "Fang's Heist",
    identifier = "FANGSHEIST",
    typeoflevel = TOL_COOP,
    rules = GTR_FRIENDLYFIRE|GTR_SPAWNINVUL|GTR_DEATHPENALTY|GTR_SPAWNENEMIES|GTR_TEAMFLAGS,
    intermissiontype = int_match,
    headerleftcolor = 222,
    headerrightcolor = 84,
	description = "w.i.p mode, sequel to nick's pizza time"
})

rawset(_G, "FangsHeist", {Net = {}, HUD = {}, Objects = {}})

// FANGS HEIGHT IS BY SAXASHITTER
// OFFICIAL SEQUEL TO NICK'S PIZZA TIME!

dofile "Functions/Inits"
dofile "Functions/Getters"
dofile "Functions/Checks"
dofile "Functions/Starters"

dofile "Hooks/Player"
dofile "Hooks/Game"
dofile "Hooks/HUD"

dofile "Objects/Signpost"
dofile "Objects/Exit"