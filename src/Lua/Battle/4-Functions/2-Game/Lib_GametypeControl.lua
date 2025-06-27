local B = CBW_Battle
local CV = B.Console

B.InGame = function()
	return gamestate == GS_LEVEL
end

B.TagGametype = function()
	return G_TagGametype() --This function has no reason to be here anymore except for backwards compatibility purposes
end

B.BattleGametype = function()
	return B.Gametypes.Battle[gametype or 1]
end

B.CPGametype = function()
	return B.Gametypes.CP[gametype or 1]
end

B.ArenaGametype = function()
	return B.Gametypes.Arena[gametype or 1]
end

B.DiamondGametype = function()
	return B.Gametypes.Diamond[gametype or 1]
end

B.BattleballGametype = function()
	return B.Gametypes.Battleball[gametype or 1]
end

B.BattleCampaign = function()
	return B.BattleGametype()
		and gametyperules & (GTR_TEAMS|GTR_CAMPAIGN) == GTR_TEAMS|GTR_CAMPAIGN -- GTR_TEAMS is added to Co-op by the Battle exe. Without it, the game will assume standard Co-op or SP.
		and (gamestate != GS_TITLESCREEN and (netgame or consoleplayer)) -- Prevents Campaign from triggering during title mode
end

B.FinalLevel = function(map)
	return mapheaderinfo[map or gamemap].nextlevel == 1103
end