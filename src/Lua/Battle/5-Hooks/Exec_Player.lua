/*Note: See Exec_System.lua for player functions in hooks:
	PreThinkFrame
	ThinkFrame
	PostThinkFrame
*/

local B = CBW_Battle
local A = B.Arena
local CV = B.Console

-- Handle player spawning
addHook("PlayerSpawn",function(player) 
	-- Init vars
	B.InitPlayer(player) 
	B.InitPriority(player)
	-- Do music
	if not(B.OvertimeMusic(player)) then
		B.PinchMusic(player)
	end
	-- Conditional spawn settings
	B.SpawnWithShield(player)
	A.StartRings(player)
	B.RestoreColors(player)
	B.ResetPlayerProperties(player)
	B.PlayerBattleSpawnStart(player)
end)

addHook("MobjSpawn", function(mo)
	B.PlayerMobjSpawn(mo)
end, MT_PLAYER)

-- Handle player vs player collision
addHook("TouchSpecial", function(...)
	return B.PlayerTouch(...)
end,MT_PLAYER)

-- Control ability usage
addHook("AbilitySpecial",function(player)
	return B.AbilitySpecial(player)
end)
addHook("ShieldSpecial", function(player)
	return B.ShieldSpecial(player)
end)
addHook("JumpSpecial",function(player)
	return B.JumpSpecial(player)
end)
addHook("SpinSpecial",function(player)
	if P_IsObjectOnGround(player.mo)
		return B.SpinSpecial(player)
	else
		return B.JumpSpinSpecial(player)
	end
end)

addHook("MobjThinker",function(mo)
	if not(mo.player) return end
	return B.PlayerMobjThinker(mo.player)
end, MT_PLAYER)

addHook("PlayerThink", function(player)
	return B.PlayerThink(player)
end)

-- Player Should Damage hook
addHook("ShouldDamage", function(...)
	return B.InGame()
	and B.ShouldDamagePlayer(...)
end,MT_PLAYER)

-- Armaggeddon blast
addHook("ShouldDamage", function(...)
	if B.InGame()
		B.DamageTargetDummy(...)
	end
	return false
end,MT_TARGETDUMMY)

-- Damage triggered
addHook("MobjDamage", function(...)
	return B.PlayerDamage(...)
		or B.DamageFX(...)
end,MT_PLAYER)

-- Player death
addHook("MobjDeath", function(...)
	return B.PlayerDeath(...)
end, MT_PLAYER)

-- Terrain Collision

addHook("MobjMoveBlocked", function(mo)
	-- Bounce off walls during tumble
    return B.PlayerMoveBlocked(mo)
end, MT_PLAYER)
