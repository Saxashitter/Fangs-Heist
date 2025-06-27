freeslot(
	'mt_controlpoint',
	'mt_cpbonus',
	's_cpbonus',
	'spr_cpbs'
)

// Control point object
mobjinfo[MT_CONTROLPOINT] = {
	//$Name "Control Point"
	//$Sprite EMBMA0
	//$Category "BattleMod Control Point"
	doomednum = 3640,
	spawnstate = S_EMBLEM1,
	height = 32*FRACUNIT,
	radius = 24*FRACUNIT,
	flags = MF_NOGRAVITY|MF_SCENERY
}

// Control point object's bonus sphere graphic
mobjinfo[MT_CPBONUS] = {
	spawnstate = S_CPBONUS,
	flags = MF_NOGRAVITY|MF_NOBLOCKMAP|MF_NOCLIPHEIGHT
}

states[S_CPBONUS] = {
	sprite = SPR_CPBS,
	frame = A|FF_FULLBRIGHT|FF_TRANS10,
	tics = 0,
	nextstate = S_CPBONUS
}