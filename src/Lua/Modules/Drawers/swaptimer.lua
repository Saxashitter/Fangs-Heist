local module = {}

local function drawRoundStats(v)
	local str = "TIME UNTIL' RUNNERS SWAP: %02d:%02d"
	local tmr = FangsHeist.Net.swap_runner

	str = $:format(
		(tmr/TICRATE) / 60,
		(tmr/TICRATE) % 60
	)

	if #FangsHeist.Net.heisters <= 1 then
		str = "LAST RUNNER STANDING"
	end

	v.drawString(320-8, 8, str, V_SNAPTORIGHT|V_SNAPTOTOP, "thin-right")
end

local function drawCurrentRunner(v)
	local runner = FangsHeist.Net.current_runner

	if not (runner and runner.valid) then return end

	local str = ("CURRENT RUNNER: %s"):format(runner.name)

	v.drawString(320-8, 16, str, V_SNAPTORIGHT|V_SNAPTOTOP, "thin-right")
end

local function drawProfitQuota(v)
	local str = ("PROFIT QUOTA: %d/%d"):format(FangsHeist.Net.heisters.profit, FangsHeist.Net.profit_quota)
	local color = V_REDMAP
	if FangsHeist.Net.heisters.profit >= FangsHeist.Net.profit_quota then
		color = V_GREENMAP
	end

	v.drawString(320-8, 24, str, V_SNAPTORIGHT|V_SNAPTOTOP|color, "thin-right")
end

local function drawHeadStart(v)
	local p = displayplayer

	if not (p and p.valid and p.heist) then
		return
	end

	local str = "You can move in %02d:%02d, as runners get a headstart."
	local tmr = FangsHeist.Net.headstart
	if p.heist:getTeam() == FangsHeist.Net.heisters then
		str = "Quick! You got a headstart! %02d:%02d"
	end

	str = $:format(
		(tmr/TICRATE) / 60,
		(tmr/TICRATE) % 60
	)

	v.drawString(160, 200-7-4, str, V_SNAPTOBOTTOM, "thin-center")
end

function module.init() end
function module.draw(v)
	local gamemode = FangsHeist.getGamemode()

	if gamemode.index ~= FangsHeist.TagTeam then return end
	if FangsHeist.Net.pregame then return end

	drawRoundStats(v)
	drawCurrentRunner(v)
	drawProfitQuota(v)
	drawHeadStart(v)
end

return module