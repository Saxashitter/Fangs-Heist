-- Fang throw animation
freeslot(
	'spr2_flob',
	's_play_lob',
	's_play_lob_finish'
)

states[S_PLAY_LOB] = {
	sprite = SPR_PLAY,
	frame = SPR2_FLOB|FF_SPR2ENDSTATE,
	tics = 3,
	var1 = S_PLAY_LOB_FINISH,
	nextstate = S_PLAY_LOB
}

states[S_PLAY_LOB_FINISH] = {
	sprite = SPR_PLAY,
	frame = SPR2_FLOB,
	tics = 15,
	nextstate = S_PLAY_WALK
}

-- Fang bombjump
freeslot('s_play_fastedge')
states[S_PLAY_FASTEDGE] = {
	sprite = SPR_PLAY,
	frame = SPR2_EDGE,
	tics = 1,
	nextstate = S_PLAY_FASTEDGE
}


--Fang's team-colored bomb

freeslot(
	'spr_cbom',
	's_colorbomb1',
	's_colorbomb2'
)

states[S_COLORBOMB1] = {
	sprite = SPR_CBOM,
	frame = A,
	action = A_GhostMe,
	tics = 1,
	nextstate = S_COLORBOMB2
}

states[S_COLORBOMB2] = {
	sprite = SPR_CBOM,
	frame = B,
	action = A_GhostMe,
	tics = 1,
	nextstate = S_COLORBOMB1
}

states[S_FBOMB_EXPL2] = {
    sprite = SPR_BARX,
    frame = 1|FF_FULLBRIGHT,
    tics = 2,
    nextstate = S_FBOMB_EXPL3
}