local B = CBW_Battle
local Bb = B.Battleball
local A = B.Arena
local D = B.Diamond
local F = B.CTF
local CV = B.Console
local CP = B.ControlPoint
local I = B.Item

local PR = CBW_PowerCards

addHook("NetVars",B.NetVars.Sync)

addHook("MapChange",function(map)
	for player in players.iterate do 
		player.revenge = false
		player.preservescore = 0
	end
	D.Reset()
	Bb.Reset()
	B.RedScore = 0
	B.BlueScore = 0
	B.SuddenDeath = false
	B.Pinch = false
	B.PinchTics = 0
	B.Exiting = false
	A.ResetLives()
	I.GameReset()
	PR.ResetAll()
	B.ResetSparring()
	F.RedFlag = nil
	F.BlueFlag = nil
	B.CampaignMapChange()
end)

addHook("MapLoad",function(map)
	B.HideTime()
	D.GetSpawns()
	Bb.GetSpawns()
	I.GetMapHeader(map)
	I.GenerateSpawns()
	for mapthing in mapthings.iterate do
		PR.MapLoadMapThing(mapthing)
	end
	PR.GetSpawnPoints() //Load spawn positions on mapload

	B.CampaignMapStart()
end)

addHook("TeamSwitch", function(...) 
	B.JoinCheck(...)
end)

addHook("ViewpointSwitch", function(...)
	B.TagCam(...)
end)

addHook("PreThinkFrame", function()
	B.SparringPartnerControl()
	D.GameControl()
	Bb.GameControl()
	I.GameControl()
	B.PinchControl()
	
	//Player control
	for player in players.iterate do
		B.PlayerPreThinkFrame(player)
	end
end)

addHook("ThinkFrame",function()	
	//Player control
	B.UserConfig()
	for player in players.iterate do
		B.PlayerThinkFrame(player)
	end
	PR.TicFrame()
	B.ResetScore()
	A.ResetScore()
end)

addHook("PostThinkFrame",function()
	for player in players.iterate do
		B.PlayerPostThinkFrame(player)
	end
	A.UpdateSpawnLives()
	A.UpdateGame()
	A.GetRanks()
	
	PR.AddFromQueue()
end)

addHook("IntermissionThinker", function(...)
	B.Intermission(...)
	if B.BattleCampaign()
		B.RemoveAllBots()
	end
end)