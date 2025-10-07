mobjinfo[freeslot "MT_FH_HITBOX"] = {
	radius = 64*FU,
	height = 64*FU,
	spawnstate = S_INVISIBLE,
	flags = MF_NOCLIP|MF_NOCLIPHEIGHT|MF_SPECIAL,
	flags2 = MF2_DONTDRAW
}

local function MoveHitbox(hitbox, mobj)
	P_SetOrigin(hitbox,
		mobj.x,
		mobj.y,
		mobj.z + mobj.height/2 - hitbox.height/2)
end

local function ValidPlayer(mobj)
	local p = mobj.player

	return p and p.valid and p.heist and p.heist:isAlive()
end

local HitboxList = {}
addHook("NetVars", function(sync)
	HitboxList = sync($)
end)

addHook("MobjSpawn", function(hitbox)
	table.insert(HitboxList, hitbox)
end, MT_FH_HITBOX)

addHook("MobjThinker", function(hitbox)
	if not hitbox.target
	or not hitbox.target.valid then
		return
	end

	
end, MT_FH_HITBOX)