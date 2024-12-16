return function()
	local song = nil
	local loop = true
	local data = FangsHeist.getTypeData()

	if FangsHeist.Net.escape
	or data.start_timer then
		song = FangsHeist.isHurryUp() and "HURRUP" or FangsHeist.Net.escape_theme[1]
		if FangsHeist.isHurryUp() then
			loop = false
		end
	end

	if song
	and mapmusname ~= song then
		mapmusname = song
		S_ChangeMusic(song, loop)
	end
end