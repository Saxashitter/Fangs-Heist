return function()
	local song = nil

	if FangsHeist.Net.escape then
		song = "THCUAG"
	end

	if song
	and mapmusname ~= song then
		mapmusname = song
		S_ChangeMusic(song, true)
	end
end