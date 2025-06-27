freeslot(
	'spr_kdra',
	's_knuckles_drilldive1',
	's_knuckles_drilldive2',
	's_knuckles_drilldive3',
	's_knuckles_drilldive4',
	'spr_kdrb',
	's_knuckles_drillrise1',
	's_knuckles_drillrise2',
	's_knuckles_drillrise3',
	's_knuckles_drillrise4',
	'mt_rockblast'
)
//Knuckles Drill drive states
states[S_KNUCKLES_DRILLDIVE1] = {
	sprite = SPR_KDRA,
	frame = A
}

states[S_KNUCKLES_DRILLDIVE2] = {
	sprite = SPR_KDRA,
	frame = B
}

states[S_KNUCKLES_DRILLDIVE3] = {
	sprite = SPR_KDRA,
	frame = C
}

states[S_KNUCKLES_DRILLDIVE4] = {
	sprite = SPR_KDRA,
	frame = D
}

//Knuckles drill rise states

states[S_KNUCKLES_DRILLRISE1] = {
	sprite = SPR_KDRB,
	frame = A
}

states[S_KNUCKLES_DRILLRISE2] = {
	sprite = SPR_KDRB,
	frame = B
}

states[S_KNUCKLES_DRILLRISE3] = {
	sprite = SPR_KDRB,
	frame = C
}

states[S_KNUCKLES_DRILLRISE4] = {
	sprite = SPR_KDRB,
	frame = D
}


//Knuckles' Debris
mobjinfo[MT_ROCKBLAST] = {
	spawnstate = S_ROCKCRUMBLEA,
	spawnhealth = 1000,
	radius = 8*FRACUNIT,
	height = 16*FRACUNIT,
	mass = 0,
	damage = 0,
	flags = MF_MISSILE|MF_BOUNCE|MF_GRENADEBOUNCE
}


mobjinfo[MT_ROCKBLAST].hit_sound = sfx_hit00
mobjinfo[MT_ROCKBLAST].blockable = 1
mobjinfo[MT_ROCKBLAST].block_stun = 2
mobjinfo[MT_ROCKBLAST].block_sound = sfx_s3k49
mobjinfo[MT_ROCKBLAST].block_hthrust = 3
mobjinfo[MT_ROCKBLAST].block_vthrust = 3
