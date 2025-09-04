local module = {}

local function DrawText(v, x, y, string, flags, align, color)
	FangsHeist.DrawString(v,
		x*FU,
		y*FU,
		FU,
		string,
		"FHTXT",
		align,
		flags,
		color)
end

function module.init() end
function module.draw(v,p)
	if FangsHeist.Net.pregame then return end
	if not (p.heist and p.heist:isAlive()) then return end

	local x = 8
	local y = 200-8
	local f = V_SNAPTOBOTTOM|V_SNAPTOLEFT

	local strData = {}
	for k,ctrl in pairs(FangsHeist.Characters[p.heist.locked_skin].controls) do
		if not ctrl:visible(p) then
			continue
		end

		local str = "["..ctrl.key.."] "
		local c

		if ctrl:cooldown(p) then
			str = $.."Cooling down..."
			c = v.getStringColormap(V_GRAYMAP)
		else
			str = $..ctrl.name
		end

		table.insert(strData, {str = str, c = c})
	end

	if p.heist:hasSign() then
		table.insert(strData, {
			str = "[TOSS FLAG] Toss Sign"
		})
	end

	y = $ - (8*#strData)

	for k,data in pairs(strData) do
		--v.drawString(x, y, data.str, data.f|f, "thin")
		DrawText(v, x, y, data.str, f, "left", data.c)
		y = $+8
	end
end

return module