local time = (3*60)*TICRATE

return {
	gametype = 0,

	escape = false,
	escape_theme = "SPRHRO",
	escape_hurryup = true,
	escape_on_start = false,

	last_man_standing = true,

	hell_stage = false,
	hell_stage_teleport = {},

	time_left = time,
	max_time_left = time,
	hurry_up = false,

	map_choices = {},

	game_over = false,
	game_over_ticker = 0,
	game_over_length = 20*TICRATE,
	retaking = false,
	selected_map = 0,
	end_anim = 0,
	retake_anim = 3*TICRATE-24,

	pregame = true,
	pregame_time = 30*TICRATE,

	placements = {},
	treasures = {}
}