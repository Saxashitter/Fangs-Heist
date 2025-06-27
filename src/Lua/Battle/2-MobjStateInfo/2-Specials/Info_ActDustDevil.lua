freeslot(
	'mt_dustdevil_base',
	'mt_dustdevil',
	'mt_swirl'
)

mobjinfo[MT_DUSTDEVIL_BASE] = {
	spawnstate = 1,
	spawnhealth = 1000,
	reactiontime = 8,
	speed = FRACUNIT,
	radius = 32*FRACUNIT,
	height = 64*FRACUNIT,
	mass = 0,
	damage = 0,
	flags = MF_NOGRAVITY|MF_BOUNCE|MF_NOSECTOR
}


mobjinfo[MT_DUSTDEVIL] = {
	spawnstate = 1,
	spawnhealth = 1000,
	reactiontime = 8,
	speed = FRACUNIT,
	radius = 16*FRACUNIT,
	height = 48*FRACUNIT,
	mass = 0,
	damage = 0,
	flags = MF_NOGRAVITY|MF_SPECIAL|MF_NOSECTOR|MF_NOCLIPHEIGHT|MF_NOBLOCKMAP
}

mobjinfo[MT_SWIRL] = {
	spawnstate = 1,
	spawnhealth = 1000,
	reactiontime = 8,
	speed = FRACUNIT,
	radius = 24*FRACUNIT,
	height = 48*FRACUNIT,
	mass = 0,
	damage = 0,
	flags = MF_NOGRAVITY|MF_NOCLIPHEIGHT|MF_NOBLOCKMAP|MF_NOCLIPTHING|MF_SCENERY
}