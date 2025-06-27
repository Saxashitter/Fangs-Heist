assert(not CBW_Battle, "Loaded multiple instances of BattleMod")

rawset(_G,"CBW_Battle",{})
rawset(_G,"CBW_PowerCards", {})
if not(CBW_PowerCardQueue)
	rawset(_G,'CBW_PowerCardQueue', {})
end

local B = CBW_Battle
local PR = CBW_PowerCards

B.NetVars = {}
B.ControlPoint = {}
B.Gametypes = {}
B.Console = {}
B.Action = {}
B.PriorityFunction = {}
B.TrainingDummy = nil
B.TrainingDummyName = nil
B.HitCounter = 0
B.Item = {}
B.SuddenDeath = false
B.Pinch = false
B.Overtime = false
B.Exiting = false
B.PinchTics = 0
B.Arena = {}
B.Diamond = {}
B.Battleball = {}
B.CTF = {}
B.GuardFunc = {}
B.SkinVars = {}
B.MessageText = {}
B.RedScore = 0
B.BlueScore = 0
B.HUDMain = true
B.HUDAlt = true
B.HUDRoulette = {}
B.Campaign = {}
B.Horde = false
B.QueueFighters = {}
B.Timeout = 0

PR.Item = {}
PR.MapThing = {}


--*** Constants
--Debug Flags
rawset(_G,"DF_GAMETYPE",	1<<0)
rawset(_G,"DF_COLLISION",	1<<1)
rawset(_G,"DF_ITEM",		1<<2)
rawset(_G,"DF_PLAYER",		1<<3)
rawset(_G,"DF_CAMERA",		1<<4)

--SkinVars flags
rawset(_G,"SKINVARS_GUARD",			1<<0)
rawset(_G,"SKINVARS_NOSPINSHIELD",	1<<1)
rawset(_G,"SKINVARS_GUNSLINGER",	1<<2)
rawset(_G,"SKINVARS_SUPERSONIC",	1<<3)
-- Deprecated flags
rawset(_G,"SKINVARS_ROSY",			0)

-- Battle SinglePlayer flags for bot characters
rawset(_G,"BSP_NOSHIELDS",			1)
rawset(_G,"BSP_LESSSHIELDS",		2)
rawset(_G,"BSP_MORESHIELDS",		1|2)
rawset(_G,"BSP_SHIELDFLAGS",		1|2)
rawset(_G,"BSP_NORINGS",		4)
rawset(_G,"BSP_MORERINGS",		8)
rawset(_G,"BSP_EVENMORERINGS",	4|8)
rawset(_G,"BSP_RINGFLAGS",		4|8)
rawset(_G,"BSP_NOACTIONS",			16)
rawset(_G,"BSP_NOGUARD",			32)
rawset(_G,"BSP_SHADOW",				64)

-- Camera helper flag constants
rawset(_G, "CF_Z",	 	MTF_EXTRA)
rawset(_G, "CF_XY",	 	MTF_OBJECTSPECIAL)
rawset(_G, "CF_ANGLE",	MTF_AMBUSH)
rawset(_G, "CF_SET",	16)

-- CP constants
rawset(_G,"CP_INERT",		0)
rawset(_G,"CP_ACTIVE",		1)
rawset(_G,"CP_CAPTURING",	2)
rawset(_G,"CP_BLOCKED",		3)

-- CP mode constants
rawset(_G,"CPMODE_NONE",			0) -- Not a CP gametype
rawset(_G,"CPMODE_STANDARD",		1) -- CPs appear sporadically and disappear once captured
rawset(_G,"CPMODE_KINGOFTHEHILL",	2) -- CP is persistent upon capturing. Player wins if they control the point for a certain period of time.
rawset(_G,"CPMODE_DOMINATION",		3) -- CPs gradually gain players points once captured. As time progresses, more CPs become available for capture. If GTR_TEAMS, this becomes a symmetrical CP versus format.
rawset(_G,"CPMODE_SEQUENCE",		4) -- CPs are unlocked in a specific order. The game ends when all CPs are captured or when time is up. If GTR_TEAMS, this becomes Attack/Defend.

-- Power Card Flag constants
rawset(_G, "PCF_NOSPIN", 			1<<0)
rawset(_G, "PCF_RUNNERDEBUFF", 		1<<1)
rawset(_G, "PCF_NOTOSS", 			1<<2)
rawset(_G, "PCF_MYSTERY", 			1<<3)
rawset(_G, "PCF_HUDWARNING", 		1<<4)
rawset(_G, "PCF_CUSTOM", 			1<<5)
rawset(_G, "PCF_CONTAINER", 		1<<6)
rawset(_G, "PCF_EVENT", 			1<<7)
rawset(_G, "PCF_FIXEDSPAWN", 		1<<8)
rawset(_G, "PCF_RINGSLINGER", 		1<<9)
