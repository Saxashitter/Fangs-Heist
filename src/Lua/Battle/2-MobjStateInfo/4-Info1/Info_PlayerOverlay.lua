freeslot(
	'mt_targetdummy',
	's_specbird1',
	's_specbird2',
	's_specbird3'
)

// TargetDummy Object
mobjinfo[MT_TARGETDUMMY] = {
	height = 64*FRACUNIT,
	spawnstate = MT_PLAYER,
	flags = MF_NOBLOCKMAP|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY|MF_SCENERY|MF_SHOOTABLE
}

//Spectating flickies
states[S_SPECBIRD1] = {
	sprite = SPR_FL01,
	frame = B,
	tics = 3,
	nextstate = S_SPECBIRD2
}

states[S_SPECBIRD2] = {
	sprite = SPR_FL01,
	frame = C,
	tics = 3,
	nextstate = S_SPECBIRD3
}
states[S_SPECBIRD3] = {
	sprite = SPR_FL01,
	frame = D,
	tics = 3,
	nextstate = S_SPECBIRD1
}