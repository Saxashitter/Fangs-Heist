// this is really just a MT_THOK with code being ran from Hooks/Game...
// ...to do stuff, :P

// heres some cool functions and states tho

states[freeslot "S_FH_EXIT_OPEN"] = {
	sprite = freeslot "SPR_EXGT",
	frame = B,
	tics = -1
}
states[freeslot "S_FH_EXIT_CLOSE"] = {
	sprite = SPR_EXGT,
	frame = A,
	tics = -1
}

function FangsHeist.defineExit(x, y, z, a)
	if FangsHeist.Net.exit
	and FangsHeist.Net.exit.valid then
		return
	end

	local exit = P_SpawnMobj(x, y, z, MT_THOK)
	exit.fuse = -1
	exit.tics = -1
	exit.state = S_FH_EXIT_CLOSE
	exit.angle = a
	exit.flags = (MF_NOTHINK|MF_NOGRAVITY|MF_NOCLIP|MF_NOCLIPHEIGHT)

	FangsHeist.Net.exit = exit
	return true
end