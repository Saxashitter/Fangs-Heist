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

	if t == FangsHeist.GAME_TICS then
		S_ChangeMusic("FH_INT", true)
		mapmusname = "FH_INT"
	end

	--[[if t >= FangsHeist.INTER_START_DELAY+FangsHeist.Net.game_over_length then
		if FangsHeist.Net.selected_map == 0 then
			local map = 1
			local votes = -1

			for i,selmap in ipairs(FangsHeist.Net.map_choices) do
				if selmap.votes >= votes then
					map = selmap.map
					votes = selmap.votes
				end
			end

			FangsHeist.Net.selected_map = map

			if map == gamemap
			and not FangsHeist.Net.retaking
			and not (mapheaderinfo[map].fh_disableretakes == "true") then
				-- RETAKING??
				FangsHeist.Net.retaking = true
				S_FadeOutStopMusic(2000)
			end
		end

		if FangsHeist.Net.retake_anim then
			FangsHeist.Net.retake_anim = max(0, $-1)
		end

		if FangsHeist.Net.selected_map
		and (not FangsHeist.Net.retaking
		or FangsHeist.Net.retake_anim == 0) then
			G_SetCustomExitVars(FangsHeist.Net.selected_map, 2)
			G_ExitLevel()
		end
	end]]

	return true
end