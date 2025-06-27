local B = CBW_Battle
local I = B.Item
local CV = B.Console
I.Spawns = {}
I.SpawnTimer = 0
I.GlobalChance = {0}
-- I.GlobalRate = 30
-- I.LocalRate = 60
-- local default_globalrate = 30
-- local default_localrate = 60
I.GlobalRate = 45
I.LocalRate = 90
local default_globalrate = 45
local default_localrate = 90

I.GameControl = function()
	if not(#I.Spawns) then return end
	if B.SuddenDeath then return end
	local rate = 4-CV.ItemRate.value
	if rate == 0 then return end
	I.SpawnTimer = $+1
	if I.SpawnTimer >= I.GlobalRate*TICRATE*rate/2 then
		I.SpawnTimer = 0
		I.DoGlobalSpawn()
	end
end

I.GetMapHeader = function(map)
	local header = mapheaderinfo[map]
	local mapname = "map "..tostring(map)..": "..tostring(header.lvlttl)
	if header.actnum != 0 then
		mapname = $..tostring(header.actnum)
	end
	//Get global item rate
	if header.battleitems_globalrate then
		I.GlobalRate = header.battleitems_globalrate
		B.DebugPrint("Set global item rate to "..I.GlobalRate,DF_ITEM)
	else
		I.GlobalRate = default_globalrate
		B.DebugPrint("No global item rate found in map header. Defaulted to "..I.GlobalRate,DF_ITEM)
	end
	//Get local item rate
	if header.battleitems_localrate then
		I.LocalRate = header.battleitems_localrate
		B.DebugPrint("Set local item rate to "..I.LocalRate,DF_ITEM)
	else
		I.LocalRate = default_localrate
		B.DebugPrint("No local item rate found in map header. Defaulted to "..I.LocalRate,DF_ITEM)
	end
	
	//Get item chance params
	B.DebugPrint("Getting global item chance parameters for "..mapname,DF_ITEM)
	I.GlobalChance = {}
	local search = {
		header.battleitems_ring,
		header.battleitems_superring,
		header.battleitems_pity,
		header.battleitems_whirlwind,
		header.battleitems_force,
		header.battleitems_elemental,
		header.battleitems_attraction,
		header.battleitems_armageddon,
		header.battleitems_roulette,
		header.battleitems_s3bubble,
		header.battleitems_s3flame,
		header.battleitems_s3lightning,
		header.battleitems_s3roulette,
		header.battleitems_hyperroulette
	}
	if #search
		for n = 1,14 do
			if search[n] and search[n] != nil //Item is non-nil, non-zero
				local count = 0
				local item = n-1 //ring = 0, superrings = 1, etc.
				for m = 1, search[n] do // Add this item <search[battleitem]> number of times
					I.GlobalChance[#I.GlobalChance+1] = item
					count = $+1
				end
				B.DebugPrint("Added item "..item.." with a frequency of "..search[n],DF_ITEM)
			end
		end
	end
	if #I.GlobalChance == 0 then
		B.DebugPrint("No global item chance parameters found. Using default settings",DF_ITEM)
		I.GlobalChance = {
			1,1,1,1,1,1,1,1,1,1,
			2,2,2,2,2,
			3,4,5,6,7,8,9,10,11,12,13
		}
	end
end

I.SetSpawning = function(mo)
	if not(mo.spawning) then
		mo.fuse = TICRATE
		mo.spawning = true
	else
		I.DoSpawn(mo)
	end
end

I.SpawnThinker = function(mo)
	if not(mo.itemspawn_init) then return end
	if B.SuddenDeath then 
		P_RemoveMobj(mo)
	return end
	I.CarouselRotate(mo)
	I.PreSpawn(mo)
	I.SpawnDebugView(mo,mo.target)
end

I.GameReset = function()
	I.Spawns = {}
	I.SpawnTimer = 0
end

I.GenerateSpawns = function()
	for mapthing in mapthings.iterate
		if mapthing.type != 321 then continue end
		local fu = FRACUNIT
		local x = mapthing.x*fu
		local y = mapthing.y*fu
		local z = mapthing.z*fu
		local subsector = R_PointInSubsector(x,y)
		if subsector.valid and subsector.sector then
			z = $+subsector.sector.floorheight
			local mo = P_SpawnMobj(x,y,z,MT_GLOBAL_SPAWN)
			I.ItemSpawnType(mo,"global")
			mo.item = 2
			mo.flags2 = MF2_DONTDRAW
		end
	end
end

I.CheckSpawnItem = function(mo)
	return not(mo and mo.valid) //Spawner went missing?
		or (mo.target and mo.target.valid) //Spawned item exists on field (not multispawn)
end


I.ResetSpawnFuse = function(spawner)
	if(spawner.localized) then
		spawner.fuse = spawner.fusetime
		B.DebugPrint("Local spawn fuse timer reset: "..spawner.fusetime,DF_ITEM)
	else
		B.Warning("Attempted to reset fuse time on a non-local item spawner")
	end
end


local function spawnitem(bubble,spawner)
	local i = CV.ItemType.value
	if i == -1 then
		i = spawner.item
	end
	//Weak Random
	if i == 14 then
		i = B.Choose( //Do probabilities
			1,1,1,1, //Super ring
			2,2, //Pity shield
			12 //S3 Roulette
		)
		B.DebugPrint("Weak Random: chose item "..i,DF_ITEM)
	end
	//Strong Random
	if i == 15 then
		i = B.Choose(
			1,1, //Super ring
			2,2, //Pity shield
			8,8, //Standard Roulette
			12,12, //S3 Roulette
			13 //Hyper Roulette
		)
		B.DebugPrint("Strong Random: chose item "..i,DF_ITEM)
	end
	//Global Random
	if i == 16 then
		i = B.Choose(unpack(I.GlobalChance))
		B.DebugPrint("Global Random: chose item "..i,DF_ITEM)
	end
	//Fixed item spawns
	if (i >= 0 and i <= 7)
		or (i >= 9 and i <= 11)
		then
		bubble.item = i
	return end
	//Roulette
	if i == 8 then
		bubble.item = 3
		bubble.roulettetype = 1
	return end
	//S3 Roulette
	if i == 12 then
		bubble.item = 9
		bubble.roulettetype = 1
	return end
	//Hyper Roulette
	if i == 13 then
		bubble.item = 0
		bubble.roulettetype = 2
	return end

end
local spawnwarning = false
local oldspawncount

I.DoGlobalSpawn = function()
	local viable = {}
	for n = 1,#I.Spawns do
		local s = I.Spawns[n]
		//Spawn does not exist
		if not(s and s.valid) then
			if spawnwarning == false then
				B.DebugPrint("Attempted to index invalid global spawn #"..n..".",DF_ITEM)
				oldspawncount = #I.Spawns
				spawnwarning = true 
			end
			I.Spawns[n] = nil //Remove from spawn table
		continue end
		//Spawn is freed
		if not(s.target) then
			viable[#viable+1] = s
		end
	end
	//If spawns were removed, print results
	if spawnwarning == true then
		B.DebugPrint(oldspawncount-#I.Spawns.." spawns were removed from the global table",DF_ITEM)
		spawnwarning = false
	end
	B.DebugPrint("Got "..#viable.." viable spawns",DF_ITEM)
	if #viable then
		local s = viable[P_RandomRange(1,#viable)]
-- 		I.DoSpawn(s)
		I.SetSpawning(s)
	else
		B.DebugPrint("No more viable spawns!",DF_ITEM)
	end
end

local function sparkle(mo)
	if mo.fuse%2 then return end
	local x = mo.x
	local y = mo.y
	local z = mo.z
	local w = mo.carouselwidth*mo.scale
	if(mo.carouselwidth) then
		if not(mo.carouselorientation)
			x = $+P_ReturnThrustX(mo,mo.angle,w)
			y = $+P_ReturnThrustY(mo,mo.angle,w)
		else
			x = $+P_ReturnThrustX(mo,mo.angle,w)
			z = $+P_ReturnThrustY(mo,mo.angle,w)
		end
	end
	local i = P_SpawnMobj(x,y,z-mo.height/2,MT_IVSP)
	i.scale = mo.scale
-- 	if mo.fuse&7
-- 		i.flags2 = $|MF2_SHADOW
-- 	end
end

local function blowbubble(mo,x,y,z)
	//Do bubbles
	local b = P_SpawnMobj(x,y,z,MT_ITEM_PRESPAWN)
	if mo.z == mo.floorz then
		P_SetObjectMomZ(b,P_RandomRange(0,10)*FRACUNIT)
	elseif mo.z+mo.height == mo.ceilingz then
		P_SetObjectMomZ(b,P_RandomRange(-10,0)*FRACUNIT)
	else
		P_SetObjectMomZ(b,P_RandomRange(-10,10)*FRACUNIT)
	end
	P_Thrust(b,P_RandomRange(0,359)*ANG1,P_RandomRange(5,15)*mo.scale)
	b.fuse = TICRATE
	b.state = B.Choose(S_ITEM_PRESPAWN1,S_ITEM_PRESPAWN1,S_ITEM_PRESPAWN2)
	b.colorized = true
	b.color = B.Choose(
		SKINCOLOR_RED,
		SKINCOLOR_ORANGE,
		SKINCOLOR_YELLOW,
		SKINCOLOR_GREEN,
		SKINCOLOR_BLUE,
		SKINCOLOR_CYAN,
		SKINCOLOR_PURPLE
	)
end

I.BubbleBurst = function(mo)
	local x = mo.x
	local y = mo.y
	local z = mo.z
	if(mo.carouselwidth) then
		local w = mo.carouselwidth*mo.scale
		if not(mo.carouselorientation)
			x = $+P_ReturnThrustX(mo,mo.angle,w)
			y = $+P_ReturnThrustY(mo,mo.angle,w)
		else
			x = $+P_ReturnThrustX(mo,mo.angle,0)
			z = $+P_ReturnThrustY(mo,mo.angle,0)
		end
	end
	for n=1,15 do
		blowbubble(mo,x,y,z)
	end
end

I.PreSpawn = function(mo)
	if not(mo.spawning) then return end
	sparkle(mo)
end

I.DoSpawn = function(spawner)
	if not(I.CheckSpawnItem(spawner)) then
		if spawner.localized and gametyperules & GTR_LIVES
			spawner.fusetime = $*3/2 -- Local spawns become less frequent in survival
		end
		spawner.spawning = 0
		if not(leveltime==0) then
			I.BubbleBurst(spawner)
		end
		local bubble = P_SpawnMobj(spawner.x,spawner.y,spawner.z+FRACUNIT,MT_ITEM_BUBBLE)
		if not(bubble and bubble.valid) then
			B.Warning("Item spawn unsuccessful. Check spawner placement: "..spawner.x/FRACUNIT..", "..spawner.y/FRACUNIT..", "..spawner.z/FRACUNIT)
			return
		else
			B.DebugPrint("Spawned Item Bubble",DF_ITEM)
		end
		if not(spawner.flurrytype) and not(spawner.multispawn) then
			B.DebugPrint("Locked spawn; item is persistent",DF_ITEM)
			spawner.target = bubble
			bubble.target = spawner
		elseif spawner.localized and not(spawner.flurrytype) then
			I.ResetSpawnFuse(spawner)
		end
		//Set bubble lifetime
		if (spawner.multispawn or not(spawner.localized) or spawner.flurrytype) then
			bubble.fuse = 30*TICRATE
		end
		//Flip Object
		if spawner.flags2&MF2_OBJECTFLIP then
			bubble.flags2 = $|MF2_OBJECTFLIP
			bubble.z = $-bubble.height-FRACUNIT
		end
		//Angle
		bubble.angle = spawner.angle
		//Fragile
		bubble.fragile = spawner.fragile
		
		if not(spawner.fragile) then
			bubble.flags = $|MF_BOUNCE
		else
			bubble.flags = $|MF_NOCLIPHEIGHT
		end
		//Water buoyancy
		bubble.buoyancy = spawner.buoyancy
		//Gravity
		if(spawner.gravity) then
			bubble.flags = $&~MF_NOGRAVITY
		end
		//Ball physics
		bubble.balltype = spawner.balltype
		if bubble.balltype then
			bubble.flags = $&~(MF_NOGRAVITY|MF_NOCLIPHEIGHT)
		end
		//Launch
		if spawner.launch == 1 then
			if not(bubble.balltype) then
				P_InstaThrust(bubble,bubble.angle,bubble.scale*5)
			else
				P_InstaThrust(bubble,bubble.angle,bubble.scale*10)
			end
		end

		
		//Item
		spawnitem(bubble,spawner)
		
		//Roulette
		if spawner.roulettetype == 1 then
			bubble.fuse = bubble.info.reactiontime
			bubble.roulettetype = 1
		elseif spawner.roulettetype == 2 then
			bubble.fuse = 2
			bubble.roulettetype = 2
		end
		
		//Flurry
		if spawner.flurrytype then
			if spawner.flurrytype == 1 then //No random variation
				P_Thrust(bubble,spawner.angle,bubble.scale)
			else
				if spawner.launch then //Random variation for directionally launched bubbles
					P_Thrust(bubble,P_RandomRange(-15,15)*ANG1,bubble.scale*3/2)
				else //Random variation for 'stationary' spawns
					P_Thrust(bubble,P_RandomRange(0,359)*ANG1,bubble.scale)
				end
			end
			if spawner.flurry < 3 then
				spawner.flurry = $+1
				spawner.fuse = 20
				spawner.spawning = 1
			else
				spawner.flurry = 0
				if (spawner.localized) then
					I.ResetSpawnFuse(spawner)
				end
			end
		end
	else
		if not(spawner and spawner.valid) then B.Warning("Can't spawn: Spawner doesn't exist!")
		elseif(spawner.target and spawner.target.valid) then
			spawner.spawning = 0
			B.Warning("Can't spawn: Item object is already on the field!")
			B.DebugPrint("Check fuse timer: "..tostring(spawner.fusetime),DF_ITEM)
		end
	end
end

I.AddGlobal = function(mo)
	I.Spawns[#I.Spawns+1] = mo
	B.DebugPrint("Added #"..#I.Spawns.." to list of global item spawners",DF_ITEM)
end

I.SetLocal = function(mo)
	if mo.fusetime then
		mo.fuse = mo.fusetime
		B.DebugPrint("Local spawn fuse set to fusetime "..mo.fusetime,DF_ITEM)
	else
		B.Warning("Spawner fusetime not initialized!")
	end
	mo.flags = ($|MF_SCENERY)&~MF_NOTHINK
	mo.localized = 1
	B.DebugPrint("Localized Item Spawn Point",DF_ITEM)
end

local function setflurry(mo)
	mo.flags = ($|MF_SCENERY)&~MF_NOTHINK
	if mo.localized then
		mo.fusetime = $*2
		I.ResetSpawnFuse(mo)
	end
end

I.SpawnSettings = function(mo,...)
	mo.flurry = 0
	mo.spawning = 0
	local args = {...}
	for n = 1,14 do
		if args[n] == nil then
			args[n] = 0
		end
	end
	mo.localized = args[1]
	if mo.localized then
		I.SetLocal(mo)
	end
	mo.item = args[2]
	mo.roulettetype = args[3]
	mo.buoyancy = args[4]
	mo.gravity = args[5]
	mo.launch = args[6]
	mo.balltype = args[7]
	mo.fragile = args[8]
	mo.multispawn = args[9]
	mo.flurrytype = args[10]
	if mo.flurrytype then
		setflurry(mo)
	end
	mo.carouselwidth = args[11]
	mo.carouselspeed = args[12]
	mo.carouselorientation = args[13]
	mo.fusetime = max(0,args[14])
	if not(mo.itemspawn_init) then
		mo.itemspawn_init = true
		B.DebugPrint("Item spawn initialized: ",DF_ITEM)
		B.DebugPrint(mo,DF_ITEM)
	end
end

I.Parameters = function(mo,thing)
	local p = thing.extrainfo
	//0 Hover in place
	if p == 0 then return end //No instructions necessary
	//1 Rise continuously
	if p == 1 then mo.buoyancy = 1 return end
	//2 Fall
	if p == 2 then mo.gravity = 1 return end
	//3 Fall, buoyancy
	if p == 3 then
		mo.buoyancy = 1
		mo.gravity = 1
	return end
	//4 Launch sideways
	if p == 4
		mo.launch = 1
	return end
	//5 Rise diagonally
	if p == 5
		mo.launch = 1
		mo.buoyancy = 1
	return end
	//6 Fall diagonally
	if p == 6
		mo.launch = 1
		mo.gravity = 1
	return end
	//7 Fall diagonally, buoyancy
	if p == 7
		mo.launch = 1
		mo.gravity = 1
		mo.buoyancy = 1
	return end
	//8 Marble physics (roll across surfaces, slide against walls)
	if p == 8
		mo.balltype = 1
	return end
	//9 Ball physics (buoyancy)
	if p == 9
		mo.balltype = 2
		mo.buoyancy = 1
	return end
	//10 Rubber ball physics (buoyancy, bounce against surfaces)
	if p == 10
		mo.balltype = 3
		mo.buoyancy = 1
	return end
	//11 Launch marble
	if p == 11
		mo.balltype = 1
		mo.launch = 1
	return end
	//12 Launch ball
	if p == 12
		mo.balltype = 2
		mo.buoyancy = 1
		mo.launch = 1
	return end
	//13 Launch rubber ball
	if p == 13
		mo.balltype = 3
		mo.buoyancy = 1
		mo.launch = 1
	return end
end

I.ItemSpawnType = function(mo,string)
	if string == "global" then
		I.AddGlobal(mo)
		mo.item = 16
		return 
	else
		I.SetLocal(mo)
	end
	if string == "ring" then
		mo.item = 0
	return end
	if string == "superring" then
		mo.item = 1
	return end
	if string == "pity" then
		mo.item = 2
	return end
	if string == "whirlwind" then
		mo.item = 3
	return end
	if string == "force" then
		mo.item = 4
	return end
	if string == "elemental" then
		mo.item = 5
	return end
	if string == "attraction" then
		mo.item = 6
	return end
	if string == "armageddon" then
		mo.item = 7
	return end
	if string == "roulette" then
		mo.item = 8
	return end
	if string == "s3bubble" then
		mo.item = 9
	return end
	if string == "s3flame" then
		mo.item = 10
	return end
	if string == "s3lightning" then
		mo.item = 11
	return end
	if string == "s3roulette" then
		mo.item = 12
	return end
	if string == "hyperroulette" then
		mo.item = 13
	return end
	if string == "weakrandom" then
		mo.item = 14
	return end
	if string == "strongrandom" then
		mo.item = 15
	return end
end

local function setfusetime(mo,thing,multiply)
	local rate = CV.ItemRate.value
	local factor = thing.angle/360
	local localrate = I.LocalRate*TICRATE
	//Thing angle sets fuse time
	if factor == 0 
		mo.fusetime = localrate
	elseif factor == 1 
		mo.fusetime = localrate>>1
	elseif factor == 2
		mo.fusetime = localrate>>2
	else
		mo.fusetime = localrate>>3
	end
	mo.fusetime = max($,TICRATE*6)
	//Console variable CV.ItemRate adjusts spawn frequency
-- 	if rate then
		mo.fusetime = $*(4-rate)/2
-- 	end
	if multiply != nil then mo.fusetime = $*multiply end
	B.DebugPrint("Fusetime set: "..mo.fusetime/TICRATE.. " (from thing.angle "..thing.angle..")",DF_ITEM)
end

local function quickthing(mo,thing,noangle)
	if thing.options&MTF_OBJECTFLIP
		mo.flags2 = $|MF2_OBJECTFLIP
	end
	if not(noangle) then
		mo.angle = thing.angle*ANG1
	end
end

I.StandardSpawnerSettings = function(mo,thing,string)
	quickthing(mo,thing)
	//Set fuse time
	setfusetime(mo,thing)

	//Set item type
	I.ItemSpawnType(mo,string)
	
	//Check the server settings to see if our spawn type is allowed
	if not(mo.localized) and CV.ItemGlobalSpawn.value == 0 then
		P_RemoveMobj(mo)
	return end
	if (mo.localized) and CV.ItemLocalSpawn.value == 0 then
		P_RemoveMobj(mo)
	return end

	
	//Get flags
	local f = thing.options
	
	//Special: Remove on contact with surfaces
		//Create mo.fragile
	if f&MTF_OBJECTSPECIAL
		mo.fragile = 1
	end
	
	//Ambush: Allow Multispawn
		//Create mo.multispawn
	if f&MTF_AMBUSH
		mo.multispawn = 1
	end
	
	//Get parameters
	I.Parameters(mo,thing)
	
	//Extra
	if f&MTF_EXTRA then
		if mo.localized then
			//Local: Spawn on map load
			I.DoSpawn(mo)
		else
			//Global: Spawn on ceiling
			if not(f&MTF_OBJECTFLIP) then
				mo.z = mo.ceilingz-mo.height
			else
				mo.z = mo.floorz
			end
			mo.gravity = 1			
		end
	end
end

I.CarouselSettings = function(mo,thing,string)
	if CV.ItemLocalSpawn.value == 0 then
		P_RemoveMobj(mo)
	return end
	B.DebugPrint("*********************",DF_ITEM)
	B.DebugPrint("start carousel for:",DF_ITEM)
	B.DebugPrint(mo,DF_ITEM)
	
	quickthing(mo,thing,true)
	local f = thing.options
	local p = thing.extrainfo
	local a = thing.angle%360
	local stagger = 0
	local function settings(c)
		//Set fuse time
		setfusetime(c,thing)
		
		//Set item type
		I.ItemSpawnType(c,string)		
		
		//Flags
		//if f&MTF_OBJECTFLIP
			//Does a flag need to be set at this stage?
		//end
		
		//Special: 2D orientation
		if f&MTF_OBJECTSPECIAL then
			c.carouselorientation = 1
		end
		
		
		//Angle = Carousel radius (drop rotation speed to compensate)
		c.carouselwidth = B.FixedLerp(64*FRACUNIT,1280*FRACUNIT,a*FRACUNIT/360)/FRACUNIT
		local maxspeed = FRACUNIT*2
		local minspeed = FRACUNIT
		c.carouselspeed = -B.FixedLerp(minspeed,maxspeed,a*FRACUNIT/360)/FRACUNIT
		//Ambush: Counter-clockwise drift
		if f&MTF_AMBUSH then
			c.carouselspeed = -1*$
		end
		//Extra: Spawn on map load
		if f&MTF_EXTRA then
			I.DoSpawn(c)
		else //Otherwise, stagger successive carousel spawns
			c.fuse = $+stagger
			stagger = $+20
		end
	end
	
	mo.angle = 0
	settings(mo)
	//Parameters = # of carousel items + 1
	//Create multiple spawns, each with a different item angle offset
	for n = 1, p
		local s = P_SpawnMobj(mo.x,mo.y,mo.z,MT_ITEM_SPAWN)
		s.flags2 = $|(mo.flags2&MF2_OBJECTFLIP)
		s.eflags = $|(mo.eflags&MFE_VERTICALFLIP)
		local i = (n)*FRACUNIT/(p+1)
		s.angle = B.FixedLerp(0,360,i)*ANG1
		settings(s)
	end
	thing.angle = 0
end

I.FlurrySettings = function(mo,thing,string)
	if CV.ItemLocalSpawn.value == 0 then
		P_RemoveMobj(mo)
	return end
	quickthing(mo,thing)
	//Set fuse time
	setfusetime(mo,thing,3)
	//Set item type
	I.ItemSpawnType(mo,string)
	//Flags
	local f = thing.options
	
	//Flip: Flip
		//MTF_OBJECTFLIP
		//Does a flag need to be set at this stage?
		
	//Special: Remove on contact with surfaces
	if f&MTF_OBJECTSPECIAL
		mo.fragile = 1
	end
	
	//Ambush: Add angle drift/variation
	if f&MTF_AMBUSH
		mo.flurrytype = 2
	else
		mo.flurrytype = 1
	end
	
	//Parameters
	I.Parameters(mo,thing)
	
	//Angle
		//Angle of Launch (no actions necessary here)
	//Extra: Spawn on map load
	if f&MTF_EXTRA
		I.DoSpawn(mo)
	end
end

I.CarouselRotate = function(mo)
	if not(mo.carouselspeed) then return end
	mo.angle = $+ANG1*mo.carouselspeed
end

I.SpawnDebugView = function(spawner,bubble)
	if not(CV.Debug.value&DF_ITEM) then spawner.flags2 = $|MF2_DONTDRAW return end
	if (spawner.fuse or not(spawner.localized)) and not(bubble and bubble.valid) then spawner.flags2 = $&~MF2_SHADOW
	else spawner.flags2 = $|MF2_SHADOW end
	spawner.colorized = true
	if not(spawner.localized) then 
		spawner.color = SKINCOLOR_BLUE
	elseif not(spawner.flurrytype or spawner.carouselwidth) then
		spawner.color = SKINCOLOR_RED
	elseif spawner.flurrytype then
		spawner.color = SKINCOLOR_YELLOW
	elseif spawner.carouselwidth then
		spawner.color = SKINCOLOR_GREEN
	end
end

I.ItemSpawnFuse = function(mo)
	if(mo.itemspawn_init)
		B.DebugPrint("Fuse triggered for item spawner "..tostring(mo),DF_ITEM)
		I.SetSpawning(mo)
		return true 
	end
end

I.ItemPrespawnThinker = function(mo)
	P_InstaThrust(mo,R_PointToAngle2(0,0,mo.momx,mo.momy),FixedHypot(mo.momx,mo.momy)*9/10)
	mo.momz = $*9/10
end
