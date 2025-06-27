freeslot('mt_groundpound')

//Ground Pound Projectile
mobjinfo[MT_GROUNDPOUND] = {
	spawnstate = S_ROCKCRUMBLEC,
	speed = 12*FRACUNIT,
	radius = 8*FRACUNIT,
	height = 16*FRACUNIT,
	mass = 0,
	damage = 0,
	flags = MF_MISSILE|MF_BOUNCE|MF_GRENADEBOUNCE
}
mobjinfo[MT_GROUNDPOUND].hit_sound = sfx_hit00
mobjinfo[MT_GROUNDPOUND].blockable = 1
mobjinfo[MT_GROUNDPOUND].block_stun = 4
mobjinfo[MT_GROUNDPOUND].block_sound = sfx_s3k49
mobjinfo[MT_GROUNDPOUND].block_hthrust = 2
mobjinfo[MT_GROUNDPOUND].block_vthrust = 6