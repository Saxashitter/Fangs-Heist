return function()
	local song = nil
	local loop = true

	if FangsHeist.Net.escape then
		song = FangsHeist.isHurryUp() and "HURRUP" or "KARKUR"
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