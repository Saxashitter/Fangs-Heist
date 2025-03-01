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
	FangsHeist.startIntermission()
end, COM_ADMIN)

COM_AddCommand("fh_votemap", function(p, map)
	if not FangsHeist.isMode() then return end
	if not FangsHeist.Net.game_over then return end
	if not (p and p.heist) then return end

	local map = tonumber(map)
	if not FangsHeist.Net.map_choices[map] then
		return
	end

	if p.heist.voted then
		FangsHeist.Net.map_choices[p.heist.voted].votes = $-1
	end

	p.heist.voted = map
	FangsHeist.Net.map_choices[map].votes = $+1
end)

COM_AddCommand("fh_receivemapvote", function(_, str)
	local data = {}

	if isserver or isdedicatedserver then return end

	for k,v in ipairs(mysplit(str or "", "^")) do
		local split = mysplit(v, ",")

		if tonumber(split[1]) == nil
		or tonumber(split[2]) == nil then
			continue
		end

		table.insert(data, {
			map = tonumber(split[1]),
			votes = tonumber(split[2])
		})
	end

	FangsHeist.Net.map_choices = data
end, COM_ADMIN)

FangsHeist.CVars = {}

FangsHeist.CVars.escape_time = CV_RegisterVar{
	name = "fh_escapetime",
	defaultvalue = 0,
	flags = CV_NETVAR
}