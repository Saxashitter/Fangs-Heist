return {
	scraps = 0,
	saved_profit = 0,
	generated_profit = 0,
	had_sign = false,

	team = 0,

	death_time = 5*TICRATE,

	enemies = 0,
	monitors = 0,
	hitplayers = 0,
	deadplayers = 0,

	treasures = {},
	treasure_time = 0,
	treasure_name = "",
	treasure_desc = "",

	picked_up_player = nil,
	picked_up_by = nil,

	conscious_meter = FU,
	conscious_meter_heal = 30*TICRATE,
	conscious_meter_reduce = TICRATE,
	conscious_meter_reduce_pick = TICRATE/2,

	spectator = false,

	lastbuttons = 0,
	buttons = 0,
	sidemove = 0,
	forwardmove = 0,

	exiting = false
}