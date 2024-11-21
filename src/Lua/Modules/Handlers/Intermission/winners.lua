local module = {}

local POSITION_DATA = {
	{x = 160*FU, y = 100*FU},
	{x = 160*FU-100*FU, y = 110*FU},
	{x = 160*FU+100*FU, y = 120*FU}
}

function module.think(p) // runs when selected
end

local profit_sort = function(a, b)
	local profit1 = FangsHeist.returnProfit(a)
	local profit2 = FangsHeist.returnProfit(b)

	return profit1 > profit2
end

function module.draw(v, width, height)
	v.drawString(160, 4, "WINNERS", V_SNAPTOTOP, "center")

	local plyrs = {}

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

		local mult = FixedDiv(width, 320*FU)
		local x = FixedMul(pos.x, mult)

		v.drawScaled(x, pos.y, FU, stnd, V_SNAPTOBOTTOM|V_SNAPTOLEFT, color)

		local y = pos.y+12*FU

		v.drawString(x, y, p.name, V_SNAPTOBOTTOM|V_SNAPTOLEFT|V_ALLOWLOWERCASE|V_YELLOWMAP, "fixed-center")
		v.drawString(x, y + 16*FU, "Profit: "..tostring(FangsHeist.returnProfit(p)), V_SNAPTOBOTTOM|V_SNAPTOLEFT, "fixed-center")
		v.drawString(x, y + 16*FU + 8*FU, "Enemies: "..tostring(p.heist.scraps), V_SNAPTOBOTTOM|V_SNAPTOLEFT, "fixed-center")
		v.drawString(x, y + 16*FU + 16*FU, "Rings: "..tostring(p.rings), V_SNAPTOBOTTOM|V_SNAPTOLEFT, "fixed-center")
	end
end

return module