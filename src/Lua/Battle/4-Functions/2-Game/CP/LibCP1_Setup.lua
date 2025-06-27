local B = CBW_Battle
local CP = B.ControlPoint
local CV = B.Console

CP.ActiveCount = 0 -- Stores number of CPs currently in play
CP.Num = 0 -- Stores the next CP index to activate
CP.ID = {} -- Stores the mobj instances of all CP objects on the map, active or inactive.
CP.Mode = false -- Determines whether CP Mode is currently in play. Returns false on non-CP game modes or if some issue has occurred.


COM_AddCommand('listcp',do
	for n,mo in ipairs(CP.ID)
		print('#'..n..'/'..mo.cpnum..' '..tostring(mo)..' status:'..mo.capture_status)
	end
end, COM_LOCAL)


-- ***
-- CP object spawn initialization
CP.MobjSpawn = function(mo)
	table.insert(CP.ID, mo)
	mo.cpnum = #CP.ID -- References the CP's index inside CP.ID

	mo.capture_status = CP_INERT -- Possible values: CP_INERT, CP_ACTIVE, CP_CAPTURING, CP_BLOCKED
	
	mo.capture_amount = {} -- Stores individual capture amounts for each player (where mo.capture_amount[n] is assigned to player[n+1]). In team modes, only indexes 1 and 2 are used (for red and blue team respectively)
		-- Replaces CP.TeamCapAmt, player.capturing, other player variables
		-- Should range from 0-FRACUNIT. Values >= FRACUNIT trigger capture bonus.
	for n = 1, 32 do
		mo.capture_amount[n] = 0
	end
	mo.capture_leader = 0 -- References the player/team index with the leading capture amount.
		-- replaces CP.LeadCapPlr
	mo.capture_highscore = 0 -- References the capture amount of mo.capture_leader
		-- replaces CP.LeadCapAmt
	
	-- NOTE: Above three must be reset whenever player instance or player mobj is missing, player is dead, or CP is made inert.
	
		-- Replaces CP.Active, CP.Capturing, CP.Blocked
	mo.capture_speed = 1 -- Amount per frame at which a CP is captured by a player
		-- Replaces CP.Meter
		-- Should be a low percentage of FRACUNIT
-- 	mo.Timer = 0
	-- Determines when the CP will appear. To be replaced by fuse.
	
	mo.cp_radius = CP.CalcRadius() -- Horizontal radius of the capture zone
	mo.cp_height = CP.CalcHeight() -- Height of the capture zone
	mo.cp_meter = CP.CalcMeter() --!! To be replaced by mo.capture_speed?
	
	
	-- Visual information
	mo.renderflags = $|RF_PAPERSPRITE|RF_FULLBRIGHT
	mo.fx = {} -- Objects table for visual parts
	CP.ResetFX(mo)
end

-- ***
-- Reset CP Mode status on mapchange
CP.ResetMode = function()
	CP.Mode = false
	CP.ID = {}
	CP.ActiveCount = 0
	CP.Num = 0
end

-- Generate CP backups if dedicated spawn points cannot be found.
CP.BackupGenerate = function()
	--Spawning a single backup CP at the player 1 spawn, in case something has gone wrong with the map or mode
	for mapthing in mapthings.iterate do
		if mapthing.type != 1 then continue end
		local fu = FRACUNIT
		local x = mapthing.x*fu
		local y = mapthing.y*fu
		local z = mapthing.z*fu
		local subsector = R_PointInSubsector(x,y)
		if subsector.valid and subsector.sector then
			z = $+subsector.sector.floorheight
			local mo = P_SpawnMobj(x,y,z,MT_CONTROLPOINT)			
			print("Backup CP has been spawned at Player 1 start")
			return mo
		end
	end
	--Default behavior, in case somehow there's no player 1 spawns????
	print("\x82 WARNING:\x80 Viable backup CP spawn could not be found.")
	return nil
end

-- Main function for generating CP objects on the map. Run during MapLoad
CP.Generate = function()
	if not(B.CPGametype()) then return end
	if #CP.ID != 0 then
		CP.ID = shuffle(CP.ID)
		CP.Mode = true
		CP.Num = 1
		return --Already have IDs? Don't need to generate more.
	end
	local id = {}
	local sp_bounce = CV.CPSpawnBounce.value
	local sp_auto = CV.CPSpawnAuto.value
	local sp_scatter = CV.CPSpawnScatter.value
	local sp_bomb = CV.CPSpawnBomb.value
	local sp_grenade = CV.CPSpawnGrenade.value
	local sp_rail = CV.CPSpawnRail.value
	local sp_inf = CV.CPSpawnInfinity.value
	local n = 1
	B.DebugPrint("Checking map things for Control Point spawn placement",DF_GAMETYPE)
	for mapthing in mapthings.iterate do
		local t = mapthing.type
		--Range of types
		if not(t >= 330 and t <= 335) and not(t == 303) then continue end
		--CVar checks
		if t==303 and not(sp_inf) then continue end
		if t==330 and not(sp_bounce) then continue end
		if t==331 and not(sp_rail) then continue end
		if t==332 and not(sp_auto) then continue end
		if t==333 and not(sp_bomb) then continue end
		if t==334 and not(sp_scatter) then continue end
		if t==335 and not(sp_grenade) then continue end
		B.DebugPrint("Spawning for thing type "..t,DF_GAMETYPE)
		local fu = FRACUNIT
		local x = mapthing.x*fu
		local y = mapthing.y*fu
		local z = mapthing.z*fu
		local subsector = R_PointInSubsector(x,y)
		if subsector.valid and subsector.sector then
			z = $+subsector.sector.floorheight
			local mo = P_SpawnMobj(x,y,z,MT_CONTROLPOINT)			
			id[n] = mo
			n = $+1
		end
	end
	local size = #id
	if size then
		CP.ID = B.Shuffle(id)
		B.DebugPrint("Shuffled "..#CP.ID.." ids",DF_GAMETYPE)
		CP.Mode = true
		CP.Num = 1
	else
		print("\x82 WARNING:\x80 No valid CP spawn positions found for current map. Attempting to spawn backup CP...")
		local mo = CP.BackupGenerate()
		if mo != nil then
			CP.Mode = true
			CP.ID[1] = mo
		else
			CP.Mode = false
		end
	end
end

-- Assign CP properties according to mapthing spawns
CP.MapThingSpawn = function(mo,thing)
	if not(B.CPGametype()) then
		P_RemoveMobj(mo)
	return end
	local settings = thing.options&15
	local parameters = thing.extrainfo
	local angle = thing.angle
	local flip = 0
	--Meter
	if parameters > 0 then
		mo.cp_meter = CP.CalcMeter(parameters)
	end
	
	--Radius
	if angle > 0 then
		mo.cp_radius = CP.CalcRadius(angle)
	end
	
	--Height
	local n = 2
	if settings&8 then n = $-1 end --Ambush flag
	if settings&1 then n = $+2 end --Extra flag
	if settings&2 then flip = 1 end --Flip flag
	if settings&4 then n = -1 end --Special flag
	mo.cp_height = CP.CalcHeight(n)
	local fu = FRACUNIT
	B.DebugPrint("Control Point ID #"..#CP.ID..": radius "..mo.cp_radius/fu..", height "..mo.cp_height/fu..", flip "..flip..", meter "..mo.cp_meter,DF_GAMETYPE)
end

--!! Get CP capture size (TODO: Convert this to capture_speed)
CP.CalcMeter = function(value)
	local minmeter = 400
	local maxmeter = 2400
	local defaultmeter = 1200
	if value != nil and value > 0 then
		local frac = FRACUNIT*value/15
		return B.FixedLerp(minmeter*FRACUNIT,maxmeter*FRACUNIT,frac)/FRACUNIT	
	else
		return defaultmeter
	end
end

-- Get CP radius
CP.CalcRadius = function(value)
	local minradius = 94*FRACUNIT
	local maxradius = 720*FRACUNIT
	local defaultradius = 384*FRACUNIT
	if value != nil and value > 0 then
		local frac = FRACUNIT*value/359
		return B.FixedLerp(minradius,maxradius,frac)
	else
		return defaultradius
	end
end

-- Get CP height
CP.CalcHeight = function(value)
	local flagheight = 96
	if value == nil or value == 0 then
		value = 2
	elseif value < 0 then
		return 0
	end
	return flagheight*value*FRACUNIT
end

