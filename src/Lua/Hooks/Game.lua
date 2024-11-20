local escape = FangsHeist.require "Modules/Handlers/escape"
local music = FangsHeist.require "Modules/Handlers/music"
local pvp = FangsHeist.require "Modules/Handlers/pvp"

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
		if (p.heist and p.heist.exiting) then
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

	escape()
	music()
	pvp.handlePVP()
	FangsHeist.teleportSign()
end)