-- Distance Constants
rawset(_G, "FH_DST_ATK", tofixed("2.5"))
rawset(_G, "FH_DST_WHF", tofixed("4.35"))

rawset(_G, "FH_DST_ATK_Y", tofixed("1.25"))
rawset(_G, "FH_DST_WHF_Y", tofixed("1.6"))

-- Attack Constants
rawset(_G, "FH_ATK_FLASH_TICS", 16)

-- Parry Constants
rawset(_G, "FH_PRY_DUR", 35)
rawset(_G, "FH_PRY_TICS", 16)
rawset(_G, "FH_PRY_PRF", 7)

-- Stun Constants
rawset(_G, "FH_STN_SPD", 8*FU)
rawset(_G, "FH_STN_AIRSPD", 10*FU)

rawset(_G, "FH_STN_SPN", 7)
rawset(_G, "FH_STN_SPN_MAX", 360*FU/8)
rawset(_G, "FH_STN_SPN_MIN", 360*FU/70)

-- Hurt Constants
rawset(_G, "FH_HRT_DUR", 35)

local FLAGS_RESET = PF_JUMPED|PF_THOKKED|PF_SPINNING|PF_STARTDASH|PF_BOUNCING|PF_GLIDING

-- Returns the angle of p2 from p1's position.
local function ReturnAngles(pmo1, pmo2)
	local dist = R_PointToDist2(pmo1.x, pmo1.y, pmo2.x, pmo2.y)
	local zdist = (pmo2.z + pmo2.height/2) - (pmo1.z + pmo1.height/2)

	local angle = R_PointToAngle2(pmo1.x, pmo1.y, pmo2.x, pmo2.y)
	local zangle = R_PointToAngle2(0,0, zdist, dist)

	return angle, zangle
end

-- Returns true if the player can be hit.
local function CanBeHit(p1, p2)
	local team1 = p1.heist:getTeam()
	local team2 = p2.heist:getTeam()

	if team1 == team2
	or p2.heist.exiting then
		return false
	end

	return true
end

local function GetAttackerAndAttacked(p, sp, hitbox, shitbox)
	if not shitbox then
		return p, sp
	end

	if hitbox.priority > shitbox.priority then
		return p, sp
	end

	if shitbox.priority > hitbox.priority then
		return sp, p
	end

	-- Determine who hits who using speed.
	local speed = R_PointToDist2(0,0, p.mo.momx, p.mo.momy)
	local sspeed = R_PointToDist2(0,0, sp.mo.momx, sp.mo.momy)

	local tier1 = speed/FixedDiv(FU, 25*FU)
	local tier2 = sspeed/FixedDiv(FU, 25*FU)

	if tier1 > tier2 then
		return p, sp
	end

	if tier2 > tier1 then
		return sp, p
	end

	-- RANDOM-NESS, GO!
	if P_RandomRange(0, 1) then
		return p, sp
	end

	return sp, p
end


local function GetHitbox(p)
	local char = FangsHeist.Characters[skins[p.skin].name]
	--local customHitbox = char:customHitbox (p, p2)

	if p.mo.state == S_FH_STUN or p.mo.state == S_FH_GUARD or p.mo.state == S_FH_CLASH then
		return
	end

	-- Define Jump Hitbox
	if p.pflags & PF_JUMPED
	and not (p.pflags & PF_NOJUMPDAMAGE) then
		local hitbox = FangsHeist.makeHitbox(
			p.mo.x,
			p.mo.y,
			p.mo.z+p.mo.height/2,
			p.mo.radius*2,
			p.mo.radius*2,
			p.mo.height*3/2,
			p.drawangle)

		hitbox.priority = 1
		return hitbox
	end

	if p.pflags & PF_SPINNING then
		local hitbox = FangsHeist.makeHitbox(
			p.mo.x,
			p.mo.y,
			p.mo.z+p.mo.height/2,
			p.mo.radius*3,
			p.mo.radius*3/2,
			p.mo.height*10/12,
			p.drawangle)

		hitbox.priority = p.pflags & PF_STARTDASH > 0 and 2 or 1
		return hitbox
	end

	if p.powers[pw_strong] & STR_MELEE then
		local hitbox = FangsHeist.makeHitbox(
			p.mo.x,
			p.mo.y,
			p.mo.z+p.mo.height/2,
			p.mo.radius*3,
			p.mo.radius*3,
			p.mo.height,
			p.drawangle)

		hitbox.priority = 1
		return hitbox
	end
end

local function Knockback(target, source)
	local angle, zangle = ReturnAngles(target, source)
	local spd = 7*source.scale
	local xySpd = FixedMul(spd, sin(zangle))
	local zSpd = -FixedMul(spd, cos(zangle))

	P_InstaThrust(target, angle, xySpd)
	target.momz = zSpd
end

local function PerfectParry(p, p2)
	p.mo.state = S_PLAY_STND
	p.mo.translation = nil
	
	p.heist.parry_time = 0
	p.heist.parry_cooldown = 0

	S_StartSound(p.mo, sfx_s1a6)
end

local function OkParry(p, p2)
	p.powers[pw_flashing] = 25

	p.mo.state = S_PLAY_STND
	p.mo.translation = nil
	
	p.heist.parry_time = 0
	p.heist.parry_cooldown = 0

	S_StartSound(p.mo, sfx_s1ad)
end

local TIERS = {
	{sfx_dmga1, sfx_dmgb1},
	{sfx_dmga2, sfx_dmgb2},
	{sfx_dmga3, sfx_dmgb3},
	{sfx_dmga4, sfx_dmgb4}
}

local function Damage(p, p2)
	if not P_DamageMobj(p2.mo, p.mo, p.mo) then
		return false
	end

	local xySpeed = R_PointToDist2(0,0,p.mo.momx-p2.mo.momx,p.mo.momy-p2.mo.momy)
	local speed = R_PointToDist2(0,0,xySpeed,p.mo.momz-p2.mo.momz)

	local tier = TIERS[max(1, min(FixedDiv(speed, 9*FU)/FU, #TIERS))]
	local sound = tier[P_RandomRange(1, #tier)]

	S_StartSound(p2.mo, sound)

	return true
end

local function RegisterGuard(atk, vic)
	if vic then
		local knockbackSpeed = 15

		if atk.heist.perf_parry_time then
			knockbackSpeed = 20
		end

		local dist = R_PointToDist2(atk.mo.x, atk.mo.y, vic.mo.x, vic.mo.y)
		local zdist = (vic.mo.z+vic.mo.height/2)-(atk.mo.z+atk.mo.height/2)
		local angle = R_PointToAngle2(atk.mo.x, atk.mo.y, vic.mo.x, vic.mo.y)
		local zangle = R_PointToAngle2(0,0, dist, zdist)
	
		local xySpd = knockbackSpeed*cos(zangle)
		local zSpd = knockbackSpeed*sin(zangle)

		P_InstaThrust(vic.mo, InvAngle(angle), xySpd)
		P_SetObjectMomZ(vic.mo, zSpd)
	end

	if atk.heist.perf_parry_time then
		PerfectParry(atk, vic)
		return 2
	end

	OkParry(atk, vic)
	return 1
end

local function DoWhiff(p)
	if p.mo.heistwhiff
	and p.mo.heistwhiff.valid then
		P_RemoveMobj(p.mo.heistwhiff)
	end

	p.mo.heistwhiff = CreateWhiffEffect(p)
	p.heist.attack_cooldown = 3*TICRATE
	p.heist.attack_time = 10

	S_StartSound(p.mo, sfx_s3k42)
end

local function DoGuard(p)
	if not P_IsObjectOnGround(p.mo) then
		p.mo.state = S_PLAY_FALL
		p.heist.parry_cooldown = 2*TICRATE
		p.powers[pw_flashing] = 2*TICRATE
		P_InstaThrust(p.mo, p.mo.angle, 12*p.mo.scale)
		P_SetObjectMomZ(p.mo, 8*p.mo.scale)
		return
	end

	p.mo.state = S_FH_GUARD
	p.pflags = $ & ~(FLAGS_RESET)

	local tics = FH_PRY_DUR
	local parry_tics = FH_PRY_TICS
	local perf_parry_tics = FH_PRY_PRF

	p.mo.tics = tics
	p.mo.translation = "FH_ParryColor"
	p.heist.parry_time = parry_tics
	p.heist.perf_parry_time = perf_parry_tics

	p.heist.parry_cooldown = 2*TICRATE

	S_StartSound(p.mo, sfx_s1a2)
end

local function RingSpill(p, dontSpill, p2)
	if not p.rings then
		return false
	end

	local gamemode = FangsHeist.getGamemode()
	local rings_spill = min(5, p.rings)

	if not dontSpill 
	and not p2 then
		P_PlayerRingBurst(p, rings_spill)
	elseif p2 then
		FangsHeist.Particles:new("Ring Steal", p.mo, p2.mo, rings_spill)
	end

	S_StartSound(p.mo, sfx_s3kb9)
	p.rings = $-rings_spill
	p.heist:gainProfitMultiplied(-FH_RINGPROFIT*rings_spill)

	return rings_spill
end

addHook("ThinkFrame", do
	if not FangsHeist.isMode() then return end
end)

addHook("ShouldDamage", function(t,i,s,dmg,dt)
	if not FangsHeist.isMode() then return end
	if not (t and t.player and t.player.heist) then return end
	
	if t.player.heist.exiting then
		return false
	end

	if dt == DMG_WATER then
		return false
	end

	local canDamage = not (t.player.powers[pw_flashing] or t.player.powers[pw_invulnerability])
	local forced

	if i
	and i.valid then
		if i.type == MT_CORK then
			if not canDamage then
				return false
			end
		end
		if i.type == MT_LHRT then
			if not canDamage then
				return false
			end
			
			forced = true
		end
	end

	if t.state == S_FH_GUARD
	and t.player.heist.parry_time
	and canDamage
	and i
	and i.valid
	and i.type ~= MT_PLAYER then
		RegisterGuard(t.player)

		if i.flags & MF_ENEMY|MF_BOSS then
			P_DamageMobj(i, t, t)
		end

		t.player.powers[pw_flashing] = 35
		return false
	end

	if s and s.valid and s.player and s.player.heist then
		local team1 = t.player.heist:getTeam()
		local team2 = s.player.heist:getTeam()

		if team1 == team2 then
			return false
		end
	end

	if t.state == S_FH_CLASH then
		return false
	end

	return forced
end, MT_PLAYER)

local function reflection(mobj,proj)
	if not FangsHeist.isMode() then return end
	if not (mobj and mobj.player and mobj.player.heist) then
		return
	end

	if not mobj.player.heist:isAlive() then return end
	if mobj.state ~= S_FH_GUARD then return end
	if not mobj.player.heist.parry_time then return end
	if not (proj.flags & MF_MISSILE) then return end
	if proj.target == mobj then return end

	proj.momx = -$
	proj.momy = -$
	proj.momz = -$
	proj.angle = $ - ANGLE_180
	proj.target = mobj

	RegisterGuard(mobj.player)

	-- Gain profit based on speed of projectile.
	local PROFIT = FH_PARRYPROFIT
	local BASE_SPEED = 24*FU
	local SPEED = R_PointToDist2(mobj.momx, mobj.momy, proj.momx, proj.momy)

	PROFIT = $ * FixedDiv(SPEED, BASE_SPEED)/FU
	mobj.player.heist:gainProfitMultiplied(PROFIT)
	
	return false
end

addHook("MobjCollide", reflection, MT_PLAYER)
addHook("MobjMoveCollide", reflection, MT_PLAYER)

addHook("MobjDamage", function(t,i,s,dmg,dt)
	if not FangsHeist.isMode() then return end
	if not (t and t.player and t.player.heist) then return end

	local gamemode = FangsHeist.getGamemode()
	gamemode:playerdamage(t.player)

	local givenSign = false

	if s
	and s.player
	and s.player.heist then
		local team = s.player.heist:getTeam()

		if t.player.heist:hasSign()
		and s.player.heist:isEligibleForSign() then
			FangsHeist.giveSignTo(s.player)
			givenSign = true
		end

		if not (t.health) then
			s.player.heist.deadplayers = $+1
			s.player.heist:gainProfitMultiplied(FH_DEADPLAYERPROFIT)
		else
			s.player.heist.hitplayers = $+1
			s.player.heist:gainProfitMultiplied(FH_HITPLAYERPROFIT)
		end
	end

	if dt & DMG_DEATHMASK then
		return
	end

	if t.player.powers[pw_shield] then return end
	local rings = RingSpill(t.player, nil, s and s.valid and s.player)

	if not rings then return end

	P_ResetPlayer(t.player)
	P_DoPlayerPain(t.player, s, i)

	return true
end, MT_PLAYER)

local function OnPlayerCollide(p, atkBox, sp)
	local pmo = p.mo
	local mo = sp.mo

	if not (sp.heist and sp.heist:isAlive()) then return end

	if p.heist.exiting
	or sp.heist.exiting then
		return
	end

	-- remove for friendly fire
	if p.heist:getTeam() == sp.heist:getTeam() then
		return
	end

	if sp.mo.state == S_FH_GUARD
	and sp.heist.parry_time then
		RegisterGuard(sp, p)
		return
	end

	local vicBox = GetHitbox(sp)
	local atk, vic = GetAttackerAndAttacked(p, sp, atkBox, vicBox)

	if Damage(atk, vic) then
		Knockback(atk.mo, vic.mo)
	end

	--[[p.mo.state = S_FH_CLASH
	sp.mo.state = S_FH_CLASH

	S_StartSound(p.mo, sfx_fhclsh)
	S_StartSound(sp.mo, sfx_fhclsh)]]
end

--[[addHook("MobjMoveCollide", function(pmo, mo)
	if not FangsHeist.isMode() then return end
	if not (pmo and pmo.player and pmo.player.heist) then return end
	if (mo and mo.type == MT_PLAYER and mo.player and mo.player.heist) then
		OnPlayerCollide(pmo, mo)
		return
	end
end, MT_PLAYER)]]

return function(p)
	if not p.heist:isAlive() then
		if p.mo
		and p.mo.valid
		and p.mo.translation == "FH_ParryColor" then
			p.mo.translation = nil
		end

		p.heist.parry_time = 0
		p.heist.perf_parry_time = 0

		return
	end

	if p.mo.state == S_FH_STUN then
		p.pflags = $|PF_FULLSTASIS
		P_SpawnGhostMobj(p.mo)
	end

	if p.mo.state == S_FH_GUARD then
		if P_IsObjectOnGround(p.mo) then
			p.pflags = $|PF_FULLSTASIS
		end

		if p.heist.parry_time then
			p.mo.translation = "FH_ParryColor"
			p.heist.parry_time = $-1
		else
			p.mo.translation = nil
		end

		p.heist.perf_parry_time = max(0, $-1)
	else
		if p.mo.translation == "FH_ParryColor" then
			p.mo.translation = nil
		end
		p.heist.parry_time = 0
		p.heist.perf_parry_time = 0
	end

	local press = p.cmd.buttons & ~p.lastbuttons

	if p.mo.state ~= S_FH_STUN
	and p.mo.state ~= S_FH_CLASH
	and p.mo.state ~= S_FH_GUARD
	and not P_PlayerInPain(p) then
		-- Parry
		if press & BT_FIRENORMAL
		and p.heist.attack_time == 0
		and p.heist.parry_cooldown == 0 then
			DoGuard(p)
		end
	end

	if p.heist.parry_cooldown then
		p.heist.parry_cooldown = $-1

		if p.heist.parry_cooldown == 0 then
			local ghost = P_SpawnGhostMobj(p.mo)
			ghost.destscale = 4*FU
			ghost.translation = "FH_ParryColor"

			S_StartSound(p.mo, sfx_ngskid)
		end
	end
	if p.heist.attack_cooldown then
		p.heist.attack_cooldown = $-1

		if p.heist.attack_cooldown == 0 then
			local ghost = P_SpawnGhostMobj(p.mo)
			ghost.destscale = 4*FU

			S_StartSound(p.mo, sfx_ngskid)
		end
	end

	local hitbox = GetHitbox(p)

	if p.powers[pw_flashing] == 0
	and p.mo.state ~= S_FH_GUARD
	and hitbox then
		FangsHeist.useHitbox(p, hitbox, OnPlayerCollide)
	end
end