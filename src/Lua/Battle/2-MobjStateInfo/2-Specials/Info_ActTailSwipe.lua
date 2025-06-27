freeslot(
	's_play_tailsfly'
)
states[S_PLAY_TAILSFLY] = {
	sprite = SPR_PLAY,
	frame = SPR2_FLY,
	tics = 2,
	nextstate = S_PLAY_TAILSFLY
}

freeslot(
	's_play_tailswipe',
	'spr2_tswp'
)
states[S_PLAY_TAILSWIPE] = {
	sprite = SPR_PLAY,
	frame = SPR2_TSWP,
	tics = 1,
	nextstate = S_PLAY_TAILSWIPE
}
freeslot(
	'mt_sonicboom',
	'spr_guil',
	's_sonicboom1',
	's_sonicboom2',
	's_sonicboom3',
	's_sonicboom4'
)
mobjinfo[MT_SONICBOOM] = {
	spawnstate = S_SONICBOOM1,
	speed = 20*FRACUNIT,
	radius = 32*FRACUNIT,
	height = 16*FRACUNIT,
	mass = 0,
	damage = 0,
	flags = MF_MISSILE|MF_NOGRAVITY|MF_NOBLOCKMAP|MF_BOUNCE|MF_GRENADEBOUNCE
}
mobjinfo[MT_SONICBOOM].hit_sound = sfx_hit02

states[S_SONICBOOM1] = {
	sprite = SPR_GUIL,
	frame = A,
	tics = 1,
	nextstate = S_SONICBOOM2
}
states[S_SONICBOOM2] = {
	sprite = SPR_GUIL,
	frame = B,
	tics = 1,
	nextstate = S_SONICBOOM3
}
states[S_SONICBOOM3] = {
	sprite = SPR_GUIL,
	frame = C,
	tics = 1,
	nextstate = S_SONICBOOM4
}
states[S_SONICBOOM4] = {
	sprite = SPR_GUIL,
	frame = D,
	tics = 1,
	nextstate = S_SONICBOOM1
}