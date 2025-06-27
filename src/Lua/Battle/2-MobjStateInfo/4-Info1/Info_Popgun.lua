-- Cork stats
mobjinfo[MT_CORK].speed = 51*FRACUNIT
mobjinfo[MT_CORK].hit_sound = sfx_hit04
mobjinfo[MT_CORK].blockable = 1
mobjinfo[MT_CORK].block_stun = 5
-- mobjinfo[MT_CORK].block_sound = sfx_s3kb5
mobjinfo[MT_CORK].block_hthrust = 12
mobjinfo[MT_CORK].block_vthrust = 10
mobjinfo[MT_CORK].spawnfire = true

-- Aerial popgun animation
freeslot(
	"spr2_fair",
	"s_play_jumpfire",
	"s_play_jumpfire_finish"
)
spr2defaults[SPR2_FAIR] = SPR2_FIRE
	
states[S_PLAY_JUMPFIRE] = {
	sprite = SPR_PLAY,
	frame = SPR2_FAIR|FF_SPR2ENDSTATE,
	tics = 3,
	var1 = S_PLAY_JUMPFIRE_FINISH,
	nextstate = S_PLAY_JUMPFIRE
}

states[S_PLAY_JUMPFIRE_FINISH] = {
	sprite = SPR_PLAY,
	frame = SPR2_FAIR,
	tics = 15,
	nextstate = S_PLAY_FALL
}
