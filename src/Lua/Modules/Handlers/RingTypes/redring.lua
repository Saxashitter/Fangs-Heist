return {
	type = MT_REDRING,
	cooldown = TICRATE/4,
	graphic = "RINGIND",
	onSpawn = function(p, ring)
		S_StartSound(p.mo, sfx_thok)
	end
}