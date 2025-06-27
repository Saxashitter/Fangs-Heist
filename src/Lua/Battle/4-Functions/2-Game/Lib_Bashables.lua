local B = CBW_Battle
local CV = B.Console

--Tic function
B.BashableThinker = function(mo)
	--Gate
	if not(mo and mo.valid) then return end
	if not(mo.battleobject) then return end
	if mo.hitstun_tics
		mo.hitstun_tics = max(0, $-1)
		if mo.hitstun_restoreflags == nil
			mo.hitstun_restoreflags = mo.flags
		end
		mo.flags = $|MF_SCENERY|MF_NOGRAVITY
		if mo.hitstun_tics
			mo.spritexoffset = P_RandomRange(8, -8) * FRACUNIT
			mo.spriteyoffset = P_RandomRange(2, 2) * FRACUNIT
		else
			mo.spritexoffset = 0
			mo.spriteyoffset = 0
			mo.flags = mo.hitstun_restoreflags
			mo.hitstun_restoreflags = nil
		end
		return true -- Pause thinker
	end
	-- Regulate flashing
	if mo.pain_tics then
		mo.pain_tics = $-1
		if mo.pain_tics&1 then 
			mo.flags2 = $|MF2_DONTDRAW
		else
			mo.flags2 = $&~MF2_DONTDRAW
		end
	end
	
	--Correct our target to reflect "owner"
	if (mo.target) and not(mo.target.player) then --Bashables should only have player objects as their target.
		--Pushables will set other pushables as their target on collision, and this can cause problems
		if mo.target.target and mo.target.target.player then --But, if our target's target is a player object, due to a chain reaction...
			mo.target = mo.target.target --...Then we may as well borrow that target, so players receive proper credit for chain reactions
		else --Otherwise, we'll just clear our target value
			mo.target = nil
		end
	end
	--Do physics
	local trueweight = FixedMul(mo.weight,mo.scale) --Weight must reflect object scale
	local speed = FixedHypot(mo.momx,mo.momy) --Get current movement speed
	local threshold = trueweight*6 --Speed necessary before the object's velocity is considered "threatening"
	
	--Bounce physics
	if mo.bouncefactor
		if P_IsObjectOnGround(mo) and abs(mo.extravalue2) > FixedMul(mo.scale<<2, gravity)
			mo.momz = FixedMul(-mo.extravalue2, mo.bouncefactor)
		end
		mo.extravalue2 = mo.momz
	end
	
	--Ball physics
	if mo.smooth then
		mo.friction = mo.momentum --Friction reflects "push momentum" at all times
		--Slope physics
		if (mo.standingslope)
			then
			local slope = mo.standingslope
			local m = FixedDiv(slope.zdelta,trueweight)
			P_Thrust(mo,slope.xydirection,m)
		end
	end
	if mo.pushed_last and not(mo.battle_atk) then
		mo.pushtics = $+1
	end
	--Object is moving at high speeds
	if speed/*+abs(mo.momz)*/ > threshold and(not(mo.sentient) or mo.pushed_last) then
		--Object can deal damage to other players
		mo.battle_atk = 1
		mo.friction = mo.momentum
		--Spawn thok mobj
		local t = P_SpawnMobj(mo.x,mo.y,mo.z,MT_THOK)
		if not(mo.target and mo.target.player) then
			t.color = SKINCOLOR_GREY
		else
			t.color = mo.target.player.skincolor
		end
		t.flags2 = $|MF2_SHADOW
		t.scale = FixedMul(FixedDiv(mo.height,t.height)*3/2,mo.scale) --Rescale to match object height
		--Object rotation is a visual indicator of movespeed
		mo.angle = $+FixedMul(speed,trueweight)/FRACUNIT*ANG1
		mo.pushtics = $+speed/FRACUNIT
		--Sliding FX
		if not(mo.smooth) and P_IsObjectOnGround(mo) and mo.pushtics >= 32
			mo.pushtics = 0
			S_StartSound(mo,sfx_s3k47)
			--Do dust particles
			local r = function()
				local w = mo.radius/FRACUNIT
				return P_RandomRange(-w,w)*FRACUNIT
			end
			P_SpawnMobj(mo.x+r(),mo.y+r(),mo.z,MT_DUST)
		end
	elseif P_IsObjectOnGround(mo) or mo.pushtics > 15 --Object is idle or not moving quickly. Keep our slate clean
		mo.pushed = nil
		mo.pushed_last = nil
		if not(mo.sentient) then
			mo.target = nil
		end
		mo.pushtics = 0
		mo.battle_atk = 0
		mo.flags = mo.info.flags
		mo.pain = false
	end
end

--Collision function
B.BashableCollision = function(mo, other)
	if not(mo.valid and other and other.valid)
	or not(mo.battleobject and B.CheckHeightCollision(mo,other))
	return end	
	B.DebugPrint("BashableCollision event between object types "..mo.type.." and "..other.type,DF_COLLISION)
	if mo.pain_tics or other.pain_tics then 
		B.DebugPrint("Denied via pain_tics",DF_COLLISION)
	return end
	--Gate to avoid multiple collisions
	if other.pushed_last == mo --and not(other.player) then
		B.DebugPrint("Denied via pushed_last",DF_COLLISION)
	return false end
	--For badniks
	if other.valid and other.health and other.flags&(MF_ENEMY|MF_BOSS)
		and mo.battle_atk --Attack state set by player collision
		then
		P_DamageMobj(other,mo,mo.target) --SMASH
		mo.hitstun_tics = max($, 3)

		B.DebugPrint("Badnik collision executed. End function",DF_COLLISION)
	return end
	if --(mo.sentient and not(other.target == mo)--Check for sentient
		((other.flags&MF_MISSILE and other.target != mo) or other.attacking or (other.battleobject and other.battle_atk)) --Projectiles; Tails' Sentry; bashables
	or (mo.flags&MF_SOLID and other.battleobject and(other.battle_atk or mo.battle_atk)) --Solids collision
		mo.pushed = other
		other.pushed = mo
		local momx, momy, momz = 
			other.momx, other.momy, other.momz
		if not(other.battleobject) then -- Sentient versus projectile or other
			other.battle_atk = 2
			other.battle_def = 1
		else --Two bashables colliding
			--Increase thrust to give collisions 
			local spd = FixedHypot(other.momx,other.momy)*101/100
-- 			local dir = R_PointToAngle2(0,0,other.momx,other.momy)
			local dir = R_PointToAngle2(other.x,other.y,mo.x,mo.y)
			P_InstaThrust(other,dir,min(80*other.scale,spd))
			other.momz = $*2
			local spd = FixedHypot(mo.momx,mo.momy)*101/100
-- 			local dir = R_PointToAngle2(0,0,mo.momx,mo.momy)
			local dir = R_PointToAngle2(mo.x,mo.y,other.x,other.y)
			P_InstaThrust(mo,dir,min(80*mo.scale,spd))
			mo.momz = $*2
			other.battle_atk = 1
			mo.battle_atk = 1
			--Share owners
			if mo.target and not(other.target) then other.target = mo.target end
			if other.target and not(mo.target) then mo.target = other.target end
			--Add bounce, remove pushable so collision functions properly
			mo.flags = ($|MF_BOUNCE&~MF_PUSHABLE)
			other.flags = ($|MF_BOUNCE&~MF_PUSHABLE)
		end
		--Reduce missile thrust to diminish knockback
		if other.flags&MF_MISSILE
			local spd = FixedHypot(other.momx,other.momy)
			local dir = R_PointToAngle2(0,0,other.momx,other.momy)
			P_InstaThrust(other,dir,spd)
			other.momz = $/2
			P_InstaThrust(mo,dir,FixedDiv(other.scale*4,mo.weight))
			mo.flags = $|MF_BOUNCE
			if other.target then
				mo.target = other.target
			end
		end
		--Execute the rest
		B.DoPlayerInteract(mo,other)
		--Missile ded
		if other.flags&MF_MISSILE then
			if mo.info.reflectarmor and other.info.allow_reflect != false
			and (not other.reflectcount or other.reflectcount < mo.info.reflectarmor)
				other.momx, other.momy, other.momz =
					momx, momy, momz
				B.ReflectProjectile(mo, other)
			else
				P_KillMobj(other)
			end
			B.DebugPrint("Missile collision executed. End function",DF_COLLISION)
			
			return
			
		end
	end
	
	--Gate for player collisions
    if not(other.player and other.valid)
	or (other.player.spectator)
	or (other.player.exiting)
	or (other.player.battlespawning)
	or B.PreRoundWait()
			B.DebugPrint("Not a player collision. End function",DF_COLLISION)
	return end

    --Height check
	if (other.z >= (mo.z + mo.height))
	or ((other.z + P_GetPlayerHeight(other.player)) < mo.z)
		B.DebugPrint("Denied via height check",DF_COLLISION)
		return
    end
	--Gate for pushing solids
	if not(mo.battle_atk) and (mo.flags&MF_SOLID and not(other.player.battle_atk)) then
		mo.flags = mo.info.flags
		B.DebugPrint("Denied (pushing solids)",DF_COLLISION)
	return end
	
	--Register "pushed"
	mo.pushed = other
	other.pushed = mo

	--Gate to avoid multiple collisions
-- 	if other.pushed_last == mo then
-- 	return end

	--Assign an "owner"
	if mo.battle_atk <= other.player.battle_atk-- and (other.player.battle_atk or not(mo.flags&MF_SOLID))
		mo.target = other
		mo.pushed_last = nil
	end
	--Set new flags for collision
	mo.flags = $|MF_BOUNCE
	mo.pushtics = 0
	B.DebugPrint("Executing DoPlayerInteract from Bashable",DF_COLLISION)
	B.DoPlayerInteract(other,mo)
-- 	--Do history
	mo.pushed = nil
	mo.pushed_last = other
	other.pushed = nil
	B.DebugPrint("Player collision executed. End function",DF_COLLISION)
	return true
end

--Spawn hook function
B.CreateBashable = function(mo,weight,friction,smooth,sentient,bounce)
	--Args
	--mo: object to modify
	--weight: Resistance to knockback (in "percent"). 100 is standard. Must be positive.
	--friction: Factor to slow object when sliding from knockback, overrides normal friction. 0 is none, 3-4 is approx normal friction.
	--smooth: Object rolls downhill. "Friction" factor always takes effect.
	--sentient: Intended for use with objects that are designed to act more like enemies
	--bounce: Vertical bounce amount (in "percent")
	
	--Set defaults and failsafes
	if weight == nil or weight <= 0 then weight = 80 end 
	if friction == nil or friction < 0 then friction = 2 end 
	if smooth == nil then smooth = false end
	if sentient == nil then sentient = false end
	if bounce == nil then bounce = 0 end
	--Apply values
	mo.battleobject = 1
	mo.weight = weight*FRACUNIT/100
	mo.momentum = (100-friction)*FRACUNIT/100
	mo.smooth = smooth
	mo.bouncefactor = bounce*FRACUNIT/100
	mo.battle_atk = 0
	mo.battle_def = 0
	mo.pushtics = 0
	mo.hitcounter = 0
	mo.sentient = sentient
	mo.pain = false
	mo.pain_tics = 0
	mo.hitstun_tics = 0
	if not(mo.shadowscale) then
		mo.shadowscale = FRACUNIT
	end
	if not(mo.flags&(MF_ENEMY|MF_BOSS))
		mo.flags2 = $|MF2_INVERTAIMABLE
	end
end

--Should damage
B.BashableShouldDamage = function(mo,other,source)
	if not(mo and mo.valid and mo.battleobject and mo.sentient) then return end
	if mo.pain_tics then return false end
	mo.pain = true
	if source and source.valid and source.player then
		P_AddPlayerScore(source.player,50)
		mo.hitcounter = $+1
		if mo == B.TrainingDummy then
			B.HitCounter = $+1
		end
		if mo.health != 1000 then
			S_StartSound(mo,sfx_s1ac)
		end
		mo.pain_tics = 15
	end
	mo.hitstun_tics = max($, 10)
	return false
end

--Line collide hook function
B.BashableLineCollide = function(mo,line)
	if mo.battleobject and line.flags&ML_BLOCKMONSTERS return true end
end