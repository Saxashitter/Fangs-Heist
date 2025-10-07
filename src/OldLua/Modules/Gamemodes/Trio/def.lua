local copy = FangsHeist.require "Modules/Libraries/copy"
local gamemode = copy(FangsHeist.Gamemodes[FangsHeist.Duo])

local path = "Modules/Gamemodes/Trio/"

gamemode.name = "Trio"
gamemode.id = "TRIO"
gamemode.teamlimit = 3
gamemode.super = FangsHeist.Gamemodes[FangsHeist.Solo]

return FangsHeist.addGamemode(gamemode)