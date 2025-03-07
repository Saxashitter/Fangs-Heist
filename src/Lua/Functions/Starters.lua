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
function FangsHeist.startEscape(p)
	if FangsHeist.Net.escape
	or HeistHook.runHook("EscapeStart", p) == true then
		return
	end

	FangsHeist.Net.escape = true
	S_StartSound(nil, sfx_gogogo)

	local data = mapheaderinfo[gamemap]
	if data.fh_escapelinedef then
		P_LinedefExecute(tonumber(data.fh_escapelinedef))
	end

	if displayplayer
	and displayplayer.valid then
		FangsHeist.doSignpostWarning(FangsHeist.playerHasSign(displayplayer))
	end
end

local function profsort(a, b)
	return a[4] > b[4]
end

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

		/*local str = ""
	
		for i,data in ipairs(FangsHeist.Net.map_choices) do
			str = $..tostring(data.map)..","..tostring(data.votes)
			if i ~= #FangsHeist.Net.map_choices then
				str = $.."^"
			end
		end

		COM_BufInsertText(server, "fh_receivemapvote "..str)*/

	if not FangsHeist.Save.ServerScores[gamemap] then
		FangsHeist.Save.ServerScores[gamemap] = {}
	end

	for p in players.iterate do
		if not (FangsHeist.isPlayerAlive(p)
		and FangsHeist.getTeamLength(p) < 1) then
			continue
		end

		local team = FangsHeist.getTeam(p)

		table.insert(FangsHeist.Save.ServerScores[gamemap], {
			p.mo.skin,
			skincolors[p.mo.color].name,
			p.name,
			team.profit
		})
	end

	table.sort(FangsHeist.Save.ServerScores[gamemap], profsort)

	if #FangsHeist.Save.ServerScores[gamemap] > 12 then
		for i = 12,#FangsHeist.Save.ServerScores[gamemap] do
			FangsHeist.Save.ServerScores[gamemap][i] = nil
		end
	end

	if FangsHeist.isServer() then
		local f = io.openlocal("client/FangsHeist/serverScores.txt", "w+")
		if f then
			f:write(FangsHeist.ServerScoresToString())
			f:flush()
			f:close()
		end
	end

	S_FadeMusic(0, MUSICRATE/2)

	for mobj in mobjs.iterate() do
		if not (mobj and mobj.valid) then continue end

		mobj.flags = $|MF_NOTHINK
	end

	FangsHeist.Net.game_over = true
	FangsHeist.Net.end_anim = 6*TICRATE
	S_ChangeMusic("FH_WIN", false)
end

local function sac(name, caption)
	local sfx = freeslot(name)

	sfxinfo[sfx].caption = caption

	return sfx
end