function FH:EndGame()
	if FH_NET.game_over
	or FH_API:RunHook("GameOver") == true then
		return
	end

	S_StartSound(nil, sfx_nargam)

	// map vote for the funny
	local maps = {}
	local checked = {}

	for i = 1,1024 do
		if not (mapheaderinfo[i] and mapheaderinfo[i].typeoflevel & TOL_HEIST and i ~= gamemap) then
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

	local i = P_RandomRange(1, #FH_INT_LINES)
	FH_NET.game_over_winline = FH_INT_LINES[i]

	local gamemode = FH:GetGamemode()
	gamemode:Finish()

	S_FadeMusic(0, FixedMul(MUSICRATE, tofixed("0.75")))

	for mobj in mobjs.iterate() do
		if not (mobj and mobj.valid) then continue end

		mobj.flags = $|MF_NOTHINK
	end

	FH_NET.game_over = true
end

function FH:SetState(p, name)
	local oldStateName = p.heist.pregame_state
	local oldState = STATES[p.heist.pregame_state]
	local state = STATES[name]

	p.heist.pregame_state = name

	oldState.exit(p, name)
	state.enter(p, oldStateName)
end