freeslot(
	'mt_crawlamissile',
	'mt_bashmissile',
	'mt_jetjawmissile',
	's_crawlamissile1',
	's_crawlamissile2',
	's_crawlamissile3',
	's_bashmissile1',
	's_bashmissile2',
	's_bashmissile3',
	's_bashmissile4',
	's_jetjawmissile1',
	's_jetjawmissile2',
	's_jetjawmissile3',
	's_jetjawmissile4',
	'spr_gpos',
	'spr_gbsh',
	'spr_gjaw'
)
	
//Tails' assist sentry
mobjinfo[MT_CRAWLAMISSILE] = {
	spawnstate = S_CRAWLAMISSILE1,
	deathstate = S_BUMBLEBORE_DIE,
	spawnhealth = 1,
	deathsound = sfx_pop,
	speed = 4*FRACUNIT,
	radius = 20*FRACUNIT,
	height = 24*FRACUNIT,
	flags = MF_MISSILE|MF_NOCLIPHEIGHT|MF_SHOOTABLE
}

mobjinfo[MT_BASHMISSILE] = {
	spawnstate = S_BASHMISSILE1,
	deathstate = S_BUMBLEBORE_DIE,
	spawnhealth = 1,
	deathsound = sfx_pop,
	speed = 4*FRACUNIT,
	radius = 20*FRACUNIT,
	height = 24*FRACUNIT,
	flags = MF_MISSILE|MF_NOGRAVITY|MF_SHOOTABLE
}

mobjinfo[MT_JETJAWMISSILE] = {
	spawnstate = S_JETJAWMISSILE1,
	deathstate = S_BUMBLEBORE_DIE,
	spawnhealth = 1,
	deathsound = sfx_pop,
	speed = 4*FRACUNIT,
	radius = 20*FRACUNIT,
	height = 24*FRACUNIT,
	flags = MF_MISSILE|MF_NOGRAVITY|MF_SHOOTABLE
}


states[S_CRAWLAMISSILE1] = {
	sprite = SPR_GPOS,
	frame = A,
	tics = 1,
	nextstate = S_CRAWLAMISSILE2
}

states[S_CRAWLAMISSILE2] = {
	sprite = SPR_GPOS,
	frame = B,
	tics = 1,
	nextstate = S_CRAWLAMISSILE3
}

states[S_CRAWLAMISSILE3] = {
	sprite = SPR_GPOS,
	frame = C,
	tics = 1,
	nextstate = S_CRAWLAMISSILE1
}


states[S_BASHMISSILE1] = {
	sprite = SPR_GBSH,
	frame = A,
	tics = 1,
	nextstate = S_BASHMISSILE2
}

states[S_BASHMISSILE2] = {
	sprite = SPR_GBSH,
	frame = B,
	tics = 1,
	nextstate = S_BASHMISSILE3
}

states[S_BASHMISSILE3] = {
	sprite = SPR_GBSH,
	frame = C,
	tics = 1,
	nextstate = S_BASHMISSILE4
}

states[S_BASHMISSILE4] = {
	sprite = SPR_GBSH,
	frame = D,
	tics = 1,
	nextstate = S_BASHMISSILE1
}

states[S_JETJAWMISSILE1] = {
	sprite = SPR_GJAW,
	frame = A,
	tics = 1,
	nextstate = S_JETJAWMISSILE2
}

states[S_JETJAWMISSILE2] = {
	sprite = SPR_GJAW,
	frame = B,
	tics = 1,
	nextstate = S_JETJAWMISSILE3
}

states[S_JETJAWMISSILE3] = {
	sprite = SPR_GJAW,
	frame = C,
	tics = 1,
	nextstate = S_JETJAWMISSILE4
}

states[S_JETJAWMISSILE4] = {
	sprite = SPR_GJAW,
	frame = D,
	tics = 1,
	nextstate = S_JETJAWMISSILE1
}

