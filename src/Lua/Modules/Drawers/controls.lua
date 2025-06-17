local module = {}

function module.init() end
function module.draw(v,p)
	if FangsHeist.Net.pregame then return end
	if not (p.heist and p.heist:isAlive()) then return end

	local x = 12
	local y = 200-12
	local f = V_SNAPTOBOTTOM|V_SNAPTOLEFT|V_ALLOWLOWERCASE

	local strData = {}
	for k,ctrl in pairs(FangsHeist.Characters[p.mo.skin].controls) do
		if not ctrl:visible(p) then
			continue
		end

		local str = "["..ctrl.key.."] - "
		local f = 0

		if ctrl:cooldown(p) then
			str = $.."Cooling down..."
			f = V_GRAYMAP
		else
			str = $..ctrl.name
		end

		table.insert(strData, {str = str, f = f})
	end

	if p.heist:hasSign() then
		table.insert(strData, {
			str = "[TOSS FLAG] - Toss Sign",
			f = 0})
	end

	y = $ - (8*#strData)

	for k,data in pairs(strData) do
		v.drawString(x, y, data.str, data.f|f, "thin")
		y = $+8
	end
end

return module