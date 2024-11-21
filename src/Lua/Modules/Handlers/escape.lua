local function module()
	if not FangsHeist.Net.escape then
		return
	end

	FangsHeist.Net.time_left = max(0, $-1)

	if not (FangsHeist.Net.time_left) then
	end

	if not (FangsHeist.Net.sign
		and FangsHeist.Net.sign.valid) then
		return
	end

	local exit = FangsHeist.Net.exit
	exit.state = S_FH_EXIT_OPEN

	for p in players.iterate do
		if not p.heist then continue end
		if not FangsHeist.isPlayerAlive(p) then continue end
		if p.heist.exiting then
			P_SetOrigin(p.mo, exit.x, exit.y, exit.z)
			p.mo.flags2 = $|MF2_DONTDRAW
			p.camerascale = FU*3
			continue
		end

		if not FangsHeist.isPlayerAtGate(p) then
			continue
		end

		if p.cmd.buttons & BT_ATTACK
		and not (p.lastbuttons & BT_ATTACK) then
			p.heist.exiting = true
			p.heist.saved_profit = FangsHeist.returnProfit(p)

			if FangsHeist.playerHasSign(p) then
				FangsHeist.respawnSign(p)
			end
		end
	end
end
return module