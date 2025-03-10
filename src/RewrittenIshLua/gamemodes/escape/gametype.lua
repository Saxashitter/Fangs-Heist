// Escape: Fang's Heist's main mode.

local gamemode = {
	name = "Escape",
	desc = "Get that signpost, and get outta there!",
	treasures = true,
	pvp = true,
	teams = true,
	force_teams = false,
	pregame = true,
	spectate_on_death = false, // Switch to true once ingame and escape starts
	timer = false, // Switch to true once ingame and escape starts.
	team_limit = 2, // CAN and PROBABLY WILL be changed via cvars. this is a soft limit
	lives = false, // lives system from singleplayer is disabled here
}

local signpost = dofile "gamemodes/escape/mobjs/signpost.lua"

// Backend
function gamemode:load_items()
end

function gamemode:start_escape(starter)
	self.spectate_on_death = true
end

// Frontend
function gamemode:on_init(map)
end

function gamemode:on_player_init(p, map)
end

function gamemode:on_load()
end

function gamemode:on_sync(net)
end

function gamemode:on_update()
end

function gamemode:player_think(p)
end

function gamemode:can_end()
end

function gamemode:on_end()
end

function gamemode:music()
end

return FH:add_gametype(gamemode)