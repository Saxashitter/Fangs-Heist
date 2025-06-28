-- Should match hud_disable_options in lua_hudlib.c
-- taken from customhud

local defaultitems = {
	{"stagetitle", "titlecard"},
	{"textspectator", "game"},
	{"crosshair", "game"},

	{"score", "game"},
	{"time", "game"},
	{"rings", "game"},
	{"lives", "game"},

	{"weaponrings", "game"},
	{"powerstones", "game"},
	{"teamscores", "gameandscores"},

	{"nightslink", "game"},
	{"nightsdrill", "game"},
	{"nightsrings", "game"},
	{"nightsscore", "game"},
	{"nightstime", "game"},
	{"nightsrecords", "game"},

	{"rankings", "scores"},
	{"coopemeralds", "scores"},
	{"tokens", "scores"},
	{"tabemblems", "scores"},

	{"intermissiontally", "intermission"},
	{"intermissiontitletext", "intermission"},
	{"intermissionmessages", "intermission"},
	{"intermissionemeralds", "intermission"},
}

customhud.SetupFont("FHFNT")
customhud.SetupFont("FHBFT")

local function is_hud_modded(name)
	for k,v in ipairs(defaultitems) do
		if name == v[1] then
			return false
		end
	end

	return true
end

local WAS_FH = false
local MOD_NAME = "FANGSHEIST"

local function make_wrapper(object)
	if not (object and object.draw) then return end
	local draw = object.draw

	return function(...)
		if not (displayplayer and displayplayer.heist) then return end

		draw(...)
	end
end

local function add(name)
	local obj,hudtype = dofile("behaviors/hud/"..name)

	if obj.draw then
		obj.draw = make_wrapper(obj)
	end
	if obj.init then
		obj.init()
	end
	obj.__name = name

	table.insert(FH_HUD, {name, obj or {}, hudtype or "game"})
end

addHook("HUD", function(v,p,c)
	if FangsHeist.isMode() then
		for i, data in ipairs(FH_HUD) do
			local name = data[1]
			local object = data[2]
			local hudtype = data[3]

			if (is_hud_modded(name)
			and not customhud.ItemExists(name))
			or not is_hud_modded(name) then
				customhud.SetupItem(name, MOD_NAME, object.draw, hudtype, i)
				continue
			end

			customhud.enable(name)
		end
		
		WAS_FH = true
		return
	end

	if WAS_FH then
		for i,data in ipairs(FangsHeist.Objects) do
			if not is_hud_modded(data[1]) then
				customhud.SetupItem(data[1], "vanilla")
				continue
			end

			customhud.disable(data[1])
		end
	end
	
	WAS_FH = false
end)

add("signtracker")
add("treasuretracker")
add("controls")
add("lives")
add("score")
add("rings")
add("time")
add("textspectator")
add("treasure")
add("timer")
add("round")
add("gogogo")
add("discord")
add("leftscores")
add("rankings")
add("intermission")
add("pregame")