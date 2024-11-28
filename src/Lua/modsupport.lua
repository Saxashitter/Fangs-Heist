// Override hook system so we can add easy-ish mod support. Hacky, but it works.
// BE SURE TO LOAD EVERY MOD AFTER THIS TO MAKE SURE THINGS WORK PROPERLY!

local _addHook = addHook

local function getReplacementFunc(name, func, ...)
	if name == "AbilitySpecial" then
		return function(p)
			if FangsHeist.isMode() then
				if not FangsHeist.canUseAbility(p) then
					return true
				end
			end

			return func(p)
		end
	end

	return func
end

rawset(_G, "addHook", function(name, func, ...)
	local replacement_func = getReplacementFunc(name, func, ...)

	_addHook(name, replacement_func, ...)
end)