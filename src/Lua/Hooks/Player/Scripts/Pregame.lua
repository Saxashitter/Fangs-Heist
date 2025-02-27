local showhud = CV_FindVar("showhud")

local function valid(p, sp)
	return sp
	and sp.valid
	and sp.heist
	and sp ~= p
	and not sp.heist.invites[p]
	and not FangsHeist.partOfTeam(p, sp)
	and sp.heist.team.leader == sp
	and FangsHeist.getTeamLength(p) < 2
end

// yes i know this code is weird
// gotta refactor a bunch of it during demo 2
local function manage_players(p)
	local plyrs = {}
	local invs = {}

	for i = 0,31 do
		local sp = players[i]

		if not valid(p, sp) then
			continue
		end

		table.insert(plyrs, sp)
		if p.heist.invites[sp] then
			table.insert(invs, sp)
		end
	end

	p.heist.playersList = plyrs
	p.heist.invitesList = invs
end

return function(p)
	if not FangsHeist.Net.pregame then
		return
	end

	manage_players(p)

	local deadzone = 25
	local horz = abs(p.heist.sidemove) >= deadzone
		and abs(p.heist.lastside) < deadzone
	local vert = abs(p.heist.forwardmove) >= deadzone
		and abs(p.heist.lastforw) < deadzone

	local x = p.heist.sidemove >= 0 and 1 or -1
	local y = p.heist.forwardmove >= 0 and 1 or -1

	// Skin Select
	if not p.heist.confirmed_skin then
		if horz then
			p.heist.locked_skin = $+x

			if p.heist.locked_skin < 0
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
	// Team Select
	elseif not p.heist.locked_team then
		// -1 == Players
		// 0 == Ready button
		// 1 == Requests

		if p.heist.team.leader ~= p then
			p.heist.cur_menu = 0
		elseif horz then
			p.heist.cur_menu = max(-1, min($+x, 1))
			p.heist.cur_sel = 1
			p.heist.hud_sel = 8
			S_StartSound(nil, sfx_menu1, p)
		end

		local length = 0

		if p.heist.cur_menu == -1 then
			length = #p.heist.playersList
		end
		if p.heist.cur_menu == 1 then
			length = #p.heist.invitesList
		end

		if length then
			if vert then
				p.heist.cur_sel = max(1, min($-y, length))
				p.heist.hud_sel = max(8, p.heist.cur_sel)
				S_StartSound(nil, sfx_menu1, p)
			end
		else
			p.heist.cur_sel = 1
			p.heist.hud_sel = 8
		end

		if p.heist.buttons & BT_JUMP
		and not (p.heist.lastbuttons & BT_JUMP) then
			if p.heist.cur_menu == -1 then
				local sp = p.heist.playersList[p.heist.cur_sel]
	
				if sp
				and sp.valid
				and sp.heist
				and sp.heist.team.leader == sp then
					sp.heist.invites[p] = true
					S_StartSound(nil, sfx_strpst, p)
				end
			end
			if p.heist.cur_menu == 1 then
				local sp = p.heist.invitesList[p.heist.cur_sel]
	
				if sp
				and sp.valid
				and sp.heist then
					p.heist.invites[sp] = nil
					p.heist.cur_sel = max(1, $-1)
					p.heist.hud_sel = max(8, p.heist.cur_sel)
					for tp,_ in pairs(sp.heist.invites) do
						sp.heist.invites[tp] = nil
					end
					FangsHeist.joinTeam(p, sp)
					S_StartSound(nil, sfx_strpst, p)
				end
			end
			if p.heist.cur_menu == 0 then
				p.heist.locked_team = true
				S_StartSound(nil, sfx_strpst, p)
			end
		end

		if (p.heist.buttons & BT_SPIN)
		and not (p.heist.lastbuttons & BT_SPIN) then
			p.heist.confirmed_skin = false
			S_StartSound(nil, sfx_alart, p)
		end
	elseif (p.heist.buttons & BT_SPIN)
	and not (p.heist.lastbuttons & BT_SPIN) then
		p.heist.locked_team = false
		S_StartSound(nil, sfx_alart, p)
	end

	if showhud.value == 0 then -- if the hud isn't being shown
		CV_StealthSet(showhud, 1) -- then force it to show :P
	end
end