-- Particle tumbler missile
freeslot('mt_tumbleparticle')
mobjinfo[MT_TUMBLEPARTICLE] = {
	spawnstate = S_JETBULLET1,
	spawnhealth = 1000,
	radius = 8*FRACUNIT,
	height = 16*FRACUNIT,
	speed = 60*FRACUNIT,
	mass = 0,
	damage = 0,
	flags = MF_MISSILE|MF_BOUNCE|MF_GRENADEBOUNCE
}
mobjinfo[MT_TUMBLEPARTICLE].tumbler = true
mobjinfo[MT_TUMBLEPARTICLE].pierce_time = 30
mobjinfo[MT_TUMBLEPARTICLE].pierce_sound = sfx_ssbbmp
mobjinfo[MT_TUMBLEPARTICLE].pierce_hthrust = 12
mobjinfo[MT_TUMBLEPARTICLE].pierce_vthrust = 6

-- Ringslinger
mobjinfo[MT_REDRING].blockable = 1
mobjinfo[MT_REDRING].block_stun = 3
mobjinfo[MT_REDRING].block_hthrust = 6
mobjinfo[MT_REDRING].block_vthrust = 2