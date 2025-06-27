freeslot('mt_diamond','mt_diamondspawn')

// Diamond object
mobjinfo[MT_DIAMOND] = {
	doomednum = -1,
	spawnstate = S_SHRD1,
	height = 32*FRACUNIT,
	radius = 12*FRACUNIT,
	flags = MF_SPECIAL
}

// Control point object
mobjinfo[MT_DIAMONDSPAWN] = {
	//$Name "Diamond Spawn Point"
	//$Sprite SHRDA0
	//$Category "BattleMod Diamond in the Rough"
	doomednum = 3630,
	spawnstate = 1,
	height = 32*FRACUNIT,
	radius = 24*FRACUNIT,
	flags = MF_NOTHINK|MF_NOSECTOR
}