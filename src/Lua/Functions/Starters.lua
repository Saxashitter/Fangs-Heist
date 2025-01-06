local dialogue = FangsHeist.require "Modules/Handlers/dialogue"
local orig = FangsHeist.require"Modules/Variables/player"

sfxinfo[freeslot "sfx_gogogo"].caption = "G-G-G-G-GO! GO! GO!"

FangsHeist.escapeThemes = {
	{"SPRHRO", true},
	{"THECUR", true},
	{"WILFOR", true},
	{"LUNCLO", true}
	// if the second argument is false, the hurry up music wont play
}
function FangsHeist.startEscape()
	if FangsHeist.Net.escape then return end

	local choice = P_RandomRange(1, #FangsHeist.escapeThemes)

	while FangsHeist.Save.escape == FangsHeist.escapeThemes[choice] do
		choice = P_RandomRange(1, #FangsHeist.escapeThemes)
	end
	FangsHeist.Save.escape = FangsHeist.escapeThemes[choice]

	FangsHeist.Net.escape = true
	FangsHeist.Net.escape_theme = FangsHeist.escapeThemes[choice]
	FangsHeist.Net.escape_choice = choice

	S_StartSound(nil, sfx_gogogo)

	FangsHeist.changeBlocks()
	local data = mapheaderinfo[gamemap]
	if data.fh_escapelinedef then
		P_LinedefExecute(tonumber(data.fh_escapelinedef))
	end

	FangsHeist.doSignpostWarning(FangsHeist.playerHasSign(displayplayer))
end

local function profsort(a, b)
	return a[4] > b[4]
end

function FangsHeist.startIntermission()
	if FangsHeist.Net.game_over then
		return
	end

	// map vote for the funny
	local maps = 0
	local checkedMaps = {}
	while maps < 3 and #checkedMaps < 1024 do
		local map = P_RandomRange(1, 1024)
		checkedMaps[map] = true
		if not mapheaderinfo[map] then continue end

		local data = mapheaderinfo[map]

		local mapWasIn = false
		for _,oldmap in ipairs(FangsHeist.Net.map_choices) do
			if map == oldmap.map then mapWasIn = true break end
		end
		if mapWasIn then continue end

		if not (data.typeoflevel & (TOL_RACE|TOL_HEIST)) then
			continue
		end
		if data.bonustype then continue end

		table.insert(FangsHeist.Net.map_choices, {
			map = map,
			votes = 0
		})
		maps = $+1
	end

	local scores = FangsHeist.Save.ServerScores
	if not scores[gamemap] then
		scores[gamemap] = {}
	end

	for p in players.iterate do
		if not FangsHeist.isPlayerAlive(p)
		or not p.heist then
			continue
		end

		table.insert(scores[gamemap], {
			p.mo.skin,
			skincolors[p.mo.color].name,
			p.name,
			FangsHeist.returnProfit(p)
		})
	end

	table.sort(scores[gamemap], profsort)

	if #scores[gamemap] > 12 then
		for i = 12,#scores[gamemap] do
			scores[gamemap][i] = nil
		end
	end

	if isserver
	or isdedicatedserver then
		local f = io.openlocal("client/FangsHeist/serverScores.txt", "w+")
		if f then
			f:write(FangsHeist.ServerScoresToString())
			f:flush()
			f:close()
		end
	end

	S_FadeMusic(0, MUSICRATE/2)

	for mobj in mobjs.iterate() do
		if not (mobj and mobj.valid) then return end

		mobj.flags = $|MF_NOTHINK
	end

	FangsHeist.Net.game_over = true
end

local oppositefaces = {
	--awake to asleep
	["JOHNBLK1"] = "JOHNBLK0",
	--asleep to awake
	["JOHNBLK0"] = "JOHNBLK1",
}

function FangsHeist.changeBlocks()
	for sec in sectors.iterate do
		for rover in sec.ffloors() do
			if not rover.valid then continue end
			local side = rover.master.frontside
			
			if not (side.midtexture == R_TextureNumForName("JOHNBLK1")
			or side.midtexture == R_TextureNumForName("JOHNBLK0")) then
			--or side.midtexture == R_TextureNumForName("TKISBKB1")
			--or side.midtexture == R_TextureNumForName("TKISBKB2"))
				continue
			end
			
			local oppositeface = oppositefaces[
				string.sub(R_TextureNameForNum(side.midtexture),1,8)
			]
				
			--???????
			if oppositeface == nil then continue end
			
			if rover.flags & FOF_SOLID
			--awake to asleep
				rover.flags = $|FOF_TRANSLUCENT|FOF_NOSHADE &~(FOF_SOLID|FOF_CUTLEVEL|FOF_CUTSOLIDS)
				rover.alpha = 128
			else
			--asleep to awake
				rover.flags = $|FOF_SOLID|FOF_CUTLEVEL|FOF_CUTSOLIDS &~(FOF_TRANSLUCENT|FOF_NOSHADE)
				rover.alpha = 255
			end
			side.midtexture = R_TextureNumForName(oppositeface)
		end
	end
end

local function sac(name, caption)
	local sfx = freeslot(name)

	sfxinfo[sfx].caption = caption

	return sfx
end

COM_AddCommand("fh_endgame", function(p)
	FangsHeist.startIntermission()
end, COM_ADMIN)

COM_AddCommand("fh_votemap", function(p, map)
	if not FangsHeist.isMode() then return end
	if not FangsHeist.Net.game_over then return end
	if not (p and p.heist) then return end

	local map = tonumber(map)
	if not FangsHeist.Net.map_choices[map] then
		return
	end

	if p.heist.voted then
		FangsHeist.Net.map_choices[p.heist.voted].votes = $-1
	end

	p.heist.voted = map
	FangsHeist.Net.map_choices[map].votes = $+1
end)