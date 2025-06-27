freeslot(
	's_teamfire1',
	's_teamfire2',
	's_teamfire3',
	's_teamfire4',
	's_teamfire5',
	's_teamfire6',
	'spr_tfir'
)
	
//Team colored Elemental Shield fire trail

states[S_TEAMFIRE1] = {
	sprite = SPR_TFIR,
	frame = FF_FULLBRIGHT|A,
	tics = 2,
	nextstate = S_TEAMFIRE2
}

states[S_TEAMFIRE2] = {
	sprite = SPR_TFIR,
	frame = FF_FULLBRIGHT|B,
	tics = 2,
	nextstate = S_TEAMFIRE3
}

states[S_TEAMFIRE3] = {
	sprite = SPR_TFIR,
	frame = FF_FULLBRIGHT|C,
	tics = 2,
	nextstate = S_TEAMFIRE4
}

states[S_TEAMFIRE4] = {
	sprite = SPR_TFIR,
	frame = FF_FULLBRIGHT|D,
	tics = 2,
	nextstate = S_TEAMFIRE5
}

states[S_TEAMFIRE5] = {
	sprite = SPR_TFIR,
	frame = FF_FULLBRIGHT|E,
	tics = 2,
	nextstate = S_TEAMFIRE6
}

states[S_TEAMFIRE6] = {
	sprite = SPR_TFIR,
	frame = FF_FULLBRIGHT|F,
	tics = 2,
	nextstate = S_TEAMFIRE1
}
