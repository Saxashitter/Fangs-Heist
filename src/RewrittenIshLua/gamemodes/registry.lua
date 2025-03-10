FH.gametypes = {}

function FH:add_gametype(gametype)
	table.insert(self.gametypes, gametype)

	if FH_DEBUG then
		print("DEBUG: Added "..gametype.name.. " (Gametype #"..#self.gametypes..")")
	end

	return gametype
end

dofile "gamemodes/escape/gametype.lua"