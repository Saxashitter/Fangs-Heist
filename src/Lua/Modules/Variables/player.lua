return {
	scraps = 0,
	had_sign = false,
	got_sign = false,
	spawn_time = 2*TICRATE,

	invites = {},

	attack_cooldown = 0,
	attack_time = 0,

	parry_cooldown = 0,
	perf_parry_time = 0,
	parry_time = 0,

	death_time = 5*TICRATE,

	enemies = 0,
	monitors = 0,
	hitplayers = 0,
	deadplayers = 0,

	treasures = {},
	treasure_time = 0,
	treasures_collected = 0,
	treasure_name = "",
	treasure_desc = "",

	pickup_list = {},

	selected = 2,
	voted = false,

	spectator = false,
	spectator_not_dead = false,

	lastbuttons = 0,
	buttons = 0,

	sidemove = 0,
	forwardmove = 0,

	lastforw = 0,
	lastside = 0,

	locked_skin = "tails", -- sonic probably
	skin_index = 2,
	alt_skin = 0,
	pregame_state = "",

	reached_second = false, -- only used in round 2

	exiting = false
}