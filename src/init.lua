G_AddGametype({
    name = "Fang's Heist",
    identifier = "FANGSHEIST",
    typeoflevel = TOL_COOP,
    rules = GTR_FRIENDLYFIRE|GTR_SPAWNINVUL|GTR_DEATHPENALTY|GTR_SPAWNENEMIES,
    intermissiontype = int_match,
    headerleftcolor = 222,
    headerrightcolor = 84,
	description = "w.i.p mode, sequel to nick's pizza time"
})

rawset(_G, "FangsHeist", {Net = {}, HUD = {}})

// FANGS HEIGHT IS BY SAXASHITTER
// OFFICIAL SEQUEL TO NICK'S PIZZA TIME!

dofile "Functions/Getters"
dofile "Functions/Checks"
dofile "Functions/Inits"

dofile "Hooks/Player"
dofile "Hooks/Game"

dofile "Objects/Signpost"