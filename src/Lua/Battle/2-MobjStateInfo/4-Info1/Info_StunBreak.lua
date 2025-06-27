freeslot("MT_STUNBREAK","S_STUNBREAK","SPR_BSBK")

mobjinfo[MT_STUNBREAK] = {
	spawnstate = S_STUNBREAK,
	spawnhealth = 1000,
	radius = 64*FRACUNIT,
	height = 64*FRACUNIT,
	mass = 16,
	flags = MF_NOBLOCKMAP|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY
}
states[S_STUNBREAK] = {
	sprite = SPR_BSBK,
	frame = FF_ANIMATE|FF_FULLBRIGHT|A|TR_TRANS30,
	tics = 18,
	nextstate = S_NULL,
	var1 = 9,//num frames
	var2 = 2//delay between frames
}
