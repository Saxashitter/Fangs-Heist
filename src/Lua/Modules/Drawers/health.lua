local module = {}

local s = FU
local x = (320 - 8)*FU
local y = (200 - 8)*FU - 17*s
local f = V_SNAPTORIGHT|V_SNAPTOBOTTOM

local fillx = 3*FU
local filly = 3*FU

local health = 0

function module.init() end
function module.draw(v,p)
	FangsHeist.DrawString(v, x, y, s, tostring(p.heist.health/FU).."%", "FHSMH", "right", f)
end

return module