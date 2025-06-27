--[[Define TOLs
freeslot(
	'tol_arena',
	'tol_survival',
	'tol_cp',
	'tol_diamond',
	'tol_battlectf',
	'tol_bigarena',
	'tol_battle',
	'tol_eggrobotag',
	'tol_battlecampaign',
	'tol_rugby',
	'tol_battleball'
)
--Add gametypes
G_AddGametype({
    name = "Arena",
    identifier = "arena",
    typeoflevel = TOL_ARENA|TOL_MATCH,
    rules = GTR_OVERTIME|GTR_STARTCOUNTDOWN|GTR_RESPAWNDELAY|GTR_PITYSHIELD|GTR_SPECTATORS|GTR_POINTLIMIT|GTR_TIMELIMIT|GTR_SPAWNINVUL|GTR_DEATHPENALTY|GTR_DEATHMATCHSTARTS|GTR_HURTMESSAGES,
    rankingtype = GT_MATCH,
	intermissiontype = int_match,
	defaultpointlimit = 0,
	defaulttimelimit = 4,
    headerleftcolor = 56,
    headerrightcolor = 56,
    description = 'Bash other players with your spin and jump moves to earn points! Collect and use rings to unleash special moves unique to each character!'
})

G_AddGametype({
    name = "Team Arena",
    identifier = "teamarena",
    typeoflevel = TOL_ARENA|TOL_MATCH,
    rules = GTR_OVERTIME|GTR_STARTCOUNTDOWN|GTR_RESPAWNDELAY|GTR_PITYSHIELD|GTR_TEAMS|GTR_SPECTATORS|GTR_POINTLIMIT|GTR_TIMELIMIT|GTR_SPAWNINVUL|GTR_DEATHPENALTY|GTR_DEATHMATCHSTARTS|GTR_HURTMESSAGES,
    rankingtype = GT_TEAMMATCH,
	intermissiontype = int_teammatch,
	defaultpointlimit = 0,
	defaulttimelimit = 4,
    headerleftcolor = 150,
    headerrightcolor = 37,
    description = 'Stick together! The team that can support each other and deal the most damage will be victorious!'
})

G_AddGametype({
    name = "Survival",
    identifier = "survival",
    typeoflevel = TOL_SURVIVAL,
    rules = GTR_OVERTIME|GTR_LIVES|GTR_STARTCOUNTDOWN|GTR_RESPAWNDELAY|GTR_PITYSHIELD|GTR_SPECTATORS|GTR_POINTLIMIT|GTR_TIMELIMIT|GTR_SPAWNINVUL|GTR_DEATHPENALTY|GTR_DEATHMATCHSTARTS|GTR_HURTMESSAGES,
    rankingtype = GT_MATCH,
	intermissiontype = int_match,
	defaultpointlimit = 0,
	defaulttimelimit = 5,
    headerleftcolor = 231,
    headerrightcolor = 231,
    description = "It's survival of the fittest! Manage your shields and rings as you compete to be the last critter standing."
})

G_AddGametype({
    name = "Team Survival",
    identifier = "teamsurvival",
    typeoflevel = TOL_SURVIVAL,
    rules = GTR_OVERTIME|GTR_LIVES|GTR_STARTCOUNTDOWN|GTR_RESPAWNDELAY|GTR_TEAMS|GTR_PITYSHIELD|GTR_SPECTATORS|GTR_POINTLIMIT|GTR_TIMELIMIT|GTR_SPAWNINVUL|GTR_DEATHPENALTY|GTR_DEATHMATCHSTARTS|GTR_HURTMESSAGES,
    rankingtype = GT_TEAMMATCH,
	intermissiontype = int_teammatch,
	defaultpointlimit = 0,
	defaulttimelimit = 5,
    headerleftcolor = 150,
    headerrightcolor = 37,
    description = "Shake'm all down in this team-based survival format. When one team runs out of lives, the other wins!"
})

G_AddGametype({
    name = "Control Point",
    identifier = "cp",
    typeoflevel = TOL_MATCH|TOL_CP,
    rules = GTR_OVERTIME|GTR_STARTCOUNTDOWN|GTR_RESPAWNDELAY|GTR_PITYSHIELD|GTR_SPECTATORS|GTR_POINTLIMIT|GTR_TIMELIMIT|GTR_SPAWNINVUL|GTR_DEATHPENALTY|GTR_DEATHMATCHSTARTS|GTR_HURTMESSAGES,
    rankingtype = GT_MATCH,
	intermissiontype = int_match,
	defaultpointlimit = 3000,
	defaulttimelimit = 5,
    headerleftcolor = 75,
    headerrightcolor = 75,
    description = "The player who stands inside the score zone for long enough will claim its reward! Knock your foes out before they steal the spotlight!"
})

G_AddGametype({
    name = "Team Control Point",
    identifier = "teamcp",
    typeoflevel = TOL_MATCH|TOL_CP,
    rules = GTR_OVERTIME|GTR_TEAMFLAGS|GTR_STARTCOUNTDOWN|GTR_RESPAWNDELAY|GTR_PITYSHIELD|GTR_TEAMS|GTR_SPECTATORS|GTR_POINTLIMIT|GTR_TIMELIMIT|GTR_SPAWNINVUL|GTR_DEATHPENALTY|GTR_DEATHMATCHSTARTS|GTR_HURTMESSAGES,
    rankingtype = GT_TEAMMATCH,
	intermissiontype = int_teammatch,
	defaultpointlimit = 3,
	defaulttimelimit = 5,
    headerleftcolor = 37,
    headerrightcolor = 150,
    description = "Players must work together to capture the control point before the opposing team does. The more players inside, the faster the capture!"
})

-- G_AddGametype({
--     name = "Diamond in the Rough",
--     identifier = "diamond",
--     typeoflevel = TOL_DIAMOND|TOL_MATCH,
--     rules = GTR_OVERTIME|GTR_STARTCOUNTDOWN|GTR_RESPAWNDELAY|GTR_PITYSHIELD|GTR_SPECTATORS|GTR_POINTLIMIT|GTR_TIMELIMIT|GTR_SPAWNINVUL|GTR_DEATHPENALTY|GTR_DEATHMATCHSTARTS|GTR_HURTMESSAGES,
--     rankingtype = GT_MATCH,
-- 	intermissiontype = int_match,
-- 	defaultpointlimit = 6000,
-- 	defaulttimelimit = 5,
--     headerleftcolor = 148,
--     headerrightcolor = 148,
--     description = 'Find and seize the diamond on the field, then hold onto it for as long as you can! Careful -- other players can steal your crystal, even just by touching it!'
-- })

-- G_AddGametype({
--     name = "Team Diamond in the Rough",
--     identifier = "teamdiamond",
--     typeoflevel = TOL_DIAMOND|TOL_MATCH,
--     rules = GTR_OVERTIME|GTR_STARTCOUNTDOWN|GTR_RESPAWNDELAY|GTR_PITYSHIELD|GTR_TEAMS|GTR_SPECTATORS|GTR_POINTLIMIT|GTR_TIMELIMIT|GTR_SPAWNINVUL|GTR_DEATHPENALTY|GTR_DEATHMATCHSTARTS|GTR_HURTMESSAGES,
--     rankingtype = GT_TEAMMATCH,
-- 	intermissiontype = int_teammatch,
-- 	defaultpointlimit = 10000,
-- 	defaulttimelimit = 5,
--     headerleftcolor = 37,
--     headerrightcolor = 150,
--     description = 'Two teams compete for a single diamond on the field; work together to seize the crystal, or protect the diamond holder if your team already has it!'
-- })

G_AddGametype({
    name = "Battle CTF",
    identifier = "battlectf",
    typeoflevel = TOL_CTF|TOL_BATTLECTF,
    rules = GTR_STARTCOUNTDOWN|GTR_RESPAWNDELAY|GTR_PITYSHIELD|GTR_TEAMFLAGS|GTR_TEAMS|GTR_SPECTATORS|GTR_POINTLIMIT|GTR_TIMELIMIT|GTR_SPAWNINVUL|GTR_DEATHPENALTY|GTR_OVERTIME|GTR_HURTMESSAGES,
    rankingtype = GT_CTF,
	intermissiontype = int_ctf,
	defaultpointlimit = 3,
	defaulttimelimit = 8,
    headerleftcolor = 37,
    headerrightcolor = 150,
    description = "Combine melee and special moves to capture the enemy flag while protecting your own. Master the slipstream to catch up to enemy flagrunners!"
})

G_AddGametype({
    name = "Rugby",
    identifier = "rugby",
    typeoflevel = TOL_RUGBY,
    rules = GTR_OVERTIME|GTR_STARTCOUNTDOWN|GTR_RESPAWNDELAY|GTR_PITYSHIELD|GTR_TEAMS|GTR_SPECTATORS|GTR_POINTLIMIT|GTR_TIMELIMIT|GTR_SPAWNINVUL|GTR_DEATHPENALTY|GTR_DEATHMATCHSTARTS|GTR_HURTMESSAGES|GTR_TEAMFLAGS,
    rankingtype = GT_CTF,
	intermissiontype = int_ctf,
	defaultpointlimit = 0,
	defaulttimelimit = 5,
    headerleftcolor = 37,
    headerrightcolor = 150,
    description = 'Reach the goalpost with the diamond crystal in hand!'
})

G_AddGametype({
    name = "Battleball",
    identifier = "battleball",
    typeoflevel = TOL_BATTLEBALL|TOL_RUGBY,
    rules = GTR_OVERTIME|GTR_STARTCOUNTDOWN|GTR_RESPAWNDELAY|GTR_PITYSHIELD|GTR_TEAMS|GTR_SPECTATORS|GTR_POINTLIMIT|GTR_TIMELIMIT|GTR_SPAWNINVUL|GTR_DEATHPENALTY|GTR_DEATHMATCHSTARTS|GTR_HURTMESSAGES|GTR_TEAMFLAGS,
    rankingtype = GT_CTF,
	intermissiontype = int_ctf,
	defaultpointlimit = 0,
	defaulttimelimit = 5,
    headerleftcolor = 37,
    headerrightcolor = 150,
    description = 'Attack the ball to send it into the goalpost!'
})]]