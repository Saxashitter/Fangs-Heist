freeslot(
	"spr_pjgn",
	"s_revengegunner1",
	"s_revengegunner2",
	"s_revengegunner3",
	"s_revengegunner4"
)



states[S_REVENGEGUNNER1] = {
	sprite = SPR_PJGN,
	frame = A,
	tics = 1,
	nextstate = S_REVENGEGUNNER2
}
states[S_REVENGEGUNNER2] = {
	sprite = SPR_PJGN,
	frame = B,
	tics = 1,
	nextstate = S_REVENGEGUNNER1
}
states[S_REVENGEGUNNER3] = {
	sprite = SPR_PJGN,
	frame = C,
	tics = 1,
	nextstate = S_REVENGEGUNNER4
}
states[S_REVENGEGUNNER4] = {
	sprite = SPR_PJGN,
	frame = D,
	tics = 1,
	nextstate = S_REVENGEGUNNER3
}