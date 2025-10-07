COM_AddCommand("fh_startescape", function(p)
	if not FangsHeist.isMode() then return end
	local gamemode = FangsHeist.getGamemode()

	if not gamemode.startEscape then return end
	if FangsHeist.Net.escape then return end
	if not p.mo then return end

	gamemode:startEscape(p)
end, COM_ADMIN)