local B = CBW_Battle
local PR = CBW_PowerCards
B.InputControl = function(player)
	if not(player.ai and player.ai.enabled) -- If AI is determining ticcmd, it will have already set think vars for this frame; don't override!
		player.thinkmoveangle = B.GetInputAngle(player)
		player.thinkmovethrust = B.GetInputThrust(player)
		player.thinkbuttons = player.cmd.buttons
	end
	
	if B.Exiting
		player.cmd.sidemove = 0
		player.cmd.forwardmove = 0
		player.cmd.buttons = 0
	end
	
	if player.playerstate != PST_LIVE or player.spectator
		return
	end
	if player.lockaim and player.mo then //Aim is being locked in place
		player.cmd.aiming = player.aiming>>16
		player.cmd.angleturn = player.mo.angle>>16
	end
	if player.pflags&PF_STASIS then
		//Failsafe for simple controls
		player.cmd.sidemove = 0
		player.cmd.forwardmove = 0
	end
	if player.lockmove
		player.cmd.sidemove = 0
		player.cmd.forwardmove = 0
		player.cmd.buttons = 0
	end
	if player.melee_state
		if player.melee_charge < FRACUNIT
			player.cmd.forwardmove = $ / 3
			player.cmd.sidemove = $ / 3
		else
			player.cmd.forwardmove = 0
			player.cmd.sidemove = 0
			player.lockmove = true
		end
	end

	if player.gotpowercard and player.gotpowercard.valid
		local card = player.gotpowercard
		local item = PR.Item[card.item]
		if item.flags&PCF_NOSPIN
			player.cmd.buttons = $&~BT_SPIN
		end
	end

end

B.GetInputAngle = function(player)
	local mo = player.mo
	if not mo
		mo = player.truemo
	end
	
	if mo and mo.valid
		if (mo.flags2&MF2_TWOD or twodlevel)
			return mo.angle
		end
		local fw = player.cmd.forwardmove
		local sw = player.cmd.sidemove
		-- 	local pang = player.cmd.angleturn << 16//is this netsafe?
		local analog = player.pflags&PF_ANALOGMODE

		local pang = mo.angle

		if fw == 0 and sw == 0 then
			return pang
		end

		if analog
			pang = player.cmd.angleturn<<FRACBITS
		end

		local c0, s0 = cos(pang), sin(pang)


		local rx, ry = fw*c0 + sw*s0, fw*s0 - sw*c0
		local retangle = R_PointToAngle2(0, 0, rx, ry)
		return retangle
	end
end

B.GetInputThrust = function(player)
	local fwd = player.cmd.forwardmove*FRACUNIT/50
	local side = player.cmd.sidemove*FRACUNIT/50
	local thrust = R_PointToDist2(fwd, side, 0, 0)
	if thrust < FRACUNIT/5 -- C-Stick deadzone
		return 0
	else
		return thrust
	end
end

B.ButtonCheck = function(player,button)
	if player.cmd.buttons&button then
		if player.buttonhistory&button then
			return 2
		else
			return 1
		end
	end
	return 0
end