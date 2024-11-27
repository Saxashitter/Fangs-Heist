local orig = FangsHeist.require "Modules/Variables/net"

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
		and p
		and p.mo
		and p.mo.valid
		and FangsHeist.Net.sign.holder == p.mo)
end

function FangsHeist.returnProfit(p)
	if not (p and p.heist) then return 0 end

	if p.heist.exiting then
		return p.heist.saved_profit
	end

	local profit = 0

	if FangsHeist.playerHasSign(p)
		profit = $+1000
	end


	profit = $+28*p.heist.hitplayers
	profit = $+50*p.heist.deadplayers
	profit = $+12*p.heist.monitors
	profit = $+35*p.heist.enemies
	profit = $+p.heist.generated_profit
	profit = $+8*p.rings

	return profit
end

function FangsHeist.playerCount()
	local count = {
		total = 0,
		alive = 0,
		exiting = 0,
		dead = 0
	}

	for p in players.iterate do
		count.total = $+1

		if not (FangsHeist.isPlayerAlive(p)
		and p.heist
		and not p.heist.spectator) then
			count.dead = $+1
			continue
		end

		if p.heist.exiting then
			count.exiting = $+1
			continue
		end

		count.alive = $+1
	end

	return count
end

local function score_sort(a, b)
	local score1 = FangsHeist.returnProfit(a)
	local score2 = FangsHeist.returnProfit(b)

	return score1 > score2
end

// Returns -1 if the player isn't placed anywhere.
function FangsHeist.getPlayerPlacement(p)
	local placement = 1
	placement = FangsHeist.Net.placements[#p]

	if not (FangsHeist.isPlayerAlive(p) and placement) then
		return -1
	end

	return placement.place
end