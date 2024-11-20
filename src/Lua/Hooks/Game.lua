local escape = FangsHeist.require "Modules/Handlers/escape"
local music = FangsHeist.require "Modules/Handlers/music"

// Mode initialization.
addHook("MapChange", do
	FangsHeist.initMode()
end)

addHook("MapLoad", do
	if not FangsHeist.isMode() then
		return
	end

	FangsHeist.loadMap()
end)

addHook("ThinkFrame", do
	if not FangsHeist.isMode() then
		return
	end

	escape()
	music()
end)