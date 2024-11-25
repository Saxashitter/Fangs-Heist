local module = {}

local text = FangsHeist.require"Modules/Libraries/text"

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

local TRIM_LENGTH = 12
local function trim(str)
	if #str > TRIM_LENGTH then
		local trim = string.sub(str, 1, TRIM_LENGTH-3)

		trim = $.."..."

		return trim
	end

	return str
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
		text.draw(v,
			160*FU,
			100*FU - 21*FU/2,
			FU,
			"NO WINNERS!!",
			"FHFNT",
			"center",
			0,
			v.getColormap(nil, SKINCOLOR_CYAN)
		)
		return
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

		local name = (trim(p.name)):upper()

		v.drawScaled(x-podium.width*podium_scale/2, 200*FU-podium.height*podium_scale, podium_scale, podium, V_SNAPTOBOTTOM|V_SNAPTOLEFT)
		v.drawScaled(x, pos.y, FU*6/8, stnd, V_SNAPTOBOTTOM|V_SNAPTOLEFT, color)

		local y = pos.y+12*FU
		local f = V_SNAPTOBOTTOM|V_SNAPTOLEFT
		// 21*FU

		text.draw(v,
			x, y,
			FU*6/9,
			name,
			"FHFNT",
			"center",
			f,
			v.getColormap(nil, p.skincolor))
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