/*
	Handles spawners.
	See also: IObj_Spawn.lua
*/

local PR = CBW_PowerCards
local variance = FRACUNIT*3/10

//*** General Functions
PR.ResetAll = do
	local cv_time = PR.CV_RespawnTime.value*TICRATE
	local min_time = FixedMul(cv_time*FRACUNIT,FRACUNIT-variance)/FRACUNIT
	local max_time = FixedMul(cv_time*FRACUNIT,FRACUNIT+variance)/FRACUNIT
	PR.Timer = P_RandomRange(min_time, max_time)
	PR.SpawnPoints = {}
	PR.LocalSpawns = {}
	PR.SpawnNumber = 1
end

local shuffle = function(set)
	local sh = {}
	local size = #set
	for n = 1,size do
		while sh[n] == nil do
			local r = P_RandomRange(1,size)
			sh[n] = set[r]
			set[r] = nil
		end
	end		
	PR.DPrint("Shuffled "..size.." indices")
	return sh
end

PR.ResetTimer = do
	PR.Timer = PR.CV_RespawnTime.value*TICRATE
	PR.DPrint("Timer reset to "..PR.CV_RespawnTime.value.." seconds")
end


//*** Spawnpoint access/cycling
PR.GetNextSpawnPoint = do
	local n = PR.SpawnNumber
	if n < #PR.SpawnPoints
		PR.SpawnNumber = $+1
	else
		PR.SpawnNumber = 1
	end
	return PR.SpawnPoints[n]
end


//*** Random
PR.GetProbabilities = function(whitelist,blacklist)
	PR.DPrint("Getting probabilities: whitelist "..tostring(whitelist)..", blacklist "..tostring(blacklist))
	local t = {}
	for n,item in ipairs(PR.Item) do
		if (not(whitelist) or item.flags&whitelist)
		and not(blacklist and item.flags&blacklist)
			for i = 1,item.chance do
				table.insert(t,n)
			end
		end
	end	
	PR.DPrint("Got "..#t.." probabilities")
	return t
end

PR.GetRandomType = function(whitelist,blacklist)
	local p = PR.GetProbabilities(whitelist,blacklist)
	if #p == 0 return nil end
	local n = P_RandomRange(1,#p)
	return p[n]
end

//*** Spawning
PR.SpawnOccupied = function(mapthing)
	return (mapthing.mobj and mapthing.mobj.valid and not(mapthing.mobj.state == S_NULL))
end

//*** Registering spawnpoints
local mapthing_table = function(...)
	local id = {}
	//Specified mapthing search
	for mapthing in mapthings.iterate do
		for _,i in ipairs({...})
			if mapthing.type == i
				table.insert(id,mapthing)
			end
		end
	end
	return id
end

PR.AddTypeSpawner = function(mobjtype,item)
	local thingnum = mobjinfo[mobjtype].doomednum
	item = $ or 0
	local t = {
		mobjtype = mobjtype,
		thingnum = thingnum,
		item = item
	}
	table.insert(PR.MapThing,t)
end

PR.MapLoadMapThing = function(mapthing)
	//Get spawner type
	local item = nil
	for n,t in ipairs(PR.MapThing) do
		if t.thingnum == mapthing.type
			item = t.item
			break
		end
	end
	if item == nil //Not a valid spawnpoint
		return
	elseif PR.Item[item] //Specified items
		if mapthing.options&MTF_EXTRA //Local timer
		and PR.Item[item].chance != -1
			table.insert(PR.LocalSpawns,{mapthing,0})
		else //Global timer
			for n = 1, PR.Item[item].chance do
				table.insert(PR.SpawnPoints,mapthing)
			end
		end
		//Store Item type as mapthing.angle
		mapthing.angle = item
	else //Random items
		if mapthing.options&MTF_EXTRA //Local timer
			table.insert(PR.LocalSpawns,{mapthing,0})
		else //Global timer
			table.insert(PR.SpawnPoints,mapthing)
		end
		//Item type is "random"
		mapthing.angle = 0
	end
-- 		print("spawn thing #"..#mapthing..", type "..mapthing.type)
end

PR.GetSpawnPoints = do
	if #PR.SpawnPoints != 0 then
		PR.SpawnPoints = shuffle($)
		return //Already have IDs? Don't need to generate more.
	end
	local n = 1
	PR.DPrint("Getting spawnpoints for power rings")
	//Main spawns
	local id = PR.SpawnPoints
	//Secondary spawns
	if #id == 0
		PR.DPrint("No primary spawnpoints found, searching match emerald spawns")
		id = mapthing_table(321)
	end
	//Tertiary spawns
	if #id == 0
		PR.DPrint("No match emerald spawns found, searching for multiplayer starts")
		id = mapthing_table(0)
	end
	//Last resort
	if #id == 0
		PR.DPrint("No multiplayer starts found, searching for player 1 starts")
		id = mapthing_table(1)
	end
	PR.SpawnPoints = shuffle(id) //Shuffle
	PR.SpawnNumber = 1 //Set Position
	PR.ResetTimer() //Reset timer
end

//*** Ticframe
PR.TicFrame = do
	local B = CBW_Battle
	local A = B.Arena
	if #PR.SpawnPoints == 0
	or B.SuddenDeath
	or not(PR.CV_Enabled.value)
	or mapheaderinfo[gamemap].powercardsenabled == "0"
	return end
	//Local timers
	for n,t in ipairs(PR.LocalSpawns) do
		local mapthing = t[1]
		local time = t[2]
		if PR.SpawnOccupied(mapthing)
			time = PR.CV_RespawnTime.value*TICRATE
		else
			if time == 0
				PR.SpawnItem(mapthing.angle, mapthing)
				time = PR.CV_RespawnTime.value*TICRATE
			else
				time = $-1
			end
		end
		t[2] = time
	end

	//Global timer
	if B.PreRoundWait() return end
	PR.Timer = $-1
	if PR.Timer <= 0
		PR.ResetTimer()
		PR.SpawnItem()
	end
end