local B = CBW_Battle
local S = B.SkinVars
local Act = B.Action
local G = B.GuardFunc
local Nf = NavFunc

S["sonic"] = {
	flags			= SKINVARS_GUARD|SKINVARS_NOSPINSHIELD,
	guard_frame		= 2,
	weight			= 100,
	shields			= 1, 
	rings			= 50,
	func_special = Act.SonicWave,
	func_doublejump_trigger = B.SonicDoubleJump,
	func_doublejump_ticframe = B.SonicDoubleJumpControl,
	func_jumpspin_trigger = B.SonicDash,
	func_jumpspin_ticframe = B.SonicDashControl,
}
S["supersonic"] = {
	flags			= SKINVARS_GUARD|SKINVARS_NOSPINSHIELD|SKINVARS_SUPERSONIC,
	guard_frame		= 2,
	weight 			= 100,
	rings			= 50,
	passive_atk		= 1,
	passive_def		= 0,
	shields			= -1,
	func_special = Act.SonicWave,
	func_doublejump_trigger = B.SonicDoubleJump,
	func_doublejump_ticframe = B.SonicDoubleJumpControl,
	func_jumpspin_trigger = B.SonicDash,
	func_jumpspin_ticframe = B.SonicDashControl,
}
S["tails"] = {
	flags			= SKINVARS_GUARD|SKINVARS_NOSPINSHIELD,
	weight			= 100,
	shields			= 1,
	rings			= 30,
	func_special = Act.TailSwipe,
	guard_frame = 2,
	func_priority_ext = Act.TailSwipe_Priority,
	func_doublejump_trigger = B.TailsFlightTrigger,
	func_doublejump_ticframe = B.TailsFlightControl,
	func_jumpspin_trigger = B.TailThrust,	
}
S["knuckles"] = {
	flags	= SKINVARS_GUARD|SKINVARS_NOSPINSHIELD,
	weight	= 120,
	shields = 1,
	rings	= 65,
	func_special = Act.Dig,
	guard_frame = 2,
	func_priority_ext = Act.Dig_Priority,
	func_collide = B.Knuckles_Collide,
	func_jumpspin_trigger = B.StartGroundPound,
	func_jumpspin_ticframe = B.DoGroundPound,
}

S["amy"] = {
	flags	= SKINVARS_GUARD|SKINVARS_NOSPINSHIELD,
	weight	= 95,
	shields	= 1,
	rings	= 40,
	func_special = Act.PikoSpin,
	guard_frame = 1,
	func_priority_ext = Act.PikoSpin_Priority,
	func_spin_trigger = B.ChargeHammer,
	func_spin_ticframe = B.HammerControl,
	func_doublejump_trigger = B.TwinSpinJump,
	func_doublejump_ticframe = B.TwinSpinControl,
	func_jumpspin_trigger = B.TwinSpin,
	func_jumpspin_ticframe = nil,
}
S["fang"] = {
	flags		= SKINVARS_GUARD|SKINVARS_NOSPINSHIELD|SKINVARS_GUNSLINGER,
	weight 		= 105,
	rings		= 70,
	shields 	= 1,
-- 	func_special = Act.CombatRoll,
	func_special = Act.BombThrow,
	guard_frame = 1,
	func_priority_ext = Act.CombatRoll_Priority,
	func_precollide = B.Fang_PreCollide,
	func_collide = B.Fang_Collide,
	func_postcollide = B.Fang_PostCollide,
	func_doublejump_trigger = B.CombatRollTrigger,
	func_doublejump_ticframe = B.CombatRollTicFrame,
}
S["metalsonic"] = {
	flags			= SKINVARS_GUARD|SKINVARS_NOSPINSHIELD,
	guard_frame		= 2,
	weight			= 115,
	shields			= 1,
	rings			= 80,
	func_special			= Act.EnergyAttack,
	func_priority_ext		= Act.EnergyAttack_Priority,
	func_jumpspin_trigger	= B.MomentumThok,
	func_jumpspin_ticframe	= B.MomentumThokControl,
}
S["eggman"] = {
	flags = SKINVARS_GUARD|SKINVARS_NOSPINSHIELD,
	guard_frame		= 2,
	weight			= 150,
	rings			= 100,
	shields			= 3,
-- 	func_pain			= B.EggChampionPain,
 	func_special		= Act.EggChampion,
}