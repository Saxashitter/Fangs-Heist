local escape = FangsHeist.require "Modules/Handlers/escape"
local music = FangsHeist.require "Modules/Handlers/music"
local pvp = FangsHeist.require "Modules/Handlers/pvp"
local orig_net = FangsHeist.require "Modules/Variables/net"
local dialogue = FangsHeist.require "Modules/Handlers/dialogue"

// Mode initialization.
addHook("MapChange", do
	FangsHeist.initMode()
end)

addHook("NetVars", function(n)
	FangsHeist.Net = n($)
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
		if (p.heist and p.heist.exiting)
		or FangsHeist.Net.game_over then
			p.cmd.buttons = 0
			p.cmd.forwardmove = 0
			p.cmd.sidemove = 0
		end
	end
end)

addHook("ThinkFrame", do
	if not FangsHeist.isMode() then
		return
	end

	dialogue.tick()

	if FangsHeist.Net.game_over then
		FangsHeist.Net.game_over_ticker = max(0, $+1)

		local t = FangsHeist.Net.game_over_ticker

		if t == FangsHeist.INTER_START_DELAY then
			S_ChangeMusic("YOKADI", true)
		end

		if t >= FangsHeist.INTER_START_DELAY+FangsHeist.Net.game_over_length then
			G_ExitLevel()
		end

		return
	end

	escape()
	music()
	FangsHeist.manageTreasures()
	pvp.handlePVP()
	FangsHeist.teleportSign()
	// dialogue.tick()

	local count = FangsHeist.playerCount()

	if count.alive == 0
	and FangsHeist.Net.escape then
		FangsHeist.startIntermission()
	end
end)