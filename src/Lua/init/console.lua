local function mysplit(inputstr, sep)
	if sep == nil then
		sep = "%s"
	end

	local t = {}

	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		table.insert(t, str)
	end

	return t
end

COM_AddCommand("fh_endgame", function(p)
	FH:EndGame()
end, COM_ADMIN)

COM_AddCommand("fh_banchar", function(p, name)
	if not name then
		CONS_Printf(p, "Name must be provided.")
		return
	end

	FH.BannedChars[name] = not $

	if FH.BannedChars[name] then
		print(("Banned %s from Fang's Heist."):format(name))
		print("Change will take place once a new match starts.")

		return
	end

	print(("Unbanned %s from Fang's Heist."):format(name))
	print("Change will take place once a new match starts.")
end, COM_ADMIN)

FH.CVars = {}
FH.CVars.EscapeTime = CV_RegisterVar{
	name = "fh_escapetime",
	defaultvalue = 0,
	flags = CV_NETVAR
}
FH.CVars.TeamLimit = CV_RegisterVar{
	name = "fh_teamlimit",
	defaultvalue = 3,
	flags = CV_NETVAR
}