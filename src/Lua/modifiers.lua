FangsHeist.Modifiers = {}

local _NIL = function() end

local __DEFAULT = {
	name = "No Name",
	init = _NIL,
	tick = _NIL,
	finish = _NIL
}
__DEFAULT.__index = __DEFAULT

function FangsHeist.addModifier(tbl)
	setmetatable(tbl, __DEFAULT)

	table.insert(FangsHeist.Modifiers, tbl)
	return #FangsHeist.Modifiers
end