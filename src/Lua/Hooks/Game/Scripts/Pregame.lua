return function()
	if FangsHeist.Net.pregame then
		if S_MusicName() ~= "FH_PRG" then
			S_ChangeMusic("FH_PRG", true)
		end

		FangsHeist.Net.pregame_time = max(0, $-1)
		local count = 0
		local confirmcount = 0
	
		for p in players.iterate do
			if p and p.heist then
				count = $+1
				if p.heist.locked_team then
					confirmcount = $+1
				end
			end
		end
	
		if confirmcount == count then
			FangsHeist.Net.pregame_time = 0
		end
	
		if FangsHeist.Net.pregame_time == 0 then
			FangsHeist.Net.pregame = false
			S_ChangeMusic(mapmusname, true)

			for p in players.iterate do
				if p and p.heist then
					p.heist.invites = {}
					p.heist.playersList = nil
					p.heist.invitesList = nil
					p.powers[pw_flashing] = TICRATE
				end
			end

			local gamemode = FangsHeist.getGamemode()
			gamemode:start()

			HeistHook.runHook("GameStart")

			local linedef = tonumber(mapheaderinfo[gamemap].gamestartlinedef)

			if linedef ~= nil then
				P_LinedefExecute(linedef)
			end
		else
			return true
		end
	end
end