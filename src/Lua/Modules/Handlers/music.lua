return function()
	local song = nil
	local loop = true
	local data = FangsHeist.getTypeData()

	if FangsHeist.Net.escape then
		song = FangsHeist.Net.escape_theme
		if FangsHeist.Save.retakes then
			song = "WILFOR"
		end
		if FangsHeist.isHurryUp() then
			song = "HURRUP"
			loop = false
		end
	end

	if song
	and mapmusname ~= song then
		mapmusname = song
		S_ChangeMusic(song, loop)
	end
end