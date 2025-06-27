local B = CBW_Battle
local CP = B.ControlPoint
local A = B.Arena
local I = B.Item
local D = B.Diamond
local F = B.CTF

function B.NetVars.Sync(network)
	-- Training Dummy / Tails Doll
	B.TrainingDummy 	= network($)
	B.TrainingDummyName = network($)
	B.HitCounter 		= network($)
	-- Control Point
    CP.Num        	= network($)
    CP.Mode       	= network($)
    CP.LeadCapPlr 	= network($)
    CP.LeadCapAmt 	= network($)
    CP.Active     	= network($)
    CP.Capturing  	= network($)
    CP.Blocked   	= network($)
    CP.Timer      	= network($)
    CP.ID         	= network($)
    CP.TeamCapAmt 	= network($)
	-- Items
	I.SpawnTimer	= network($)
	I.Spawns 		= network($)
	I.GlobalChance	= network($)
	I.GlobalRate	= network($)
	I.LocalRate		= network($)
	-- Arena
	A.SpawnLives 	= network($)
	A.Fighters 		= network($)
	A.RedFighters	= network($)
	A.BlueFighters	= network($)
	A.SpawnLives	= network($)
	A.Survivors 	= network($)
	A.RedSurvivors 	= network($)
	A.BlueSurvivors = network($)
	A.GameOvers		= network($)
	-- Diamond
	D.ID 			= network($)
	D.Spawns 		= network($)
	-- CTF
	F.RedFlag 		= network($)
	F.BlueFlag		= network($)
	-- Game state
	B.RedScore		= network($)
	B.BlueScore		= network($)
	B.Pinch 		= network($)
	B.PinchTics 	= network($)
	B.Overtime		= network($)
	B.SuddenDeath 	= network($)
	B.Exiting 		= network($)
	B.Horde			= network($)

	-- Power Cards
	PR.Timer		 = net($)
	PR.SpawnPoints	 = net($)
	PR.SpawnNumber	 = net($)
-- 	for n,t in pairs(PR.Item)
-- 		t.chance = net($)
-- 	end
end