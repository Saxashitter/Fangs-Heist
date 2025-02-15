local showhud = CV_FindVar("showhud")

return function(p)
	if FangsHeist.Net.pregame then
		if not p.heist.confirmed_skin then
			local deadzone = 10
			if abs(p.heist.sidemove) >= deadzone
			and abs(p.heist.lastside) < deadzone then
				local sign = p.heist.sidemove >= 0 and 1 or -1
				
				--p.heist.locked_skin = max(0, min($+sign, #skins-1))
				p.heist.locked_skin = $+sign
				if p.heist.locked_skin < 0 then
					p.heist.locked_skin = #skins-1
				elseif p.heist.locked_skin > #skins-1 then
					p.heist.locked_skin = 0
				end

				S_StartSound(nil, sfx_menu1, p)
			end

			if p.heist.buttons & BT_JUMP
			and not (p.heist.lastbuttons & BT_JUMP) then
				p.heist.confirmed_skin = true
				S_StartSound(nil, sfx_strpst, p)
			end
		elseif (p.heist.buttons & BT_SPIN)
		and not (p.heist.lastbuttons & BT_SPIN) then
			p.heist.confirmed_skin = false
			S_StartSound(nil, sfx_alart, p)
		end

		if showhud.value == 0 then -- if the hud isn't being shown
			CV_StealthSet(showhud, 1) -- then force it to show :P
		end
	end
end