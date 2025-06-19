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

mobjinfo[MT_PLAYER].radius = $*3/2

-- Stun Constants
rawset(_G, "FH_STN_SPD", 8*FU)
rawset(_G, "FH_STN_AIRSPD", 10*FU)

rawset(_G, "FH_STN_SPN", 7)
rawset(_G, "FH_STN_SPN_MAX", 360*FU/8)
rawset(_G, "FH_STN_SPN_MIN", 360*FU/70)

-- Hurt Constants
rawset(_G, "FH_HRT_DUR", 35)

local FLAGS_RESET = PF_JUMPED|PF_THOKKED|PF_SPINNING|PF_STARTDASH|PF_BOUNCING|PF_GLIDING

local StunList = {}
local ClashList = {}
addHook("NetVars", function(sync)
	StunList = sync($)
	ClashList = sync($)
end)

-- Checks if the player is in the hitbox to get hurt.
local function IsInHitBox(mo1, mo2, xmul, ymul)
	xmul = $ or FH_DST_ATK
	ymul = $ or FH_DST_ATK_Y

	local dist = R_PointToDist2(mo1.x, mo1.y, mo2.x, mo2.y)

	if dist <= fixmul(mo1.radius+mo2.radius, xmul) then
		local h1 = fixmul(mo1.height, ymul)
		local h2 = fixmul(mo2.height, ymul)

		return mo2.z <= mo1.z+h1
		and mo1.z <= mo2.z+h2
	end

	return false
end

-- Returns the angle of p2 from p1's position.
local function ReturnAngles(p1, p2)
	local pmo1 = p1.mo
	local pmo2 = p2.mo

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

-- Returns the priority that the player's attack should have.
local PRO_JUMP = 2
local PRO_MELEE = 2
local PRO_ROLL = 3
local PRO_SPINDASH = 4
local PRO_INVINC = 5

local function GetAttackPriority(p, p2)
	local char = FangsHeist.Characters[skins[p.skin].name]
	local customPriority = char:attackPriority(p, p2)

	if customPriority then
		return customPriority
	end

	if not P_PlayerCanDamage(p, p2.mo) then
		return 0
	end

	if p.powers[pw_invulnerability] then
		return PRO_INVINC
	end

	-- Melee
	if p.powers[pw_strong] & STR_MELEE then
		return PRO_MELEE
	end

	-- Spindash
	if P_IsObjectOnGround(p.mo)
	and p.pflags & PF_SPINNING
	and p.pflags & PF_STARTDASH then
		return PRO_SPINDASH
	end

	-- Jumping
	if not P_IsObjectOnGround(p.mo)
	and p.pflags & PF_JUMPED then
		return PRO_JUMP
	end

	-- Rolling
	if p.pflags & PF_SPINNING then
		return PRO_ROLL
	end

	return PRO_JUMP
end

-- Returns the nearest valid player within 2048 FRACUNITs.
local function GetNearestAttackablePlayer(mo, blacklist)
	local found
	local dist

	local x = mo.x
	local y = mo.y

	for plyr in players.iterate do
		if blacklist
		and blacklist[plyr] then
			continue
		end

		if not (plyr.valid
		and plyr.heist
		and plyr.heist:isAlive()
		and not plyr.heist.exiting) then
			continue
		end

		if mo.player then
			if not (mo.player ~= plyr
			and CanBeHit(mo.player, plyr)) then
				continue
			end
		end

		local mo2 = plyr.mo

		local xyDist = R_PointToDist2(mo.x, mo.y, mo2.x, mo2.y)
		local circularDist = R_PointToDist2(0, xyDist, 0, abs((mo.z+mo.height/2) - (mo2.z+mo2.height/2)))

		if dist == nil then
			found = plyr
			dist = circularDist

			continue
		end

		if xyDist > dist then
			continue
		end

		found = plyr
		dist = circularDist
	end

	return found, dist
end

-- Makes an attack for self, which is a list.
local function DefAttack(self, atk, vic)
	table.insert(self, {
		atk = atk,
		vic = vic})
end

-- Returns true if the player is in self.
local function IsInList(self, p)
	for i, tbl in ipairs(self) do
		if tbl.atk == p
		or tbl.vic == p
		or tbl == p then
			return true
		end
	end

	return false
end

-- Setting the player to this state will stun them if they hit a perfect parry.
function A_FHStun(mo)
	if not FangsHeist.isMode() then return end
	if not (mo and mo.player and mo.player.heist and mo.player.heist:isAlive()) then
		return
	end

	local spd = FixedMul(FH_STN_SPD, mo.scale)
	local airspd = FixedMul(FH_STN_AIRSPD, mo.scale)

	P_InstaThrust(mo, mo.player.drawangle, -spd)
	P_SetObjectMomZ(mo, airspd)
	S_StartSound(mo, sfx_s1c9)

	mo.fh_stun = {
		forced_angle = mo.player.drawangle,
		start_angle = mo.player.drawangle,
		tics = 0
	}
	mo.player.pflags = $ & ~(FLAGS_RESET)

	if not IsInList(StunList, mo.player) then
		table.insert(StunList, mo.player)
	end
end

-- Setting the player to this state has them unable to move, but invincible until they land.
function A_FHClash(mo)
	if not FangsHeist.isMode() then return end
	if not (mo and mo.player and mo.player.heist and mo.player.heist:isAlive()) then
		return
	end

	if P_IsObjectOnGround(mo) then
		mo.tics = 28
	end

	mo.fh_clash = true

	table.insert(ClashList, mo.player)
end

states[S_FH_STUN].action = A_FHStun
states[S_FH_CLASH].action = A_FHClash

local function StunThinker(p)
	local mo = p.mo

	if P_IsObjectOnGround(mo) then
		mo.state = S_PLAY_FALL

		local spd = FixedMul(FH_STN_SPD, mo.scale)
		local airspd = FixedMul(FH_STN_AIRSPD, mo.scale)

		p.drawangle = mo.fh_stun.start_angle

		P_InstaThrust(mo, p.drawangle, -spd/2)
		P_SetObjectMomZ(mo, airspd/2)

		S_StartSound(mo, sfx_s1b4)
		S_StartSound(mo, sfx_s3k4c)
		mo.player.powers[pw_flashing] = 13

		return true
	end

	if mo.state ~= S_FH_STUN then
		return true
	end

	local speed = ease.linear(
		FixedDiv(mo.fh_stun.tics, FH_STN_SPD),
		FH_STN_SPN_MAX,
		FH_STN_SPN_MIN)

	local thrust = FixedMul(FH_STN_SPD, mo.scale)

	mo.fh_stun.forced_angle = $ + FixedAngle(speed)
	p.drawangle = mo.fh_stun.forced_angle

	P_InstaThrust(mo, mo.fh_stun.start_angle, -thrust)
	mo.fh_stun.tics = min($+1, FH_STN_SPN)
end

local function ClashThinker(p)
	local mo = p.mo

	if mo.state ~= S_FH_CLASH then
		p.powers[pw_flashing] = 0
		return true
	end

	p.powers[pw_flashing] = 3
end

local function SpawnShield(p)
	local shield = P_SpawnMobjFromMobj(p.mo, 0,0,0, MT_THOK)
	shield.state = char.attackEffectState
	shield.target = p.mo
end

local function Knockback(p1, p2, knockbackOther)
	local mo1 = p1.mo
	local mo2 = p2.mo

	local angle, zangle = ReturnAngles(p1, p2)

	local rev_angle = angle+ANGLE_180

	p1.drawangle = angle
	p2.drawangle = rev_angle

	local spd = 12*mo1.scale
	local xySpd = FixedMul(spd, sin(zangle))
	local zSpd = -FixedMul(spd, cos(zangle))

	P_InstaThrust(mo1, rev_angle, xySpd)
	mo1.momz = zSpd
	if not P_IsObjectOnGround(mo1) then
		mo1.state = S_PLAY_FALL
	end
	p1.pflags = $ & ~(FLAGS_RESET)

	if not knockbackOther then
		return
	end

	P_InstaThrust(mo2, angle, xySpd)
	mo2.momz = -zSpd
	if not P_IsObjectOnGround(mo2) then
		mo2.state = S_PLAY_FALL
	end
	p2.pflags = $ & ~(FLAGS_RESET)
end

local function PerfectParry(p, p2)
	if p2 then
		p2.drawangle = R_PointToAngle2(p2.mo.x, p2.mo.y, p.mo.x, p.mo.y)
		p2.mo.state = S_FH_STUN
		p2.pflags = $ & ~(FLAGS_RESET)
	end
	
	p.mo.state = S_PLAY_STND
	p.mo.translation = nil
	
	p.heist.parry_time = 0
	p.heist.parry_cooldown = 0

	S_StartSound(p.mo, sfx_s1a6)
end

local function OkParry(p, p2)
	local tics = 35

	if p2 then
		Knockback(p2, p)
		p2.powers[pw_flashing] = tics
	end

	p.powers[pw_flashing] = tics

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

local function Damage(p, p2, knockback)
	if not P_DamageMobj(p2.mo, p.mo, p.mo) then
		return
	end

	local xySpeed = R_PointToDist2(0,0,p.mo.momx-p2.mo.momx,p.mo.momy-p2.mo.momy)
	local speed = R_PointToDist2(0,0,xySpeed,p.mo.momz-p2.mo.momz)

	local tier = TIERS[max(1, min(FixedDiv(speed, 9*FU)/FU, #TIERS))]
	local sound = tier[P_RandomRange(1, #tier)]

	S_StartSound(p2.mo, sound)
	S_StartSound(p.mo, sound, p)

	if knockback == nil then
		knockback = true
	end

	if knockback then
		Knockback(p, p2)
	end

	p2.heist.attack_cooldown = max($, TICRATE)

	p.powers[pw_flashing] = FH_ATK_FLASH_TICS
end

local function RegisterGuard(atk, vic)
	if atk.heist.perf_parry_time then
		PerfectParry(atk, vic)
		return 2
	end

	OkParry(atk, vic)
	return 1
end

local function CreateWhiffEffect(p)
	-- code from mm, by luigi budd
	local angle = p.mo.angle
	local dist = 16*FU
	local whiff = P_SpawnMobjFromMobj(p.mo,
		P_ReturnThrustX(nil,angle, dist) + p.mo.momx,
		P_ReturnThrustY(nil,angle, dist) + p.mo.momy,
		p.mo.height/2,
		MT_THOK
	)

	whiff.state = S_FH_WHIFF
	whiff.fuse = -1 --whiff.tics
	whiff.angle = angle
	whiff.renderflags = $|RF_NOSPLATBILLBOARD|RF_FLOORSPRITE
	whiff.scale = FixedMul($, tofixed("1.5"))
	whiff.height = 0

	whiff.spritexscale = whiff.scale
	whiff.spriteyscale = whiff.scale

	return whiff
end

local function WhiffAttack(p)
	local blacklist = {}
	local found = true

	while found do
		found = GetNearestAttackablePlayer(p.mo, blacklist)
		if not found then break end

		blacklist[found] = true

		if found.mo.state == S_FH_STUN
		or found.mo.state == S_FH_CLASH
		or found.powers[pw_flashing] then
			continue
		end

		if not IsInHitBox(p.mo, found.mo) then
			local adiff = FixedAngle(
				AngleFixed(
					R_PointToAngle2(
						p.mo.x, p.mo.y,
						found.mo.x, found.mo.y
					)
				) - AngleFixed(p.mo.angle)
			)
	
			if AngleFixed(adiff) > 180*FU then
				adiff = InvAngle($)
			end
	
			if (AngleFixed(adiff) > 115*FU)
			or not IsInHitBox(p.mo, found.mo, FH_DST_WHF, FH_DST_WHF_Y) then
				continue
			end
		end
	
		if found.mo.state == S_FH_GUARD
		and found.heist.parry_time then
			RegisterGuard(found, p)
			p.heist.attack_time = 0
			break
		end
	
		--Damage(p, found, false, false)

		--[[
		found.drawangle = R_PointToAngle2(found.mo.x, found.mo.y, p.mo.x, p.mo.y)
		found.mo.state = S_FH_STUN
		]]

		found.drawangle = InvAngle(p.mo.angle)
		found.pflags = $ & ~FLAGS_RESET
		found.powers[pw_flashing] = 12

		found.mo.state = S_PLAY_FALL
		S_StartSound(found.mo, sfx_s1c9)
		P_InstaThrust(found.mo, p.mo.angle, 27*p.mo.scale)
		P_SetObjectMomZ(found.mo, 7*p.mo.scale)

		p.powers[pw_flashing] = FH_ATK_FLASH_TICS
	end
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
	p.mo.state = S_FH_GUARD
	p.pflags = $ & ~(FLAGS_RESET)

	local tics = -1
	local parry_tics = FH_PRY_TICS
	local perf_parry_tics = FH_PRY_PRF

	if P_IsObjectOnGround(p.mo) then
		tics = FH_PRY_DUR
	end

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
	p.heist:gainProfit(-FH_RINGPROFIT*rings_spill)

	return rings_spill
end

local function RemoveCarry(p)
	if p.powers[pw_carry] == CR_ROLLOUT then
		local rollout = p.mo.tracer

		if rollout and rollout.valid and rollout.tracer == p.mo then
			rollout.tracer = nil
			rollout.flags = $|MF_PUSHABLE
		end

		p.mo.tracer = nil
	else
		local mo = p.mo.tracer

		if mo and mo.valid and mo.tracer == p.mo then
			mo.tracer = nil
		end

		p.mo.tracer = nil
	end

	p.powers[pw_carry] = CR_NONE
end

addHook("ThinkFrame", do
	if not FangsHeist.isMode() then return end

	for i = #StunList, 1, -1 do
		local p = StunList[i]

		if not (p
		and p.valid
		and p.heist
		and p.heist:isAlive()
		and p.mo.fh_stun
		and not StunThinker(p)) then
			table.remove(StunList, i)
			if p.mo and p.mo.valid then
				p.mo.fh_stun = nil
			end
		end
	end
	for i = #ClashList, 1, -1 do
		local p = ClashList[i]

		if not (p
		and p.valid
		and p.heist
		and p.heist:isAlive()
		and p.mo.fh_clash
		and not ClashThinker(p)) then
			table.remove(ClashList, i)
			if p.mo and p.mo.valid then
				p.mo.fh_clash = nil
			end
		end
	end

	local attacks = {}

	-- Iterate through players to see who is attacking who
	--[[for p in players.iterate do
		if not (p.valid and p.heist and p.heist:isAlive()) then
			continue
		end
		if IsInList(attacks, p)
		or p.mo.state == S_FH_GUARD then
			continue
		end

		local found = GetNearestAttackablePlayer(p.mo)
		if not found then continue end

		if not IsInHitBox(p.mo, found.mo) then
			continue
		end
		if not P_PlayerCanDamage(p, found.mo) then
			continue
		end
		if IsInList(ClashList, found)
		or IsInList(attacks, found) then
			continue
		end

		if found.mo.state == S_FH_GUARD
		and found.heist.parry_time then
			RegisterGuard(found, p)
			continue
		end

		DefAttack(attacks, p, found)
	end]]

	-- Iterate through attacks and see who attacks who.
	for _, atk in ipairs(FangsHeist.Net.attacks) do
		local atkP = atk.atk
		local vicP = atk.vic

		local atkPro = GetAttackPriority(atkP, vicP)
		local vicPro = GetAttackPriority(vicP, atkP)

		if atkPro == 0 and vicPro == 0 then
			continue
		end

		if atkPro > vicPro then
			Damage(atkP, vicP, nil, vicP.mo.state == S_FH_STUN)
			continue
		end

		if vicPro > atkPro then
			Damage(vicP, atkP, nil, atkP.mo.state == S_FH_STUN)
			continue
		end

		Knockback(atkP, vicP, true)
		atkP.mo.state = S_FH_CLASH
		vicP.mo.state = S_FH_CLASH

		S_StartSound(atkP.mo, sfx_fhclsh)
		S_StartSound(vicP.mo, sfx_fhclsh)
	end
	FangsHeist.Net.attacks = {}
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
	mobj.player.heist:gainProfit(PROFIT)
	
	return false
end

addHook("MobjCollide", reflection, MT_PLAYER)
addHook("MobjMoveCollide", reflection, MT_PLAYER)

addHook("MobjDamage", function(t,i,s,dmg,dt)
	if not FangsHeist.isMode() then return end
	if not (t and t.player and t.player.heist) then return end

	for _,tres in ipairs(t.player.heist.treasures) do
		if not (tres.mobj.valid) then continue end

		local angle = FixedAngle(P_RandomRange(1, 360)*FU)

		P_InstaThrust(tres.mobj, angle, 12*FU)
		P_SetObjectMomZ(tres.mobj, 4*FU)

		tres.mobj.target = nil
	end
	t.player.heist.treasures = {}

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
			s.player.heist:gainProfit(FH_DEADPLAYERPROFIT)
		else
			s.player.heist.hitplayers = $+1
			s.player.heist:gainProfit(FH_HITPLAYERPROFIT)
		end
	end

	if not givenSign
	and t.player.heist:hasSign() then
		local sign = FangsHeist.Net.sign
		sign.holder = nil

		local launch_angle = FixedAngle(P_RandomRange(0, 360)*FU)

		P_InstaThrust(sign, launch_angle, 8*FU)
		P_SetObjectMomZ(sign, 4*FU)
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

local function OnPlayerCollide(pmo, mo)
	local p = pmo.player
	local sp = mo.player

	if pmo.z > mo.z+mo.height then return end
	if mo.z > pmo.z+pmo.height then return end

	if p.heist.exiting
	or sp.heist.exiting then
		return
	end

	-- remove for friendly fire
	if p.heist:getTeam() == sp.heist:getTeam() then
		return
	end

	if IsInList(FangsHeist.Net.attacks, p)
	or pmo.state == S_FH_GUARD then
		return
	end

	if not IsInHitBox(pmo, mo) then
		return
	end

	if not P_PlayerCanDamage(p, mo) then
		return
	end

	if IsInList(ClashList, sp)
	or IsInList(FangsHeist.Net.attacks, sp) then
		return
	end

	if sp.mo.state == S_FH_GUARD
	and sp.heist.parry_time then
		RegisterGuard(sp, p)
		return
	end

	DefAttack(FangsHeist.Net.attacks, p, sp)
end

addHook("MobjMoveCollide", function(pmo, mo)
	if not FangsHeist.isMode() then return end
	if not (pmo and pmo.player and pmo.player.heist) then return end
	if (mo and mo.type == MT_PLAYER and mo.player and mo.player.heist) then
		OnPlayerCollide(pmo, mo)
		return
	end
end, MT_PLAYER)

return function(p)
	-- General handler for things like the Insta-Shield, and stuff.
	if p.mo and p.mo.valid then
		if not (p.mo.heistwhiff and p.mo.heistwhiff.valid) then
			p.mo.heistwhiff = nil
		end
	end

	if not p.heist:isAlive() then
		if p.mo
		and p.mo.valid
		and p.mo.translation == "FH_ParryColor" then
			p.mo.translation = nil
		end

		p.heist.parry_time = 0
		p.heist.perf_parry_time = 0

		if p.mo
		and p.mo.valid
		and p.mo.heistwhiff then
			P_RemoveMobj(p.mo.heistwhiff)
			p.mo.heistwhiff = nil
		end

		return
	end

	if p.mo.heistwhiff then
		P_MoveOrigin(p.mo.heistwhiff,
			p.mo.x+p.mo.momx,
			p.mo.y+p.mo.momy,
			p.mo.z+p.mo.momz)
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
		-- Whiff
		if press & BT_ATTACK
		and p.heist.attack_cooldown == 0 then
			DoWhiff(p)
		end
	
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

	if p.heist.attack_time then
		p.heist.attack_time = $-1
		WhiffAttack(p)
	end
end

--[[local instashields = {}

addHook("NetVars", function(n)
	instashields = n($)
end)

rawset(_G, "FH_ATTACKCOOLDOWN", TICRATE)
rawset(_G, "FH_ATTACKTIME", G)
rawset(_G, "FH_PARRYCOOLDOWN", TICRATE*2)
rawset(_G, "FH_PARRYTIME", TICRATE)
rawset(_G, "FH_PARRYSUCCESS", 25)
rawset(_G, "FH_PARRYAIRSUCCESS", 17)

for i = 1,4 do
	sfxinfo[freeslot("sfx_dmga"..i)].caption = "Attack"
	sfxinfo[freeslot("sfx_dmgb"..i)].caption = "Attack"
end
for i = 1,2 do
	sfxinfo[freeslot("sfx_parry"..i)].caption = "Parry"
end
function A_FHGuardAnim(mo)
	mo.frame = ($ & ~FF_FRAMEMASK)|C

	if P_IsObjectOnGround(mo) then
		mo.tics = FH_PARRYTIME
	end

	mo.translation = "FH_ParryColor"
	S_StartSound(mo, sfx_s1c1)

	if not (mo and mo.player and mo.player.valid and mo.player.heist) then
		return
	end

	local heist = mo.player.heist

	heist.parry_time = P_IsObjectOnGround(mo) and FH_PARRYSUCCESS or FH_PARRYAIRSUCCESS
	heist.parry_cooldown = FH_PARRYCOOLDOWN
end

states[freeslot "S_FH_GUARD"] = {
	sprite = SPR_PLAY,
	frame = SPR2_TRNS,
	tics = -1,
	action = A_FHGuardAnim,
	nextstate = S_PLAY_FALL
}

local attackSounds = {
	{sfx_dmga1, sfx_dmgb1},
	{sfx_dmga2, sfx_dmgb2},
	{sfx_dmga3, sfx_dmgb3},
	{sfx_dmga4, sfx_dmgb4}
}

addHook("ThinkFrame", do
	if #instashields then
		for i = #instashields,1,-1 do
			local shield = instashields[i]
	
			if not (shield and shield.valid) then
				table.remove(instashields, i)
				continue
			end
			if not (shield.target and shield.target.valid and shield.target.health) then
				P_RemoveMobj(shield)
				table.remove(instashields, i)
				continue
			end
	
			P_MoveOrigin(shield,
				shield.target.x,
				shield.target.y,
				shield.target.z)
		end
	end
end)

local function L_ReturnThrustXYZ(mo, point, speed)
	local horz = R_PointToAngle2(mo.x, mo.y, point.x, point.y)
	local vert = R_PointToAngle2(0, mo.z, FixedHypot(mo.x-point.x, mo.y-point.y), point.z)

	local x = FixedMul(FixedMul(speed, cos(horz)), cos(vert))
	local y = FixedMul(FixedMul(speed, sin(horz)), cos(vert))
	local z = FixedMul(speed, sin(vert))

	return x, y, z
end

local function L_ClaireThrustXYZ(mo,xyangle,zangle,speed,relative)
	local xythrust = P_ReturnThrustX(nil,zangle,speed)
	local zthrust = P_ReturnThrustY(nil,zangle,speed)
	if relative then
		P_Thrust(mo,xyangle,xythrust)		
		mo.momz = $+zthrust	
	else
		P_InstaThrust(mo,xyangle,xythrust)		
		mo.momz = zthrust	
	end
	return xythrust, zthrust
end

local function armaDamage(mo, found)
	if not (found and found.valid and found.health) then
		return
	end
	if found.type ~= MT_PLAYER then return end
	if R_PointToDist2(mo.x, mo.y, found.x, found.y) > 1536*FU then
		return
	end
	if not found.player then return end
	if mo.player.heist:isPartOfTeam(found.player) then
		return
	end

	P_DamageMobj(found, mo, mo)
end

addHook("ShieldSpecial", function(p)
	if not FangsHeist.isMode() then
		return
	end
	if not p.heist then return end
	if p.powers[pw_shield] ~= SH_ARMAGEDDON then
		return
	end

	searchBlockmap("objects",
		armaDamage,
		p.mo,
		p.mo.x-2048*FU,
		p.mo.x+2048*FU,
		p.mo.y-2048*FU,
		p.mo.y+2048*FU
	)
end)

return function(p)
	if not p.heist:isAlive() then
		p.heist.blocking = false
		return
	end

	local char = FangsHeist.Characters[p.mo.skin]
	local gamemode = FangsHeist.getGamemode()

	local flags = STR_ATTACK|STR_BUST
	if p.heist.attack_time then
		p.heist.attack_time = max(0, $-1)

		if not p.heist.strong_attack then
			p.powers[pw_strong] = $|flags
			p.heist.strong_attack = true
		end
	end
	if not p.heist.attack_time
	and p.heist.strong_attack then
		p.heist.strong_attack = false
		p.powers[pw_strong] = $ & ~flags
	end

	if p.heist.attack_cooldown then
		p.heist.attack_cooldown = max(0, $-1)

		if p.heist.attack_cooldown == 0 then
			local ghost = P_SpawnGhostMobj(p.mo)
			ghost.destscale = 4*FU

			S_StartSound(p.mo, sfx_ngskid)
		end
	end

	if p.heist.parry_cooldown then
		p.heist.parry_cooldown = max(0, $-1)

		if p.heist.parry_cooldown == 0 then
			local ghost = P_SpawnGhostMobj(p.mo)
			ghost.destscale = 4*FU
			ghost.translation = "FH_ParryColor"

			S_StartSound(p.mo, sfx_ngskid)
		end
	end

	if p.heist:isGuarding() then
		p.heist.parry_time = max(0, $-1)

		if p.heist.parry_time then
			p.mo.translation = "FH_ParryColor"
		else
			p.mo.translation = nil
		end

		if P_IsObjectOnGround(p.mo) then
			p.pflags = $|PF_FULLSTASIS
		end
	else
		p.mo.translation = nil
		p.heist.parry_time = 0
	end

	-- attacking
	if p.heist.attack_cooldown == 0
	and p.cmd.buttons & BT_ATTACK
	and not (p.lastbuttons & BT_ATTACK)
	and not P_PlayerInPain(p)
	and not p.heist:isGuarding()
	and char.useDefaultAttack then
		p.heist.attack_cooldown = char.attackCooldown
		p.heist.attack_time = FH_ATTACKTIME

		local shield = P_SpawnMobjFromMobj(p.mo, 0,0,0, MT_THOK)
		shield.state = char.attackEffectState
		shield.target = p.mo
		table.insert(instashields, shield)

		S_StartSound(p.mo, sfx_s3k42)
	end

	if p.cmd.buttons & BT_FIRENORMAL
	and not (p.lastbuttons & BT_FIRENORMAL)
	and not P_PlayerInPain(p)
	and not p.heist:isGuarding()
	and p.heist.parry_cooldown == 0
	and p.heist.attack_cooldown == 0
	and char.useDefaultGuard then
		p.mo.state = S_FH_GUARD
	end

	if char:isAttacking(p)
	and gamemode.pvp then
		local player, speed, parried = p.heist:damagePlayers()

		if player
		and not parried
		and HeistHook.runHook("PlayerHit", p, player, speed, parried) ~= true then
			-- stop attack
			p.heist.attack_time = 0

			if not parried then
				if speed ~= false then
					local tier = max(1, min(FixedDiv(speed, 10*FU)/FU, #attackSounds))
					local sound = attackSounds[tier][P_RandomRange(1, 2)]
	
					S_StartSound(p.mo, sound)
	
					p.heist.attack_cooldown = 0
				end
	
				local angle = R_PointToAngle2(p.mo.x, p.mo.y, player.mo.x, player.mo.y)
		
				if P_IsObjectOnGround(p.mo) then
					p.mo.state = S_PLAY_STND
					P_InstaThrust(p.mo, angle, -10*FU)
					p.pflags = $ & ~(PF_SPINNING|PF_STARTDASH)
				else
					p.pflags = $|PF_SPINNING
					p.pflags = $ & ~(PF_JUMPED|PF_STARTJUMP|PF_THOKKED|PF_BOUNCING|PF_GLIDING)
					p.mo.state = S_PLAY_FALL
					P_InstaThrust(p.mo, angle, -10*FU)
				end
			end
		end

		if player
		and parried then
			local angle = R_PointToAngle2(p.mo.x, p.mo.y, player.mo.x, player.mo.y)

			P_DoPlayerPain(p)
			p.drawangle = angle
			P_InstaThrust(p.mo, angle, -45*FU)
			P_SetObjectMomZ(p.mo, 13*p.mo.scale)
			p.heist.attack_cooldown = char.attackCooldown
		end
	end
end]]