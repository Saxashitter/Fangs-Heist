local function GetMostVotedMap()
	local maps = FangsHeist.Net.map_choices

	local map = 1
	local votes

	for i, newMap in ipairs(maps) do
		if votes == nil or newMap.votes > votes then
			map = newMap.map
			votes = newMap.votes

			continue
		end

		if votes == newMap.votes then
			local tbl = {map, newMap.map}

			map = tbl[P_RandomRange(1, 2)]
		end
	end

	return map
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

	if t >= FangsHeist.GAME_TICS
	and S_MusicName() ~= "FH_INT" then
		S_ChangeMusic("FH_INT", true)
	end

	if t == FangsHeist.GAME_TICS then
		S_StartSound(nil, sfx_nartgw)
	end

	if t == FangsHeist.RESULTS_TICS then
		S_StartSound(nil, sfx_s221)
	end

	if t == FangsHeist.GAME_TICS+FangsHeist.BLACKOUT_TICS then
		S_StartSound(nil, sfx_narcon)
		S_StartSound(nil, sfx_cwdscr)
	end

	if t == FangsHeist.SWITCH_TICS then
		G_SetCustomExitVars(GetMostVotedMap(), 2)
		G_ExitLevel()
	end

	return true
end