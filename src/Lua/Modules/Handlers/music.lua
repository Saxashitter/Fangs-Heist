return function()
	local song = nil
	local loop = true
	local volume = false

	if FangsHeist.Net.escape then
		song = FangsHeist.Net.escape_theme

		if consoleplayer
		and consoleplayer.valid
		and consoleplayer.heist
		and consoleplayer.heist.reached_second then
			song = FangsHeist.Net.round2_theme
		end

		if not FangsHeist.Net.time_left then
			song = "FHTUP"
		elseif FangsHeist.Save.retakes then
			song = "MANTRA"
			volume = true

			if FangsHeist.Save.retakes > 1 then
				song = "FIFTTP"
			end
		elseif FangsHeist.isHurryUp() then
			song = "HURRUP"
			loop = false
		else
			volume = true
		end
	elseif not FangsHeist.Net.pregame
	and FangsHeist.Save.retakes then
		song = "FHRETK"
	end

	local custom = HeistHook.runHook("Music", song)
	if type(custom) == "string" then
		song = custom
	end

	if song
	and mapmusname ~= song then
		mapmusname = song
		S_ChangeMusic(song, loop)
	end
	if song
	and volume then
		local t = max(0, min(FixedDiv((5*TICRATE)-FangsHeist.Net.time_left, 5*TICRATE), FU))
	
		S_SetInternalMusicVolume(ease.linear(t, 100, 0))
	end
end