local module = {}

--[[local X = 12
local Y = 12 + 13 + 4

local TEXT_X = 12 + 16 + 4
local TEXT_Y = 3

local FLAGS = V_SNAPTOLEFT|V_SNAPTOTOP

function module.draw(v, p)
	if FangsHeist.Net.pregame
	or FangsHeist.Net.game_over then
		return
	end

	local ringFrame = (leveltime/4) % 4
	local ring = v.cachePatch("FH_RINGS_RING"..ringFrame)

	v.draw(X+8-ring.width/2, Y, ring, FLAGS)

	local string = tostring(p.rings)
	local x = 0

	for i = 1, #string do
		local num = string:sub(i,i)
		local patch = v.cachePatch("FH_RINGS_NUM"..num)

		v.draw(TEXT_X+x, Y+TEXT_Y, patch, FLAGS)
		x = $ + patch.width + 1
	end
end]]

return module