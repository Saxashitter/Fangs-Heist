//LUA_RSPN

-- kays#5325

if AddObjectTypeRespawn
	return
end

/************
 * CONTENTS *
 ************/
-- SET-UP
	-- RoverCheck <-- check here for documentation
	-- RoverList
	-- RoverRespawnQueue
	-- ObjectRespawnQueue

-- DEFAULT FUNCTIONS
	-- RegularRoverCheck
	-- RegularShouldRespawn
	-- RegularTimer
	-- RegularSpawn
	-- RegularSetUp

-- ADD OBJECTS
	-- CheckType
	-- AddObjectTypeRespawn <-- check here for documentation

-- HOOKS
	-- ThinkFrame
	-- MapChange
	-- MapLoad
	-- NetVars

/**********
 * SET-UP *
 **********/
--[[ RoverCheck
This is set in MapChange through the level header field
 Lua.RoverCheck. This field may be the name of a function in
 the global table, which is called when a bustable block is
 destroyed to determine whether and when to respawn it.

The function receives the rover as an argument and should
 return a tic_t, to be used as the timer for how long to wait
 before respawning. If the function returns 0, nil, or false, 
 the rover is not respawned.

If Lua.RoverCheck is set, but does not point to a function,
 RoverCheck will be set to RegularRoverCheck.

Otherwise, RoverCheck will be nil, and none of the FOF respawning
 code will run for this map.
]]--
local RoverCheck

--[[ RoverList
List of rovers with FF_BUSTUP, set during MapLoad.
Rovers are moved from this list to RoverRespawnQueue
 when they no longer exist, and are moved back after
 being respawned.
]]--
local RoverList = {}

--[[ RoverRespawnQueue
	array of tables, with fields:
		timer | tic_t    | how long before respawning rover
		rover | ffloor_t | rover to respawn
]]--
local RoverRespawnQueue = {}

--[[ ObjectRespawnQueue
	array of tables, with fields:
		timer      | tic_t      | how long before respawning object
		spawnpoint | mapthing_t | mapthing to respawn from
		spawnfunc  | function   | function to spawn the object
		setupfunc  | function   | function to set up the object
		objecttype | enum (MT_) | the actual object type to spawn
]]--
local ObjectRespawnQueue = {}

/*********************
 * DEFAULT FUNCTIONS *
 *********************/
-- Regular function for FOF respawning.
local function RegularRoverCheck()
	if (not (netgame or multiplayer)) -- never respawn in single player
		or (maptol & TOL_NIGHTS) -- never respawn in NiGHTS
		or (not CV_FindVar("respawnitem").value) -- never respawn if cvar is off
		or (G_IsSpecialStage()) -- never respawn in special stage
	then
		return 0
	end

	return CV_FindVar("respawnitemtime").value*TICRATE -- okay do it
end

-- Regular functions for object respawning, see AddObjectTypeRespawn for usage
local function RegularShouldRespawn(mo)
	if (not (netgame or multiplayer)) -- never respawn in single player
		or (maptol & TOL_NIGHTS) -- never respawn in NiGHTS
		or (not CV_FindVar("respawnitem").value) -- never respawn if cvar is off
		or (G_IsSpecialStage()) -- never respawn in special stage
		or (mo.flags2 & MF2_DONTRESPAWN) -- never respawn if don't respawn
	then
		return false
	end

	return true -- okay do it
end

local function RegularTimer()
	return CV_FindVar("respawnitemtime").value*TICRATE
end

-- spawnpoint.scale is upcoming in 2.2.7
local function RegularSpawn(spawnpoint, objecttype)
	if not (spawnpoint and spawnpoint.valid) then return nil end

	local x = spawnpoint.x << FRACBITS
	local y = spawnpoint.y << FRACBITS
	local z = spawnpoint.z << FRACBITS

	local flip = (not (mobjinfo[objecttype].flags & MF_SPAWNCEILING)) ~= (not (spawnpoint.options & MTF_OBJECTFLIP))
	local sector = R_PointInSubsector(x, y).sector

	if flip
		if sector.c_slope
			z = P_GetZAt(sector.c_slope, x, y) - $ - mobjinfo[objecttype].height --FixedMul(mobjinfo[objecttype].height, spawnpoint.scale)
		else
			z = sector.ceilingheight - $ - mobjinfo[objecttype].height --FixedMul(mobjinfo[objecttype].height, spawnpoint.scale)
		end
	else
		if sector.f_slope
			z = P_GetZAt(sector.f_slope, x, y) + $
		else
			z = sector.floorheight + $
		end
	end

	local mo = P_SpawnMobj(x, y, z, objecttype)
	mo.spawnpoint = spawnpoint
	spawnpoint.mobj = mo

	return mo
end

-- spawnpoint.scale, pitch, and roll are upcoming in 2.2.7
local function RegularSetUp(spawnpoint, mo)
	if not (spawnpoint and spawnpoint.valid and mo and mo.valid) then return end

	--mo.scale = spawnpoint.scale

	mo.angle = FixedAngle(spawnpoint.angle << FRACBITS)
	--mo.pitch = FixedAngle(spawnpoint.pitch << FRACBITS)
	--mo.roll  = FixedAngle(spawnpoint.roll  << FRACBITS)

	if spawnpoint.options & MTF_AMBUSH
		mo.flags2 = $|MF2_AMBUSH
	end

	--[[if spawnpoint.options & MTF_OBJECTSPECIAL
	end]]--

	if spawnpoint.options & MTF_OBJECTFLIP
		mo.eflags = $|MFE_VERTICALFLIP
		mo.flags2 = $|MF2_OBJECTFLIP
	end

	--[[if spawnpoint.options & MTF_EXTRA
	end]]--
end

/***************
 * ADD OBJECTS *
 ***************/
-- quick sanity function
local function CheckType(var, expected, func, varname)
	local t = type(var)
	if t ~= expected
		local funcstr = func and ("\130" .. func .. ": \128") or ""
		local varstr = varname and (" for argument " .. varname) or ""
		error(funcstr .. "type " .. expected .. " expected" .. varstr .. ", got " .. t, 0)
	end
end

--[[ AddObjectTypeRespawn(objecttype, [shouldrespawnfunc], [timerfunc], [spawnfunc], [setupfunc])

objecttype: enum (MT_)
	The only required argument. The object type to add an MobjRemoved hook for and respawn.

shouldrespawnfunc: boolean function(mo, mo.spawnpoint)
	Defaults to RegularShouldRespawn. When an object of objecttype is removed, this
	function should return whether or not to actually add it to the respawn queue.
	Note that an object will never be added to the queue without a valid spawnpoint.

timerfunc: tic_t function(mo, mo.spawnpoint)
	Defaults to RegularTimer. When an object of objecttype is removed, this function
	should return the time before respawning, in tics.

spawnfunc: mobj_t function(spawnpoint, objecttype)
	Defaults to RegularSpawn. This function is called when it's time to respawn the
	object. It spawns the object in the correct position, links the object to its
	spawnpoint and vice-versa, and returns the object. Most objects can use the
	default spawnfunc.

setupfunc: void function(spawnpoint, mo)
	Defaults to RegularSetUp. This function is called after the object is spawned to
	correctly set things such as its angle and flags. Objects with special properties,
	such as spikes, will need to use a custom setupfunc.
]]--
rawset(_G, "AddObjectTypeRespawn", function(objecttype, shouldrespawnfunc, timerfunc, spawnfunc, setupfunc)
	shouldrespawnfunc = $ or RegularShouldRespawn
	timerfunc = $ or RegularTimer
	spawnfunc = $ or RegularSpawn
	setupfunc = $ or RegularSetUp

	local success, errmsg = pcall(do
		CheckType(objecttype, "number", "AddObjectTypeRespawn", "objecttype")
		CheckType(shouldrespawnfunc, "function", "AddObjectTypeRespawn", "shouldrespawnfunc")
		CheckType(timerfunc, "function", "AddObjectTypeRespawn", "timerfunc")
		CheckType(spawnfunc, "function", "AddObjectTypeRespawn", "spawnfunc")
		CheckType(setupfunc, "function", "AddObjectTypeRespawn", "setupfunc")
	end)

	if not success
		print(errmsg)
		return
	end

	addHook("MobjRemoved", function(mo)
		if mo.spawnpoint and mo.spawnpoint.valid and shouldrespawnfunc(mo, mo.spawnpoint)
			table.insert(ObjectRespawnQueue, {
				timer = timerfunc(mo, mo.spawnpoint),
				spawnpoint = mo.spawnpoint,
				spawnfunc = spawnfunc,
				setupfunc = setupfunc,
				objecttype = objecttype
			})
		end
	end, objecttype)
end)

/*********
 * HOOKS *
 *********/
addHook("ThinkFrame", do
	local removekeys = {}

	if RoverCheck
		-- Check RoverList for dead rovers
		for i, rover in ipairs(RoverList)
			if not (rover.flags & FF_EXISTS)
				local respawn = RoverCheck(rover)
				if respawn
					table.insert(RoverRespawnQueue, {
						timer = respawn,
						rover = rover
					})
				end
				table.insert(removekeys, i)
			end
		end
		for i = #removekeys, 1, -1
			table.remove(RoverList, removekeys[i])
		end
		removekeys = {}

		-- Decrement RoverRespawnQueue timers, respawn rovers as necessary
		for i, rtable in ipairs(RoverRespawnQueue)
			if rtable.timer
				rtable.timer = $ - 1
			else
				rtable.rover.flags = $|FF_EXISTS
				table.insert(RoverList, rtable.rover)
				table.insert(removekeys, i)
			end
		end
		for i = #removekeys, 1, -1
			table.remove(RoverRespawnQueue, removekeys[i])
		end
		removekeys = {}
	end

	-- Decrement ObjectRespawnQueue timers, respawn objects as necessary
	for i, otable in ipairs(ObjectRespawnQueue)
		if otable.timer
			otable.timer = $ - 1
		else
			local mo = otable.spawnfunc(otable.spawnpoint, otable.objecttype)
			otable.setupfunc(otable.spawnpoint, mo)
			table.insert(removekeys, i)
		end
	end
	for i = #removekeys, 1, -1
		table.remove(ObjectRespawnQueue, removekeys[i])
	end
end)

addHook("MapChange", function(mapnum)
	local rovercheckstring = mapheaderinfo[mapnum].rovercheck
	if rovercheckstring
		local success, value = pcall(do return _G[rovercheckstring] end)
		if success and (type(value) == "function")
			RoverCheck = value
		else
			RoverCheck = RegularRoverCheck
		end
	else
		RoverCheck = nil
	end

	RoverList = {}
	RoverRespawnQueue = {}
	ObjectRespawnQueue = {}
end)

addHook("MapLoad", do
	if not RoverCheck then return end
	for sector in sectors.iterate
		for rover in sector.ffloors()
			if rover.flags & FF_BUSTUP
				table.insert(RoverList, rover)
			end
		end
	end
end)

addHook("NetVars", function(net)
	RoverCheck = net($)
	RoverList = net($)
	RoverRespawnQueue = net($)
	ObjectRespawnQueue = net($)
end)