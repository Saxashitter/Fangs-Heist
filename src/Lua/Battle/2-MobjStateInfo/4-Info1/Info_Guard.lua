//Battle parry and parried graphics
freeslot(
	"mt_battleshield",
	"mt_negashield",
	"s_battle_shield",
	"spr_sbsh"
)

mobjinfo[MT_BATTLESHIELD] = {
	spawnstate = S_BATTLE_SHIELD,
	spawnhealth = 1000,
	speed = 8,
	radius = 64*FRACUNIT,
	height = 64*FRACUNIT,
	dispoffset = 10,
	mass = 16,
	flags = MF_NOBLOCKMAP|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY|MF_SCENERY
}
mobjinfo[MT_NEGASHIELD] = {
	spawnstate = S_BATTLE_SHIELD,
	spawnhealth = 1000,
	speed = 8,
	radius = 64*FRACUNIT,
	height = 64*FRACUNIT,
	dispoffset = 10,
	mass = 16,
	flags = MF_NOBLOCKMAP|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY|MF_SCENERY
}
states[S_BATTLE_SHIELD] = {
	sprite = SPR_SBSH,
	frame = FF_ANIMATE|A,
	tics = 20,
	nextstate = S_NULL,
	var1 = 9,
	var2 = 2
}

//instashield katsy version
//lua ported over to 2.2, new insta-shield sprites, and bug-fixes by DirkTheHusky

freeslot(
	"MT_INSTASHIELD",
	"MT_INSTAHIT",
	"S_INSTASHIELD",
	"S_INSTASHIELD1",
	"S_INSTASHIELD1B",
	"S_INSTASHIELD2",
	"S_INSTASHIELD2B",
	"S_INSTASHIELD3",
	"S_INSTASHIELD3B",
	"S_INSTASHIELD4",
	"S_INSTASHIELD4B",
	"S_INSTASHIELD5",
	"S_INSTASHIELD5B",
	"S_INSTASHIELD6",
	"S_INSTASHIELD6B",
	"S_INSTASHIELD7",
	"S_INSTASHIELD7B",
	"S_INSTAHIT",
	"S_INSTAHIT1",
	"S_INSTAHIT2",
	"SPR_TWSP"
)

//soc crap
mobjinfo[MT_INSTAHIT] = {
	doomednum = -1,
	spawnhealth = 1,
	spawnstate = S_INSTAHIT1,
	radius = 64*FRACUNIT,
	height = 64*FRACUNIT,
	flags = MF_NOGRAVITY|MF_SCENERY|MF_NOCLIPHEIGHT
}

mobjinfo[MT_INSTASHIELD] = {
	doomednum = -1,
	spawnhealth = 1,
	spawnstate = S_INSTASHIELD1,
	radius = 32*FRACUNIT,
	height = 32*FRACUNIT,
	flags = MF_NOGRAVITY|MF_NOBLOCKMAP|MF_NOCLIP|MF_SCENERY|MF_NOCLIPHEIGHT
}

states[S_INSTAHIT1] = {SPR_NULL, 0, 1, A_CapeChase, 0, 0, S_INSTAHIT2}
states[S_INSTAHIT2] = {SPR_NULL, 0, 1, A_CapeChase, 0, 0, S_INSTAHIT1}

states[S_INSTASHIELD1] = {SPR_TWSP, 0|FF_FULLBRIGHT, 1, A_CapeChase, 0, 0, S_INSTASHIELD2}
states[S_INSTASHIELD2] = {SPR_TWSP, 1|FF_FULLBRIGHT, 1, A_CapeChase, 0, 0, S_INSTASHIELD3}
states[S_INSTASHIELD3] = {SPR_TWSP, 2|FF_FULLBRIGHT, 1, A_CapeChase, 0, 0, S_INSTASHIELD4}
states[S_INSTASHIELD4] = {SPR_TWSP, 3|FF_FULLBRIGHT, 1, A_CapeChase, 0, 0, S_INSTASHIELD5}
states[S_INSTASHIELD5] = {SPR_TWSP, 4|FF_FULLBRIGHT, 1, A_CapeChase, 0, 0, S_INSTASHIELD6}
states[S_INSTASHIELD6] = {SPR_TWSP, 5|FF_FULLBRIGHT, 1, A_CapeChase, 0, 0, S_INSTASHIELD7}
states[S_INSTASHIELD7] = {SPR_TWSP, 6|FF_FULLBRIGHT, 1, A_CapeChase, 0, 0, 0}