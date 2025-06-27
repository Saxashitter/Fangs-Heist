local B = CBW_Battle
local S = B.SkinVars
local Act = B.Action
local G = B.GuardFunc
local Nf = NavFunc


-- General attributes
S[-1].flags			= SKINVARS_GUARD
S[-1].weight		= 100
S[-1].shields 		= 1
S[-1].rings			= 50
S[-1].passive_atk 	= 0
S[-1].passive_def 	= 0
S[-1].guard_frame 	= 0

-- Ring Ability special function
S[-1].func_special 			= nil
-- Guard triggered function
S[-1].func_guard_trigger 	= G.Parry
-- Attack/defense priority functions
S[-1].func_priority 		= B.Priority_FullCommon -- Core priority rules. Generally recommended that this remain unchanged.
S[-1].func_priority_ext 	= nil -- Extended priority rules. Runs after func_priority.
-- Custom collision instructions
S[-1].func_precollide 		= nil
S[-1].func_collide 			= nil
S[-1].func_postcollide 		= nil
S[-1].func_pain				= nil
-- Ability exhaustion meter control
S[-1].func_exhaust 			= nil
-- Custom move control
S[-1].func_jump_trigger 			= nil
S[-1].func_jump_ticframe 			= nil
S[-1].func_spin_trigger 			= nil
S[-1].func_spin_ticframe 			= nil
S[-1].func_doublejump_trigger 		= nil
S[-1].func_doublejump_ticframe 		= nil
S[-1].func_jumpspin_trigger 		= nil
S[-1].func_jumpspin_ticframe 		= nil
	
 --Deprecated
-- sprites = {}
-- special = nil
