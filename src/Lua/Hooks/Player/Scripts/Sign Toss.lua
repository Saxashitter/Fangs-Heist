return function(p)
	if not (p.heist and p.heist:isAlive()) then return end
	if #p.heist.pickup_list == 0 then return end

	if p.cmd.buttons & BT_TOSSFLAG
	and not (p.lastbuttons & BT_TOSSFLAG) then
		local item = p.heist.pickup_list[#p.heist.pickup_list]
		if not item then return end
		item = $.mobj

		FangsHeist.Carriables.ReleaseCarriable(item, false, true)

		P_InstaThrust(item, p.mo.angle, 12*p.mo.scale)
		P_SetObjectMomZ(item, 6*p.mo.scale)

		item.momx = $+p.mo.momx
		item.momy = $+p.mo.momy
		item.momz = $+p.mo.momz

		S_StartSound(p.mo, sfx_s3k51)

		p.powers[pw_flashing] = 2*TICRATE
	end
end