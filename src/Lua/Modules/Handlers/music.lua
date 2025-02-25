return function()
	local song = nil
	local loop = true
	local volume = 255

	if FangsHeist.Net.escape then
		song = FangsHeist.Net.escape_theme
		if FangsHeist.Save.retakes then
			song = "WILFOR"

			if FangsHeist.Save.retakes > 1 then
				song = "FIFTTP"
			end
		end
		if FangsHeist.isHurryUp() then
			song = "HURRUP"
			loop = false
		elseif FangsHeist.Net.time_left then
			local t = max(0, min(FixedDiv((5*TICRATE)-FangsHeist.Net.time_left, 5*TICRATE), FU))
	
			S_SetInternalMusicVolume(ease.linear(t, 100, 0))
		else
			song = "FHTUP"
		end
	end

	if song
	and mapmusname ~= song then
		mapmusname = song
		S_ChangeMusic(song, loop)
	end
end