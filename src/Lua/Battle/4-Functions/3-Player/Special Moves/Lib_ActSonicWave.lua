local B = CBW_Battle

local rate = 5
local ang = ANG1*3
local recoil_xy = 10
local recoil_z = 10
local cooldown = TICRATE*2

-- Sonic Wave Projectile
addHook('MobjSpawn', function(mo)
	mo.fuse = mo.info.reactiontime
	mo.actionspd = mo.scale*45
	S_StartSound(mo, sfx_s3k97)
end, MT_SONICWAVE)
addHook('MobjThinker',function(mo)
	local speed = R_PointToDist2(0, 0, mo.momx, mo.momy)
	speed = R_PointToDist2(0, 0, $, mo.momz)
	local topspeed = FixedMul(mo.scale*mo.info.painchance, mo.actionspd)/45
	topspeed = $<<(mo.supersonic*2)
	if speed < topspeed
		local factor = FixedDiv(B.FixedLerp(speed, topspeed, FRACUNIT>>5), speed)
		mo.momx = FixedMul($, factor)
		mo.momy = FixedMul($, factor)
		mo.momz = FixedMul($, factor)
	end
	if mo.fuse % 2
		local z = P_MobjFlip(mo) == -1 and mo.height-mobjinfo[MT_SONICWAVETRAIL].height
			or 0
		local s = P_SpawnMobjFromMobj(mo, 0, 0, z, MT_SONICWAVETRAIL)
		if s and s.valid
			local teamred = gametyperules & GTR_TEAMS and not(B.BattleCampaign()) and mo.target and mo.target.player and mo.target.ctfteam == 1
			s.target = mo.target
			s.colorized = true
			if mo.fuse % 3 == 0
				s.color = SKINCOLOR_WHITE
			elseif mo.fuse % 3 == 1
				s.color = teamred and SKINCOLOR_PINK or SKINCOLOR_SLATE
			elseif mo.fuse % 3 == 2
				s.color = teamred and SKINCOLOR_RED or SKINCOLOR_BLUE
			end
			s.scale = $ + mo.actionspd/45
			s.momx = 1
		end
	end
end, MT_SONICWAVE)


-- Projectile spawner
local doSonicWave = function(mo, angle, n, supersonic)
	local z = P_MobjFlip(mo) == -1 and mo.height-mobjinfo[MT_SONICWAVE].height
		or 0
	local wave = P_SpawnMobjFromMobj(mo, 0, 0, z, MT_SONICWAVE)
	if wave and wave.valid
		wave.target = mo
		if mo.player
			wave.actionspd = FixedMul(mo.scale, mo.player.actionspd)
			wave.supersonic = supersonic
		end
		if angle == nil
			angle = mo.player.drawangle
		else
			angle = $ * (1 + supersonic*2)
			angle = $ + mo.player.drawangle
		end
		local speed = wave.info.speed * (1<<(supersonic*2))
		if supersonic
			wave.fuse = $/8
		end
		P_InstaThrust(wave, angle, speed)
		-- Aerial modifiers
		if not(P_IsObjectOnGround(mo))
			
			P_SetObjectMomZ(wave, -speed/(1+n))
			wave.momx = $*2/3
			wave.momy = $*2/3
		end
	end
end

-- Recoil thrust function
local doRecoil = function(mo)
	local water = B.WaterFactor(mo)
	local air = P_IsObjectOnGround(mo) and 1 or 2
	P_InstaThrust(mo, mo.player.drawangle+ANGLE_180, mo.scale*recoil_xy/water/air)
	P_SetObjectMomZ(mo, FRACUNIT*recoil_z/water/air)
end

-- Action handler
B.Action.SonicWave = function(mo, doaction)
	local player = mo.player
	local supersonic = B.SkinVars[player.skin].flags & SKINVARS_SUPERSONIC and 1 or 0 --Super Sonic gets extra privileges and modifications
	player.actiontext = "Sonic Wave"
	player.actionrings = not(supersonic) and 10 or 5
	if not(B.CanDoAction(player))
		player.actiontime = 0
		player.actionstate = 0
-- 		if player.actionstate
-- 			B.ApplyCooldown(player, cooldown)
-- 		end
	end
	local onground = P_IsObjectOnGround(mo)
	if doaction == 1 and player.actionstate == 0
		player.actionstate = 1
		player.actiontime = 1
		player.drawangle = mo.angle
		B.PayRings(player)
			B.ApplyCooldown(player, cooldown/(1+supersonic))
		S_StartSound(mo, sfx_zoom)
	end
	if player.actionstate
		local rate = rate
		if supersonic
			rate = $*2/3
		end
		if onground
			mo.momx = player.cmomx
			mo.momy = player.cmomy
			player.pflags = $|PF_STARTDASH
			mo.state = S_PLAY_SPINDASH
		else
			player.pflags = ($|PF_SPINNING) &~ (PF_JUMPED|PF_STARTJUMP|PF_THOKKED|PF_SHIELDABILITY)
			mo.state = S_PLAY_ROLL
		end
		mo.tics = 1 -- Animation control
		player.lockmove = true
		player.lockaim = true
		player.actiontime = $-1
		if not(onground) and player.actionstate < 3
			doRecoil(mo)
		end

		if player.actiontime == 0
			if player.actionstate == 1
				doSonicWave(mo, 0, 0, supersonic)
				player.actiontime = rate
				player.actionstate = 2
			elseif player.actionstate == 2
				doSonicWave(mo, ang, 1, supersonic)
				doSonicWave(mo, -ang, 1, supersonic)
				player.actiontime = rate
				player.actionstate = 3
			elseif player.actionstate == 3
				doSonicWave(mo, ang*2, 2, supersonic)
				doSonicWave(mo, 0, 2, supersonic)
				doSonicWave(mo, -ang*2, 2, supersonic)
				if not supersonic
					player.actiontime = 15
					player.actionstate = 10
					doRecoil(mo)
					player.mo.state = S_PLAY_ROLL
				else
					player.actiontime = rate
					player.actionstate = 4
				end
			elseif player.actionstate == 4
				doSonicWave(mo, ang, 0, supersonic)
				doSonicWave(mo, -ang, 0, supersonic)
				doSonicWave(mo, ang*3, 0, supersonic)
				doSonicWave(mo, -ang*3, 0, supersonic)
				player.actiontime = rate
				player.actionstate = 5
			elseif player.actionstate == 5
				doSonicWave(mo, 0, 0, supersonic)
				doSonicWave(mo, ang*2, 1, supersonic)
				doSonicWave(mo, -ang*2, 1, supersonic)
				doSonicWave(mo, ang*4, 1, supersonic)
				doSonicWave(mo, -ang*4, 1, supersonic)
				player.actiontime = 10
				player.actionstate = 10
				doRecoil(mo)
				player.mo.state = S_PLAY_ROLL
			else
				player.actionstate = 0
				player.mo.state = S_PLAY_FALL
				player.pflags = $ &~ (PF_SPINNING|PF_STARTDASH)
-- 				player.powers[pw_nocontrol] = max($,5)
			end
		end
	end
end