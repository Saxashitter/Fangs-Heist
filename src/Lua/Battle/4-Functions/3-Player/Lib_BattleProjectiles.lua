local B = CBW_Battle
local CV = B.Console

B.BattleMissileThinker = function(mo)
	if not (mo and mo.valid and mo.flags & MF_MISSILE and mo.health) return end
	return B.ReflectedProjectileThinker(mo)
	or B.UnderwaterMissile(mo)
	or B.TwoDMissile(mo)
end

B.ReflectedProjectileThinker = function(mo)
	if mo.hitstun_tics
		mo.hitstun_tics = $ - 1
		-- Do visual shake
		if mo.hitstun_tics
			mo.spritexoffset = P_RandomRange(16, -16) * FRACUNIT
			mo.spriteyoffset = P_RandomRange(16, -16) * FRACUNIT
		else
			mo.spritexoffset = 0
			mo.spriteyoffset = 0
		end
		return true -- Pause thinker
	end
	if mo.reflectcount
		-- Do visual sparkle
		local mt = mo.reflectcount > 1 and MT_SUPERSPARK
			or MT_BOXSPARKLE
		local fx = P_SpawnMobjFromMobj(mo, 0, 0, mo.height/2, mt)
		fx.momx = P_RandomRange(-1, 1) * fx.scale
		fx.momy = P_RandomRange(-1, 1) * fx.scale
		fx.momz = P_RandomRange(-1, 1) * fx.scale
		fx.fuse = 5
		if mo.target and mo.target.valid and mo.target.player
			fx.colorized = true
			fx.color = mo.target.player.skincolor
		end
	end
end

B.ReflectProjectile = function(pmo, missile)
	local source = missile.target
	-- Do status
	missile.target = pmo
	missile.reflectcount = $ and $+1 or 1
	missile.hitstun_tics = 7
	pmo.hitstun_tics = max($, 3)

	 -- Do redirection
	local angle, zangle, zdist
	if source and source.valid
		angle = R_PointToAngle2(pmo.x, pmo.y, source.x, source.y)
		zdist = source.z + source.height/2 - (pmo.z + pmo.height/2)
	else
		angle = R_PointToAngle2(pmo.x, pmo.y, missile.x, missile.y)
		zdist = missile.z + missile.height/2 - (pmo.z + pmo.height/2)
	end

	zangle = R_PointToAngle2(0, 0, angle, -zdist)

	local xyspeed = R_PointToDist2(0, 0, missile.momx, missile.momy)
	local zspeed = missile.momz
	local speed = R_PointToDist2(0, 0, xyspeed, zspeed)* 7/6
	missile.momz = P_ReturnThrustY(nil, zangle, speed)
	P_InstaThrust(missile, angle, abs(P_ReturnThrustX(nil, zangle, speed)))

	-- Effects
	S_StartSound(pmo, sfx_s1c9)
	for n = 1, 4 do
		local fx = P_SpawnMobjFromMobj(missile, 0, 0, missile.height/2,  n & 1 and MT_BOXSPARKLE or MT_SUPERSPARK)
		fx.momx = P_RandomRange(-10, 10) * fx.scale
		fx.momy = P_RandomRange(-10, 10) * fx.scale
		fx.momz = P_RandomRange(-10, 10) * fx.scale
	end
	if TD_ShieldBlock and pmo.player and pmo.player.dollshield and pmo.player.dollshield.valid
		TD_ShieldBlock(pmo)
	end
	
	P_TeleportMove(missile, missile.x + missile.momx, missile.y + missile.momy, missile.z + missile.momz)
end

B.DoMissilePierce = function(pmo, missile)
	S_StartSound(pmo, sfx_shattr)
	B.ZLaunch(pmo, FRACUNIT*15)
	pmo.player.powers[pw_flashing] = max($, 25)
	B.DoPlayerTumble(pmo.player, TICRATE*3, R_PointToAngle2(missile.x, missile.y, pmo.x, pmo.y), FRACUNIT*2, true)
	missile.momx = 0
	missile.momy = 0
	missile.momz = 0
	A_Scream(missile)
	missile.flags = $&~MF_MISSILE
	missile.state = missile.info.deathstate
end

B.PlayerVSProjectileCollide = function(pmo, missile)
	if not(missile and missile.valid and missile.flags&MF_MISSILE -- Not a valid missile
	and pmo and pmo.valid and pmo.player and pmo.player.valid) -- Not a valid player
	or pmo.z > missile.z + missile.height -- Height check 1
	or missile.z > pmo.z + pmo.height -- Height check 2
		return
	end
	
	missile.reflectcount = $ or 0
	-- Player is intangible
	if pmo.player.intangible
		return false
	end

	-- Enemy projectile: Player has reflection armor or is guarding
	if not(missile.target and missile.target.player and B.MyTeam(missile.target.player, pmo.player))
		if pmo.player.guard == 1
			if B.GuardTrigger(pmo, missile, missile.target, 1, 0)
				return false
			end
		elseif pmo.player.reflectarmor and missile.info.allow_reflect != false
			if pmo.player.reflectarmor > missile.reflectcount
				B.ReflectProjectile(pmo, missile)
			else
				-- Armor broke! Send player into a long tumble
				B.DoMissilePierce(pmo, missile)
			end
			if missile.valid -- Missile may have been destroyed in the process of reflect/piercing
				pmo.player.reflectarmor = $-missile.reflectcount
			end
			return false
		end
	end

	-- Disallow certain projectiles from interacting with allies
	if missile.target and missile.target.valid
	and missile.target.player and missile.target.player.valid
	and B.MyTeam(missile.target.player,pmo.player)
	and not missile.info.cantouchteam
		return false
	end
end

B.TeamFireTrail = function(mo)
	mo.fuse = min($, TICRATE * 4)
	if not(G_GametypeHasTeams() and mo.target and mo.target.valid and mo.target.player) then return end
	if not(mo.ctfteam) then
		local player = mo.target.player
		mo.ctfteam = player.ctfteam
-- 		mo.color = player.skincolor
-- 		mo.state = S_TEAMFIRE1
	end
end

local spawnheart = function(mo, launchang, anglemod, grow, zspd)
	local range = 3
	local x = mo.x + P_RandomRange(-range,range)*mo.scale
	local y = mo.y + P_RandomRange(-range,range)*mo.scale
	local z = mo.z
	if P_MobjFlip(mo) == -1
		z = $ + mo.height
	end
	local momz = P_RandomRange(zspd + 0, zspd + 2)*FRACUNIT
	local hfriction = P_RandomRange(80,90)
	local hrt = P_SpawnXYZMissile(mo.target, mo, MT_PIKOWAVEHEART, x,y,z)
	if hrt and hrt.valid
		hrt.friction = hfriction //Horz friction
		hrt.momz = momz * P_MobjFlip(mo)
		
		local thrust = hrt.scale*2
		local angle = FixedAngle(P_RandomRange(0,359)<<FRACBITS)
		P_InstaThrust(hrt,angle,thrust)
		
		local thrust2 = mo.scale * 13
		P_Thrust(hrt,launchang + anglemod,thrust2)
		hrt.scale = mo.scale / 2
		hrt.fuse = 29
		hrt.grow = grow
		
		if (mo.time%4) and mo.color
			hrt.state = S_PIKOWAVE3
			hrt.color = mo.teamcolor
		end
		
		return true
	end
	
	return false
end

B.PikoWaveThinker = function(mo)
	if not(mo.target and mo.target.valid)
		P_RemoveMobj(mo)
		return
	end
	if mo.state != S_PIKOWAVE1
		mo.momx = 0
		mo.momy = 0
		mo.momz = 0
		return
	end
	
	if mo.time == nil
		mo.time = 1
	end
	mo.time = $+1
	
	local launchang = R_PointToAngle2(0,0,mo.momx,mo.momy)
	
	//Spawn projectiles
	if not(mo.time%3)
		S_StartSound(mo,sfx_hoop2)
		spawnheart(mo, launchang, 0, true, 9)
	else
		spawnheart(mo, launchang, -ANG30, false, 7)
		spawnheart(mo, launchang, ANG30, false, 7)
	end
	
	//Speeds up over time
	local friction = 103
	mo.momx = $*friction/100
	mo.momy = $*friction/100
	
	mo.angle = $ + ANG10
end

B.ShouldDamage_PlayerVSHeart = function(mo,heart,owner)
	//Relegate this hook to interactions with players and heart projectiles
	if not(mo and mo.valid) then return end
	if not(mo.player) then return end
	if not(heart and heart.valid and (heart.type == MT_LHRT or heart.type == MT_PIKOWAVEHEART)) then return end
	if not(heart.flags&MF_MISSILE) then return end //heart is dead
	if not(owner and owner.type == MT_PLAYER) then return end
	if mo.player.pflags&PF_TAGIT and not(owner.player.pflags&PF_TAGIT) then return false end
	
	local friendly = B.MyTeam(mo.player,owner.player)
	if friendly and not B.SuddenDeath
		//Do pink shield
		return 
	end
	return nil
end

B.ShouldDamage_PlayerVSBlockableProjectile = function(pmo,mo,source)
	if not(mo and mo.valid
		and (mo.info.blockable != nil or mo.info.pierce_guard or mo.info.tumbler)
		and mo.flags&MF_MISSILE)
		return
	end

	if pmo.player and source and source.valid and source.player and not(B.MyTeam(source.player,pmo.player)) and not P_PlayerInPain(pmo.player)

		B.PlayerCreditPusher(pmo.player,source)
		
		local vulnerable = B.PlayerCanBeDamaged(pmo.player)
		local guarding = pmo.player.guard > 0
		local reflectarmor = pmo.player.reflectarmor
		
		local tumbler = mo.info.tumbler or false
		local hthrust = mo.info.block_hthrust or 0
		local vthrust = mo.info.block_vthrust or 0
		local blockstun = mo.info.block_stun or 0
		local sound = mo.info.block_sound or sfx_s3k7b
		local blockable = mo.info.blockable or 0

		local pierce_guard = mo.info.pierce_guard or false
		local pierce_sound = mo.info.pierce_sound or sfx_shattr
		local pierce_time = mo.info.pierce_time or 28
		local pierce_hthrust = mo.info.pierce_hthrust or 3
		local pierce_vthrust = mo.info.pierce_vthrust or 10

		local allowreflect = mo.info.allow_reflect
		if allowreflect == nil
			allowreflect = true
		end
		if pierce_guard
		and (not vulnerable or guarding or reflectarmor and not allowreflect)
		or tumbler
		and not(guarding or reflectarmor and allowreflect)
			if not(pmo.hitstun_tics and pmo.player.tumble)
				-- Do guard pierce
				B.ZLaunch(pmo, FRACUNIT*pierce_vthrust, false)
				B.XYLaunch(pmo,mo.angle, FRACUNIT*pierce_hthrust, false)
				local angle = R_PointToAngle2(0,0,pmo.momx,pmo.momy)
				local recoilthrust = FixedHypot(pmo.momx,pmo.momy)		
				B.DoPlayerTumble(pmo.player, pierce_time, angle, recoilthrust)
				if guarding or reflectarmor and allowreflect
					pmo.player.powers[pw_flashing] = pmo.hitstun_tics + 8
				end
				S_StartSound(pmo,pierce_sound)
			end
			return false
			
		elseif blockable and vulnerable and pmo.player.battle_def >= blockable then
		
			B.ResetPlayerProperties(pmo.player, false, false)
			
			if P_IsObjectOnGround(pmo) then
				B.XYLaunch(pmo,mo.angle,FRACUNIT*hthrust, false)
				pmo.state = S_PLAY_SKID
			else
				pmo.momz = $/2
				B.ZLaunch(pmo, FRACUNIT*vthrust, true)
				B.XYLaunch(pmo,mo.angle,FRACUNIT*hthrust / 2, false)
			end
			
			S_StartSound(pmo,sound)
				
			//Do flinch, uncurl
			local angle = R_PointToAngle2(0,0,pmo.momx,pmo.momy)
			local recoilthrust = FixedHypot(pmo.momx,pmo.momy)
			B.DoPlayerFlinch(pmo.player, blockstun, angle, recoilthrust)
			mo.flags = $ &~ MF_MISSILE
			mo.state = mo.info.deathstate
			
			return false
			
		elseif blockable and not(vulnerable) then
		
			if P_IsObjectOnGround(pmo) then
				P_Thrust(pmo,mo.angle,mo.scale*hthrust / 2)
			else
				pmo.momz = $ * 3/4
				B.ZLaunch(pmo, mo.scale*vthrust/2, true)
				P_Thrust(pmo,mo.angle,mo.scale*hthrust / 4)
			end
			S_StartSound(pmo,sound)
			
			return false
		
		end
		
		return true -- Proceed onto damage routine
		
	end
end

B.PlayerRoboMissileCollision = function(pmo,missile,source)
	//Missiles only
	if not(missile and missile.valid and missile.robomissile_init and missile.flags&MF_MISSILE) then return end
	//Enemy player collisions only
	if not(pmo.player and source and source.valid and source.player and not(B.MyTeam(source.player,pmo.player))) then return false end
	//The game already handles standard missile damage.
	//We just need to make an exception case
	if pmo.player.battle_def != 0
		local spd = FixedDiv(
			FixedHypot(missile.momx,missile.momy)/2,
			pmo.weight
		)
-- 		local angle = R_PointToAngle2(missile.x,missile.y,pmo.x,pmo.y)
-- 		P_Thrust(pmo,angle,spd)
		if not(P_IsObjectOnGround(pmo)) then
			P_SetObjectMomZ(pmo,FRACUNIT*8,0)
		end
		//Do uncurling, skidding
		B.DoPlayerFlinch(pmo.player, spd*2/FRACUNIT, R_PointToAngle2(0,0,missile.momx,missile.momy),spd,true)
		P_KillMobj(missile)
	return false end
end