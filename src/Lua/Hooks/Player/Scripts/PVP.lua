local instashields = {}

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

addHook("ShouldDamage", function(t,i,s,dmg,dt)
	if not FangsHeist.isMode() then return end
	if not (t and t.player and t.player.heist) then return end
	
	if t.player.heist.exiting then
		return false
	end

	if dt == DMG_WATER then
		return false
	end

	local char = FangsHeist.Characters[t.skin]
	local damage = FH_BLOCKDEPLETION
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
			
			damage = $/5
			forced = true
		end
	end
	
	if t.player.heist:isGuarding()
	and t.player.heist.parry_time
	and canDamage then
		return false
	end

	return forced
end, MT_PLAYER)

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
end