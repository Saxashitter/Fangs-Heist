local B = CBW_Battle

B.ArmaCharge = function(player)
	if not player.valid or not player.mo or not player.mo.valid or not player.armachargeup
		player.armachargeup = nil
		return
	end
	
	local mo = player.mo
	
	if (player.actionstate
		or player.playerstate != PST_LIVE
		or P_PlayerInPain(player)
		or (player.powers[pw_shield] & SH_NOSTACK) != SH_ARMAGEDDON)
		
		player.armachargeup = nil
		player.pflags = $ & ~PF_FULLSTASIS
		return
	end
	
	mo.state = S_PLAY_ROLL
	player.pflags = $ | PF_THOKKED | PF_SHIELDABILITY | PF_FULLSTASIS | PF_JUMPED & ~PF_NOJUMPDAMAGE
	
	player.armachargeup = $ + 1
	//Speed Cap
	local speed = FixedHypot(mo.momx,mo.momy)
	if speed > mo.scale then
		local dir = R_PointToAngle2(0,0,mo.momx,mo.momy)
		P_InstaThrust(mo,dir,FixedMul(speed,mo.friction))
	end
	P_SetObjectMomZ(mo,0,false)
	
	if player.armachargeup == 14
		S_StartSoundAtVolume(mo, sfx_s3kc4s, 200)
		S_StartSoundAtVolume(nil, sfx_s3kc4s, 80)
	end
	
	if player.armachargeup >= 27
		player.armachargeup = nil
		player.pflags = $ & ~PF_FULLSTASIS
		player.pflags = $ & ~(PF_JUMPED|PF_THOKKED)
		
		mo.state = S_PLAY_FALL
		local shake = 14
		local shaketics = 5
		P_StartQuake(shake * FRACUNIT, shaketics)
		S_StartSoundAtVolume(nil, sfx_s3kb4, 170)
		P_BlackOw(player)
	end
end

local ElementalStomp = function(player)
	local mo = player.mo
	mo.state = S_PLAY_ROLL
	mo.momx = $ * 3/5
	mo.momy = $ * 3/5
	P_SetObjectMomZ(mo, -25*FRACUNIT)
	S_StartSound(mo,sfx_s3k43)
	player.pflags = ($|PF_THOKKED|PF_SHIELDABILITY)
end
local ArmageddonExplosion = function(player)
	local mo = player.mo
	player.armachargeup = 1
	player.dashmode = 0
	player.pflags = $ | PF_SHIELDABILITY | PF_FULLSTASIS | PF_JUMPED & ~PF_NOJUMPDAMAGE
	mo.state = S_PLAY_ROLL

	S_StartSoundAtVolume(mo, sfx_s3kc4s, 200)
	S_StartSoundAtVolume(nil, sfx_s3kc4s, 100)
end
local WhirlwindJump = function(player)
	P_DoJumpShield(player)
	player.pflags = ($|PF_THOKKED|PF_SHIELDABILITY)
end
local FlameDash = function(player)
	local mo = player.mo
	mo.state = S_PLAY_ROLL
	P_Thrust(mo, mo.angle, 30*mo.scale)
	S_StartSound(mo,sfx_s3k43)
	player.pflags = ($|PF_THOKKED|PF_SHIELDABILITY) & ~PF_NOJUMPDAMAGE
end
local BubbleBounce = function(player)
	local mo = player.mo
	mo.momx = $/3
	mo.momy = $/3
	S_StartSound(mo,sfx_s3k44)
	mo.state = S_PLAY_ROLL
	player.pflags = ($|PF_THOKKED|PF_SHIELDABILITY) & ~PF_NOJUMPDAMAGE
	P_SetObjectMomZ(mo, -24*FRACUNIT)
end
local ThunderJump = function(player)
	local mo = player.mo
	mo.state = S_PLAY_ROLL
	P_DoJumpShield(player)
	S_StartSound(mo,sfx_s3k45)
	player.pflags = ($|PF_THOKKED|PF_SHIELDABILITY) & ~PF_NOJUMPDAMAGE
end
local ForceStop = function(player)
	local mo = player.mo
	P_InstaThrust(mo, 0, 0*FRACUNIT)
	
	player.weapondelay = 25
	P_SetObjectMomZ(mo, 0*FRACUNIT)
	S_StartSound(mo,sfx_ngskid)
	player.pflags = $|PF_THOKKED|PF_SHIELDABILITY
end
local AttractionShot = function(player)
	local mo = player.mo
	local lockonshield = P_LookForEnemies(player, false, false)
	mo.tracer = lockonshield
	mo.target = lockonshield
	if lockonshield and lockonshield.valid
		player.pflags = ($|PF_THOKKED|PF_JUMPED|PF_SHIELDABILITY) & ~(PF_NOJUMPDAMAGE)
		mo.state = S_PLAY_ROLL
		mo.angle = R_PointToAngle2(mo.x, mo.y, lockonshield.x, lockonshield.y)
		S_StartSound(mo, sfx_s3k40)
		player.homing = 1*TICRATE/2
	else
		player.pflags = ($|PF_THOKKED|PF_SHIELDABILITY)
		S_StartSound(mo, sfx_s3ka6)
		player.homing = 2
	end
end

B.CanShieldActive = function(player)
	return not P_PlayerInPain(player)
-- 		and not player.gotcrystal
-- 		and not player.gotflag
		and not player.gotflagdebuff
		and not player.gotpowercard
		and not player.justtossedflag
		and not player.isjettysyn
		and not player.revenge
		and not player.exiting
		and not player.actionstate
		and not player.powers[pw_nocontrol]
		and not (player.pflags&PF_SHIELDABILITY)
end
B.DoShieldActive = function(player)
	// The SRB2 shields.
	-- Elemental Stomp.
	if (player.powers[pw_shield] & SH_NOSTACK) == SH_ELEMENTAL
		ElementalStomp(player)
		return
	end

	-- Armageddon Explosion.
	if (player.powers[pw_shield] & SH_NOSTACK) == SH_ARMAGEDDON
		ArmageddonExplosion(player)
		return
	end

	-- Whirlwind Jump.
	if (player.powers[pw_shield] & SH_NOSTACK) == SH_WHIRLWIND
		WhirlwindJump(player)
		return
	end

	-- Force Stop.
	if (player.powers[pw_shield] & ~(SH_FORCEHP|SH_STACK)) == SH_FORCE
		ForceStop(player)
		return
	end

	-- Attraction Shot.
	if (player.powers[pw_shield] & SH_NOSTACK) == SH_ATTRACT
		AttractionShot(player)
		return
	end

	// The S3K shields.
	-- Flame Dash.
	if (player.powers[pw_shield] & SH_NOSTACK) == SH_FLAMEAURA
		FlameDash(player)
		return
	end

	-- Bubble Bounce.
	if (player.powers[pw_shield] & SH_NOSTACK) == SH_BUBBLEWRAP
		BubbleBounce(player)
		return
	end
	
	-- Thunder Jump.
	if (player.powers[pw_shield] & SH_NOSTACK) == SH_THUNDERCOIN
		ThunderJump(player)
		return
	end
end

B.ShieldSwap = function(player)
	local sh = player.powers[pw_shield] & SH_NOSTACK
	
	if not player.shieldswap_cooldown
	and sh and #player.shieldstock
		player.shieldswap_cooldown = 15
		
		player.powers[pw_shield] = 0
		P_RemoveShield(player)

		P_SwitchShield(player, player.shieldstock[1])
		table.insert(player.shieldstock, sh)
		table.remove(player.shieldstock, 1)
		
		S_StartSound(player.mo, sfx_shswap)
	else
		S_StartSound(nil, sfx_s3k8c, player)
	end
end

B.ShieldTossFlagButton = function(player)
	if player and player.valid and player.mo and player.mo.valid
		player.shieldswap_cooldown = max(0, $ - 1)
		
		if B.CanShieldActive(player)
			and (B.ButtonCheck(player,BT_TOSSFLAG) == 1)
			and not (player.tossdelay == 2*TICRATE - 1)
			
			local temp = player.powers[pw_shield]&SH_NOSTACK
			local power = player.shieldstock[1]
			
			if temp != SH_PITY and
				(
					(player.pflags&PF_JUMPED)
					and not player.powers[pw_carry]
					and not (player.pflags&PF_THOKKED and not (player.secondjump == UINT8_MAX and temp == SH_BUBBLEWRAP))
				)
				B.DoShieldActive(player)
			
			else--Shield swap
				if B.ButtonCheck(player,BT_TOSSFLAG) == 1
					B.ShieldSwap(player)
				end
			end
		elseif B.ButtonCheck(player,BT_TOSSFLAG) == 1
			S_StartSound(nil, sfx_s3k8c, player)
		end
	end
end