local module = {}

local alpha

function module.init()
	alpha = 10
end

function module.draw(v, p)
	if p.heist.treasure_time then
		alpha = max(0, $-1)
	else
		alpha = min($+1, 10)
	end

	if alpha == 10 then return end
	local f = V_SNAPTOBOTTOM|(alpha*V_10TRANS)

	local y = 180
	if FangsHeist.Net.escape then
		y = $-26
	end

	v.drawString(160, y-17, "Treasure got!", f, "thin-center")
	v.drawString(160, y-9, p.heist.treasure_name, f, "center")
	v.drawString(160, y, p.heist.treasure_desc, f, "thin-center")
end

return module