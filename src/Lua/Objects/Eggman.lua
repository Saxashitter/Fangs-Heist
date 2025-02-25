// YEAAAAAAH EGGMAAAAAAN
// managed through game as well lmao

freeslot(
	"MT_FH_EGGMAN",
	"S_FH_EGGMAN_DOOMCHASE",
	"S_FH_EGGMAN_PTCHASE",
	"S_FH_EGGMAN_COOLDOWN"
)
local STATE_FUNCS = {}

mobjinfo[MT_FH_EGGMAN] = {
	radius = 32*FU,
	height = 32*FU,
	spawnstate = S_FH_EGGMAN_DOOMCHASE,
	flags = MF_NOGRAVITY|MF_NOCLIP|MF_NOCLIPHEIGHT
}

states[S_FH_EGGMAN_DOOMCHASE] = {
	sprite = SPR_EGGM,
	frame = A,
	tics = -1
}
states[S_FH_EGGMAN_PTCHASE] = {
	sprite = SPR_EGGM,
	frame = A,
	tics = -1
}
states[S_FH_EGGMAN_COOLDOWN] = {
	sprite = SPR_EGGM,
	frame = A,
	tics = 10*TICRATE,
	nextstate = S_FH_EGGMAN_PTCHASE
}

local function validCheck(p)
	return FangsHeist.isPlayerAlive(p)
	and not p.heist.exiting
	and not p.heist.spectator
end

local function getRandomPlayer()
	local randomPlayers = {}

	for p in players.iterate do
		if validCheck(p) then
			table.insert(randomPlayers, p)
		end
	end

	if #randomPlayers == 0 then
		return false
	end

	return randomPlayers[P_RandomRange(1, #randomPlayers)]
end

local function getNearestPlayer(mo)
	local player

	for p in players.iterate do
		if not validCheck(p) then
			continue
		end

		if player == nil then
			player = p
			continue
		end

		local dist1 = FixedHypot(
			FixedHypot(
				p.mo.x-mo.x,
				p.mo.y-mo.y
			),
			(p.mo.z + p.mo.height/2) - (mo.z + mo.height/2)
		)
		local dist2 = FixedHypot(
			FixedHypot(
				player.mo.x-mo.x,
				player.mo.y-mo.y
			),
			(player.mo.z + player.mo.height/2) - (mo.z + mo.height/2)
		)

		if dist1 < dist2 then
			player = p
		end
	end

	return player
end

local function isColliding(mo, smo)
	return mo.x-mo.radius < smo.x+smo.radius
	and mo.y-mo.radius < smo.y+smo.radius
	and mo.z < smo.z+smo.height
	and smo.x-smo.radius < mo.x+mo.radius
	and smo.y-smo.radius < mo.y+mo.radius
	and smo.z < mo.z+mo.height
end

local function canDamage(found)
	return found.type == MT_PLAYER
end

local function killObjects(mo, found)
	if not (found and found.valid) then return end
	if not canDamage(found) then return end
	if not isColliding(mo, found) then return end

	P_DamageMobj(found, mo, mo, 999, DMG_INSTAKILL)
end

// Endgame Chase
local function SET_POS(mo, target, dist)
	local angle = R_PointToAngle2(mo.x, mo.y, target.x, target.y)
	local aiming = R_PointToAngle2(
		0,
		mo.z+mo.height/2,
		FixedHypot(mo.x-target.x, mo.y-target.y),
		target.z+target.height/2
	)

	local x = FixedMul(FixedMul(-dist, cos(angle)), cos(aiming))
	local y = FixedMul(FixedMul(-dist, sin(angle)), cos(aiming))
	local z = FixedMul(-dist, sin(aiming))

	P_MoveOrigin(mo,
		target.x + x,
		target.y + y,
		target.z + (target.height/2) + z
	)
	mo.angle = angle
end

local function ENDGAME_CHASE(mo)
	if not (mo.target
	and mo.target.valid
	and mo.target.health
	and mo.target.player
	and validCheck(mo.target.player)) then
		local p = getRandomPlayer()

		if not p then return end

		mo.target = p.mo
		mo.distance = 500*FU
		SET_POS(mo, mo.target, mo.distance)
	end

	local target = mo.target

	local dist = FixedHypot(
		FixedHypot(
			mo.x-target.x,
			mo.y-target.y
		),
		(mo.z+mo.height/2) - (target.z+target.height/2)
	)

	mo.distance = max(0, $ - ((500*FU) - target.radius)/(5*TICRATE))

	if dist > mo.distance then
		SET_POS(mo, mo.target, mo.distance)
	end

	P_MoveOrigin(mo,
		mo.x,
		mo.y,
		ease.linear(FU/24, mo.z, (target.z + target.height/2) - (mo.height/2)))

	searchBlockmap("objects",
		killObjects,
		mo,
		mo.x-mo.radius*4,
		mo.x+mo.radius*4,
		mo.y-mo.radius*4,
		mo.y+mo.radius*4
	)
end

local function PT_CHASE(mo)
	local p = getNearestPlayer(mo)

	if not p then return end

	local target = p.mo

	local band = 1024*FU
	local speed = 30*FU

	if FangsHeist.playerHasSign(p) then
		// We're a bitch, but not that big of a bitch.
		speed = 18*FU
	end

	local angle = R_PointToAngle2(mo.x, mo.y, target.x, target.y)
	local aiming = R_PointToAngle2(
		0,
		mo.z+mo.height/2,
		FixedHypot(mo.x-target.x, mo.y-target.y),
		target.z+target.height/2
	)

	local x = mo.x + FixedMul(FixedMul(speed, cos(angle)), cos(aiming))
	local y = mo.y + FixedMul(FixedMul(speed, sin(angle)), cos(aiming))
	local z = mo.z + FixedMul(speed, sin(aiming))

	z = ease.linear(FU/24, $, target.z + (target.height/2) - (mo.height/2))

	P_MoveOrigin(mo,
		x,
		y,
		z)

	local dist = FixedHypot(
		FixedHypot(mo.x-target.x, mo.y-target.y),
		(mo.z+mo.height/2)-(target.z+target.height/2)
	)

	if dist > band then
		SET_POS(mo, target, band)
	end

	mo.angle = angle

	searchBlockmap("objects",
		killObjects,
		mo,
		mo.x-mo.radius*4,
		mo.x+mo.radius*4,
		mo.y-mo.radius*4,
		mo.y+mo.radius*4
	)
end

addHook("MobjThinker", function(mo)
	if not mo.valid then return end

	if mo.state == S_FH_EGGMAN_DOOMCHASE then
		ENDGAME_CHASE(mo)
	end
	if mo.state == S_FH_EGGMAN_PTCHASE then
		PT_CHASE(mo)
	end
end, MT_FH_EGGMAN)