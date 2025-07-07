local module = {}

local START_X = 320
local END_X = START_X - 49 - 12
local Y = 12
local FLAGS = V_SNAPTOTOP|V_SNAPTORIGHT

local TICS = 17
local ELAPSED = 0

function module.init() end
function module.draw(v, p)
	local multiplier = p.heist:getMultiplier()
	local multiplierStr = tostring(multiplier)
	local enabled = multiplier > 1

	if enabled then
		ELAPSED = min($+1, TICS)
	else
		ELAPSED = max($-1, 0)
	end

	local t = FixedDiv(ELAPSED, TICS)

	if t <= 0 then return end

	local x = ease.outquad(t, START_X*FU, END_X*FU)
	local y = Y*FU
	local bg = v.cachePatch("FH_MULTIPLIER")

	v.drawScaled(x, y, FU, bg, FLAGS, v.getColormap(TC_RAINBOW, p.skincolor))

	local tw = 9
	local patchQueue = {v.cachePatch("FH_MULTIPLIER_X")}

	for i = 1, #multiplierStr do
		local cut = multiplierStr:sub(i,i)
		local patch = v.cachePatch("FH_MULTIPLIER"..cut)

		table.insert(patchQueue, patch)
		tw = $+patch.width
	end

	x = $ + bg.width*FU/2 - tw*FU/2
	y = $ + bg.height*FU/2 - 13*FU/2 - 2*FU

	for k, patch in ipairs(patchQueue) do
		v.drawScaled(x, y, FU, patch, FLAGS, v.getColormap(TC_RAINBOW, p.skincolor))
		x = $ + patch.width*FU
	end
end

return module