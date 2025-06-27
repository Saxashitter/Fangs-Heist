local B = CBW_Battle
local A = B.Arena
local CV = B.Console

B.PlayerRegulateFlashing = function(player)
	if not P_PlayerInPain(player) and player.powers[pw_flashing]
		if P_PlayerTouchingSectorSpecial(player, 1, 1)
		or P_PlayerTouchingSectorSpecial(player, 1, 2)
		or P_PlayerTouchingSectorSpecial(player, 1, 3)
		or P_PlayerTouchingSectorSpecial(player, 1, 4)
		or P_PlayerTouchingSectorSpecial(player, 1, 5)
		or P_PlayerTouchingSectorSpecial(player, 1, 11)
			-- Do nothing
		elseif player.battle_atk + player.battle_def > 1
		or player.panim == PA_ABILITY
		or player.panim == PA_ABILITY2
			player.powers[pw_flashing] = min($, 2)
		end
	end
end

B.PlayerCanBeDamaged = function(player)
	if not(player.playerstate == PST_LIVE)
	or player.powers[pw_invulnerability]
	or player.powers[pw_super]
	or player.powers[pw_flashing]
		return false
	end
	return true
end

B.ShouldDamage_PlayerVSTargetDummy = function(target, inflictor)
	if inflictor and inflictor.valid and inflictor.type == MT_TARGETDUMMY 
		return false 
	end
end

B.ShouldDamage_PlayerVSSpinFire = function(target, inflictor, source)
	if not(target.player and inflictor and inflictor.valid and source and source.valid and source.player)
	return end
	
	if inflictor.type == MT_SPINFIRE
	and not(target.player.powers[pw_shield]&SH_PROTECTFIRE)
	and not(target.player.powers[pw_flashing] or target.player.powers[pw_super] or target.player.powers[pw_invulnerability])
	and not(B.MyTeam(target.player,source.player))
		return true
	end
end

local getNonNil = function(vars, func)
	for n = 1, #func do
		local ret = func[n](unpack(vars))
		if ret != nil
			return ret
		end
	end
end


B.ShouldDamage_PlayerVSPlayerProjectile = function(...)
	return getNonNil( {...}, {
		B.ShouldDamage_PlayerVSSpinFire,
		B.ShouldDamage_PlayerVSBlockableProjectile,
		B.ShouldDamage_PlayerVSHeart,
		B.PlayerBombDamage,
		B.PlayerRoboMissileCollision
	})
end

B.ShouldDamage_PlayerVSPlayer = function(target,inflictor,source)
	if (target.player and target.player.intangible and (source or inflictor))
		return false
	end
	if not(inflictor and inflictor.valid and inflictor.player and inflictor != target)
	or not(target.player and not(B.MyTeam(target.player,source.player)))
	or not(B.PlayerCanBeDamaged(target.player) or inflictor.flags2&MF2_SUPERFIRE)
		return
	end
	return true
end

B.ShouldDamagePlayer =  function(...)
	return B.ShouldDamage_PlayerVSPlayer(...)
	or B.ShouldDamage_PlayerVSPlayerProjectile(...)
end

B.PlayerDamage = function(target, inflictor, source, damage, damagetype)
	if not(target.player) then return end
	-- Do guarding
	if B.GuardTrigger(target, inflictor, source, damage, damagetype) then return true end
	
	target.hitstun_tics = 10
	target.hitstun_disrupt = true
	
	-- Do custom damage
	local func = B.GetSkinVarsValue(target.player, 'func_pain')
	if func
	and func(target, inflictor, source, damage, damagetype)
		return true
	end
	-- Handle damage dealt/received by revenge jettysyns
	A.RevengeDamage(target,inflictor,source)
	-- Establish enemy player as the last pusher (for hazard kills)
	B.PlayerCreditPusher(target.player,inflictor)
	B.PlayerCreditPusher(target.player,source)
	
	if inflictor and inflictor.valid
		if inflictor.info.hit_sound and target and target.valid
			S_StartSound(target, inflictor.info.hit_sound)
		end
		
		if inflictor.info.spawnfire and source.player and source.player.playerstate == PST_LIVE and (source.player.powers[pw_shield] & SH_NOSTACK) == SH_ELEMENTAL
			S_StartSound(inflictor, sfx_s22e)
			S_StartSoundAtVolume(inflictor, sfx_s3k82, 180)
			local m = 20
			for n = 0, m do
				local fire = P_SPMAngle(inflictor,MT_SPINFIRE,0,0)
				if fire and fire.valid
					fire.flags = $ & ~MF_NOGRAVITY
					B.InstaThrustZAim(fire,(360/m)*n*ANG1,ANGLE_45*P_MobjFlip(inflictor),inflictor.scale * 7)
					fire.fuse = 4 * TICRATE
					fire.target = source
				end
			end
		end
	end
	
	local player = target.player
	if player and player.valid and (player.powers[pw_shield] & SH_NOSTACK) == SH_ARMAGEDDON-- no more arma revenge boom
		player.powers[pw_shield] = SH_PITY
	end
end

B.DamageFX = function(target, inflictor, source, damage, damagetype)
	if not target and target.valid return end
	if target.player return end
	if inflictor and inflictor.valid and inflictor.info.hit_sound and target and target.valid
		S_StartSound(target, inflictor.info.hit_sound)
	end
end

B.PlayerDeath = function(target, inflictor, source, damagetype)
	local killer
	local player = target.player
	
	-- Standard kill
	if inflictor and inflictor.player
		killer = inflictor.player
	elseif source and source.player
		killer = source.player
	end
	
	-- Player was pushed into a death hazard
	if player and (damagetype == DMG_DEATHPIT or damagetype == DMG_CRUSHED)
	and player.pushed_creditplr and player.pushed_creditplr.valid and not B.MyTeam(player,player.pushed_creditplr)
		killer = player.pushed_creditplr
		P_AddPlayerScore(player.pushed_creditplr,50)
		B.DebugPrint(player.pushed_creditplr.name.." received 50 points for sending "..player.name.." to their demise")
	end
	-- Player ran out of lives in Survival mode
	if player.lives == 1 and B.BattleGametype() and G_GametypeUsesLives()
		B.PrintGameFeed(player," ran out of lives!")
		A.GameOvers = $+1
	end
	-- Death time penalty
	if B.BattleGametype() 
		if not B.PreRoundWait()
			if not (gametyperules & GTR_CAMPAIGN)
				if not G_GametypeUsesLives()
				and G_GametypeHasTeams()
					player.deadtimer = -(1+min(CV.RespawnTime.value-3,player.respawnpenalty*2))*TICRATE
					player.respawnpenalty = $+1
				elseif player.lives == 1 and CV.Revenge.value
					player.deadtimer = (2-10-(player.respawnpenalty)*2)*TICRATE
					player.respawnpenalty = $+1
				end
			end
		else
			player.deadtimer = TICRATE*3
		end
	end
	if not (target.player and target.player.revenge)
		A.KillReward(killer)
	end
	
	player.spectatortime = player.deadtimer -TICRATE*3
end