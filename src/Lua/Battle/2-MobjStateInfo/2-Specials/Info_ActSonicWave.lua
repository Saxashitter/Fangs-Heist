freeslot('MT_SONICWAVE', 'MT_SONICWAVETRAIL', 'S_SONICWAVE', 'S_SONICWAVETRAIL', 'SPR_SWAV')
mobjinfo[MT_SONICWAVE] = {
	spawnstate = S_SONICWAVE,
	radius = 16*FRACUNIT,
	height = 32*FRACUNIT,
	speed = 5*FRACUNIT, -- Starting speed
	reactiontime = 50,
	painchance = 60, -- Top speed (multiplied by scale)
	damage = 1,
	flags = MF_MISSILE|MF_NOGRAVITY|MF_NOBLOCKMAP
}

mobjinfo[MT_SONICWAVETRAIL] = {
	spawnstate = S_SONICWAVETRAIL,
	radius = 12*FRACUNIT,
	height = 32*FRACUNIT,
	damage = 1,
	flags = MF_MISSILE|MF_NOGRAVITY|MF_NOBLOCKMAP|MF_NOCLIP|MF_NOCLIPHEIGHT
-- 	flags = MF_SCENERY|MF_NOGRAVITY|MF_NOBLOCKMAP|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOCLIPTHING
}


states[S_SONICWAVE] = {
	tics = -1,
	sprite = SPR_SPLH,
-- 	sprite = SPR_JBUL,
-- 	sprite = SPR_SWAV,
-- 	frame = FF_ANIMATE,
-- 	var1 = 3,
-- 	var2 = 1,
-- 	nextstate = S_NULL
}

	// Water Splish
states[S_SONICWAVETRAIL] = {
	sprite = SPR_SPLH,
	frame = FF_ANIMATE,
	tics = 8,
	var1 = 7,
	var2 = 1
}