// treasures cause we like them
// all sprites currently used by Speedcore Tempest

freeslot "SPR_TRES"

local UNGRABBED_FLAGS = 0
local GRABBED_FLAGS = MF_NOTHINK|MF_NOGRAVITY|MF_NOCLIP|MF_NOCLIPHEIGHT

FangsHeist.treasures = {
	{
		name = "Franklin Badge",
		desc = "This MIGHT have been used in a kite experiment.",
		frame = A
	};
	{
		name = "Light Burden",
		desc = "You only have One Shot.",
		frame = B
	};
	{
		name = "Rainy Ukelele",
		desc = "...And his music was electric.",
		frame = C
	};
	{
		name = "Jet Lotus",
		desc = "He's RAMPING!!",
		frame = D
	};
	{
		name = "Tempest Ribbon",
		desc = "In a world of glass, the girl faced endless conflict.",
		frame = E
	};
	{
		name = "Fatalis Ribbon",
		desc = "In a world of glass, the girl was shrouded in unyielding light.",
		frame = F
	};
	{
		name = "Galactic Talisman",
		desc = "A symbol for cool guys and intergalactic armies alike!",
		frame = G
	};
	{
		name = "Writer's Mask",
		desc = "I just can't GET ENUF!",
		frame = H
	};
	{
		name = "Strongest Plush",
		desc = "Baka! Baka!",
		frame = I
	};
	{
		name = "Saint's Knife",
		desc = "The Fickle Princess left the Hero with nothing but hate in his heart.",
		frame = J
	};
}

local function set_mobj_to_data(mobj, data)
	mobj.sprite = SPR_TRES
	mobj.frame = data.frame
end

function FangsHeist.defineTreasure(x, y, z)
	local treasure = P_SpawnMobj(x, y, z, MT_THOK)
	treasure.flags = MF_NOTHINK|MF_NOBLOCKMAP
	treasure.fuse = -1
	treasure.tics = -1

	local choice = P_RandomRange(1, #FangsHeist.treasures)

	table.insert(FangsHeist.Net.treasures, {
		mobj = treasure,
		data = FangsHeist.treasures[choice]
	})
	set_mobj_to_data(treasure, FangsHeist.treasures[choice])
end

local function manage_unpicked(tres)
	local mobj = tres.mobj
	local data = tres.data

	for p in players.iterate do
		if not FangsHeist.isPlayerAlive(p) then continue end
		if P_PlayerInPain(p) then continue end

		local dist = R_PointToDist2(mobj.x, mobj.y, p.mo.x, p.mo.y)
		local heightdist = abs(p.mo.z-mobj.z)

		if dist > 64*FU
		or heightdist > 64*FU then
			continue
		end

		S_StartSound(p.mo, sfx_kc30)

		table.insert(p.heist.treasures, tres)
		mobj.target = p.mo
		mobj.index = #p.heist.treasures

		break
	end
end

local function manage_picked(tres)
	local mobj = tres.mobj
	local data = tres.data

	local target = mobj.target

	P_MoveOrigin(mobj,
		target.x,
		target.y,
		(target.z+target.height)+(16*FU*(mobj.index-1)))
end

function FangsHeist.manageTreasures()
	for _,tres in pairs(FangsHeist.Net.treasures) do
		local mobj = tres.mobj
		local data = tres.data

		if mobj.target
		and not (mobj.target.valid
		and mobj.target.player
		and FangsHeist.isPlayerAlive(mobj.target.player)) then
			mobj.target = nil
		end

		if not mobj.target then
			mobj.flags = UNGRABBED_FLAGS
			manage_unpicked(tres)
			continue
		end

		mobj.flags = GRABBED_FLAGS
		manage_picked(tres)
	end
end