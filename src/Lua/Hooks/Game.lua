local escape = FangsHeist.require "Modules/Handlers/escape"
local music = FangsHeist.require "Modules/Handlers/music"
local pvp = FangsHeist.require "Modules/Handlers/pvp"
local orig_net = FangsHeist.require "Modules/Variables/net"
local dialogue = FangsHeist.require "Modules/Handlers/dialogue"

// Mode initialization.
addHook("MapChange", function(map)
	FangsHeist.initMode(map)
end)

addHook("NetVars", function(n)
	FangsHeist.Net = n($)
	FangsHeist.Save = n($)
end)

addHook("MapLoad", do
	if not FangsHeist.isMode() then
		return
	end

	FangsHeist.loadMap()
end)

addHook("PreThinkFrame", do
	if not FangsHeist.isMode() then
		return
	end

	for p in players.iterate do
		if not p.heist then continue end

		p.heist.lastbuttons = p.heist.buttons

		p.heist.buttons = p.cmd.buttons
		p.heist.forwardmove = p.cmd.forwardmove
		p.heist.sidemove = p.cmd.sidemove

		if FangsHeist.isPlayerAlive(p) then
			if p.heist.exiting
			or p.heist.weapon_hud then
				p.cmd.buttons = 0
				p.cmd.forwardmove = 0
				p.cmd.sidemove = 0
			end
		end
	end
end)

addHook("ThinkFrame", do
	if not FangsHeist.isMode() then
		return
	end
	local data = FangsHeist.getTypeData()

	dialogue.tick()

	FangsHeist.Net.placements = {}
	for i = 0,31 do
		local p = players[i]

		if not (p and p.valid and FangsHeist.isPlayerAlive(p)) then
			FangsHeist.Net.placements[i] = nil
			continue
		end

		if not FangsHeist.Net.placements[i] then
			FangsHeist.Net.placements[i] = {p = p, place = 1}
		end
	end

	// ROUND 2:
	for _,data in pairs(FangsHeist.Net.placements) do
		data.place = 1

		local profit = FangsHeist.returnProfit(data.p)

		for _,data2 in pairs(FangsHeist.Net.placements) do
			if data == data2 then continue end

			local profit2 = FangsHeist.returnProfit(data2.p)

			if profit2 > profit then
				data.place = $+1
				continue
			end

			if profit2 == profit
			and #data2.p > #data.p then
				data.place = $+1
			end
		end
	end

	if FangsHeist.Net.game_over then
		FangsHeist.Net.game_over_ticker = max(0, $+1)

		local t = FangsHeist.Net.game_over_ticker

		if t == FangsHeist.INTER_START_DELAY then
			S_ChangeMusic("YOKADI", true)
			mapmusname = "YOKADI"
		end

		if t >= FangsHeist.INTER_START_DELAY+FangsHeist.Net.game_over_length then
			G_ExitLevel()
		end

		return
	end

	if data.escape then
		escape()
	elseif data.start_timer then
		FangsHeist.Net.time_left = max(0, $-1)
	end

	music()
	FangsHeist.manageTreasures()
	pvp.tick()
	FangsHeist.teleportSign()
	// dialogue.tick()

	local count = FangsHeist.playerCount()

	if count.alive == 0
	and FangsHeist.Net.escape then
		FangsHeist.startIntermission()
	end
end)