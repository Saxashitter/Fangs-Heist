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

	if not FangsHeist.isPlayerAlive(p) then
		if p.heist.blockMobj then
			P_RemoveMobj(p.heist.blockMobj)
			p.heist.blockMobj = nil
		end

		return
	end

	if p.heist.blocking then
		if not p.heist.blockMobj then
			local shield = P_SpawnMobjFromMobj(p.mo, 0,0,0, MT_THOK)
			shield.state = S_FH_SHIELD
			shield.dispoffset = 10
			shield.flags = MF_NOTHINK
			shield.spriteyoffset = -2*FU
			shield.colorized = true

			p.heist.blockMobj = shield
		end

		local t = FixedDiv(p.heist.block_time, FH_BLOCKTIME*2)
		local scale = FixedDiv(p.mo.height, 22*FU)

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

states[freeslot "S_FH_INSTASHIELD"] = {
	sprite = freeslot"SPR_TWSP",
	frame = A|FF_ANIMATE|FF_FULLBRIGHT,
	tics = G,
	var1 = G,
	var2 = 1
}

states[freeslot "S_FH_SHIELD"] = {
	sprite = freeslot"SPR_FHSH",
	frame = A|FF_FULLBRIGHT|FF_TRANS30,
	tics = -1
}

return function(p)
	manageBlockMobj(p)
	if not FangsHeist.isPlayerAlive(p) then
		p.heist.blocking = false
		return
	end

	local char = FangsHeist.Characters[p.mo.skin]

	if p.heist.attack_time then
		p.heist.attack_time = max(0, $-1)

		if p.heist.attack_time == 0 then
			p.powers[pw_strong] = $|STR_ATTACK
		else
			p.powers[pw_strong] = $|STR_ATTACK
		end
	end
			
	p.heist.attack_cooldown = max(0, $-1)
	p.heist.block_cooldown = max(0, $-1)

	-- attacking
	if p.heist.attack_cooldown == 0
	and p.cmd.buttons & BT_ATTACK
	and not (p.lastbuttons & BT_ATTACK)
	and not p.heist.blocking
	and char.useDefaultAttack then
		p.heist.attack_cooldown = char.attackCooldown
		p.heist.attack_time = FH_ATTACKTIME

		local shield = P_SpawnMobjFromMobj(p.mo, 0,0,0, MT_THOK)
		shield.state = S_FH_INSTASHIELD
		shield.target = p.mo
		table.insert(instashields, shield)

		S_StartSound(p.mo, sfx_s3k42)
	end

	-- blocking
	if not p.heist.blocking then
		p.heist.block_time = max(0, $-2)

		if p.heist.block_cooldown == 0
		and p.cmd.buttons & BT_FIRENORMAL then
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


	if char:isAttacking(p) then
		p.heist.attack_time = 0

		local player, speed = FangsHeist.damagePlayers(p)

		if player then
			if speed ~= false then
				local tier = max(1, min(FixedDiv(speed, 10*FU)/FU, #attackSounds))
				local sound = attackSounds[tier][P_RandomRange(1, 2)]

				S_StartSound(p.mo, sound)
			end

			local angle = R_PointToAngle2(p.mo.x, p.mo.y, player.mo.x, player.mo.y)
	
			if P_IsObjectOnGround(p.mo) then
				p.mo.state = S_PLAY_STND
				P_InstaThrust(p.mo, angle, -10*FU)
			else
				p.mo.state = S_PLAY_FALL
				P_InstaThrust(p.mo, angle, -10*FU)
			end
		end
	end
end