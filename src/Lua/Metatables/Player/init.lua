local mt = {}
local path = "Metatables/Player/"

loadfile(path.."Checks")(mt)
loadfile(path.."Getters")(mt)
loadfile(path.."Triggers")(mt)

local _netTable = {
	__index = function(self, key)
		if mt[key] then
			return mt[key]
		end
	end
}

FangsHeist.PlayerMT = _netTable
registerMetatable(FangsHeist.PlayerMT)