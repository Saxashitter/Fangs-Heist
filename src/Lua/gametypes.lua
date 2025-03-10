FangsHeist.gametypes = {}

local function _NULL() end

local DEFAULT = {
	pvp = true,
	friendlyfire = false,
	teamlimit = 2,
	selectable = false, // ONLY FOR SINGLEPLAYER
	lives = false, // ALSO ONLY FOR SINGLEPLAYER (but can be used in multiplayer)
	
}

function FangsHeist.addGametype(gametype)
	table.insert(FangsHeist.gametypes, gametype)

	print("FH - "..gametype.name)
	return gametype
end

dofile "Gamemodes/escape/gametype.lua"