return function(p)
	if not (p.heist and p.heist:isAlive()) then return end
	if not p.heist:hasSign() then return end

	if p.cmd.buttons & BT_TOSSFLAG
	and not (p.lastbuttons & BT_TOSSFLAG) then
		local sign

		for k,v in ipairs(p.heist.pickup_list) do
			if v.id == "Sign" then
				sign = v.mobj
				break
			end
		end

		if not sign then return end

		FangsHeist.Carriables.ReleaseCarriable(sign, false, true)

		P_InstaThrust(sign, p.mo.angle, 12*p.mo.scale)
		P_SetObjectMomZ(sign, 6*p.mo.scale)

		sign.momx = $+p.mo.momx
		sign.momy = $+p.mo.momy
		sign.momz = $+p.mo.momz

		S_StartSound(p.mo, sfx_s3k51)

		p.powers[pw_flashing] = 2*TICRATE
	end
end