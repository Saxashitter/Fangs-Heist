local Particles = {}

Particles.Effects = {}
Particles.Instances = {}

addHook("NetVars", function(sync)
	Particles.Instances = sync($)
end)

local EFFECT_DEF = {
	new = function(self) end,
	tick = function(self) end,
	kill = function(self) end
}

function Particles:define(name, tbl, extends)
	local data = {}
	data.super = extends or EFFECT_DEF

	for k,v in pairs(EFFECT_DEF) do
		data[k] = v
	end

	for k,v in pairs(tbl) do
		data[k] = v
	end

	self.Effects[name] = data
end
	
function Particles:new(name, ...)
	if not self.Effects[name] then
		return
	end

	local effect = {}
	effect.id = name

	self.Effects[name].new(effect, ...)

	table.insert(self.Instances, effect)
	return effect
end

addHook("MapChange", do
	Particles.Instances = {}
end)

addHook("PostThinkFrame", do
	for i = #Particles.Instances, 1, -1 do
		local instance = Particles.Instances[i]
		local effect = Particles.Effects[instance.id]

		if effect.tick(instance) then
			effect.kill(instance)
			table.remove(Particles.Instances, i)
		end
	end
end)

FangsHeist.Particles = Particles

local PATH = "Modules/Effects/"

Particles:define("Ring Steal",
	dofile(PATH.."ringsteal"))