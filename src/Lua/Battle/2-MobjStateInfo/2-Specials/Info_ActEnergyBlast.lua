-- Metal Sonic charging energy
freeslot('SPR2_PATK', 'S_PLAY_PREPATK')
spr2defaults[SPR2_PATK] = SPR2_ROLL
states[S_PLAY_PREPATK] = {
	sprite = SPR_PLAY,
	frame = SPR2_PATK,
	tics = 4,
	nextstate = S_PLAY_PREPATK
}
freeslot(
	'mt_energyblast',
	'mt_energyaura',
	'mt_energygather'
)

//Metal Sonic's Energy Blast

mobjinfo[MT_ENERGYBLAST] = {
	spawnstate = S_ENERGYBALL1,
	spawnhealth = 1000,
	reactiontime = 8,
	speed = 36*FRACUNIT,
	radius = 24*FRACUNIT,
	height = 48*FRACUNIT,
	mass = 0,
	damage = 0,
	flags = MF_MISSILE|MF_NOGRAVITY|MF_NOBLOCKMAP
}
mobjinfo[MT_ENERGYBLAST].hit_sound = sfx_hit01

mobjinfo[MT_ENERGYAURA] = {
	spawnstate = S_MSSHIELD_F1,
	dispoffset = 2,
	flags = MF_NOBLOCKMAP|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY|MF_SCENERY
}

mobjinfo[MT_ENERGYGATHER] = {
	spawnstate = S_JETFUME1,
	dispoffset = -1,
	flags = MF_NOBLOCKMAP|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY|MF_SCENERY
}