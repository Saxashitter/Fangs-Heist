sfxinfo[freeslot "sfx_gogogo"].caption = "G-G-G-G-GO! GO! GO!"
function FangsHeist.startEscape()
	if FangsHeist.Net.escape then return end

	FangsHeist.Net.escape = true
	S_StartSound(nil, sfx_gogogo)

	FangsHeist.changeBlocks()
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

local oppositefaces = {
	--awake to asleep
	["JOHNBLK1"] = "JOHNBLK0",
	--asleep to awake
	["JOHNBLK0"] = "JOHNBLK1",
}

function FangsHeist.changeBlocks()
	for sec in sectors.iterate do
		for rover in sec.ffloors() do
			if not rover.valid then continue end
			local side = rover.master.frontside
			
			if not (side.midtexture == R_TextureNumForName("JOHNBLK1")
			or side.midtexture == R_TextureNumForName("JOHNBLK0")) then
			--or side.midtexture == R_TextureNumForName("TKISBKB1")
			--or side.midtexture == R_TextureNumForName("TKISBKB2"))
				continue
			end
			
			local oppositeface = oppositefaces[
				string.sub(R_TextureNameForNum(side.midtexture),1,8)
			]
				
			--???????
			if oppositeface == nil then continue end
			
			if rover.flags & FOF_SOLID
			--awake to asleep
				rover.flags = $|FOF_TRANSLUCENT|FOF_NOSHADE &~(FOF_SOLID|FOF_CUTLEVEL|FOF_CUTSOLIDS)
				rover.alpha = 128
			else
			--asleep to awake
				rover.flags = $|FOF_SOLID|FOF_CUTLEVEL|FOF_CUTSOLIDS &~(FOF_TRANSLUCENT|FOF_NOSHADE)
				rover.alpha = 255
			end
			side.midtexture = R_TextureNumForName(oppositeface)
		end
	end
end

COM_AddCommand("fh_endgame", function(p)
	FangsHeist.startIntermission()
end)