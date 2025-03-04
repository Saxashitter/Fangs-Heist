return function(p)
	if not FangsHeist.isPlayerAlive(p) then return end
	if not FangsHeist.playerHasSign(p) then return end

	local sign = FangsHeist.Net.sign

	if p.cmd.buttons & BT_TOSSFLAG
	and not (p.lastbuttons & BT_TOSSFLAG) then
		-- throw sign

		sign.holder = nil
		P_InstaThrust(sign, p.mo.angle, 8*p.mo.scale)
		P_SetObjectMomZ(sign, 4*p.mo.scale)
		sign.momx = $+p.mo.momx
		sign.momy = $+p.mo.momy
		sign.momz = $+p.mo.momz
		S_StartSound(p.mo, sfx_s3k51)

		p.powers[pw_flashing] = 2*TICRATE
	end
end