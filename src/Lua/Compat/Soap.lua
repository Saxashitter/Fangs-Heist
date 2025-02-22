local function btntic(p,tic,enum)
	local btn = p.cmd.buttons
	if btn & enum
		tic = $+1
	else
		tic = 0
	end
	return tic
end

addHook("PlayerThink", function(p)
	if not FangsHeist.isMode() then return end
	if not (p.mo and p.mo.valid) then return end
	if p.mo.skin ~= "soapthehedge" then return end
	if not p.soaptable then return end

	-- Hacky fixes to make sure Soap isn't overpowered with the sign
	if FangsHeist.playerHasSign(p) then
		if p.soaptable.c1 == 1
		and p.soaptable.just_uppercut == 2
		and not p.soaptable.inPain
		and p.mo.health then
			-- Only launch Soap a bit.
			Soap_ZLaunch(p.mo, 7*FU)
		end
	end
end)

-- Be sure to override once Soap is added.
local OVERRIDDEN = false
addHook("AddonLoaded", do
	if OVERRIDDEN then return end
	if not Soap_ButtonStuff then return end

	OVERRIDDEN = true

	rawset(_G,"Soap_ButtonStuff", function(p)
		local soap = p.soaptable
		
		soap.jump = btntic(p,$,BT_JUMP)
		soap.use = btntic(p,$,BT_USE)
		soap.tossflag = btntic(p,$,BT_TOSSFLAG)
		soap.c1 = btntic(p,$,BT_CUSTOM1)
		soap.c2 = btntic(p,$,BT_CUSTOM2)
		soap.c3 = btntic(p,$,BT_CUSTOM3)
		soap.weaponnext = btntic(p,$,BT_WEAPONNEXT)
		soap.weaponprev = btntic(p,$,BT_WEAPONPREV)
	
		-- FANGS HEIST
		if FangsHeist.isMode()
		and p.heist
		and FangsHeist.playerHasSign(p) then
			-- No dashing for you!
			soap.use = 2
		end
	end)
end)