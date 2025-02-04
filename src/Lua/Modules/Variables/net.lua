local time = (3*60)*TICRATE

return {
	gametype = 0,

	escape = false,
	escape_theme = "SPRHRO",
	escape_hurryup = true,

	time_left = time,
	max_time_left = time,
	hurry_up = false,
	its_over = false,

	map_choices = {},

	game_over = false,
	game_over_ticker = 0,
	game_over_length = 20*TICRATE,
	end_anim = 0,

	pregame = true,
	pregame_time = 30*TICRATE,

	placements = {},
	treasures = {}
}