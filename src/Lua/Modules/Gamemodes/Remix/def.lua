local copy = FangsHeist.require "Modules/Libraries/copy"
local gamemode = copy(FangsHeist.Gamemodes[FangsHeist.Escape])

local path = "Modules/Gamemodes/Remix/"

gamemode.name = "Remix"
gamemode.id = "REMIX"
gamemode.desc = "dude this is just like the time when i"
gamemode.modifiers = {}
gamemode.pregametheme = "FH_PG2"
gamemode.super = FangsHeist.Gamemodes[FangsHeist.Escape]

local default = {
	init = function() end,
	tick = function() end,
	finish = function() end
}
default.__index = default

function gamemode:addModifier(tbl)
	setmetatable(tbl, default)
	table.insert(self.modifiers, tbl)
end

function gamemode:getModifier()
	return self.modifiers[FangsHeist.Net.modifier or 1]
end

function gamemode:setModifier()
	FangsHeist.Net.modifier = P_RandomRange(1, #self.modifiers)
	self:getModifier():init()
end

function gamemode:init(map)
	self.super.init(self, map)

	FangsHeist.Net.modifier = nil
end

function gamemode:startEscape(p)
	self.super.startEscape(self, p)
	self:setModifier()
end

function gamemode:update()
	self.super.update(self)

	if FangsHeist.Net.escape then
		self:getModifier():tick()
	end
end

gamemode.bombs = gamemode:addModifier(dofile(path.."Modifiers/bombs.lua"))
gamemode.explosion = gamemode:addModifier(dofile(path.."Modifiers/explosion.lua"))
gamemode.doubletime = gamemode:addModifier(dofile(path.."Modifiers/doubletime.lua"))

return FangsHeist.addGamemode(gamemode)