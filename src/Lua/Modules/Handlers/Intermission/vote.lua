local module = {}
local curSel = 1

module.name = "Vote"

local function get_map(v, id)
	return v.cachePatch(G_BuildMapName(id).."P")
end

local function draw_map(v, x, y, scale, map, flags, selected, voted)
	local icon = get_map(v, map.map)
	local tf = V_ALLOWLOWERCASE
	if selected then
		tf = $|V_YELLOWMAP
	end
	if voted then
		tf = $|V_GREENMAP
	end

	v.drawScaled(x-(icon.width*scale/2), y-(icon.height*scale/2), scale, icon, flags)
	v.drawString(x, y+(icon.height*scale/2), G_BuildMapTitle(map.map), flags|tf, "small-fixed-center")
	v.drawString(x, y+(icon.height*scale/2)+4*FU, tostring(map.votes), flags|tf, "fixed-center")

	return icon
end

function module.init()
	curSel = 1
end

local DEADZONE = 10

function module.think(input) // runs when selected
	if abs(input.sidemove) > DEADZONE
	and abs(input.lastside) <= DEADZONE then
		local dir = 1
		if input.sidemove < 0 then
			dir = -1
		end

		curSel = max(1, min($+dir, #FangsHeist.Net.map_choices))
	end

	if input.buttons & BT_JUMP
	and not (input.lastbuttons & BT_JUMP) then
		COM_BufInsertText(consoleplayer, "fh_votemap "..curSel)
	end
end

function module.draw(v,p)
	local sw = v.width()*FU/v.dupx()
	local sep = (sw/2) - (100*FU)
	local length = #FangsHeist.Net.map_choices

	for i,map in pairs(FangsHeist.Net.map_choices) do
		local x = sw/2
		local patch = get_map(v, map.map)
		local scale = FU/2

		x = $+FixedMul(patch.width*scale + 12*FU, i*FU - 2*FU)

		draw_map(v, x, 100*FU, scale, map, V_SNAPTOLEFT, curSel == i, p and p.heist and p.heist.voted == i)
	end
end

return module