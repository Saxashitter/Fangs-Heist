local B = CBW_Battle
--
-- Dynamic 2D Camera
-- 
-- By Flame
-- Ported to from SRB2 Mod: Super Smash Bros: Sonic Showdown (SSB:SS) vS-001 (S for 'Smash')
-- Based on the SRB2FLAME source from 1.09.4
--
-- Special thanks to SSNTails for original Camera code
--

--
-- smash_getMobjForType(type)
--
-- Description:
-- Return the first mobj that is found with the right type.
-- Useful for finding a single unique object in a map.
-- If no map object was found, it returns nil.
--
local function smash_getMobjForType(type)
	for i_mo in mobjs.iterate() do -- i_mo is "iterating mo"
		if (i_mo.type != type)
			continue -- Ignore it
		end
		
		return i_mo
	end
	return nil
end

-- Camera doesn't exist yet upon spawn? 
-- Let's create the camera object...
-- But only for 2D mode!
addHook("PlayerSpawn", function(p)
	if p and p.valid and not p.spectator
	and p.mo and p.mo.valid
		local mo = p.mo -- Our mo is valid, so let's simplify
		if twodlevel or (mo.flags2 & MF2_TWOD)  -- 2D Mode?
			-- Spawn this camera object.
			local cam = P_SpawnMobj(mo.x, mo.y - (270<<FRACBITS), mo.z, MT_PLAYCAM)
			cam.target = mo
			cam.angle = R_PointToAngle2(cam.x, cam.y, cam.target.x, cam.target.y)
			p.awayviewmobj = cam -- Look at with the custom camera's POV
		end
	end
end)

-- Did the player switch to 2D controls mid-map?
-- Let's create the camera object!
addHook("PlayerThink", function(p)
	if p and p.valid and not p.spectator
	and p.mo and p.mo.valid
		local mo = p.mo -- Our mo is valid, so let's simplify
		if twodlevel or (mo.flags2 & MF2_TWOD) -- 2D Mode?
			-- Spawn this camera object.
			if not p.awayviewmobj
				local cam = P_SpawnMobj(mo.x, mo.y - (270<<FRACBITS), mo.z, MT_PLAYCAM)
				cam.target = mo
				cam.angle = R_PointToAngle2(cam.x, cam.y, cam.target.x, cam.target.y) -- Make it face towards your target.
				p.awayviewmobj = cam -- Set your POV to the 'new' camera POV
			else
				p.awayviewtics = 2 -- ALWAYS look at with the custom camera's POV
			end
		else -- NOT in 2D mode anymore?
			if p.awayviewmobj and (p.awayviewmobj.type == MT_PLAYCAM) -- Check if your awayviewmobj set to MT_PLAYCAM?
				p.awayviewtics = 0 -- Reset your awayviewtics.
				P_RemoveMobj(p.awayviewmobj) -- Remove it!
				p.awayviewmobj = nil -- Make this available again.
			end
		end
	end
end)

-- Let's get to the meat of the code...
addHook("MobjThinker", function(mo)
	if consoleplayer == nil then return end //Dedicated server check
	if mo and mo.valid -- We're valid!
	and mo.target and mo.target.valid -- Our target is valid!

		if mo.target.player and mo.target.player.valid -- Check again, our target is a valid player?
		and (mo.target.player.playerstate != PST_DEAD) -- Our player is alive?
			local p = mo.target.player
			-- Borrow some vanilla values
			local camheight = CV_FindVar("cam_height").value>>FRACBITS
			local camdist = CV_FindVar("cam_dist").value>>FRACBITS
			local dist = R_PointToDist2(mo.x, mo.y, mo.target.x, mo.target.y)
			local zdiff = (mo.target.z - mo.z)
			
			
			--p.awayviewaiming = R_PointToAngle2(0, 0, dist, zdiff)
-- 			p.awayviewaiming = p.aiming
			p.awayviewaiming = 0
			--mo.angle = R_PointToAngle2(mo.x, mo.y, mo.target.x, mo.target.y)

			local cam = {}
			cam = { x = mo.x,
					y = mo.y,
					z = mo.z
					}

			cam.border = { min = smash_getMobjForType(MT_CAMMIN), -- Closest Mo
							max = smash_getMobjForType(MT_CAMMAX) -- Furthest mo
							}
			-- Simplify ourselves
			local cammin = cam.border.min
			local cammax = cam.border.max
			
			-- Oh boy... Let's see what we'll need...
			local numplayers = 0
			local numpeeps = FRACUNIT
			local current = 0
			local centerX = 0
			local farthestplayerX = 0
			local centerZ = 0
			local farthestplayerZ = 0
			local NewDist
			local CAMERA_MAXMOVE = 20*FRACUNIT -- Default Maxmove
			local dist = 0
			for p in players.iterate
				if not p.mo -- Not a valid mo?
					continue
				end
				
				if p.spectator or p.bot -- Ignore Spectators and bots
					continue
				end
				
				if p.lives <= 0 -- I'm dead
					continue
				end
				
				if (p.playerstate == PST_DEAD) -- I'm actually dead.
					continue
				end
				
				numplayers = $ + 1
				
				centerX = FixedMul($, FixedDiv(numpeeps-FRACUNIT, numpeeps))
				centerX = $ + FixedMul(p.mo.x, FixedDiv(FRACUNIT, numpeeps))

				centerZ = FixedMul($, FixedDiv(numpeeps-FRACUNIT, numpeeps))
				centerZ = $ + FixedMul(p.mo.z, FixedDiv(FRACUNIT, numpeeps))

				numpeeps = $ + FRACUNIT
			end
			
			-- Don't do anything with the camera if everyone's dead
			if (numplayers == 0)
				return
			elseif (numplayers == 1) -- Only you?
-- 				CAMERA_MAXMOVE = 30*FRACUNIT
				CAMERA_MAXMOVE = 999*FRACUNIT
			end
			
			-- Move the Caerma X
			dist = centerX - (cam.x)
			
			if (dist > 0)
				if (dist > CAMERA_MAXMOVE)
					cam.x = $ + CAMERA_MAXMOVE
				else
					cam.x = $ + dist
				end
			elseif (dist < 0)
				if (dist < -CAMERA_MAXMOVE)
					cam.x = $ + -CAMERA_MAXMOVE
				else
					cam.x = $ + dist
				end
			end

			if (cammin and cam.x < cammin.x)
				cam.x = cammin.x
			elseif (cammax and cam.x > cammax.x)
				cam.x = cammax.x
			end
			
			-- Move the Camera Z
			centerZ = $ + camheight<<FRACBITS -- Let's give the user some cam_height feasibility.
			dist = centerZ - (cam.z)

			if (dist > 0)
				if (dist > CAMERA_MAXMOVE)
					cam.z = $ + CAMERA_MAXMOVE
				else
					cam.z = $ + dist
				end
			elseif (dist < 0)
				if (dist < -CAMERA_MAXMOVE)
					cam.z = $ + -CAMERA_MAXMOVE
				else
					cam.z = $ + dist
				end
			end

			if (cammin and cam.z < cammin.z)
				cam.z = cammin.z
			elseif (cammax and cam.z > cammax.z)
				cam.z = cammax.z
			end
			
			for p in players.iterate -- FROM HERE: Calculate furthest players
				if not p.mo -- Not a valid mo?
					continue
				end
				
				if p.spectator or p.bot -- Ignore Spectators and bots
					continue
				end
				
				if p.lives <= 0 -- I'm dead
					continue
				end
				
				if (p.playerstate == PST_DEAD) -- I'm actually dead.
					continue
				end
				
				current = abs(p.mo.x - centerX)

				if (current > farthestplayerX)
					farthestplayerX = current
				end

				current = abs(p.mo.z - centerZ)

				if (current > farthestplayerZ)
					farthestplayerZ = current
				end
			end
			
			-- Subtract a little so the player isn't right on the edge of the camera.
			NewDist = -(farthestplayerX + farthestplayerZ + 64*FRACUNIT)

			-- Move the camera's Y
			if (numplayers == 1) -- If it's only you...
				dist = NewDist - (mo.y) - (camdist<<FRACBITS)  -- Let's give the user some cam_dist feasibility.
			else
				dist = NewDist - (mo.y)
			end

			if (dist > 0)
				if (dist > CAMERA_MAXMOVE)
					cam.y = $ + CAMERA_MAXMOVE
				else
					cam.y = $ + dist
				end
			elseif (dist < 0)
				if (dist < -CAMERA_MAXMOVE)
					cam.y = $ + -CAMERA_MAXMOVE
				else
					cam.y = $ + dist
				end
			end
			
			-- This may seem backward but its not.
			if (cammin and cam.y > cammin.y)
				cam.y = cammin.y
			elseif (cammax and cam.y < cammax.y)
				cam.y = cammax.y
			elseif not cammax and (cam.y < mo.target.y - 3*(camdist<<FRACBITS)/2) -- OOB check
				cam.y = mo.target.y - 3*(camdist<<FRACBITS)/2
			end
			//Apply camera smoothing
-- 			cam.x = B.FixedLerp(mo.x,cam.x,FRACUNIT/2)
-- 			cam.y = B.FixedLerp(mo.y,cam.y,FRACUNIT/2)
-- 			cam.z = B.FixedLerp(mo.z,cam.z,FRACUNIT/2)
			//apply boundaries
			if displayplayer and displayplayer.mo then
				local bounds = FRACUNIT*32
				local yo = FRACUNIT*512
				local zo = FRACUNIT*64
				local c = displayplayer.mo
				cam.x = B.FixedLerp(mo.x,min(c.x+bounds,max(c.x-bounds,$)),FRACUNIT/2)
				cam.y = B.FixedLerp(mo.y,min(c.y-yo+bounds,max(c.y-yo-bounds,$)),FRACUNIT/2)
				cam.z = B.FixedLerp(mo.z,min(c.z+zo+bounds,max(c.z+zo-bounds,$)),FRACUNIT/2)
			end
			
			-- Phew! That was a lot. Now set the mo to the stored cam table values this tic
			P_TeleportMove(mo, cam.x, cam.y, cam.z)
		else -- mo.target.player is not valid or dead.
			P_RemoveMobj(mo)
			return
		end
	else -- Not a valid target
		P_RemoveMobj(mo)
		return
	end
end, MT_PLAYCAM)