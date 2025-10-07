FangsHeist.HitLagged = {}

rawset(_G, "FH_HITLAGTICS", 35)

local function returnMobjData(mo)
	local data = {
		mo = mo,
		flags = mo.flags,
		flags2 = mo.flags2,
		eflags = mo.eflags,
		state = mo.state,
		frame = mo.frame,
		tics = mo.tics,
		angle = mo.angle
	}

	FangsHeist.runHook("CreateHitlagMobjStruct", mo, data)
	return data
end

function FangsHeist.makeHitlagTable(mo1, mo2)
	if not (mo1 and mo1.valid) then return end
	if not (mo2 and mo2.valid) then return end

	local tbl = {}

	tbl[1] = returnMobjData(mo1)
	tbl[2] = returnMobjData(mo2)

	tbl.tics = FH_HITLAGTICS
	return tbl
end

function FangsHeist.doHitLag(mo1, mo2)
	local tbl = FangsHeist.makeHitlagTable(mo1, mo2)

	if not tbl then
		return
	end

	-- TODO: finish it (god im lazy)
end

function FangsHeist.stopVoicelines(p)
	local char = FangsHeist.Characters[p.heist.locked_skin]

	for k, tbl in pairs(char.voicelines) do
		for _, snd in ipairs(tbl) do
			S_StopSoundByID(p.mo, snd)
		end
	end
end

function FangsHeist.playVoiceline(p, line, private)
	local char = FangsHeist.Characters[p.heist.locked_skin]

	if not char.voicelines[line] then
		return
	end
	if not p.heist.voicelines then return end

	FangsHeist.stopVoicelines(p)

	local lines = char.voicelines[line]

	S_StartSound(p.mo, lines[P_RandomRange(1, #lines)], private and p)
end