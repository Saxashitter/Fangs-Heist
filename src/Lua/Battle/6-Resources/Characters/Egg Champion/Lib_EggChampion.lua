local B = CBW_Battle

local dprint = function(str)
	B.DebugPrint(str, DF_PLAYER)
end

local dghost = function(mo, condition)
	local ghost = P_SpawnGhostMobj(mo)
	ghost.destscale = $<<1
	ghost.colorized = true
	if condition
		ghost.color = SKINCOLOR_GREEN
	else
		ghost.color = SKINCOLOR_RED
	end
end

-- Some "enums"
local ST = {
	NEUTRAL = 0,
	RISE = 1,
	FALL = 2,
	EXPOSED = 3,
	PAIN = 4,
	ATKSTART = 5,
	ATKRELEASE = 6,
	GUARD = 7,
	PARRY = 8,
	MASK = 15,
	ATKFLAG = 16,
	COOLDOWNFLAG = 16<<1,
}
local MODE = {
	BOXER = 0,
	TANK = 1,
	KNIGHT = 2
}
local ARM = {
	GLOVE = 0,
	LAUNCHER = 1,
	SWORD = 2,
	SHIELD = 3
}

freeslot('SPR_SWRD')

-- Some variable settings
local glovesprite = SPR_CBLL
local spikesprite = SPR_FMCE
local gunsprite = SPR_TRET
local swordsprite = SPR_SWRD
local shieldsprite = SPR_PUMI
local attackstarttics = 12
local missilerate = 5
local swordrot = ANG60
local shielddisabletime = TICRATE/2
local shieldmax = 5
local suffertics = TICRATE*4

--Egg Champion Arm
freeslot("MT_EGGCHAMPION_ARM")
mobjinfo[MT_EGGCHAMPION_ARM] = {
	radius = 20*FRACUNIT,
	height = 40*FRACUNIT,
	spawnstate = S_CANNONBALL1,
	speed = 60*FRACUNIT,
	flags = MF_SPECIAL|MF_NOGRAVITY|MF_NOCLIPHEIGHT|MF_NOCLIP|MF_SCENERY,
}

local chainmax = 8
local spawnCoil = function(mo, num)
	local coil = P_SpawnMobjFromMobj(mo, 0, 0, 0, 1) --dunno if hijacking the "unknown" object is good form, but I don't care!
	coil.sprite = SPR_TRNG
	coil.color = SKINCOLOR_SILVER
	coil.renderflags = $|RF_PAPERSPRITE
-- 	coil.scale = $*(abs(chainmax/2-num)+chainmax/2)/chainmax
	return coil
end

addHook('MobjSpawn', function(mo)
	mo.armtype = 0
	mo.attackstate = 0
	mo.attacktics = 0
	mo.paintics = 0
	mo.ready = false
	mo.side = "left"
	mo.chain = {}
	mo.sprite = SPR_PUMI
	mo.shadowscale = FRACUNIT
	for n = 1, chainmax do
		mo.chain[n] = spawnCoil(mo, n)
	end
end, MT_EGGCHAMPION_ARM)

local transformArm = function(arm, sprite)
	if arm.sprite != sprite
		arm.sprite = sprite
		local ghost = P_SpawnGhostMobj(arm)
		ghost.colorized = true
		ghost.destscale = $<<1
		ghost.color = SKINCOLOR_WHITE
		ghost.blendmode = AST_ADD	
	end
end

local doArmType = function(arm)
	local mode = arm.owner.eggchampionvars.mode
	if mode == MODE.BOXER
		arm.armtype = ARM.GLOVE
	elseif mode == MODE.TANK
		arm.armtype = ARM.LAUNCHER
	elseif mode == MODE.KNIGHT
		if arm.side == "right"
			arm.armtype = ARM.SWORD
		elseif arm.side == "left"
			arm.armtype = ARM.SHIELD
		end
	end
end

local spawnEggChampionArm = function(mo, side)
	local arm = P_SpawnMobjFromMobj(mo,0,0,0,MT_EGGCHAMPION_ARM)
	if arm and arm.valid
		mo.eggchampionvars.arms[side] = arm
		arm.owner = mo
		arm.side = side
		doArmType(arm)
		dprint("Spawned egg champion's "..side.." arm")
	else
		dprint("Failed to spawn egg champion's "..side.." arm")
	end
	return arm
end

local spawnMissile = function(arm, mt)
	local hitbox
	local mo = arm.owner
	local near = B.GetNearestPlayer(mo,60,-1)
	if mt
		if not(near)
			local dist = mo.scale * 512
			local tx = P_ReturnThrustX(nil, mo.angle, dist)
			local ty = P_ReturnThrustY(nil, mo.angle, dist)
			hitbox = P_SpawnPointMissile(mo, mo.x+tx, mo.y+ty, mo.z, mt, arm.x, arm.y, arm.z)
		else
			hitbox = P_SpawnXYZMissile(mo, near.mo, mt, arm.x, arm.y, arm.z)
		end
		dprint('Spawned missile at '..arm.side..' arm')
	else
		local angle
		if not(near)
			local dist = mo.scale * 512
			local tx = P_ReturnThrustX(nil, mo.angle, dist)
			local ty = P_ReturnThrustY(nil, mo.angle, dist)
			angle = R_PointToAngle2(arm.x, arm.y, mo.x + tx, mo.y + ty)
		else
			angle = R_PointToAngle2(arm.x, arm.y, near.mo.x, near.mo.y)
		end
		P_InstaThrust(arm, angle, FixedMul(arm.info.speed, arm.scale))
		dprint('Threw '..arm.side..' arm')
	end
	return hitbox
end

local releaseArmAttack = function(arm)
	local owner = arm.owner
	local vars = owner.eggchampionvars
	if arm.armtype == ARM.LAUNCHER --Launcher attack
		if owner.player.rings
			spawnMissile(arm, MT_TORPEDO2)
			owner.player.rings = $-1
		else
			spawnMissile(arm, MT_DUST)
		end
		owner.player.weapondelay = missilerate
		arm.attacktics = missilerate*2
		arm.attackstate = 0
	elseif arm.armtype == ARM.SWORD --Sword attack
		arm.attackstate = 2
		spawnMissile(arm)
		arm.attacktics = TICRATE*2
		arm.flags = ($&~(MF_NOCLIP|MF_NOCLIPHEIGHT))|MF_BOUNCE
	else --Punch attack
		local hitbox = spawnMissile(arm, MT_EGGCHAMPION_PUNCH)
		if hitbox and hitbox.valid
			arm.target = hitbox
			hitbox.fuse = 18
			hitbox.arm = arm
		end
		arm.attackstate = 2	
	end
end

local startArmAttack = function(arm)
	local owner = arm.owner
	local vars = owner.eggchampionvars
	arm.ready = false
	if arm.armtype == ARM.LAUNCHER
		if vars.state != ST.ATKRELEASE
			arm.attacktics = attackstarttics
			arm.attackstate = 1
		elseif vars.state != ST.ATKSTART
			releaseArmAttack(arm)
			arm.ready = false
		end
	else --Punch attack, sword throw
		arm.attackstate = 1
		owner.state = S_PLAY_STND
		owner.state = S_PLAY_FIRE
		owner.player.panim = PA_ABILITY2
		owner.player.weapondelay = 20
		owner.player.drawangle = owner.angle
		arm.attacktics = attackstarttics
		if arm.side == "right"
			owner.frame = $+8
		end
	end
end

-- Arm movement
local repositionArm = function(arm, side, cycle)
	if arm.target and arm.target.valid --We're following a hitbox
		P_TeleportMove(arm, arm.target.x, arm.target.y, arm.target.z)
		return
	end
	
	local mo = arm.owner
	local state = 0
	if cycle and cycle < 0
		state = -cycle
		cycle = nil
	end
	if state == ST.GUARD
		cycle = nil
	end
	-- Get angle offset of arm's position
	local thrustangle = 30*FRACUNIT --We might interpolate this value later
	if side == "right"
		thrustangle = -$
	end
	-- Get distance offset of arm's position
	local thrustdist = mo.radius+arm.radius+mo.scale*48
	-- Get z position
	local z = mo.z + mo.height/2 - arm.height/2
	-- State modifiers
	if arm.armtype == ARM.LAUNCHER
		if state == ST.GUARD
			thrustangle = $/2
			thrustdist = $*3/4
			if side == "left"
				z = $ + mo.height/4
			end
		elseif state == ST.PARRY
			thrustdist = $/2
			z = $ + mo.height/2
		else
			thrustdist = $/2
			thrustangle = $*2
			if arm.ready == false -- Recoil movement
				local lerpamt = min(FRACUNIT, FRACUNIT*arm.attacktics/missilerate)
				thrustdist = B.FixedLerp($, $, lerpamt)
				thrustangle = B.FixedLerp($, $*2, lerpamt)
			end
		end
	elseif arm.armtype == ARM.GLOVE
		if state --Sanity check
			if state == ST.GUARD
				thrustangle = $/2
				thrustdist = $*3/4
				if side == "left"
					z = $ + mo.height/4
				end
			elseif state == ST.PARRY
				thrustdist = $/2
				z = $ + mo.height/2
			elseif state == ST.PAIN
			or state == ST.EXPOSED
				thrustangle = $*2
				z = $ + mo.height/4
			elseif state == ST.RISE
				if side == "left"
					thrustangle = $*2
					z = $ - mo.height/2
				else
					z = $ + mo.height/2
				end
				thrustdist = $/2
			elseif state == ST.FALL
				z = $ + mo.height/4
			elseif state == ST.ATKSTART|ST.ATKFLAG -- This arm is winding up for an attack
				thrustangle = B.FixedLerp($*4, $*3, FRACUNIT*arm.attacktics/attackstarttics)
			elseif state & ST.COOLDOWNFLAG -- This arm is cooling down after an attack
			or state == ST.ATKRELEASE -- Attack was released (not the attacking arm)
				thrustangle = $*3
				z = $ - mo.height/4
			elseif state == ST.ATKSTART --Starting attack (not the attacking arm)
				thrustangle = $*2
				thrustdist = $*5/6
			end
		end
	else --Sword and shield
		if arm.armtype == ARM.SWORD and arm.attackstate == 2 --Sword is currently flying
			return
		end
		if arm.armtype == ARM.SHIELD
			cycle = nil
		end
		if arm.armtype == ARM.SHIELD and state != ST.ATKSTART and arm.ready
			thrustangle = 0
			if state == ST.GUARD
				thrustdist = $>>1
			end
		elseif arm.armtype == ARM.SWORD
		and not(arm.ready or arm.attackstate == 1 or arm.attacktics)
			thrustangle = 0
			thrustdist = 0
			z = mo.z + mo.height + mo.scale*2
			cycle = nil
		else
			if state == ST.GUARD
				thrustangle = $/2
				thrustdist = $*3/4
				if side == "left"
					z = $ + mo.height/4
				end
			elseif state == ST.PARRY
				thrustdist = $/2
				z = $ + mo.height/2
			else
				if arm.ready == false -- Recoil movement
					local lerpamt = min(FRACUNIT, FRACUNIT*arm.attacktics/missilerate)
					thrustdist = B.FixedLerp($, $, lerpamt)
					thrustangle = B.FixedLerp($, $*2, lerpamt)
				end
			end
		end		
	end
	if arm.armtype != ARM.SHIELD and arm.armtype != ARM.SWORD
		thrustangle = FixedAngle($)+mo.player.drawangle
	else
		thrustangle = FixedAngle($)+mo.angle --Shield should always follow the camera angle
	end
	-- Translate to x and y position
	local x = mo.x + P_ReturnThrustX(nil, thrustangle, thrustdist)
	local y = mo.y + P_ReturnThrustY(nil, thrustangle, thrustdist)
			
	if cycle != nil --Add cyclical motion to arms to emulate "fighter stance"
		local angle = mo.player.drawangle
		local radius = mo.scale*16
		local speed = FRACUNIT*16
		local wheel = FixedAngle(cycle*speed)
		local zangle = wheel
		
		if arm.armtype == ARM.GLOVE
			if side == "left"
				zangle = wheel+ANGLE_180
			end
			local xythrust = P_ReturnThrustX(nil, zangle, radius)
			x = $ + P_ReturnThrustX(nil, angle, xythrust)
			y = $ + P_ReturnThrustY(nil, angle, xythrust)
		else
			radius = $>>2
		end
	
		local zthrust = P_ReturnThrustY(nil, zangle, radius)
		z = $ + zthrust
	end
	
	--Travel to destination position
	arm.momx = $/3 + (x-arm.x)/2
	arm.momy = $/3 + (y-arm.y)/2
	arm.momz = $/3 + (z-arm.z)/2
end

-- Arm Thinker (Actions)
local regulateChampionArm = function(mo, side, pressattack, holdattack)
	local vars = mo.eggchampionvars
	if not(vars.arms[side] and vars.arms[side].valid)
		if not(spawnEggChampionArm(mo,side))
			return pressattack --No arm to regulate for this frame
		end
	end
	local arm = vars.arms[side]
	local cycle = vars.cycle
	local canattack = true
	arm.attacktics = max(0, $-1)
	arm.paintics = max(0, $-1)
	arm.scale = mo.scale
	arm.angle = mo.player.drawangle
	
	--Change arm to suit mode
	if arm.attackstate == 0 and arm.attacktics == 0 and arm.paintics == 0
		doArmType(arm)
	end
	
	--Regulate shield hitbox
	if arm.armtype == ARM.SHIELD
		if vars.shieldhp > 0
			if not(arm.shield and arm.shield.valid)
				local shield = P_SpawnMobjFromMobj(arm, 0, 0, 0, MT_EGGCHAMPION_SHIELD)
				if shield and shield.valid
					shield.arm = arm
					shield.owner = mo
					arm.shield = shield
					dprint("Spawn shield object")
				end
			end
		elseif (arm.shield and arm.shield.valid) --Shield has been broken!
			B.MakeDeadJunk(arm.shield, arm)
			dprint("Destroyed shield")
		end
	else
		if arm.shield
			if arm.shield.valid
				P_RemoveMobj(arm.shield)
				dprint("Despawned shield object")
			end
			arm.shield = nil
		end
	end

	--Regulate arm to match battle special
	local special = vars.specials[vars.activespecial]
	if special
		canattack = false
		arm.ready = false
		if vars.activespecial == MODE.BOXER+1
			local n = side == "left" and 2 or 1
			local follow = vars.specials[MODE.BOXER+1].parts[n]
			if follow and follow.valid
				arm.attackstate = 2
				arm.target = follow
			end
		end
	end
	if special and vars.activespecial == MODE.BOXER+1
		P_SpawnPointMissile(mo, arm.x, arm.y, arm.z, MT_EGGCHAMPION_PUNCHSPECIAL, arm.x, arm.y, arm.z)
	end
	-- Arm is currently in the middle of a launched attack
	if arm.attackstate == 2 
		if arm.armtype == ARM.GLOVE --Punching
			if not(arm.target and arm.target.valid) --Hitbox was removed
				arm.attackstate = 0
				arm.attacktics = 15
				dprint("Returned "..side.." arm")
			end
			repositionArm(arm, side)
		else --Thrown sword
			--Seek owner
-- 			local angle = R_PointToAngle2(arm.x, arm.y, mo.x, mo.y)
			arm.momx = $*97/100 + (mo.x-arm.x)/150
			arm.momy = $*97/100 + (mo.y-arm.y)/150
			arm.momz = $*97/100 + ((mo.z+mo.height/2)-(arm.z+arm.height/2))/150
			if arm.z < mo.z
				arm.z = max($, arm.floorz)
			elseif arm.z+arm.height > mo.z+mo.height
				arm.z = min($, arm.ceilingz-arm.height)
			end
			--Hitbox
			local slice = P_SpawnPointMissile(mo, arm.x, arm.y, arm.z, MT_EGGCHAMPION_SLICE, arm.x, arm.y, arm.z)
			if slice and slice.valid
				slice.fuse = 2
			end
			--Lose terrain collision
			if arm.attacktics == 0
				arm.flags = ($|MF_NOCLIP|MF_NOCLIPHEIGHT)&~MF_BOUNCE
			end
		end
		return pressattack, holdattack
	end
	--Fallthrough to standard arm behavior
	if vars.state == ST.GUARD -- Guard state
	or vars.state == ST.PARRY -- Parry state
	or vars.state == ST.PAIN -- Pain state
	or vars.state == ST.EXPOSED -- Midair vulnerable state
		cycle = -vars.state
		canattack = false
	elseif vars.state == ST.ATKSTART -- Attack startup
	or vars.state == ST.ATKRELEASE -- Attack release
		if arm.attackstate == 1
			cycle = -(vars.state|ST.ATKFLAG)
		elseif not(arm.ready)
			cycle = -(vars.state|ST.COOLDOWNFLAG)
		else
			cycle = -vars.state
		end
	elseif not(arm.ready) -- Attack cooldown
		cycle = -ST.ATKFLAG
	elseif vars.state == ST.RISE -- Rising
	or vars.state == ST.FALL -- Falling
		cycle = -vars.state
	end
	-- Attack regulation
	if not(canattack) --Unable to attack
		pressattack = false
		arm.attackstate = 0
		arm.attacktics = 0
	elseif arm.attackstate == 1 -- Attack startup
		if not(arm.attacktics)
			-- Launch attack
			releaseArmAttack(arm)
			dprint("Launched "..side.." arm")
		end
	elseif canattack --This arm can start an attack
		if (arm.armtype != ARM.SHIELD)
		and ((arm.armtype != ARM.LAUNCHER and pressattack) or (arm.armtype == ARM.LAUNCHER and (pressattack or holdattack)))
		and arm.ready --Make sure our cooldown is over first!
			dprint("Started arm attack on "..side.." side")
			startArmAttack(arm)
			pressattack = false
			holdattack = false
		else
			arm.ready = arm.attacktics == 0 and arm.paintics == 0  and not(special) --Restore from cooldown
		end
	end
	
	if arm.armtype == ARM.SHIELD --Shield "ready" regulation
		arm.ready = arm.shield and arm.shield.valid and not(arm.shield.flags & MF_NOCLIPTHING) and not(special)
	end
		
	--Do arm movements
	repositionArm(arm, side, cycle)
	return pressattack, holdattack
end

-- Arm Thinker (Visual)
addHook('MobjThinker', function(mo)
	if not(mo.owner and mo.owner.valid and mo.owner.health and mo.owner.eggchampionvars)
		P_RemoveMobj(mo)
		dprint("Removed egg champion arm")
		return
	elseif not(mo.target and mo.target.valid)
		mo.target = nil
	end
	local vars = mo.owner.eggchampionvars
	if mo.owner.player.skincolor != skins[mo.owner.skin].prefcolor
		mo.colorized = true
	else
		mo.colorized = false
	end
	--Reset flags for this frame
	mo.renderflags = $&~(RF_PAPERSPRITE|RF_FLOORSPRITE)
	mo.flags2 = $&~MF2_DONTDRAW
	if mo.owner.flags2 & MF2_DONTDRAW
		mo.flags2 = $|MF2_DONTDRAW
	end
	if not(mo.armtype == ARM.SWORD)
		mo.rollangle = 0
	end
	if mo.armtype == ARM.GLOVE --Boxing Glove
		if vars.activespecial == MODE.BOXER+1
			transformArm(mo, spikesprite)
			P_SpawnGhostMobj(mo)
		else
			transformArm(mo, glovesprite)
		end
		if mo.paintics & 1 and not(mo.owner.player.powers[pw_flashing])
			mo.flags2 = $|MF2_DONTDRAW
		end
	elseif mo.armtype == ARM.LAUNCHER --Rocket Launcher
		transformArm(mo, gunsprite)
	elseif mo.armtype == ARM.SWORD --Sword
		transformArm(mo, swordsprite)
		if mo.attackstate == 2
			mo.renderflags = $|RF_FLOORSPRITE
			mo.rollangle = $+swordrot
			mo.angle = mo.rollangle
			local ghost = P_SpawnGhostMobj(mo)
			ghost.renderflags = $|RF_FLOORSPRITE
			ghost.colorized = true
			ghost.color = P_RandomRange(1, FIRSTSUPERCOLOR-1)
			if leveltime & 1
				local thok = P_SpawnMobjFromMobj(mo, 0, 0, -mo.scale*40, MT_IVSP)
				thok.color = mo.owner.player.skincolor
				thok.colorized = true
				thok.scale = $<<1
				thok.destscale = $>>1
			end
		elseif mo.attackstate == 1
			mo.rollangle = $+swordrot
		elseif vars.state == ST.GUARD
			mo.rollangle = ANG30
		else
			mo.rollangle = $/2
			if vars.activespecial == MODE.KNIGHT + 1
				local ghost = P_SpawnGhostMobj(mo)
				ghost.renderflags = $|RF_FULLBRIGHT
				ghost.colorized = true
				ghost.color = SKINCOLOR_WHITE
				ghost.destscale = $<<1
			end
		end
	elseif mo.armtype == ARM.SHIELD --Shield
		transformArm(mo, shieldsprite)
		mo.renderflags = $|RF_PAPERSPRITE
		mo.angle = R_PointToAngle2(mo.owner.x, mo.owner.y, mo.x, mo.y) + ANGLE_90
		if not(mo.shield and mo.shield.valid) or (mo.shield.flags & MF_NOCLIPTHING and leveltime & 1)
			mo.flags2 = $|MF2_DONTDRAW
		end
	end
	if mo.attackstate == 1 --Attack startup effect
		local ghost = P_SpawnGhostMobj(mo)
		ghost.destscale = $<<1
		ghost.color = P_RandomRange(1,FIRSTSUPERCOLOR-1)
		ghost.colorized = true
		ghost.blend = AST_ADD
	end
	
	mo.colorized = mo.owner.colorized or $
	mo.color = mo.owner.color
	
	local drawchain = mo.armtype == ARM.GLOVE and not(mo.flags2&MF2_DONTDRAW)
	
	if not(drawchain)
		for n, part in pairs(mo.chain) do
			if not(part.valid) -- Replace missing parts
				part = spawnCoil(mo, n)
			end
			part.flags2 = $|MF2_DONTDRAW
		end
	else
		--Move chain along
		local x1 = mo.owner.x+mo.owner.momx
		local y1 = mo.owner.y+mo.owner.momy
		local z1 = mo.owner.z+mo.owner.height/2+mo.owner.momz
		local x2 = mo.x + mo.momx
		local y2 = mo.y + mo.momy
		local z2 = mo.z + mo.height/2 + mo.momz
		
		local thrustangle = mo.owner.player.drawangle
		local thrustdist = mo.owner.radius * 3/4
		if mo.side == "left"
			thrustangle = $+ANGLE_90
		elseif mo.side == "right"
			thrustangle = $-ANGLE_90
		end
		if vars.activespecial == MODE.BOXER+1 and vars.specials[MODE.BOXER+1]
			local n = mo.side == "left" and 2 or 1
			local follow = vars.specials[MODE.BOXER+1].parts[n]
			if follow and follow.valid
				thrustangle = R_PointToAngle2(mo.owner.x, mo.owner.y, follow.x, follow.y)
			end
		end
		x1 = $+P_ReturnThrustX(nil, thrustangle, thrustdist)
		y1 = $+P_ReturnThrustY(nil, thrustangle, thrustdist)
		
		local minstretchdist = mo.scale * 0
		local maxstretchdist = mo.scale * 512
		local Mm = maxstretchdist-minstretchdist
		local dist = R_PointToDist2(0, z1, R_PointToDist2(mo.x, mo.y, mo.owner.x, mo.owner.y), z2)
		local stretchamt = FixedDiv(dist - minstretchdist, Mm)
	-- 	local bendtilt = FixedAngle(B.FixedLerp(0, -90*FRACUNIT, min(FRACUNIT, stretchamt*2)))
		local bendtilt = -ANGLE_45
		local bendamt = max(FRACUNIT-stretchamt, 0)
		stretchamt = min(max($, 0), FRACUNIT)

		
		local cmax = B.FixedLerp(4, chainmax, stretchamt) -- Determine max number of segments to draw for this frame
		local l = cmax+1 --sequence lerp max
		local b = cmax/2 --center point on arm bend

		local color = mo.owner.color == skins[mo.owner.skin].prefcolor and SKINCOLOR_SILVER
			or mo.owner.color

		for n, part in pairs(mo.chain) do
			if not(part.valid) -- Replace missing parts
				part = spawnCoil(mo, n)
			end
			if n > cmax --Segment is higher than what we currently plan on drawing
				part.flags2 = $|MF2_DONTDRAW
				continue
			else
				part.flags2 = $&~MF2_DONTDRAW
			end

			part.color = color
			--Interpolate part distance across the chain
			local lerpamt = FRACUNIT*n/l
			local x = B.FixedLerp(x1, x2, lerpamt)
			local y = B.FixedLerp(y1, y2, lerpamt)
			local z = B.FixedLerp(z1, z2, lerpamt)
			--Add bend according to stretch amount
			local bend = bendamt*(#mo.chain-abs(n-b))/5
			bend = 32 * $//* FixedSqrt($)
			local xybend = P_ReturnThrustX(nil, bendtilt, bend)
			local zbend = P_ReturnThrustY(nil, bendtilt, bend)
			x = $ + P_ReturnThrustX(nil, thrustangle, xybend)
			y = $ + P_ReturnThrustY(nil, thrustangle, xybend)
			z = $ + zbend
			P_TeleportMove(part, x, y, z)
			--Interpolate angle
			local ang1 = AngleFixed(R_PointToAngle2(x1, y1, x, y))
			local ang2 = AngleFixed(R_PointToAngle2(x, y, x2, y2))
			if ang1-ang2 > 180*FRACUNIT
				ang2 = $ + 360*FRACUNIT
			elseif ang2-ang1 > 180*FRACUNIT
				ang1 = $ + 360*FRACUNIT
			end
			part.angle = FixedAngle(B.FixedLerp(ang1, ang2, lerpamt))+ANGLE_90
		end
	end
end, MT_EGGCHAMPION_ARM)

addHook('TouchSpecial', function(arm, pmo)
	if arm.armtype == ARM.SWORD --Retrieving the sword
		if pmo == arm.owner and not(arm.attacktics)
			arm.attackstate = 0
		end
-- 	elseif arm.armtype == ARM.SHIELD and arm.ready -- Shield blocks attacks
-- 		if pmo != arm.owner
-- 			P_InstaThrust(pmo, arm.owner.angle, arm.owner.scale * 12)
-- 			if pmo.player.battle_atk
-- 				arm.attacktics = 16
-- 				arm.ready = false
-- 				arm.owner.player.battle_atk = 0
-- 				arm.owner.player.battle_def = 3
-- 			end
-- 		end
	end
	return true
end, MT_EGGCHAMPION_ARM)

addHook('MobjRemoved', function(mo)
	if mo.chain
		for n, part in pairs(mo.chain) do
			if part.valid
				P_RemoveMobj(part)
			end
			part = nil
		end
	end
end, MT_EGGCHAMPION_ARM)

--Egg Champion Punch Hitbox
freeslot("MT_EGGCHAMPION_PUNCH")
mobjinfo[MT_EGGCHAMPION_PUNCH] = {
	spawnstate = S_INVISIBLE,
	--deathstate = S_XPLD1,
	speed = FRACUNIT*70,
	radius = 20*FRACUNIT,
	height = 40*FRACUNIT,
	damage = 1,
	flags = MF_NOBLOCKMAP|MF_MISSILE|MF_NOGRAVITY,
}
mobjinfo[MT_EGGCHAMPION_PUNCH].hit_sound = sfx_hit03
mobjinfo[MT_EGGCHAMPION_PUNCH].cantouchteam = true
mobjinfo[MT_EGGCHAMPION_PUNCH].blockable = 1
mobjinfo[MT_EGGCHAMPION_PUNCH].block_stun = 5
mobjinfo[MT_EGGCHAMPION_PUNCH].block_sound = sfx_s3kb5
mobjinfo[MT_EGGCHAMPION_PUNCH].block_hthrust = 10
mobjinfo[MT_EGGCHAMPION_PUNCH].block_vthrust = 2
mobjinfo[MT_EGGCHAMPION_PUNCH].spawnfire = true
mobjinfo[MT_EGGCHAMPION_PUNCH].allow_reflect = false

addHook("MobjSpawn",function(mo)
end,MT_EGGCHAMPION_PUNCH)

addHook('MobjThinker', function(mo)
	if not(mo.arm and mo.arm.valid)
		P_RemoveMobj(mo)
		return
	end
	mo.momx = $*9/10
	mo.momy = $*9/10
	mo.momz = $*9/10
end, MT_EGGCHAMPION_PUNCH)

local punchParryTrigger = function(mo)
	if mo.arm and mo.arm.valid
		dprint('Punch parry trigger')
		mo.arm.target = nil
		mo.arm.attackstate = 0
		mo.arm.paintics = suffertics
	end
	P_RemoveMobj(mo)
	return true
end
addHook("ShouldDamage", punchParryTrigger, MT_EGGCHAMPION_PUNCH)

-- Egg Champion Boxer Special hitbox
freeslot("MT_EGGCHAMPION_PUNCHSPECIAL")
mobjinfo[MT_EGGCHAMPION_PUNCHSPECIAL] = {
	spawnstate = S_INVISIBLE,
	--spawnstate = S_UNKNOWN,
	--deathstate = S_XPLD1,
	speed = FRACUNIT,
	radius = 20*FRACUNIT,
	height = 40*FRACUNIT,
	damage = 1,
	flags = MF_NOBLOCKMAP|MF_MISSILE|MF_NOGRAVITY,
}
mobjinfo[MT_EGGCHAMPION_PUNCHSPECIAL].hit_sound = sfx_hit03
mobjinfo[MT_EGGCHAMPION_PUNCHSPECIAL].allow_reflect = false

addHook("MobjSpawn",function(mo)
	if mo.valid
		mo.fuse = 2
		mo.momx = 1
	end
end,MT_EGGCHAMPION_PUNCHSPECIAL)
--addHook("ShouldDamage", punchParryTrigger, MT_EGGCHAMPION_PUNCHSPECIAL)


--Egg Champion Slicer Hitbox
freeslot("MT_EGGCHAMPION_SLICE")
mobjinfo[MT_EGGCHAMPION_SLICE] = {
	spawnstate = S_INVISIBLE,
	--deathstate = S_XPLD1,
	speed = FRACUNIT,
	radius = 48*FRACUNIT,
	height = 5*FRACUNIT,
	damage = 1,
	flags = MF_NOBLOCKMAP|MF_MISSILE|MF_NOGRAVITY,
}
mobjinfo[MT_EGGCHAMPION_SLICE].hit_sound = sfx_hit03
mobjinfo[MT_EGGCHAMPION_SLICE].allow_reflect = false
mobjinfo[MT_EGGCHAMPION_SLICE].pierce_guard = true

--Egg Champion Shield Hitbox
freeslot("MT_EGGCHAMPION_SHIELD")
mobjinfo[MT_EGGCHAMPION_SHIELD] = {
	radius = 60*FRACUNIT,
	height = 60*FRACUNIT,
	spawnstate = S_INVISIBLE,
	speed = 60*FRACUNIT,
	flags = MF_SOLID|MF_PUSHABLE|MF_NOGRAVITY|MF_NOCLIPHEIGHT|MF_NOCLIP|MF_SCENERY,
}
mobjinfo[MT_EGGCHAMPION_SHIELD].reflectarmor = 1

local isOurShield = function(mo,pmo)

	return mo.owner == pmo or mo.owner == pmo.target
end

local doCollision = function(mo, other)
	if not(mo.valid and other and other.valid and mo.owner and mo.owner.valid) return end
	local owner = mo.owner
	mo.target = mo.owner
	local x,y,z = mo.x + mo.momx, mo.y + mo.momy, mo.z + mo.momz
	local ret = not(isOurShield(mo, other)) and B.BashableCollision(mo, other)
	x = mo.x + mo.momx - $
	y = mo.y + mo.momy - $
	z = mo.z + mo.momz - $
	owner.momx = $+x
	owner.momy = $+y
	owner.momz = $+z
	return ret
end

addHook("MobjSpawn", function(mo)
	B.CreateBashable(mo,150,friction,smooth,true) --Sentience is true -- allows us to track damage dealt
end, MT_EGGCHAMPION_SHIELD)

addHook("MobjThinker",function(mo)
	local owner = mo.owner
	local arm = mo.arm
	--Despawn object if player object is missing, arm is missing, or arm is not in shield form
	if not(arm and arm.valid and owner and owner.valid)
	or arm.armtype != ARM.SHIELD
		P_RemoveMobj(mo)
		dprint("Removed shield. Conditions: "..tostring(arm and arm.valid)..", "..tostring(owner and owner.valid)..", "..tostring(arm and arm.valid and arm.armtype == ARM.SHIELD))
		return
	end
	--Update target -- should always refer to owner. No questions asked.
	mo.target = owner
	
	
	--Transfer coordinate distance into momentum. This allows use to register hits with other objects while our position stays up-to-date.
	local dx = arm.x-mo.x
	local dy = arm.y-mo.y
	local dz = arm.z-mo.z
-- 	P_TeleportMove(mo, arm.x, arm.y, arm.z)
	mo.momx = owner.momx + dx
	mo.momy = owner.momy + dy
	mo.momz = owner.momz + dz

	--Do standard bash think
	B.BashableThinker(mo)
	
	if mo.fuse or P_PlayerInPain(owner.player) or owner.player.powers[pw_flashing] or owner.player.powers[pw_invulnerability] or owner.player.powers[pw_super]
		mo.flags = $ | MF_NOCLIPTHING
	else
		mo.flags = $ &~ MF_NOCLIPTHING
	end
end, MT_EGGCHAMPION_SHIELD)

addHook("MobjFuse", function(mo)
	mo.pushed = nil
	mo.pushed_last = nil
	return true
end, MT_EGGCHAMPION_SHIELD)
-- addHook("MobjLineCollide", function(...)
-- 	return B.BashableLineCollide(...)
-- end, MT_EGGCHAMPION_SHIELD)

addHook("MobjCollide", function(...)
	return doCollision(...)
end, MT_EGGCHAMPION_SHIELD)

addHook("MobjMoveCollide", function(...)
	return doCollision(...)
end, MT_EGGCHAMPION_SHIELD)

addHook("TouchSpecial", function(...)
	return doCollision(...)
end, MT_EGGCHAMPION_SHIELD)

addHook("ShouldDamage", function(...)
	local mo = ... --First argument
	local ret = B.BashableShouldDamage(...)
	if mo.pain and mo.owner and mo.owner.valid and mo.owner.eggchampionvars
		dprint('Triggered shield damage')
		mo.flags = $|MF_NOCLIPTHING
		mo.fuse = shielddisabletime
		mo.owner.eggchampionvars.shieldhp = $-1
		mo.hitcounter = 0
		mo.pain = false
		mo.pushed = nil
		mo.pushed_last = nil
	end
	return 
end, MT_EGGCHAMPION_SHIELD)


-- *** Battle Specials 
local startSpecial = {}
local doSpecial = {}
local endSpecial = {}
-- Boxer Mode Special
local mode = MODE.BOXER+1
local rate = FRACUNIT/TICRATE/2
local length = 256
local minlength = 64
local cycles = 3
startSpecial[mode] = function(mo)
	local specials = mo.eggchampionvars.specials
	if not(specials[mode])
		specials[mode] = {parts = {}, amount = 0}
	end
end

endSpecial[mode] = function(mo)
	local specials = mo.eggchampionvars.specials
	if specials[mode].parts
		for n, e in pairs(specials[MODE.BOXER+1].parts) do
			if e and e.valid
				P_RemoveMobj(e)
			end
		end
		specials[mode].parts = nil
	end
	specials[mode] = nil
end

doSpecial[mode] = function(mo)
	local sp = mo.eggchampionvars.specials[mode]
	sp.amount = $ + rate --Ticking
	
	local amount = sp.amount
	
	if amount >= FRACUNIT --End of sequence
		endSpecial[mode](mo)
		return
	end
	
	for n = 1, 2 do
		-- Create parts if not already present
		if not(sp.parts[n] and sp.parts[n].valid)
			local part = P_SpawnMobjFromMobj(mo, 0, 0, 0, 1)
			sp.parts[n] = part
			sp.parts[n].flags2 = $|MF2_DONTDRAW
		end
		local part = sp.parts[n]
		
		-- Movement control
		local dist = FixedMul(mo.scale, sin(FixedAngle(amount*180))*(length-minlength) + minlength*FRACUNIT) -- Distance from center. Starts from center, swings outward, then swings back inward
		local angle = FixedAngle(cos(FixedAngle(amount*180))*cycles*180) -- Current angle. Circles around the center by the amount of times indicated by "cycles". Cos/2 applies smoothing to rotational movement.
		
		-- Angle offset
		if n == 1
			angle = mo.angle + ANGLE_90 + $
		else
			angle = mo.angle + ANGLE_270 + $
		end
		
		-- Get coordinates
		local x = mo.x + P_ReturnThrustX(nil, angle, dist)
		local y = mo.y + P_ReturnThrustY(nil, angle, dist)
		local z = mo.z + mo.height/3
		
		-- Do reposition
		P_TeleportMove(part, x, y, z)
	end
end

-- Tank Mode Special
local mode = MODE.TANK+1
local starttics = TICRATE*3/4
local refiretics = TICRATE/6
local refiremax = 5
local angleoffset = ANG10/2
local lift = 2
local liftoffset = 4

startSpecial[mode] = function(mo)
	local specials = mo.eggchampionvars.specials
	if not(specials[mode])
		specials[mode] = {tics = starttics, count = 0}
	end
end

endSpecial[mode] = function(mo)
	local specials = mo.eggchampionvars.specials
	if specials[mode].flashmo and specials[mode].flashmo.valid
		P_RemoveMobj(specials[mode].flashmo)
	end
	specials[mode] = nil
end

doSpecial[mode] = function(mo)
	local sp = mo.eggchampionvars.specials[mode]
	
	-- Do flashing
	if not(sp.flashmo and sp.flashmo.valid)
		sp.flashmo = P_SpawnMobjFromMobj(mo, 0, 0, 0, 1)
		sp.flashmo.sprite = SPR_ENRG
		sp.flashmo.scale = $>>1
	end
	local thrust = mo.radius
	local angle = mo.angle + ANGLE_180
	local x, y, z =
		mo.x + P_ReturnThrustX(nil, angle, thrust), 
		mo.y + P_ReturnThrustY(nil, angle, thrust), 
		mo.z + mo.height/3
	P_TeleportMove(sp.flashmo, x, y, z)
	sp.flashmo.flags2 = $ ^^ MF2_DONTDRAW
	
	-- Do ticking
	sp.tics = $-1
	
	-- Do firing
	if sp.tics <= 0
		sp.count = $ + 1
		for n = 0, 1 do
			-- Create missile
			local msl = P_SpawnMobjFromMobj(mo, 0, 0, 0, MT_FBOMB)
			if msl and msl.valid
				msl.target = mo
				-- Set missile speed and direction
				local thrust = FixedMul(mo.scale, msl.info.speed)
				local angle = mo.angle
				if n & 1
					angle = $ + angleoffset * (refiremax - sp.count + 1)
				else
					angle = $ - angleoffset * (refiremax - sp.count + 1)
				end
				local zthrust = FRACUNIT * (sp.count * lift + liftoffset)
				P_InstaThrust(msl, angle, thrust)
				P_SetObjectMomZ(msl, zthrust, false)
			end
		end
		if sp.count >= refiremax -- End of firing sequence
			endSpecial[mode](mo)
		else
			sp.tics = refiretics -- Time until next attack
		end
	end
end

-- Knight Mode Special
local mode = MODE.KNIGHT+1
local raisetics = TICRATE
freeslot("MT_EGGCHAMPION_LIGHTNING_TRAVEL")
mobjinfo[MT_EGGCHAMPION_LIGHTNING_TRAVEL] = {
	spawnstate = S_INVISIBLE,
--	spawnstate = S_UNKNOWN,
	radius = FRACUNIT,
	height = FRACUNIT,
	speed = FRACUNIT*36,
	reactiontime = 3,
	painchance = 512,
	flags = MF_NOCLIPTHING|MF_NOBLOCKMAP|MF_NOGRAVITY|MF_BOUNCE|MF_SCENERY
}

freeslot("MT_EGGCHAMPION_LIGHTNING_MARKER", "SPR_LSPL", "S_EGGCHAMPION_LIGHTNING_MARKER")
mobjinfo[MT_EGGCHAMPION_LIGHTNING_MARKER] = {
--	spawnstate = S_INVISIBLE,
	spawnstate = S_EGGCHAMPION_LIGHTNING_MARKER,
	radius = FRACUNIT*64,
	height = FRACUNIT,
	speed = 0,
	reactiontime = TICRATE,
	flags = MF_NOCLIPTHING|MF_NOGRAVITY|MF_NOCLIPHEIGHT|MF_NOCLIP|MF_SCENERY
}
states[S_EGGCHAMPION_LIGHTNING_MARKER] = {
	sprite = SPR_LSPL,
	tics = -1,
	nextstate = S_EGGCHAMPION_LIGHTNING_MARKER
}

startSpecial[mode] = function(mo)
	mo.eggchampionvars.specials[mode] = {tics = raisetics}
	local l = P_SpawnMobjFromMobj(mo, 0, 0, 0, MT_EGGCHAMPION_LIGHTNING_TRAVEL)
	l.target = mo
	l.fuse = TICRATE*2
	l.reactiontime = FixedDiv(l.info.reactiontime*10, l.info.speed)
	P_InstaThrust(l, mo.angle, FixedMul(mo.scale, l.info.speed))
end

endSpecial[mode] = function(mo)
	mo.eggchampionvars.specials[mode] = nil
end

doSpecial[mode] = function(mo)
	mo.eggchampionvars.specials[mode].tics = $-1
	if mo.eggchampionvars.specials[mode].tics <= 0
		endSpecial[mode](mo)
	end
end

-- Kn: Travel thinker
addHook("MobjThinker", function(mo)
	mo.angle = R_PointToAngle2(0, 0, mo.momx, mo.momy)
	P_InstaThrust(mo, mo.angle, FixedMul(mo.scale, mo.info.speed))
	mo.reactiontime = $-1
	if mo.reactiontime <= 0
		mo.reactiontime = mo.info.reactiontime
		local angle, thrust, x, y
		angle = FixedAngle(P_RandomRange(0, 359)*FRACUNIT)
		thrust = P_RandomRange(0, mo.info.painchance) * mo.scale
		x = P_ReturnThrustX(nil, angle, thrust)
		y = P_ReturnThrustY(nil, angle, thrust)
		if not(R_PointInSubsectorOrNil(mo.x+x, mo.y+y))
			return
		end
		local l = P_SpawnMobjFromMobj(mo, x, y, 0, MT_EGGCHAMPION_LIGHTNING_MARKER)
		l.target = mo.target
		l.reactiontime = l.info.reactiontime
		if P_MobjFlip(mo) == 1
			l.z = l.floorz
		else
			l.z = l.ceilingz-l.height
		end
	end
end, MT_EGGCHAMPION_LIGHTNING_TRAVEL)

-- Kn: Lightning strike
local strikeheight = 640
local lightningStrike = function(mo)
	local ghost = P_SpawnGhostMobj(mo)
	ghost.sprite = SPR_ENRG
	P_StartQuake(FRACUNIT*2, 1)

	local range = mo.radius
	searchBlockmap('objects',function(mo,found)
		if (found.flags & (MF_ENEMY|MF_BOSS) or found.player)
		and found.z + found.height >= mo.floorz
		and found.z < min(mo.ceilingz, strikeheight*mo.scale + mo.floorz)
		--and not(mo.target and mo.target.valid and B.MyTeam(mo.target, found))
			P_DamageMobj(found, mo, mo.target)
		end
	end,mo,mo.x-range,mo.x+range,mo.y-range,mo.y+range)
end

-- Kn: Marker thinker
addHook("MobjSpawn", function(mo)
	mo.renderflags = RF_FULLBRIGHT|RF_FLOORSPRITE|RF_SHADOWDRAW
	mo.flags2 = $|MF2_SHADOW
end, MT_EGGCHAMPION_LIGHTNING_MARKER)
addHook("MobjThinker", function(mo)
	mo.flags2 = $ ^^ MF2_DONTDRAW
	mo.reactiontime = $-1
	if mo.reactiontime > 0 and mo.reactiontime % 4 == 0 -- Warning splat overlay
		local ghost = P_SpawnGhostMobj(mo)
		ghost.scale = mo.scale>>1
		ghost.destscale = $<<1
		ghost.z = min(mo.ceilingz-1, mo.floorz + mo.scale*strikeheight)
		ghost.renderflags = RF_FULLBRIGHT|RF_FLOORSPRITE|RF_SHADOWDRAW
		ghost.flags2 = $|MF2_SHADOW
		if mo.reactiontime < TICRATE
			local ghost = P_SpawnGhostMobj(mo)
			ghost.scale = mo.scale>>1
			ghost.destscale = $<<1
		end
	end
	if mo.reactiontime <= 0 -- Strike effects
		local ghost = P_SpawnGhostMobj(mo)
		ghost.destscale = $<<1
		CBW_Battle.DoLightning(mo, 3)
	end
	if mo.reactiontime == 0
		lightningStrike(mo)
	elseif mo.reactiontime == -10
		P_RemoveMobj(mo)
	end
end, MT_EGGCHAMPION_LIGHTNING_MARKER)


-- Special table remover
local removeSpecials = function(mo)
	for n, sp in pairs(mo.eggchampionvars.specials) do
		if sp
			endSpecial[n](mo)
		end
	end
end

-- Specials master controller
local regulateSpecials = function(mo, doaction)
	local vars = mo.eggchampionvars
	local player = mo.player
	local ret = false
	if P_PlayerInPain(player) or not(mo.health) or player.powers[pw_nocontrol]
		if vars.activespecial
			removeSpecials(mo)
			return ret
		end
	end
	if not(vars.activespecial) and doaction
		for n,arm in pairs(vars.arms) do
			if arm.attackstate != 0
				doaction = false
				return false --!!!debug
			end
		end
		local n = vars.mode+1
		startSpecial[n](mo)
		if vars.specials[n]
			vars.activespecial = n
		end
	end
	-- Keep track of our active special, even if current mode has changed
	if vars.specials[vars.activespecial]
		doSpecial[vars.activespecial](mo)
	elseif vars.activespecial
		vars.activespecial = 0
	end
end

-- Initialize Egg Champion table
local initEggChampion = function(mo)
	mo.eggchampionvars = {
		mode = 0,
		arms = {},
		tics = 0,
		cycle = 0,
		state = 0,
		shieldhp = shieldmax,
		activespecial = 0,
		specials = {},
	}
	dprint("Initialized egg champion table data")
end

local removeEggChampion = function(mo)
	if not(mo.eggchampionvars) return end
	for n, arm in pairs(mo.eggchampionvars.arms) do
		if (arm.valid) 
			P_RemoveMobj(arm) --Chain will be dealt with by the MobjRemoved hook
		end
		arm = nil
	end
	removeSpecials(mo)
	mo.eggchampionvars = nil
	dprint("Cleared EggChampion objects and table data")
end

-- Egg Champion main controller
addHook('PlayerThink',function(player)
	if not(player.mo and player.mo.health)
	--or P_PlayerInPain(player)
		return
	end
	local mo = player.mo
	--Manage EggChampion table data
	if mo.skin != 'eggman'
		if type(mo.eggchampionvars) == "table"
			removeEggChampion(mo)
		end
		return --Do not run EggChampion code for non-eggman players
	elseif type(mo.eggchampionvars) != "table"
		initEggChampion(mo)
	end

	local vars = mo.eggchampionvars
	vars.cycle = $+1

	-- Attack frame regulation. <7 == left punch, >7 == right punch
	if mo.state == S_PLAY_FIRE and (mo.frame&FF_FRAMEMASK == 7 or mo.frame & FF_FRAMEMASK == 15)
		mo.state = S_PLAY_WALK
	end

	-- Change mode (!! input tentative; TODO: swap animation)
	if B.CanDoAction(player)
	and B.PlayerButtonPressed(mo.player,BT_CUSTOM1,false)
	and not(vars.activespecial)
		vars.mode = ($+1) % 3
	end

	-- Regulate Battle special moves
-- 	regulateSpecials(mo, B.PlayerButtonPressed(player,BT_ATTACK,false))
	regulateSpecials(mo, player.actionstate == 1)

	local forceangle = false
	
	-- Egg Champion state regulation
	
	vars.state = 0
	if P_PlayerInPain(player)
		vars.state = ST.PAIN
	elseif player.guard > 1
		vars.state = ST.PARRY
	elseif player.guard
		vars.state = ST.GUARD
	elseif not(P_IsObjectOnGround(mo) or player.pflags & (PF_THOKKED|PF_JUMPED))
		vars.state = ST.EXPOSED
		if not(player.powers[pw_nocontrol])
			player.pflags = $|PF_JUMPED
		end
	else
		local attackstate = 0
		if vars.mode != MODE.TANK
			for n,arm in pairs(vars.arms) do
				if not(arm.valid) continue end
				attackstate = arm.attackstate or $
			end
		else
			for n,arm in pairs(vars.arms) do
				if not(arm.valid) continue end
				if arm.attackstate == 1
					attackstate = $ or 1
				else
					attackstate = arm.ready == false and 2 or $
				end
			end
		end
		if(attackstate == 1)
			vars.state = ST.ATKSTART
		elseif(attackstate == 2)
			vars.state = ST.ATKRELEASE
		elseif player.pflags & (PF_JUMPED|PF_THOKKED) == PF_JUMPED and mo.momz * P_MobjFlip(mo) > 0
			vars.state = ST.RISE
		elseif not(P_IsObjectOnGround(mo))
			vars.state = ST.FALL
		end

		forceangle = (attackstate == 2) or $
	end
	
	if forceangle
		player.drawangle = mo.angle
	end
	
	-- Arm regulation
	local pressattack = not(player.weapondelay) and B.PlayerButtonPressed(mo.player,BT_SPIN,false)
	local holdattack = not(player.weapondelay) and B.PlayerButtonPressed(mo.player,BT_SPIN,true)
	pressattack, holdattack = regulateChampionArm(mo, "left", pressattack, holdattack) --Returns false if we just attacked with this arm
	regulateChampionArm(mo, "right", pressattack, holdattack)
end)

-- Egg Champion overrides SpinSpecial routines
addHook('SpinSpecial',function(player)
	if player.mo.eggchampionvars != nil
		return true
	end
end)

-- Jump ability
addHook('AbilitySpecial', function(player)
	if player.mo.eggchampionvars != nil and player.pflags & PF_SHIELDABILITY == 0
		player.pflags = $ | PF_THOKKED
		return true
	end
end)
addHook('JumpSpecial', function(player)
	if player.mo.eggchampionvars != nil and player.pflags & (PF_THOKKED|PF_SHIELDABILITY) == PF_THOKKED
		local jumpfactor = FixedMul(player.jumpfactor, player.mo.scale*39/4)
		P_SetObjectMomZ(player.mo, gravity * 2, true)
		player.mo.momz = min(max(FixedMul($, player.mo.friction), -jumpfactor), jumpfactor)
		return true
	end
end)

-- Pain control
-- B.EggChampionPain = function(target, inflictor, source, damage, damagetype)
-- 	local vars = target.eggchampionvars
-- 	if vars and vars.arms.left and vars.arms.left.valid
-- 	and vars.arms.left.
-- end

-- Battle Action controller
B.Action.EggChampion = function(mo, doaction)
	local player = mo.player
	local vars = mo.eggchampionvars
	if not vars 
		return
	end
	player.actiontext = "Special"
	player.actionrings = 10
	if vars.activespecial
		player.actionstate = 1
	else
		player.actionstate = 0
	end
	if not B.CanDoAction(player)
		return
	end
	if doaction == 1 and not vars.activespecial
		B.PayRings(player)
		regulateSpecials(mo, doaction)
		B.ApplyCooldown(player,TICRATE*4)
	end
end