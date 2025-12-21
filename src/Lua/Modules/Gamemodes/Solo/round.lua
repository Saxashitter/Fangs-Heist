local gamemode = {}

gamemode.round2_tpdelay = 35
gamemode.round2_shootout = 35
gamemode.round2_fadeout = 35

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
		if p.heist.round_anim then continue end

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

	--[[P_SetOrigin(p.mo,
		pos[1],
		pos[2],
		pos[3]
	)
	
	p.mo.angle = pos[4]
	p.drawangle = pos[4]

	S_StartSound(p.mo, sfx_s1c3)
	S_StartSound(p.mo, sfx_s227, p)
	p.heist.reached_second = true
	
	P_InstaThrust(p.mo, p.mo.angle, FixedHypot(p.rmomx, p.rmomy))

	local linedef = tonumber(mapheaderinfo[gamemap].fh_round2linedef)
	
	if linedef ~= nil then
		P_LinedefExecute(linedef)
	end

	if p == displayplayer then
		FangsHeist.doRound2HUD()
	end]]

	S_StartSound(p.mo, sfx_s1c3)

	p.heist.round_tpdelay = self.round2_tpdelay or 0
	p.heist.round_shootout = self.round2_shootout or 0
	p.heist.round_fadeout = self.round2_fadeout or 0
	p.heist.round_anim = true
end

function gamemode:manageRound2Animation(p)
	if not p.heist.round_anim then
		return
	end

	if p.heist.round_tpdelay or p.heist.round_fadeout then
		local pos = FangsHeist.Net.round_2_mobj

		P_SetOrigin(p.mo,
			pos.x, pos.y, pos.z+pos.height/2-p.mo.height/2
		)
		p.drawangle = pos.angle
		p.mo.momx = 0
		p.mo.momy = 0
		p.mo.momz = 0
		p.mo.flags2 = $|MF2_DONTDRAW
		p.powers[pw_flashing] = 2*TICRATE

		if p.heist.round_fadeout then
			p.heist.round_fadeout = $ - 1
		else
			p.heist.round_tpdelay = $ - 1
		end

		if not p.heist.round_tpdelay then
			local pos = FangsHeist.Net.round_2_teleport

			-- flash spooky
			local linedef = tonumber(mapheaderinfo[gamemap].fh_round2linedef)
			if linedef ~= nil then
				P_LinedefExecute(linedef)
			end

			p.heist.reached_second = true
			p.mo.angle = pos.angle
			if p == displayplayer then
				FangsHeist.doRound2HUD()
			end
		end

		return
	end

	if p.heist.round_shootout then
		local pos = FangsHeist.Net.round_2_teleport

		P_SetOrigin(p.mo,
			pos.x, pos.y, pos.z+pos.height/2-p.mo.height/2
		)
		p.drawangle = pos.angle
		p.mo.momx = 0
		p.mo.momy = 0
		p.mo.momz = 0
		p.powers[pw_flashing] = 2*TICRATE
		p.mo.flags2 = $|MF2_DONTDRAW
		
		p.heist.round_shootout = $ - 1

		if not p.heist.round_shootout then
			P_InstaThrust(p.mo, pos.angle, 35*p.mo.scale)
			p.mo.flags2 = $ & ~MF2_DONTDRAW
			p.cmd.buttons = p.heist.buttons
			p.lastbuttons = p.heist.lastbuttons
			p.heist.round_anim = false
			S_StartSound(p.mo, sfx_s1c3)
			p.pflags = $ & ~(PF_SPINNING|PF_JUMPED|PF_STARTJUMP|PF_STARTDASH|PF_BOUNCING)
			p.mo.state = S_PLAY_FALL
			p.heist.round_debounce = 10
		end

		return
	end
end

return gamemode