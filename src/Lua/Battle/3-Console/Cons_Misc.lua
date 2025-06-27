local B = CBW_Battle
local CV = B.Console

COM_AddCommand("battleversioninfo",function(player)
	CONS_Printf(player,
		"\x82".."BattleMod ("..B.VersionNumber.."."..B.VersionSub..
		") \x80 written by CobaltBW. Last updated "..CBW_Battle.VersionDate.."\n"..
		"Maps created by CobaltBW, FlareBlade93, and Krabs.\n"..
		"This version of BattleMod has been modified and merged into Fang's Heist by Saxashitter.\n"..
		"Please visit the mb.SRB2.org topic for full credits & changelog."
	)
end,0)