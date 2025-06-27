-- Battle Twinspin animation
freeslot("S_PLAY_BATTLETWINSPINJUMP")
states[S_PLAY_BATTLETWINSPINJUMP] = {
	sprite = SPR_PLAY,
	frame = SPR2_TWIN,
	tics = 1,
	nextstate = S_PLAY_BATTLETWINSPINJUMP
}

-- Piko Splash
mobjinfo[MT_LHRT].hit_sound = sfx_hit03
mobjinfo[MT_LHRT].cantouchteam = true
mobjinfo[MT_LHRT].blockable = 1
mobjinfo[MT_LHRT].block_stun = 3
-- mobjinfo[MT_LHRT].block_sound = sfx_s3kb5
mobjinfo[MT_LHRT].block_hthrust = 6
mobjinfo[MT_LHRT].block_vthrust = 2
mobjinfo[MT_LHRT].spawnfire = true

-- Piko Wave
freeslot("MT_PIKOWAVE", "MT_PIKOWAVEHEART", "S_PIKOWAVE1", "S_PIKOWAVE2", "S_PIKOWAVE3", "spr_bhrt", "sfx_hamrc")

mobjinfo[MT_PIKOWAVE] = {
	spawnstate = S_PIKOWAVE1,
	xdeathstate = S_SPRK1,
	spawnhealth = 1000,
	reactiontime = 8,
	speed = 35*FRACUNIT,
	radius = 6*FRACUNIT,
	height = 12*FRACUNIT,
	mass = 0,
	damage = 0,
	flags = MF_NOGRAVITY|MF_BOUNCE
}
mobjinfo[MT_PIKOWAVE].hit_sound = sfx_hit03
mobjinfo[MT_PIKOWAVE].cantouchteam = true
mobjinfo[MT_PIKOWAVE].blockable = 1
mobjinfo[MT_PIKOWAVE].block_stun = 3
-- mobjinfo[MT_PIKOWAVE].block_sound = sfx_s3kb5
mobjinfo[MT_PIKOWAVE].block_hthrust = 6
mobjinfo[MT_PIKOWAVE].block_vthrust = 2
mobjinfo[MT_PIKOWAVE].spawnfire = true

mobjinfo[MT_PIKOWAVEHEART] = {
	spawnstate = S_PIKOWAVE2,
	deathstate = S_SPRK1,
	xdeathstate = S_SPRK1,
	radius = 24*FRACUNIT,
	height = 24*FRACUNIT,
	damage = 1,
	flags = MF_NOBLOCKMAP|MF_MISSILE
}
mobjinfo[MT_PIKOWAVEHEART].hit_sound = sfx_hit03
mobjinfo[MT_PIKOWAVEHEART].cantouchteam = true
mobjinfo[MT_PIKOWAVEHEART].blockable = 1
mobjinfo[MT_PIKOWAVEHEART].block_stun = 6
mobjinfo[MT_PIKOWAVEHEART].block_hthrust = 7
mobjinfo[MT_PIKOWAVEHEART].block_vthrust = 5

states[S_PIKOWAVE1] = {
	sprite = SPR_BHRT,
	frame = FF_PAPERSPRITE|B
}
states[S_PIKOWAVE2] = {
	sprite = SPR_BHRT,
	frame = FF_TRANS20|A
}
states[S_PIKOWAVE3] = {
	sprite = SPR_BHRT,
	frame = FF_TRANS20|B
}