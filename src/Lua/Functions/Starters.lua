sfxinfo[freeslot "sfx_gogogo"].caption = "G-G-G-G-GO! GO! GO!"
function FangsHeist.startEscape()
	if FangsHeist.Net.escape then return end

	FangsHeist.Net.escape = true
	S_StartSound(nil, sfx_gogogo)
end