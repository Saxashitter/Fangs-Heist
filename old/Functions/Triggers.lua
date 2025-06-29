function FangsHeist.clashPlayers(p, sp)
	local angle = R_PointToAngle2(p.mo.x, p.mo.y, sp.mo.x, sp.mo.y)

	P_InstaThrust(p.mo, angle, -p.speed)
	P_InstaThrust(sp.mo, angle, p.speed)

	local char1 = FangsHeist.Characters[p.mo.skin]
	local char2 = FangsHeist.Characters[sp.mo.skin]

	char1:onClash(p, sp)
	char2:onClash(sp, p)

	p.mo.state = S_PLAY_FALL
	sp.mo.state = S_PLAY_FALL

	p.powers[pw_flashing] = 10
	sp.powers[pw_flashing] = 10
end