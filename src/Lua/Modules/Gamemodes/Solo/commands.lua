COM_AddCommand("fh_startescape", function()
	if not FangsHeist.isMode() then return end
	local gamemode = FangsHeist.getGamemode()

	if not gamemode.startEscape then return end
	if FangsHeist.Net.escape then return end

	gamemode:startEscape()
end, COM_ADMIN)