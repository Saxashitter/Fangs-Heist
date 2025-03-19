local time = (3*60)*TICRATE

return {
	gamemode = 1,

	map_choices = {},

	game_over = false,
	game_over_ticker = 0,
	game_over_length = 20*TICRATE,
	retaking = false,
	selected_map = 0,
	end_anim = 0,
	retake_anim = 2*TICRATE,

	pregame = true,
	pregame_time = 30*TICRATE,

	placements = {},
	teams = {},
	treasures = {},

	last_profit = -1
}