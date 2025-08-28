local function GetMostVotedMap()
	local maps = FangsHeist.Net.map_choices

	local map = 1
	local gametype = 1
	local votes

	for i, newMap in ipairs(maps) do
		if votes == nil or newMap.votes > votes then
			map = newMap.map
			gametype = newMap.gametype
			votes = newMap.votes

			continue
		end

		if votes == newMap.votes then
			local tbl = {{map = map, gametype = gametype}, newMap}
			local sel = tbl[P_RandomRange(1, 2)]

			map = sel.map
			gametype = sel.gametype
		end
	end

	return map, FangsHeist.Gamemodes[gametype].gametype
end
local function GetTeamLeader(team)
	for _, p in ipairs(team) do
		if p
		and p.valid then
			return p
		end
	end
end
return function()
	local gamemode = FangsHeist.getGamemode()

	if gamemode:shouldend() then
		FangsHeist.startIntermission()
	end

	if not FangsHeist.Net.game_over then
		return
	end

	FangsHeist.Net.game_over_ticker = max(0, $+1)

	local t = FangsHeist.Net.game_over_ticker
	local song = "FH_INT"

	if t == FangsHeist.GAME_TICS then
		S_StartSound(nil, sfx_nartgw)
	end

	if t == FangsHeist.RESULTS_TICS then
		S_StartSound(nil, sfx_s221)
	end

	if t == FangsHeist.GAME_TICS+FangsHeist.BLACKOUT_TICS then
		local skin = nil
		local plc = FangsHeist.Net.placements
		if (plc[1]
		and plc[1][1]
		and plc[1][1].valid) then
			local p = GetTeamLeader(plc[1])
			skin = p.heist.locked_skin
		end
		local char = FangsHeist.Characters[skin]
		local lines = char.voicelines["accept"]
		if #plc != 0
			S_StartSound(nil, sfx_cwdscr)
			if skin != nil and lines != nil
				S_StartSound(nil, lines[P_RandomRange(1, #lines)])
			else
				S_StartSound(nil, sfx_narcon)
			end
		else
			S_StartSound(nil,sfx_cwdaww)
			S_StartSound(nil,sfx_narnco)
		end
	end

	if t >= FangsHeist.RESULTS_TICS then
		song = "FH_MPV"
	end

	if t >= FangsHeist.GAME_TICS
	and S_MusicName() ~= song then
		S_ChangeMusic(song, true)
	end

	if t == FangsHeist.SWITCH_TICS
	and (isserver or isdedicatedserver) then
		COM_BufInsertText(server, ("map %s -gametype %s -f"):format(GetMostVotedMap()))
	end

	return true
end