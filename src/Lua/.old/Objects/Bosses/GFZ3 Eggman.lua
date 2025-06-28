freeslot"MT_FH_EGGMAN_BOSS1"
freeslot"S_FH_EGGMAN_BOSS1_IDLE"
freeslot"S_FH_EGGMAN_BOSS1_PREP"
freeslot"S_FH_EGGMAN_BOSS1_ATTACK"

local IDLE_FRAME = A
local PREP_FRAME = C
local ATTACK_FRAME = N
local DAMAGE_COOLDOWN = 9

local PHASES = {
	{
		health = 25,
		attacks = {"attack1"},
		music = "BLODRA"
	}
}

mobjinfo[MT_FH_EGGMAN_BOSS1] = {
	radius = mobjinfo[MT_EGGMOBILE].radius,
	height = mobjinfo[MT_EGGMOBILE].height,
	spawnstate = S_FH_EGGMAN_BOSS1_IDLE,
	flags = MF_NOGRAVITY
}

states[S_FH_EGGMAN_BOSS1_IDLE] = {
	sprite = SPR_EGGM,
	frame = IDLE_FRAME,
	tics = -1
}
states[S_FH_EGGMAN_BOSS1_PREP] = {
	sprite = SPR_EGGM,
	frame = PREP_FRAME,
	tics = -1
}
states[S_FH_EGGMAN_BOSS1_ATTACK] = {
	sprite = SPR_EGGM,
	frame = ATTACK_FRAME,
	tics = -1
}

local EGGMAN_STATES = {}

-- Mobj behavior.
local function change_state(mo, state)
	if type(state) ~= "string" then
		return
	end

	local newState = EGGMAN_STATES[state]
	if not newState then return end

	if mo.eggState then
		local prevState = EGGMAN_STATES[mo.eggState]

		if prevState and prevState.exit then
			prevState.exit(mo)
		end
	end

	mo.state = newState.state or S_FH_EGGMAN_BOSS1_IDLE

	if newState and newState.enter then
		newState.enter(mo)
	end

	mo.eggState = state
	mo.attackable = newState.attackable
	return true
end

local function set_phase(mo, phase)
	if not PHASES[phase] then
		return
	end

	local phaseData = PHASES[phase]

	mo.phase = phase
	mo.bossHealth = phaseData.health

	if mapmusname ~= phaseData.music then
		mapmusname = phaseData.music
		S_ChangeMusic(mapmusname, true)
	end
end

local function get_random_attack(mo)
	local phase = PHASES[mo.phase]

	return phase.attacks[P_RandomRange(1, #phase.attacks)]
end

local function makeEggState(name, state, attackable, enter, think, exit, switch)
	EGGMAN_STATES[name] = {
		state = state,
		attackable = (attackable),
		enter = enter,
		think = think,
		exit = exit,
		switch = switch
	}
end

-- Idle state.
local function EGGMAN_IDLE_ENTER(mo)
	mo.timeToSwitch = 5*TICRATE
end
local function EGGMAN_IDLE_THINK(mo)
	mo.timeToSwitch = max(0, $-1)
end
local function EGGMAN_IDLE_EXIT(mo)
	mo.timeToSwitch = nil
end
local function EGGMAN_IDLE_SWITCH(mo)
	if mo.timeToSwitch == 0 then
		return get_random_attack(mo)
	end
end

makeEggState("idle",
	S_FH_EGGMAN_BOSS1_IDLE,
	false,
	EGGMAN_IDLE_ENTER,
	EGGMAN_IDLE_THINK,
	EGGMAN_IDLE_EXIT,
	EGGMAN_IDLE_SWITCH)

-- Attack state.
local function EGGMAN_ATTACK1_ENTER(mo)
	mo.timeToAttack = 3*TICRATE
	mo.attackTime = 3*TICRATE
	mo.missiles = 3
	mo.missileDelay = 0
	mo.origPos = {x = mo.x, y = mo.y, z = mo.z}
	mo.tween = 0
	mo.turnAngle = 0

	local availablePlayers = {}
	for p in players.iterate do
		if FangsHeist.isPlayerAlive(p) then
			table.insert(availablePlayers, p)
		end
	end

	if #availablePlayers then
		mo.chosenPlayer = availablePlayers[P_RandomRange(1,#availablePlayers)]
	end
end

local function EGGMAN_ATTACK1_THINK(mo)
	mo.tween = min($+FU/7, FU)

	if not FangsHeist.isPlayerAlive(mo.chosenPlayer) then
		return
	end

	local pmo = mo.chosenPlayer.mo
	local t = mo.tween

	if mo.timeToAttack then
		mo.turnAngle = $ + (ANG1*7)
		local dx = 150*cos(mo.turnAngle)
		local dy = 150*sin(mo.turnAngle)
	
		local x = ease.outcubic(t, mo.origPos.x, pmo.x+dx)
		local y = ease.outcubic(t, mo.origPos.y, pmo.y+dy)
		local z = ease.outcubic(t, mo.origPos.z, pmo.z+24*FU)
	
		P_MoveOrigin(mo, x, y, z)
		mo.angle = R_PointToAngle2(mo.x, mo.y, pmo.x, pmo.y)

		mo.timeToAttack = max(0, $-1)

		if mo.timeToAttack == 0 then
			mo.state = S_FH_EGGMAN_BOSS1_ATTACK
		end
	else
		if not (mo.missileDelay) then
			if mo.missiles then
				mo.missiles = $-1
				mo.missileDelay = 8

				local missile = P_SpawnMobj(mo.x, mo.y, mo.z, MT_FH_EGGMAN_MISSILE1)
				missile.target = mo.chosenPlayer.mo
				missile.tracer = mo

				S_StartSound(mo, sfx_thok)
			end
		else
			mo.missileDelay = max(0, $-1)
		end

		mo.attackTime = max(0, $-1)
	end
end

local function EGGMAN_ATTACK1_EXIT(mo)
	mo.timeToAttack = nil
	mo.attackTime = nil
	mo.origPos = nil
	mo.tween = nil
	mo.missiles = nil
	mo.missileDelay = nil
	mo.chosenPlayer = nil
end

local function EGGMAN_ATTACK1_SWITCH(mo)
	if not FangsHeist.isPlayerAlive(mo.chosenPlayer) then
		return "idle"
	end

	if not (mo.attackTime) then
		return "idle"
	end
end

local function EGGMAN_ATTACK1_DAMAGE(mo)
	if mo.damaged then return end

	mo.damaged = true
end

makeEggState("attack1",
	S_FH_EGGMAN_BOSS1_PREP,
	true,
	EGGMAN_ATTACK1_ENTER,
	EGGMAN_ATTACK1_THINK,
	EGGMAN_ATTACK1_EXIT,
	EGGMAN_ATTACK1_SWITCH)

-- Mobj hooks

addHook("MobjSpawn", function(mo)
	mo.damaged = 0
	mo.damage_cooldown = 0
	FangsHeist.Net.boss = mo
	set_phase(mo, 1)
	change_state(mo, "idle")
end, MT_FH_EGGMAN_BOSS1)

addHook("MobjThinker", function(mo)
	if FangsHeist.Net.pregame then return end

	if not (mo.eggState and EGGMAN_STATES[mo.eggState]) then
		return
	end

	local state = EGGMAN_STATES[mo.eggState]
	local switch = state and state.switch and state.switch(mo)

	if state.think then
		state.think(mo)
	end

	if switch then
		change_state(mo, switch)
	end

	if not (mo.damage_cooldown) then
		for p in players.iterate do
			if not (p and p.mo and p.mo.health) then continue end
	
			if FixedHypot(p.mo.x-mo.x, p.mo.y-mo.y) <= p.mo.radius+mo.radius
			and mo.z+mo.height >= p.mo.z
			and p.mo.z+p.mo.height >= mo.z then
				if P_PlayerCanDamage(p, mo) then
					mo.damage_cooldown = DAMAGE_COOLDOWN
					mo.bossHealth = max(0, $-1)
					print "OUCH"
	
					if mo.bossHealth == 0 then
						local nextPhase = PHASES[mo.phase+1]

						if nextPhase then
							set_phase(mo, mo.phase+1)
						else
							FangsHeist.startIntermission()
							return
						end
					end

					p.mo.momx = $*-1
					p.mo.momy = $*-1
					p.mo.momz = $*-1

					if mo.attackable
					and mo.eggState ~= "idle" then
						change_state(mo, "idle")
					end
	
					break
				end
			end
		end 
	end

	mo.damage_cooldown = max(0, $-1)

	local t = FixedDiv(mo.damage_cooldown, DAMAGE_COOLDOWN)

	mo.spritexoffset = P_RandomRange(-16, 16)*t
	mo.spriteyoffset = P_RandomRange(-16, 16)*t
end, MT_FH_EGGMAN_BOSS1)

addHook("MapThingSpawn", function(mo)
	if not FangsHeist.isMode() then return end

	P_SpawnMobj(mo.x,mo.y,mo.z, MT_FH_EGGMAN_BOSS1)
	if mo and mo.valid then
		P_RemoveMobj(mo)
	end
end, MT_EGGMOBILE)