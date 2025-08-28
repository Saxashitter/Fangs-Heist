
local orig_net = FangsHeist.require "Modules/Variables/net"
local scripts = {}
local add = function(name)
	table.insert(scripts, dofile("Hooks/Game/Scripts/"..name))
end

// Mode initialization.
addHook("MapChange", function(map)
	if not multiplayer then
		mapmusname = mapheaderinfo[map].musname or $
	end

	FangsHeist.defCharList()
	FangsHeist.initMode(map)
end)

addHook("NetVars", function(n)
	FangsHeist.Net = n($)
	FangsHeist.Save = n($)

	/*local net = {
		"gamemode",
		"map_choices",
		"game_over",
		"game_over_ticker",
		"game_over_length",
		"game_over_winline",
		"pregame",
		"pregame_time",
		"pregame_transparency",
		"placements",
		"teams",
		"treasures",
		"last_profit"
	}
	local save = {
		"last_map",
		"retakes"
	}

	for _,v in ipairs(net) do
		FangsHeist.Net[v] = n($)
	end
	for _,v in ipairs(save) do
		FangsHeist.Save[v] = n($)
	end*/

	--local gamemode = FangsHeist.getGamemode()
	--gamemode:sync(n)
end)

addHook("MapLoad", do
	if not FangsHeist.isMode() then
		return
	end

	FangsHeist.loadMap()
end)

addHook("ThinkFrame", do
	if not FangsHeist.isMode() then
		return
	end

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

	local custom, custom2, custom3 = FangsHeist.runHook("Music", song)
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
	if not FangsHeist.isMode() then return end
	if FangsHeist.Net.pregame
	or FangsHeist.Net.game_over then
		return
	end

	local gamemode = FangsHeist.getGamemode()
	gamemode:postthink()
end)
addHook("PreThinkFrame", do
	if not FangsHeist.isMode() then return end
	if FangsHeist.Net.pregame
	or FangsHeist.Net.game_over then
		return
	end

	local gamemode = FangsHeist.getGamemode()
	gamemode:prethink()
end)

addHook("GameQuit", FangsHeist.initHUD)

add("Team")
add("Placements")
add("Pregame")
add("Game Over")