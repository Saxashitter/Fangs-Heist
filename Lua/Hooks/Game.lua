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