freeslot("S_BEANTHEDYNAMITE", "SPR_BTDY")

states[S_BEANTHEDYNAMITE] = {
	sprite = SPR_BTDY,
	frame = A,
	tics = -1
}

function FangsHeist.defineBean(x, y, z)
	local thok = P_SpawnMobj(x, y, z, MT_THOK)
	thok.flags = MF_NOTHINK|MF_NOBLOCKMAP
	thok.state = S_BEANTHEDYNAMITE
	thok.tics = -1
	thok.fuse = -1

	FangsHeist.Net.bean = thok

	return thok
end