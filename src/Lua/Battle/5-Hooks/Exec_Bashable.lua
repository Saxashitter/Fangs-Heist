local B = CBW_Battle
local CV = B.Console
//Tails Doll sparring partner
addHook("MobjSpawn",B.TailsDollCreate,MT_SPARRINGDUMMY)

addHook("MobjThinker",B.TailsDollThinker,MT_SPARRINGDUMMY)

addHook("MobjFuse", function(mo)
	B.TailsDollFuse(mo,mo.target)
	return true
end,MT_SPARRINGDUMMY)

//Chess Pieces
local ChessSpawn = function(mo)
	if P_RandomRange(0,1) then
		mo.color = SKINCOLOR_SILVER
	else
		mo.color = SKINCOLOR_JET
	end
end

addHook("MobjSpawn",function(mo) ChessSpawn(mo) end,MT_CHESSKNIGHT)
addHook("MobjSpawn",function(mo) ChessSpawn(mo) end,MT_CHESSKING)
addHook("MobjSpawn",function(mo) ChessSpawn(mo) end,MT_CHESSQUEEN)
addHook("MobjSpawn",function(mo) ChessSpawn(mo) end,MT_CHESSPAWN)

// B.CreateBashable(mo,weight,friction,smooth,sentient)
	//Args
	//mo: object to modify
	//weight: Resistance to knockback (in "percent"). 100 is standard. Must be positive.
	//friction: Factor to slow object when sliding from knockback, overrides normal friction. 0 is none, 3-4 is approx normal friction.
	//smooth: Object rolls downhill. "Friction" factor always takes effect.
	//sentient: Intended for use with objects that are designed to act more like enemies


//Bash boulder
addHook("MobjSpawn",function(mo) 
	mo.flags2 = $|MF2_AMBUSH
end,MT_BASHBOULDER)
 
addHook("MapThingSpawn",function(mo,thing)
	if thing.options&MTF_AMBUSH
		mo.scale = $*3/2
	end
end, MT_BASHBOULDER)

addHook("MobjThinker",function(mo)
	if not(mo and mo.valid) or mo.flags&MF_NOTHINK then return end
	mo.fuse = 999
end,MT_BASHBOULDER)

//Game logic hooks

for n = 0, #mobjinfo-1 do
	local m = mobjinfo -- ZoneBuilder is inept
	local mt = m[n]
	if not mt.battle_bashable
		continue 
	end
	
	addHook("MobjSpawn",function(mo)
		local i = mo.info
		B.CreateBashable(mo, i.battle_weight, i.battle_friction, i.battle_smooth, i.battle_sentient, i.battle_bounce)
	end, n)

	addHook("MobjThinker",function(...)
		return B.BashableThinker(...)
	end, n)

	addHook("MobjLineCollide", function(...)
		return B.BashableLineCollide(...)
	end, n)

	addHook("MobjCollide", function(...)
		return B.BashableCollision(...)
	end, n)

	addHook("MobjMoveCollide", function(...)
		return B.BashableCollision(...)
	end, n)

	addHook("TouchSpecial", function(...)
		B.BashableCollision(...)
		return true
	end, n)

	addHook("ShouldDamage", function(...)
		return B.BashableShouldDamage(...)
	end, n)
end