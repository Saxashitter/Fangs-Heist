local orig_plyr = FangsHeist.require"Modules/Variables/player"

local function valid_player(p)
	return p and p.mo and p.mo.health and p.heist and not p.heist.spectator and not p.heist.exiting
end

local function choose_player()
	local plyrs = {}
	for p in players.iterate do
		if valid_player(p) then
			table.insert(plyrs, p)
		end
	end

	if not (#plyrs) then
		return false
	end

	return plyrs[P_RandomRange(1, #plyrs)]
end

local function handleEggman()
	if not (FangsHeist.Net.eggman
		and FangsHeist.Net.eggman.valid) then
			local sign = FangsHeist.Net.sign
			local eggman = P_SpawnMobj(sign.x, sign.y, sign.z, MT_THOK)

			FangsHeist.Net.eggman = eggman
	end

	local eggman = FangsHeist.Net.eggman
	eggman.state = S_EGGMOBILE_STND
	eggman.fuse = -1
	eggman.tics = -1

	if not (eggman.target
		and eggman.target.valid
		and eggman.target.player
		and valid_player(eggman.target.player)) then
			local p = choose_player()

			if not p then
				return
			end

			eggman.target = p.mo
	end


	local p = eggman.target.player

	local x = p.mo.x
	local y = p.mo.y
	local z = p.mo.z

	p.heist.death_time = max(0, $-1)

	local t = FixedDiv(p.heist.death_time, orig_plyr.death_time)
	local distance = ease.linear(
		t,
		0,
		-240*FU
	)

	x = $+FixedMul(distance, cos(p.drawangle))
	y = $+FixedMul(distance, sin(p.drawangle))

	P_MoveOrigin(eggman,
		ease.linear(FU-(t/5), eggman.x, x),
		ease.linear(FU-(t/5), eggman.y, y),
		ease.linear(FU/5, eggman.z, z))

	eggman.angle = R_PointToAngle2(eggman.x, eggman.y, p.mo.x, p.mo.y)

	if not (p.heist.death_time)
	and p.mo
	and p.mo.valid then
		P_DamageMobj(p.mo, nil, nil, 999, DMG_INSTAKILL)
	end
end

local function module()
	if not FangsHeist.Net.escape then
		return
	end

	FangsHeist.Net.time_left = max(0, $-1)

	if not (FangsHeist.Net.time_left) then
		handleEggman()
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
			p.heist.saved_profit = FangsHeist.returnProfit(p)
			p.heist.exiting = true

			if FangsHeist.playerHasSign(p) then
				FangsHeist.respawnSign(p)
			end
		end
	end
end
return module