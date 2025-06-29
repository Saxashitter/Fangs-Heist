freeslot("MT_FH_TAILS_MOUNT", "MT_FH_TAILS_DEST")

local LINKS = {
	[MT_FH_TAILS_MOUNT] = MT_FH_TAILS_DEST;
	[MT_FH_TAILS_DEST] = MT_FH_TAILS_MOUNT;
}
mobjinfo[MT_FH_TAILS_DEST] = {
	--$Name Tails Destination
	--$Sprite STNDA1
	--$Category FangsHeist
	--$NotAngled

	--$Arg0 Tag
	--$Arg0Default 0
	--$Arg0Type 0
	--$Arg0Tooltip Number to link Tails.

	flags = MF_NOGRAVITY|MF_NOSECTOR|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOCLIPTHING,
	radius = 32*FU,
	height = 48*FU,
	doomednum = 2350
}
mobjinfo[MT_FH_TAILS_MOUNT] = {
	--$Name Tails Mount
	--$Sprite STNDA1
	--$Category FangsHeist
	--$NotAngled

	--$Arg0 Tag
	--$Arg0Default 0
	--$Arg0Type 0
	--$Arg0Tooltip Number to link the destination of Tails.

	flags = MF_NOGRAVITY|MF_NOSECTOR|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOCLIPTHING,
	radius = 32*FU,
	height = 48*FU,
	doomednum = 2349,
	spawnstate = S_PLAY_STND
}

local get_tag = function(mt)
	if udmf then
		return mt.args[0]
	end

	return mt.angle
end

local is_link = function(mt, tag)
	if udmf
	and mt.args[0] == tag then
		return true
	end

	if not udmf
	and mt.angle == tag then
		return true
	end

	return false
end

local function set_link(mo, tag)
	if not (LINKS[mo.type]) then return end

	for mt in mapthings.iterate do
		if mt.mobj
		and mt.mobj.valid
		and mt.mobj.type == LINKS[mo.type]
		and is_link(mt, tag) then
			mo.link = mt.mobj
			mt.mobj.link = mo
			return true
		end
	end
end

addHook("MapThingSpawn", function(mo, mt)
	mo.skin = "tails"
	mo.color = SKINCOLOR_ORANGE
	mo.speed = FU/35

	mo.orig_pos = {x = mo.x, y = mo.y, z = mo.z}
	if set_link(mo, get_tag(mt)) then
		mo.targ_pos = {x = mo.link.x, y = mo.link.y, z = mo.link.z}
		mo.link.link = nil
		mo.link = nil
	end
end, MT_FH_TAILS_MOUNT)
addHook("MapThingSpawn", function(mo, mt)
	if set_link(mo, get_tag(mt)) then
		mo.link.targ_pos = {x = mo.x, y = mo.y, z = mo.z}
		mo.link.link = nil
		mo.link = nil
	end
end, MT_FH_TAILS_DEST)