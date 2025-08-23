local function IsPlayerFinished(p)
	local gamemode = FangsHeist.getGamemode()
	local state = FangsHeist.getPregameState(p)

	if p.bot then
		return true
	end

	if state
	and state.ready then
		return true
	end

	return false
end

local function ShouldPregameEnd()
	if FangsHeist.Net.pregame_time <= 0 then
		return true -- End if time's up.
	end

	local count = 0
	local confirmcount = 0
	local gamemode = FangsHeist.getGamemode()

	for p in players.iterate do
		if not p.heist then
			continue
		end

		count = $+1

		if IsPlayerFinished(p) then
			confirmcount = $+1
		end
	end
	return confirmcount == count
end

local function EndPregame()
	FangsHeist.Net.pregame = false
	local trans = FixedMul(1000,tofixed("0.65"))
	S_ChangeMusic(mapmusname,true,nil,nil,0,trans)

	for p in players.iterate do
		if not p.heist then
			continue
		end

		p.heist.invites = {}
		p.heist.playersList = nil
		p.heist.invitesList = nil

		p.powers[pw_flashing] = 2*TICRATE
	end

	local gamemode = FangsHeist.getGamemode()
	gamemode:start()

	local linedef = tonumber(mapheaderinfo[gamemap].fh_gamestartlinedef)
	if linedef ~= nil then
		P_LinedefExecute(linedef)
	end

	HeistHook.runHook("GameStart")
end

return function()
	if not FangsHeist.Net.pregame then
		FangsHeist.Net.pregame_transparency = min(10, $+1)
		return
	end

	if S_MusicName() ~= "FH_PRG" then
		S_ChangeMusic("FH_PRG", true)
	end

	FangsHeist.Net.pregame_transparency = max(0, $-1)
	FangsHeist.Net.pregame_time = $-1

	local gamemode = FangsHeist.getGamemode()
	local finished = ShouldPregameEnd()

	if finished then
		EndPregame()
		return
	end

	return true
end