// YEAAAAAAH EGGMAAAAAAN

// alerts for when eggman targets you
local alerts = {}

local function alertZPos(mo)
	local height = mo.height + 24*mo.scale
	local z = mo.z

	if mo.player
	and mo.player.heist then
		if mo.player.heist:hasSign() then
			height = $+48*mo.scale
		end
		height = $+24*#mo.player.heist.treasures
	end

	return z, height
end
addHook("ThinkFrame", do
	if not #alerts then return end

	for i = #alerts, 1, -1 do
		local alert = alerts[i]

		if not (alert
		and alert.valid) then
			table.remove(alerts, i)
			continue
		end

		if not (alert.target
		and alert.target.health) then
			table.remove(alerts, i)
			P_RemoveMobj(alert)
			continue
		end

		local z, height = alertZPos(alert.target)

		alert.scale = alert.target.scale
		alert.flags = $|MF_NOGRAVITY|MF_NOCLIP|MF_NOCLIPHEIGHT
		P_MoveOrigin(alert,
			alert.target.x,
			alert.target.y,
			z + height)
	end
end)

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
	local gamemode = FangsHeist.getGamemode()

	return p.heist
	and p.heist:isAlive()
	and not p.heist.exiting
	and not p.heist.spectator
	and gamemode:eggmanblacklist(p)
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

local function doAlert(mo)
	local z, height = alertZPos(mo)
	local alert = P_SpawnMobjFromMobj(mo, 0,0,height, MT_GHOST)

	S_StartSound(mo, sfx_alart)

	if not (alert and alert.valid) then
		return
	end

	alert.fuse = states[S_FANG_INTRO12].tics+10
	alert.state = S_ALART1
	alert.target = mo
	alert.dispoffset = 36
	table.insert(alerts, alert)
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
	mo._lastplayer = nil
	if not (mo.target
	and mo.target.valid
	and mo.target.health
	and mo.target.player
	and validCheck(mo.target.player)) then
		local p = getRandomPlayer()

		if not p then return end

		mo.target = p.mo
		mo.distance = 500*FU
		doAlert(p.mo)
		
		local target = mo.target
		local angle = R_PointToAngle2(mo.x, mo.y, target.x, target.y)

		P_MoveOrigin(mo,
			target.x + FixedMul(-mo.distance, cos(angle)),
			target.y + FixedMul(-mo.distance, sin(angle)),
			target.z+target.height/2-mo.height/2)
	end

	local target = mo.target

	local dist = FixedHypot(
		mo.x-target.x,
		mo.y-target.y
	)

	mo.distance = max(0, $ - ((500*FU) - target.radius)/(5*TICRATE))

	local x = mo.x
	local y = mo.y

	local angle = R_PointToAngle2(mo.x, mo.y, target.x, target.y)
	local aiming = R_PointToAngle2(
		0,
		mo.z+mo.height/2,
		FixedHypot(mo.x-target.x, mo.y-target.y),
		target.z+target.height/2
	)

	if dist > mo.distance then
		x = target.x + FixedMul(-mo.distance, cos(angle))
		y = target.y + FixedMul(-mo.distance, sin(angle))
	end

	P_MoveOrigin(mo,
		x,
		y,
		ease.linear(FU/8, mo.z, (target.z + target.height/2) - (mo.height/2)))
	mo.angle = angle

	if FixedHypot(mo.x-target.x, mo.y-target.y) < target.radius
	and mo.z < target.z+target.height
	and target.z < mo.z+mo.height then
		P_DamageMobj(target, mo, mo, 999, DMG_INSTAKILL)
	end
end

local function L_ReturnThrustXYZ(mo, point, speed)
	local horz = R_PointToAngle2(mo.x, mo.y, point.x, point.y)
	local vert = R_PointToAngle2(0, mo.z+mo.height/2, FixedHypot(mo.x-point.x, mo.y-point.y), point.z)

	local x = FixedMul(FixedMul(speed, cos(horz)), cos(vert))
	local y = FixedMul(FixedMul(speed, sin(horz)), cos(vert))
	local z = FixedMul(speed, sin(vert))

	return x, y, z
end

local function PT_CHASE(mo)
	local p = getNearestPlayer(mo)
	if not p then return end

	if mo._lastplayer ~= p then
		doAlert(p.mo)
		mo._lastplayer = p
	end

	local target = p.mo

	local band = 1500*FU
	local speed = 25*FU

	if P_PlayerInPain(p) 
	or p.powers[pw_flashing] then
		speed = 6*FU
	elseif p.heist:isNerfed() then
		// We're a bitch, but not that big of a bitch.
		speed = 18*FU
	end

	local dist = FixedHypot(
		FixedHypot(mo.x-target.x, mo.y-target.y),
		(mo.z+mo.height/2)-(target.z+target.height/2)
	)

	if dist > band then
		// rubberbanding code from jisk, taken from ptsr
		speed = FixedMul($, FU+FixedDiv(dist - band, band))
	end

	local momx, momy, momz = L_ReturnThrustXYZ(mo, {
		x = target.x,
		y = target.y,
		z = target.z + (target.height/2)
	}, speed)

	mo.momx = momx
	mo.momy = momy
	mo.momz = momz
	mo.angle = R_PointToAngle2(mo.x, mo.y, target.x, target.y)

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