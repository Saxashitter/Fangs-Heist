local files = {}
// Used internally to get modules from the mod.
function FangsHeist.require(path)
	if not (files[path]) then
		files[path] = dofile(path)
	end

	return files[path]
end

// Get players nearby, mainly used for pickup-ables.
function FangsHeist.getNearbyPlayers(mobj, distscale, blacklist)
	if not (distscale) then distscale = FU*3/2 end

	local nearby = {}

	for p in players.iterate do
		if not FangsHeist.isPlayerAlive(p) then
			continue
		end

		local dist = R_PointToDist2(p.mo.x, p.mo.y, mobj.x, mobj.y)
		local heightdist = abs(p.mo.z-mobj.z)

		if dist > FixedMul(p.mo.radius+mobj.radius, distscale) then
			continue
		end

		if heightdist > FixedMul(max(mobj.height, p.mo.height), distscale) then
			continue
		end

		if blacklist
		and blacklist(p) then
			continue
		end

		table.insert(nearby, p)
	end

	return nearby
end

function FangsHeist.playerHasSign(p)
	return (FangsHeist.Net.sign
		and FangsHeist.Net.sign.valid
		and FangsHeist.Net.sign.holder == p.mo)
end

function FangsHeist.returnProfit(p)
	if not (p and p.heist) then return 0 end

	local profit = 0

	if FangsHeist.playerHasSign(p)
		profit = $+1000
	end

	profit = $+p.heist.scraps
	profit = $+(8*p.rings)

	return profit
end