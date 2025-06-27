freeslot(
	"SPR_CAPJ",
	"MT_POWERCARDCAPSULE",
	"MT_POWERCARDCAPSULE_SPAWNPOINT",
	"S_GGCAPSULE",
	"S_GGCAPSULE_JUNK"
)

mobjinfo[MT_POWERCARDCAPSULE] = {
	doomednum = -1,
	spawnstate = S_GGCAPSULE,
	painstate = S_GGCAPSULE,
	deathstate = S_GGCAPSULE,
	spawnhealth = 1,
	radius = 72*FRACUNIT,
	height = 144*FRACUNIT,
	flags = MF_NOGRAVITY|MF_SPECIAL|MF_SHOOTABLE
}

mobjinfo[MT_POWERCARDCAPSULE_SPAWNPOINT] = {
	//$Name "Power Card Capsule"
	//$Sprite CAPSA0
	//$Category "BattleMod Power Card Spawns"
	doomednum = 3589,
	spawnstate = S_NULL,
	spawnhealth = 1,
	radius = 72*FRACUNIT,
	height = 144*FRACUNIT,
	flags = MF_NOTHINK|MF_NOSECTOR|MF_NOBLOCKMAP
}

states[S_GGCAPSULE] = {SPR_CAPS, A, -1, nil, 0, 0, S_NULL}
states[S_GGCAPSULE_JUNK] = {SPR_CAPJ, A, TICRATE, nil, 0, 0, S_NULL}