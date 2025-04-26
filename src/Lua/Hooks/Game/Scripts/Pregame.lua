local function ManageCamera()
	local pos = FangsHeist.Net.pregame_cam

	if not pos.enabled then return end

	local thrustx = FixedMul(pos.dist, cos(pos.angle+ANGLE_180))
	local thrusty = FixedMul(pos.dist, sin(pos.angle+ANGLE_180))

	local x = pos.x + thrustx
	local y = pos.y + thrusty

	camera.angle = pos.angle
	camera.aiming = 0

	P_TeleportCameraMove(camera, x, y, pos.z)
	print(x/FU, y/FU, pos.z/FU)

	--[[local steps = ((pos.dist/16)/FU)+1
	for i = 0, steps do
		local cx = camera.x
		local cy = camera.y

		if not P_TryCameraMove(camera, cx+(thrustx/steps), cy+(thrusty/steps)) then
			break
		end
	end]]

	camera.momx = 0
	camera.momy = 0
	camera.momz = 0
end

return function()
	if not FangsHeist.Net.pregame then return end

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

		return
	end

	FangsHeist.Net.pregame_cam.angle = $ + FixedAngle(tofixed("0.78"))
	ManageCamera()

	return true
end