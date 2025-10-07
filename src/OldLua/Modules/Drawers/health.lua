local module = {}

local s = FU
local x = (320 - 8)*FU
local y = (200 - 8)*FU - 17*s
local f = V_SNAPTORIGHT|V_SNAPTOBOTTOM

local fillx = 3*FU
local filly = 3*FU

local shake = 0
local shakeDepletion = 0
local shakeMaxDepletion = 0

local shiver = 0

function FangsHeist.doHealthShake(tics, factor)
	shakeDepletion = tics
	shakeMaxDepletion = tics

	shake = factor or 8*FU
end

function FangsHeist.doHealthShiver(factor)
	shiver = factor or 2*FU
end

function FangsHeist.stopHealthShiver()
	shiver = 0
end

function module.init()
	shake = 0
	shakeDepletion = 0
	shakeMaxDepletion = 0
	shiver = 0
end

function module.draw(v,p)
	local x = x
	local y = y

	if shakeDepletion then
		local t = FixedDiv(shakeDepletion, shakeMaxDepletion)
	
		x = $ + ease.linear(t, 0, v.RandomRange(-shake, shake))
		y = $ + ease.linear(t, 0, v.RandomRange(-shake, shake))

		shakeDepletion = $-1
	end

	if shiver then
		x = $ + v.RandomRange(-shiver, shiver)
		y = $ + v.RandomRange(-shiver, shiver)
	end

	FangsHeist.DrawString(v, x, y, s, tostring(p.heist.health/FU).."%", "FHSMH", "right", f)
end

return module