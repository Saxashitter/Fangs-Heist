local dialogue = FangsHeist.require "Modules/Handlers/dialogue"
local orig = FangsHeist.require"Modules/Variables/player"

sfxinfo[freeslot "sfx_gogogo"].caption = "G-G-G-G-GO! GO! GO!"
sfxinfo[freeslot "sfx_nargam"].caption = "GAME!"

FangsHeist.escapeThemes = {
	{"SPRHRO", true},
	--{"THECUR", true},
	--{"WILFOR", true},
	--{"LUNCLO", true}
	// if the second argument is false, the hurry up music wont play
}

local function profsort(a, b)
	return a[4] > b[4]
end

FangsHeist.GAME_TICS = 2*TICRATE
FangsHeist.RESULTS_TICS = 8*TICRATE
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
	"has completed Fang's Heist! HIT IT, TAILS!!",
	"got silly!",
	"has deemed that you get their %s steam!",
	"is sigma!",
	"was the murderer!",
	"has DOMINATED all of you NOOBS!!",
	"got lucky, I swear!",
	"rigged the match while we weren't looking.",
	"didn't deserve the win.",
	"is NOT the one getting thrown in The Locker Of Losers!",
	"still doesn't know what MAPXX means...",
	"is the top heister!",
	"is fresher than a bowl of lettuce!",
	"was the MVP!",
	"is Ripping and Tearing!",
	"tada.wav",
	"pwned you roblox style",
	"won the game of Hexic HD!",
	"used a calcium gun on you and your teammates!",
	"has cantaloupe'd everyone!",
	"won a game of Balatro",
	"scored a Hole in One!",
	"posted Glungus in #general!",
	"did your mom!",
	"passed their night shift at a pizzeria!",
	"made everyone WOKE!!",
	"deleted Twitter's worst features!",
	"blue-balled you!",
	"cancelled you!",
	"solved your test chamber!",
	"got all the ladies!",
	"got all the men!",
	"crushed you with a Storage Cube!",
	"saved the princess!"
}

function FangsHeist.startIntermission()
	if FangsHeist.Net.game_over
	or HeistHook.runHook("GameOver") == true then
		return
	end

	S_StartSound(nil, sfx_nargam)

	// map vote for the funny
	local maps = {}
	local checked = {}

	for i = 1,1024 do
		if not (mapheaderinfo[i] and mapheaderinfo[i].typeoflevel & TOL_HEIST) then
			continue
		end

		table.insert(maps, i)
	end

	for i = 1, 3 do
		if not (#maps) then
			break
		end

		local key = P_RandomRange(1, #maps)
		local map = maps[key]

		table.insert(FangsHeist.Net.map_choices, {
			map = map,
			votes = 0
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

local function sac(name, caption)
	local sfx = freeslot(name)

	sfxinfo[sfx].caption = caption

	return sfx
end