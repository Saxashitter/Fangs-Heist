local B = CBW_Battle
local S = B.SkinVars

B.AbilityTicFrame = function(player)
	local jump, spin, doublejump, jumpspin =
		B.GetSkinVarsValue(player, "func_jump_ticframe") or do return false end,
		B.GetSkinVarsValue(player, "func_spin_ticframe") or do return false end,
		B.GetSkinVarsValue(player, "func_doublejump_ticframe") or do return false end,
		B.GetSkinVarsValue(player, "func_jumpspin_ticframe") or do return false end
	
	player.battlevars.jumpfunc_active = jump(player, BT_JUMP, "jumpfunc_active")
	player.battlevars.spinfunc_active = spin(player, BT_SPIN, "spinfunc_active")
	player.battlevars.doublejumpfunc_active = doublejump(player, BT_JUMP, "doublejumpfunc_active")
	player.battlevars.spinfunc_active = jumpspin(player, BT_SPIN, "spinfunc_active")
end