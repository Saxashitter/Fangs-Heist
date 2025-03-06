// this is really just a MT_THOK with code being ran from Hooks/Game...
// ...to do stuff, :P

// heres some cool functions and states tho

states[freeslot "S_FH_MARVQUEEN"] = {
	sprite = freeslot "SPR_MAQU",
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
	exit.state = S_FH_MARVQUEEN
	exit.angle = a
	exit.flags = (MF_NOTHINK|MF_NOGRAVITY|MF_NOCLIP|MF_NOCLIPHEIGHT)

	FangsHeist.Net.exit = exit
	return true
end