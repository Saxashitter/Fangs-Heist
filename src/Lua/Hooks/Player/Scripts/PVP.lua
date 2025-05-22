local instashields = {}

addHook("NetVars", function(n)
	instashields = n($)
end)

rawset(_G, "FH_ATTACKCOOLDOWN", TICRATE)
rawset(_G, "FH_ATTACKTIME", G)
rawset(_G, "FH_BLOCKCOOLDOWN", 5)
rawset(_G, "FH_BLOCKTIME", 3*TICRATE)
rawset(_G, "FH_BLOCKDEPLETION", FH_BLOCKTIME/3)

for i = 1,4 do
	sfxinfo[freeslot("sfx_dmga"..i)].caption = "Attack"
	sfxinfo[freeslot("sfx_dmgb"..i)].caption = "Attack"
end
sfxinfo[freeslot"sfx_fhboff"].caption = "Block disabled"
sfxinfo[freeslot"sfx_fhbonn"].caption = "Block enabled"
sfxinfo[freeslot"sfx_fhbbre"].caption = "Block broken"

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

local function manageBlockMobj(p)
	if not (p.heist.blockMobj and p.heist.blockMobj.valid) then
		p.heist.blockMobj = nil
	end

	if not FangsHeist.Net.pregame then
		if p.heist.spawn_time then
			p.powers[pw_flashing] = TICRATE
		end
		p.heist.spawn_time = max(0, $-1)
	end

	if not FangsHeist.isPlayerAlive(p) then
		if p.heist.blockMobj then
			P_RemoveMobj(p.heist.blockMobj)
			p.heist.blockMobj = nil
		end

		return
	end

	local char = FangsHeist.Characters[p.mo.skin]

	if p.heist.blocking then
		if not p.heist.blockMobj then
			local shield = P_SpawnMobjFromMobj(p.mo, 0,0,0, MT_THOK)
			shield.state = char.blockShieldState
			shield.dispoffset = 10
			shield.flags = MF_NOTHINK
			shield.spriteyoffset = -2*FU
			shield.colorized = true

			p.heist.blockMobj = shield
		end

		local t = FixedDiv(p.heist.block_time, FH_BLOCKTIME*2)
		local scale = FixedDiv(p.mo.height, 48*FU)

		p.heist.blockMobj.scale = ease.linear(t, scale, 0)
		p.heist.blockMobj.color = p.mo.color

		local z = ease.linear(t, 0, p.mo.height/2)
		P_MoveOrigin(p.heist.blockMobj,
			p.mo.x, p.mo.y, p.mo.z+z)
	else
		if p.heist.blockMobj then
			P_RemoveMobj(p.heist.blockMobj)
			p.heist.blockMobj = nil
		end
	end
end

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
	if FangsHeist.isPartOfTeam(mo.player, found.player) then
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

	
	if char:isBlocking(t.player)
	and canDamage then
		local blocking = not FangsHeist.depleteBlock(t.player, damage)

		if blocking then
			if i
			and i.valid then
				if i.flags & MF_MISSILE then
					i.target = t

					--[[P_InstaThrust(i,
						InvAngle(R_PointToAngle2(0,0, i.momx, i.momy)),
						R_PointToDist2(0,0, i.momx, i.momy))
					i.momz = -$]]

					local speed = R_PointToDist2(
						0,0,
						R_PointToDist2(0,0, i.momx, i.momy),
						i.momz
					)
					local horz = R_PointToAngle2(i.x, i.y, t.x, t.y)
					local vert = R_PointToAngle2(0, i.z+(i.height/2), speed, t.z+(t.height/2))

					L_ClaireThrustXYZ(i, InvAngle(horz), InvAngle(vert), speed)
				end
			end

			t.player.powers[pw_flashing] = TICRATE
			return false
		end
	end

	return forced
end, MT_PLAYER)

return function(p)
	manageBlockMobj(p)
	if not FangsHeist.isPlayerAlive(p) then
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
	p.heist.block_cooldown = max(0, $-1)

	-- attacking
	if p.heist.attack_cooldown == 0
	and p.cmd.buttons & BT_ATTACK
	and not (p.lastbuttons & BT_ATTACK)
	and not p.heist.blocking
	and not P_PlayerInPain(p)
	and char.useDefaultAttack then
		p.heist.attack_cooldown = char.attackCooldown
		p.heist.attack_time = FH_ATTACKTIME

		local shield = P_SpawnMobjFromMobj(p.mo, 0,0,0, MT_THOK)
		shield.state = char.attackEffectState
		shield.target = p.mo
		table.insert(instashields, shield)

		S_StartSound(p.mo, sfx_s3k42)
	end

	-- blocking
	if not p.heist.blocking then
		p.heist.block_time = max(0, $-2)

		if p.heist.block_cooldown == 0
		and p.heist.attack_cooldown == 0
		and p.cmd.buttons & BT_FIRENORMAL
		and not P_PlayerInPain(p)
		and char.useDefaultBlock then
			p.heist.block_cooldown = FH_BLOCKCOOLDOWN
			S_StartSound(p.mo, sfx_fhbonn)
			p.heist.blocking = true
		end
	else
		p.heist.block_time = min($+1, FH_BLOCKTIME)

		if p.heist.block_cooldown == 0
		and not (p.cmd.buttons & BT_FIRENORMAL) then
			p.heist.block_cooldown = FH_BLOCKCOOLDOWN
			S_StartSound(p.mo, sfx_fhboff)
			p.heist.blocking = false
		end
	end

	if char:isAttacking(p)
	and gamemode.pvp then
		local player, speed = FangsHeist.damagePlayers(p)

		if player
		and HeistHook.runHook("PlayerHit", p, player, speed) ~= true then
			-- stop attack
			p.heist.attack_time = 0

			if speed ~= false then
				local tier = max(1, min(FixedDiv(speed, 10*FU)/FU, #attackSounds))
				local sound = attackSounds[tier][P_RandomRange(1, 2)]

				S_StartSound(p.mo, sound)

				p.heist.attack_cooldown = 0
				p.heist.block_time = max(0, $-20)
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
end