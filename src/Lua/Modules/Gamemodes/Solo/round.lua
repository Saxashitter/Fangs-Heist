local gamemode = {}

function gamemode:spawnRound2Portal(pos)
	local mobj = P_SpawnMobj(pos.x, pos.y, pos.z, MT_THOK)
	mobj.angle = pos.a
	mobj.flags = $|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY|MF_NOBLOCKMAP
	mobj.state = S_FH_ROUNDPORTAL
	mobj.destscale = 2*FU
	mobj.scale = 2*FU

	FangsHeist.Net.round_2_mobj = mobj
	self:manageRing(mobj, not FangsHeist.Net.escape, true)
end

function gamemode:round2Check()
	if not FangsHeist.Net.round_2 then
		return
	end

	local mobj = FangsHeist.Net.round_2_mobj

	for p in players.iterate do
		if not (p.heist and p.heist:isAlive()) then continue end
		if p.heist.reached_second then continue end

		if R_PointToDist2(p.mo.x,p.mo.y,mobj.x,mobj.y) > 24*FU+p.mo.radius then
			continue
		end
		if p.mo.z > mobj.z+50*mobj.scale then
			continue
		end
		if mobj.z > p.mo.z+p.mo.height then
			continue
		end

		self:doRound2(p)
	end
end

function gamemode:doRound2(p)
	if not FangsHeist.Net.round_2 then return end
	if p.heist.reached_second then return end
	if FangsHeist.runHook("Round2", p) then return end

	local pos = FangsHeist.Net.round_2_teleport.pos

	P_SetOrigin(p.mo,
		pos[1],
		pos[2],
		pos[3]
	)
	
	p.mo.angle = pos[4]
	p.drawangle = pos[4]
	
	p.heist.reached_second = true
	
	S_StartSound(nil, sfx_mixup, p)
	P_InstaThrust(p.mo, p.mo.angle, FixedHypot(p.rmomx, p.rmomy))

	local linedef = tonumber(mapheaderinfo[gamemap].fh_round2linedef)
	
	if linedef ~= nil then
		P_LinedefExecute(linedef)
	end

	if p == displayplayer then
		FangsHeist.doRound2HUD()
	end
end

return gamemode