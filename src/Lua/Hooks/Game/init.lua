local orig_net = FangsHeist.require "Modules/Variables/net"
local dialogue = FangsHeist.require "Modules/Handlers/dialogue"

local scripts = {}
local add = function(name)
	table.insert(scripts, dofile("Hooks/Game/Scripts/"..name))
end

// Mode initialization.
addHook("MapChange", function(map)
	if not multiplayer then
		mapmusname = mapheaderinfo[map].musname or $
	end

	FangsHeist.initMode(map)
end)

addHook("NetVars", function(n)
	/*FangsHeist.Net = n($)
	FangsHeist.Save = n($)*/

	local net = {
		"gamemode",
		"map_choices",
		"game_over",
		"game_over_ticker",
		"game_over_length",
		"retaking",
		"selected_map",
		"end_anim",
		"retake_anim",
		"pregame",
		"pregame_time",
		"pregame_cam",
		"placements",
		"teams",
		"treasures",
		"last_profit"
	}
	local save = {
		"last_map",
		"retakes",
		"ServerScores"
	}

	for _,v in ipairs(net) do
		FangsHeist.Net[v] = n($)
	end
	for _,v in ipairs(save) do
		FangsHeist.Save[v] = n($)
	end

	local gamemode = FangsHeist.getGamemode()
	gamemode:sync(n)
end)

addHook("MapLoad", do
	if not FangsHeist.isMode() then
		return
	end

	FangsHeist.loadMap()
end)

addHook("PreThinkFrame", do
	if not FangsHeist.isMode() then
		return
	end

	for p in players.iterate do
		if not p.heist then continue end

		p.heist.lastbuttons = p.heist.buttons

		p.heist.buttons = p.cmd.buttons

		p.heist.lastforw = p.heist.forwardmove
		p.heist.lastside = p.heist.sidemove

		p.heist.forwardmove = p.cmd.forwardmove
		p.heist.sidemove = p.cmd.sidemove

		if p.heist:isAlive() then
			if p.heist.exiting then
				p.cmd.buttons = 0
				p.cmd.forwardmove = 0
				p.cmd.sidemove = 0
			end
		end
		if FangsHeist.Net.game_over
		or FangsHeist.Net.pregame then
			p.cmd.buttons = 0
			p.cmd.sidemove = 0
			p.cmd.forwardmove = 0
		end
	end
end)

addHook("ThinkFrame", do
	if not FangsHeist.isMode() then
		return
	end
	local stop = false

	dialogue.tick()

	for i,script in ipairs(scripts) do
		if script() then
			return
		end
	end

	local gamemode = FangsHeist.getGamemode()
	gamemode:update()

	-- manage music
	local song
	local volume
	local loop

	song, loop, volume = gamemode:music()

	local custom, custom2, custom3 = HeistHook.runHook("Music", song)
	if type(custom) == "string" then
		song = custom
	end
	if type(custom2) == "boolean" then
		loop = custom2
	end
	if type(custom3) == "number" then
		volume = custom3
	end

	if song
	and mapmusname ~= song then
		mapmusname = song
		S_ChangeMusic(song, loop)
	end
	if song
	and volume ~= nil then
		S_SetInternalMusicVolume(volume)
	end

	// dialogue.tick()
end)

addHook("PostThinkFrame", do
	local p = displayplayer

	if not FangsHeist.isMode() then return end
	if multiplayer then return end
	if not (p and p.heist) then return end

	if (p.exiting or p.pflags & PF_FINISHED)
	and not p.heist.exiting then
		p.exiting = 0
		p.pflags = $ & ~(PF_FINISHED|PF_FULLSTASIS)
	end
end)

add("Team")
add("Placements")
add("Pregame")
add("Game Over")