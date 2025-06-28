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
	FH.StartIntermission()
end, COM_ADMIN)

COM_AddCommand("fh_votemap", function(p, map)
	if not FH.isMode() then return end
	if not FH_NET.game_over then return end
	if not (p and p.heist) then return end

	local map = tonumber(map)
	if not FH_NET.MapChoices[map] then
		return
	end

	if p.heist.voted then
		FH_NET.MapChoices[p.heist.voted].votes = $-1
	end

	p.heist.voted = map
	FH_NET.MapChoices[map].votes = $+1
end)

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