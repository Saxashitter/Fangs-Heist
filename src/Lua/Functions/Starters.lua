sfxinfo[freeslot "sfx_gogogo"].caption = "G-G-G-G-GO! GO! GO!"
function FangsHeist.startEscape()
	if FangsHeist.Net.escape then return end

	FangsHeist.Net.escape = true
	S_StartSound(nil, sfx_gogogo)

	FangsHeist.doSignpostWarning(FangsHeist.playerHasSign(displayplayer))
end

function FangsHeist.startIntermission()
	if FangsHeist.Net.game_over then
		return
	end

	S_FadeMusic(0, MUSICRATE/2)

	for mobj in mobjs.iterate() do
		if not (mobj and mobj.valid) then return end

		mobj.flags = $|MF_NOTHINK
	end

	FangsHeist.Net.game_over = true
end