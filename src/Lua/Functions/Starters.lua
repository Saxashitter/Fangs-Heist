FangsHeist.GAME_TICS = 2*TICRATE
FangsHeist.RESULTS_TICS = 15*TICRATE
FangsHeist.BLACKOUT_TICS = 60
FangsHeist.SWITCH_TICS = FangsHeist.GAME_TICS + FangsHeist.RESULTS_TICS + 15*TICRATE
FangsHeist.WINNER_LINES = {
	"is the winner!",
	"was the greediest!",
	"took your money!",
	"ate you for dinner!",
	"ate you for breakfast!",
	"took more than a spoonful!",
	"is the next Lebron!",
	"saved The Netherworld!",
	"has saved the day!",
	"saved Fang's Heist! HIT IT, TAILS!!",
	"got silly!",
	"is sigma!",
	"was the murderer!",
	"has DOMINATED all of you NOOBS!!",
	"got lucky, I swear!",
	"rigged the match while we weren't looking.",
	"didn't deserve the win.",
	"still doesn't know what MAPXX means...",
	"is the top heister!",
	"is fresher than a bowl of lettuce!",
	"was the MVP!",
	"is Ripping and Tearing!",
	"tada.wav",
	"pwned you roblox style",
	"used a calcium gun on you and your teammates!",
	"has cantaloupe'd everyone!",
	"scored a Hole in One!",
	"posted Glungus in #general!",
	"did your mom!",
	"passed their night shift at a pizzeria!",
	"made everyone WOKE!!",
	"deleted Twitter's worst features!",
	"cancelled you!",
	"solved your test chamber!",
	"got all the ladies!",
	"crushed you with a Storage Cube!",
	"saved the princess!",
	"oh my goodness guys my stomach is rolling from eating that onion and rotten garlics oh my goodness okay guys this is episode two and uh right now guys I want to show you my living room uh my hallway I guess oh my goodness my stomach"
}

function FangsHeist.startIntermission()
	if FangsHeist.Net.game_over
	or FangsHeist.runHook("GameOver") == true then
		return
	end

	S_StartSound(nil, sfx_nargam)

	// map vote for the funny
	local maps = {}
	local checked = {}

	for i = 1,1024 do
		if not (mapheaderinfo[i] and i ~= gamemap) then
			continue
		end

		for _, gm in ipairs(FangsHeist.Gamemodes) do
			if gm.tol & mapheaderinfo[i].typeoflevel then
				table.insert(maps, i)
				break
			end
		end
	end

	for i = 1, 3 do
		if not (#maps) then
			break
		end

		local key = P_RandomRange(1, #maps)
		local map = maps[key]

		local modes = {}
		for i, gm in ipairs(FangsHeist.Gamemodes) do
			if gm.tol & mapheaderinfo[map].typeoflevel then
				table.insert(modes, i)
			end
		end

		table.insert(FangsHeist.Net.map_choices, {
			map = map,
			votes = 0,
			gametype = P_RandomRange(1, modes[P_RandomRange(1, #modes)])
		})

		table.remove(maps, key)
	end

	local i = P_RandomRange(1, #FangsHeist.WINNER_LINES)
	FangsHeist.Net.game_over_winline = FangsHeist.WINNER_LINES[i]

	local gamemode = FangsHeist.getGamemode()
	gamemode:finish()

	S_FadeMusic(0, FixedMul(MUSICRATE, tofixed("0.75")))

	for mobj in mobjs.iterate() do
		if not (mobj and mobj.valid) then continue end

		mobj.flags = $|MF_NOTHINK
	end

	FangsHeist.Net.game_over = true
end