local dialogue = FangsHeist.require "Modules/Handlers/dialogue"
local orig = FangsHeist.require"Modules/Variables/player"

sfxinfo[freeslot "sfx_gogogo"].caption = "G-G-G-G-GO! GO! GO!"
sfxinfo[freeslot "sfx_nargam"].caption = "GAME!"

FangsHeist.escapeThemes = {
	{"SPRHRO", true},
	--{"THECUR", true},
	--{"WILFOR", true},
	--{"LUNCLO", true}
	// if the second argument is false, the hurry up music wont play
}
function FangsHeist.startEscape(p)
	if FangsHeist.Net.escape
	or HeistHook.runHook("EscapeStart", p) == true then
		return
	end

	FangsHeist.Net.escape = true
	S_StartSound(nil, sfx_gogogo)

	FangsHeist.changeBlocks()
	local data = mapheaderinfo[gamemap]
	if data.fh_escapelinedef then
		P_LinedefExecute(tonumber(data.fh_escapelinedef))
	end

	if displayplayer
	and displayplayer.valid then
		FangsHeist.doSignpostWarning(FangsHeist.playerHasSign(displayplayer))
	end
end

local function profsort(a, b)
	return a[4] > b[4]
end

function FangsHeist.startIntermission()
	if FangsHeist.Net.game_over
	or HeistHook.runHook("GameOver") == true then
		return
	end

	S_StartSound(nil, sfx_nargam)

	// map vote for the funny
	if FangsHeist.isServer() then
		local maps = {}
		local checked = {}

		for i = 1,1024 do
			if not (mapheaderinfo[i] and mapheaderinfo[i].typeoflevel & TOL_HEIST) then
				continue
			end
	
			table.insert(maps, i)
		end

		for i = 1, 3 do
			if not (#maps) then
				break
			end

			local key = P_RandomRange(1, #maps)
			local map = maps[key]

			table.insert(FangsHeist.Net.map_choices, {
				map = map,
				votes = 0
			})
	
			table.remove(maps, key)
		end

		local str = ""

		for i,data in ipairs(FangsHeist.Net.map_choices) do
			str = $..tostring(data.map)..","..tostring(data.votes)
			if i ~= #FangsHeist.Net.map_choices then
				str = $.."^"
			end
		end

		COM_BufInsertText(server, "fh_receivemapvote "..str)
	end

	local scores = FangsHeist.Save.ServerScores
	if not scores[gamemap] then
		scores[gamemap] = {}
	end

	for p in players.iterate do
		if not FangsHeist.isPlayerAlive(p)
		or not p.heist then
			continue
		end

		table.insert(scores[gamemap], {
			p.mo.skin,
			skincolors[p.mo.color].name,
			p.name,
			FangsHeist.returnProfit(p)
		})
	end

	table.sort(scores[gamemap], profsort)

	if #scores[gamemap] > 12 then
		for i = 12,#scores[gamemap] do
			scores[gamemap][i] = nil
		end
	end

	if FangsHeist.isServer() then
		local f = io.openlocal("client/FangsHeist/serverScores.txt", "w+")
		if f then
			f:write(FangsHeist.ServerScoresToString())
			f:flush()
			f:close()
		end
	end

	S_FadeMusic(0, MUSICRATE/2)

	for mobj in mobjs.iterate() do
		if not (mobj and mobj.valid) then return end

		mobj.flags = $|MF_NOTHINK
	end

	FangsHeist.Net.game_over = true
	FangsHeist.Net.end_anim = 6*TICRATE
	S_ChangeMusic("FH_WIN", false)
end

local oppositefaces = {
	--awake to asleep
	["JOHNBLK1"] = "JOHNBLK0",
	--asleep to awake
	["JOHNBLK0"] = "JOHNBLK1",
}

function FangsHeist.changeBlocks()
	for sec in sectors.iterate do
		for rover in sec.ffloors() do
			if not rover.valid then continue end
			local side = rover.master.frontside
			
			if not (side.midtexture == R_TextureNumForName("JOHNBLK1")
			or side.midtexture == R_TextureNumForName("JOHNBLK0")) then
			--or side.midtexture == R_TextureNumForName("TKISBKB1")
			--or side.midtexture == R_TextureNumForName("TKISBKB2"))
				continue
			end
			
			local oppositeface = oppositefaces[
				string.sub(R_TextureNameForNum(side.midtexture),1,8)
			]
				
			--???????
			if oppositeface == nil then continue end
			
			if rover.flags & FOF_SOLID
			--awake to asleep
				rover.flags = $|FOF_TRANSLUCENT|FOF_NOSHADE &~(FOF_SOLID|FOF_CUTLEVEL|FOF_CUTSOLIDS)
				rover.alpha = 128
			else
			--asleep to awake
				rover.flags = $|FOF_SOLID|FOF_CUTLEVEL|FOF_CUTSOLIDS &~(FOF_TRANSLUCENT|FOF_NOSHADE)
				rover.alpha = 255
			end
			side.midtexture = R_TextureNumForName(oppositeface)
		end
	end
end

function FangsHeist.joinTeam(p, sp)
	if sp.heist.team.leader == sp
	and FangsHeist.getTeamLength(sp) > 0 then
		local ps = {}
		for k,v in pairs(sp.heist.team.players) do
			if k == sp then continue end

			table.insert(ps, k)
		end
		sp.heist.team.leader = ps[P_RandomRange(1, #ps)]
	end

	sp.heist.team.players[sp] = nil
	p.heist.team.players[sp] = true

	sp.heist.team = p.heist.team
end

local function sac(name, caption)
	local sfx = freeslot(name)

	sfxinfo[sfx].caption = caption

	return sfx
end

local function return_player(p)
	if tonumber(p) ~= nil then
		p = tonumber(p)

		if (players[p] and players[p].valid) then
			return players[p]
		end
	end

	for checkp in players.iterate do
		if checkp.name == p then
			return checkp
		end
	end
end

--[[COM_AddCommand("fh_jointeam", function(p, sp)
	if not FangsHeist.isMode() then return end
	if not FangsHeist.Net.pregame then
		CONS_Printf(p, "This can only be done during Pre-game!")
		return
	end

	sp = return_player($)
	if not (sp and sp.heist) then
		CONS_Printf(p, "That's not a valid player.")
		return
	end

	if p.heist.team.players[sp] then
		CONS_Printf(p, "This player is in your team.")
		return
	end

	if sp.heist.team.leader ~= sp then
		CONS_Printf(p, "This player isn't the leader.")
		return
	end

	if sp.heist.invites[p] then
		CONS_Printf(p, "You already requested to join this player.")
		return
	end

	local length = FangsHeist.getTeamLength(sp)
	if length >= 2 then
		CONS_Printf(p, "This player's team is full.")
		return
	end

	sp.heist.invites[p] = true
	CONS_Printf(sp, p.name.." has requested to join your team!")
	CONS_Printf(sp, "Use \"fh_acceptrequest "..#p.."\" to accept their request!")

	CONS_Printf(p, "Request successful.")
end)

COM_AddCommand("fh_acceptrequest", function(p, sp)
	if not FangsHeist.isMode() then return end
	if not FangsHeist.Net.pregame then
		CONS_Printf(p, "This can only be done during Pre-game!")
		return
	end

	sp = return_player($)
	if not (sp and sp.heist) then
		CONS_Printf(p, "That's not a valid player.")
		return
	end

	if not p.heist.invites[sp] then
		CONS_Printf(p, "This player never requested to join you.")
		return
	end

	local length = FangsHeist.getTeamLength(p)
	if length >= 2 then
		CONS_Printf(p, "Your team is full.")
		CONS_Printf(sp, "This player's team is full.")
		return
	end

	FangsHeist.joinTeam(p, sp)
	CONS_Printf(p, "Team successful.")
	CONS_Printf(sp, "Team successful.")
end)]]