// treasures cause we like them
// all sprites currently used by Speedcore Tempest

freeslot "SPR_TRES"

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

function FangsHeist.manageTreasures()
	for p in players.iterate do
		if not (FangsHeist.isPlayerAlive(p)) then continue end

		local remove = {}

		for _,tres in pairs(FangsHeist.Net.treasures) do
			local mobj = tres.mobj
			local data = tres.data

			local dist = R_PointToDist2(p.mo.x, p.mo.y, mobj.x, mobj.y)
			local heightdist = abs(p.mo.z-mobj.z)

			if dist > 64*FU
			or heightdist > 64*FU then
				continue
			end

			p.heist.treasure_name = data.name
			p.heist.treasure_desc = data.desc
			p.heist.treasure_time = 3*TICRATE
			p.heist.treasures = $+1
			S_StartSound(p.mo, sfx_kc30)

			table.insert(remove, tres)
		end

		for _,i in pairs(remove) do
			for k,tres in pairs(FangsHeist.Net.treasures) do
				if tres == i then
					if tres.mobj and tres.mobj.valid then
						P_RemoveMobj(tres.mobj)
					end

					table.remove(FangsHeist.Net.treasures, k)
					break
				end
			end
		end
	end
end