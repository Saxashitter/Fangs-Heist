local module = {}

local text = FangsHeist.require "Modules/Libraries/text"

local _flash
local _rings
local alpha
local y

function module.init()
	_flash = true
	_rings = 0
	alpha = 0
	y = 0
end

function module.draw(v, p)
	-- local flash = _flash
	-- local rings = _rings

	-- _flash = (p.rings == 0)
	-- rings = p.rings

	-- y = ease.linear(FU/2, $, 0)

	-- if rings == 0 then
	-- 	alpha = max(0, $-1)
	-- else
	-- 	alpha = min(10, $+1)
	-- end

	-- if rings ~= _rings then
	-- 	y = -4*FU
	-- 	_rings = rings
	-- end

	-- local rings_patch = v.cachePatch("FH_RINGS1")
	-- local red_rings_patch = v.cachePatch("FH_RINGS2")

	-- local scale = (FU/3)*2
	-- v.drawScaled(10*FU, 32*FU, scale, rings_patch, V_SNAPTOLEFT|V_SNAPTOTOP)

	-- if alpha ~= 10 then
	-- 	v.drawScaled(10*FU, 32*FU, scale, red_rings_patch, V_SNAPTOLEFT|V_SNAPTOTOP|(alpha*V_10TRANS))
	-- end

	-- text.draw(v,
	-- 	100*FU,
	-- 	32*FU + y,
	-- 	scale,
	-- 	tostring(p.rings),
	-- 	"RNGFT",
	-- 	"right",
	-- 	V_SNAPTOLEFT|V_SNAPTOTOP
	-- )

	hudinfo[HUD_RINGS].y = 26
	hudinfo[HUD_RINGSNUM].y = 26
	hudinfo[HUD_RINGSNUMTICS].y = 26
end

return module