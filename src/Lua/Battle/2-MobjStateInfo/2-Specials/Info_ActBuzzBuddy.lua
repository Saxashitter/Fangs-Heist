freeslot('mt_buzzbuddy','s_buzzbuddy1','s_buzzbuddy2','spr_gbuz')

mobjinfo[MT_BUZZBUDDY] = {
	spawnstate = S_BUZZBUDDY1,
	deathstate = S_BUMBLEBORE_DIE,
	spawnhealth = 0,
	deathsound = sfx_pop,
	speed = 4*FRACUNIT,
	radius = 20*FRACUNIT,
	height = 24*FRACUNIT,
	flags = MF_ENEMY|MF_SPECIAL|MF_SHOOTABLE|MF_NOGRAVITY
}
states[S_BUZZBUDDY1] = {
	sprite = SPR_GBUZ,
	frame = 0,
	tics = 1,
	nextstate = S_BUZZBUDDY2
}

states[S_BUZZBUDDY2] = {
	sprite = SPR_GBUZ,
	frame = 1,
	tics = 1,
	nextstate = S_BUZZBUDDY1
}