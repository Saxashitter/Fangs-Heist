local function btntic(p,tic,enum)
	local btn = p.cmd.buttons
	if btn & enum
		tic = $+1
	else
		tic = 0
	end
	return tic
end

-- Temporary character creation until' Luigi Budd adds proper support for Soap.
FangsHeist.makeCharacter("soapthehedge", {
	isAttacking = function(self, p)
		return (p.heist.attack_time) or p.mo.state == S_PLAY_MELEE
	end,
	controls = {
		{
			key = "C1",
			name = "Uppercut",
			cooldown = function(self, p)
				return (p.heist.attack_cooldown)
			end,
			visible = function(self, p)
				return not p.heist.blocking
			end
		},
		{
			key = "FIRE",
			name = "Attack",
			cooldown = function(self, p)
				return (p.heist.attack_cooldown)
			end,
			visible = function(self, p)
				return not p.heist.blocking
			end
		},
		{
			key = "FIRE NORMAL",
			name = "Block",
			cooldown = function(self, p)
				return (p.heist.attack_cooldown or p.heist.block_cooldown)
			end,
			visible = function(self, p)
				return true
			end
		}
	}
})

addHook("PlayerThink", function(p)
	if not FangsHeist.isMode() then return end
	if not (p.mo and p.mo.valid) then return end
	if p.mo.skin ~= "soapthehedge" then return end
	if not p.soaptable then return end

	-- Hacky fixes to make sure Soap isn't overpowered with the sign
	if p.soaptable.c1 == 1
	and p.soaptable.just_uppercut == 2
	and not p.soaptable.inPain
	and p.mo.health then
		-- Only launch Soap a bit.
		if FangsHeist.isPlayerNerfed(p) then
			Soap_ZLaunch(p.mo, 7*FU)
		end

		p.heist.attack_cooldown = 70
	end
end)

-- Be sure to override once Soap is added.
local OVERRIDDEN = false
addHook("AddonLoaded", do
	if OVERRIDDEN then return end
	if not Soap_ButtonStuff then return end

	OVERRIDDEN = true

	Takis_Hook.addHook("CanPlayerHurtPlayer",function(p1,p2, nobs)
	    if FangsHeist.isMode() then
	        return false
	    end
	end)

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
		and FangsHeist.isPlayerNerfed(p) then
			-- No dashing for you!
			soap.use = 2
		end
		if FangsHeist.isMode()
		and p.heist
		and p.heist.attack_cooldown then
			-- No uppercut either, if we are on cooldown.
			soap.c1 = 0
		end
	end)
end)