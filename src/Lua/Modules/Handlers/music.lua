return function()
	local song = nil
	local loop = true
	local volume = false

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
	and volume ~= nil then
		S_SetInternalMusicVolume(volume)
	end
end