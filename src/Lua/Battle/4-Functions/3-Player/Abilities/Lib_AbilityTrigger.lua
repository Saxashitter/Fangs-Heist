-- Houses instructions for ability trigger hooks such as JumpSpecial, AbilitySpecial, etc.

local B = CBW_Battle
local S = B.SkinVars

B.AbilitySpecial = function(player)
	if not(B.MidAirAbilityAllowed(player)) then return true end
	-- Fix metal sonic shield stuff
	if player.charability == CA_FLOAT
		and ((player.mo and player.mo.valid and (player.mo.state == S_PLAY_ROLL)) or player.secondjump == UINT8_MAX)
		return true
	end

	local func = B.GetSkinVarsValue(player, "func_doublejump_trigger")
	if func
		return func(player, BT_JUMP)
	end
end

B.ShieldSpecial = function(player)
	if B.CanShieldActive(player)
		and (B.ButtonCheck(player,BT_SPIN) == 1 or (player.powers[pw_shield]&SH_NOSTACK == SH_WHIRLWIND and B.ButtonCheck(player,BT_JUMP) == 1))
		and not(B.GetSkinVarsFlags(player)&SKINVARS_NOSPINSHIELD)
		B.DoShieldActive(player)
	end
	return true
end

B.JumpSpecial = function(player)
	if player.lockjumpframe
	or player.melee_state
		return true
	end
	local func = B.GetSkinVarsValue(player, "func_jump_trigger")
	if func
		return func(player, BT_JUMP)
	end
end

B.SpinSpecial = function(player)
	if player.powers[pw_carry]
		return
	end
	local func = B.GetSkinVarsValue(player, "func_spin_trigger")
	if func
		return func(player, BT_SPIN)
	end
end

B.JumpSpinSpecial = function(player)
	if player.powers[pw_carry]
	or not B.MidAirAbilityAllowed(player)
	or not (player.pflags & PF_JUMPED)
		return
	end
	local func = B.GetSkinVarsValue(player, "func_jumpspin_trigger")
	if func
		return func(player, BT_SPIN)
	end
	
	if player.powers[pw_super] and player.charability == CA_THOK and player.actionstate -- Super thok character control
		return true
	end
end