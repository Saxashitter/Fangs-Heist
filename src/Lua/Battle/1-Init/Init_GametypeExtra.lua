local B = CBW_Battle
local G = B.Gametypes

G.TeamScoreType = {0,0,0,0,0,0,0,0}

G.SuddenDeath = {false,false,false,false,false,false,false,false}

--Does this gametype use the Battle format?
G.Battle = {false,false,false,false,false,false,false,false}

--Does this gametype use the Control Point format?
G.CP = {false,false,false,false,false,false,false,false}

--Does this gametype use the Arena format?
G.Arena = {false,false,false,false,false,false,false,false}

--Does this gametype use the Diamond format?
G.Diamond = {false,false,false,false,false,false,false,false}

--Does this gametype use the Battleball format?
G.Battleball = {false,false,false,false,false,false,false,false}

G.TeamScoreType[GT_FANGSHEISTESCAPE]	= 0
G.SuddenDeath[GT_FANGSHEISTESCAPE] 		= false
G.Battle[GT_FANGSHEISTESCAPE] 			= true
G.CP[GT_FANGSHEISTESCAPE] 				= false
G.Arena[GT_FANGSHEISTESCAPE] 			= false
G.Diamond[GT_FANGSHEISTESCAPE]			= false
G.Battleball[GT_FANGSHEISTESCAPE] 		= false