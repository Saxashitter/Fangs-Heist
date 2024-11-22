local module = {}

module.name = "Winners"

local POSITION_DATA = {
	{x = 160*FU, y = 110*FU, patch = "FH_PODIUM_FIRST"},
	{x = 160*FU-100*FU, y = 120*FU, patch = "FH_PODIUM_SECOND"},
	{x = 160*FU+100*FU, y = 130*FU, patch = "FH_PODIUM_THIRD"}
}

function module.think(p) // runs when selected
end

local profit_sort = function(a, b)
	local profit1 = FangsHeist.returnProfit(a)
	local profit2 = FangsHeist.returnProfit(b)

	return profit1 > profit2
end

function module.draw(v)
	local plyrs = {}

	local width = v.width()*FU/v.dupx()
	local height = v.height()*FU/v.dupy()

	for p in players.iterate do
		if not (FangsHeist.isPlayerAlive(p) and p.heist) then
			continue
		end

		table.insert(plyrs, p)
	end

	table.sort(plyrs, profit_sort)

	if not (#plyrs) then
		v.drawString(160, 100, "EVERYONE DIED!", 0, "center")
	end

	for i = 1,3 do
		if not plyrs[i] then break end

		local p = plyrs[i]
		local pos = POSITION_DATA[i]

		local stnd = v.getSprite2Patch(p.skin, SPR2_STND, false, A, 1)
		local color = v.getColormap(p.skin, p.skincolor)

		local podium = v.cachePatch(pos.patch)
		local podium_scale = FU*6/8

		local mult = FixedDiv(width, 320*FU)
		local x = FixedMul(pos.x, mult)

		v.drawScaled(x-podium.width*podium_scale/2, 200*FU-podium.height*podium_scale, podium_scale, podium, V_SNAPTOBOTTOM|V_SNAPTOLEFT)
		v.drawScaled(x, pos.y, FU*6/8, stnd, V_SNAPTOBOTTOM|V_SNAPTOLEFT, color)

		local y = pos.y+12*FU

		v.drawString(x, y, p.name, V_SNAPTOBOTTOM|V_SNAPTOLEFT|V_ALLOWLOWERCASE|V_YELLOWMAP, "fixed-center")
		y = $+16*FU
	
		v.drawString(x, y, "Profit: "..tostring(FangsHeist.returnProfit(p)), V_SNAPTOBOTTOM|V_SNAPTOLEFT, "fixed-center")
		y = $+8*FU
	
		v.drawString(x, y, "Enemies: "..tostring(p.heist.enemies), V_SNAPTOBOTTOM|V_SNAPTOLEFT, "fixed-center")
		y = $+8*FU

		v.drawString(x, y, "Monitors: "..tostring(p.heist.monitors), V_SNAPTOBOTTOM|V_SNAPTOLEFT, "fixed-center")
		y = $+8*FU

		v.drawString(x, y, "Treasures: "..tostring(p.heist.treasures), V_SNAPTOBOTTOM|V_SNAPTOLEFT, "fixed-center")
		y = $+8*FU

		v.drawString(x, y, "Rings: "..tostring(p.rings), V_SNAPTOBOTTOM|V_SNAPTOLEFT, "fixed-center")
	end
end

return module