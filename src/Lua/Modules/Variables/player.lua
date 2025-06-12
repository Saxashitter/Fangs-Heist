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

	weapon_hud = false,
	weapon_selected = 1,

	weapon = nil,
	weapon_cooldown = 0,

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

	locked_skin = 0, -- sonic probably
	confirmed_skin = false,
	locked_team = false,

	cur_sel = 1,
	hud_sel = 8, -- for some kinda camera thing idfk
	cur_menu = 0,

	reached_second = false, -- only used in final demo stages

	exiting = false
}