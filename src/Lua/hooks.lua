-- code by unmatched bracket and jisk and luigi

rawset(_G, "HeistHook", {})
HeistHook.events = {}

/*
	return value: Boolean (override default behavior?)
	true = override, otherwise hook is ran then the default function after
*/
local handler_snaptrue = {
	func = function(current, result)
		return result or current
	end,
	initial = false
}

/*
	if true, then the default func will run
	if false, then the default func will be forced to not run
	if nil, use the default behavior
	...generally
*/
local handler_snapany = {
	func = function(current, result)
		if result ~= nil then
			return result
		else
			return current
		end
	end,
	initial = nil
}
local handler_default = handler_snaptrue

local typefor_mobj = function(this_mobj, type)
	return this_mobj.type == type
end

local events = {}

// HOOKS
	// Example:
	/*HeistHook.addHook("GameInit", function()
		print("I am initalized!")
	end)*/

events["GameInit"] = {}
// GameInit:
	// Runs after the gametype is initalized.
	// No arguments are passed.

events["PlayerInit"] = {}
// PlayerInit:
	// Runs after the player has been initalized.
	// Arguments:
		// player == player_t

events["GameLoad"] = {}
// GameLoad:
	// Runs after the gametype spawns objects.
	// No arguments are passed.

events["GameStart"] = {}
// GameStart:
	// Runs when pre-game ends.
	// No arguments are passed.

events["EscapeStart"] = {}
// EscapeStart:
	// Runs when escape sequences start.
	// return true: Stops the code from running.
	// Arguments:
		// starter == player_t

events["PlayerExit"] = {}
// PlayerExit:
	// Runs when player runs to a exit.
	// return true: Stops the code from running.
	// Arguments:
		// exiter == player_t

events["TimeUp"] = {}
// TimeUp:
	// Runs when time runs out.
	// No arguments are passed.

events["GameOver"] = {}
// GameOver:
	// Runs when the game ends.
	// return true: Stops the game from ending.
	// No arguments are passed.

events["PlayerAttack"] = {}
// PlayerAttack:
	// Runs before the player attacks using Fire.
	// return true: Stop the default behavior.
	// Arguments:
		// player == player_t

events["PlayerParry"] = {}
// PlayerParry:
	// Runs before the player attempts to parry.
	// return true: Stop the default behavior.
	// Arguments:
		// player == player_t
		
events["PlayerParried"] = {}
// PlayerParry:
	// Runs when the player parries another player.
	// Arguments:
		// parrier == player_t
		// parried == player_t

events["PlayerParriedEnemy"] = {}
// PlayerParry:
	// Runs when the player parries a enemy or a projectile.
	// Arguments:
		// parrier == player_t
		// parried == mobj_t

events["PlayerClash"] = {}
// PlayerClash:
	// Runs when the player clashes with another.
	// Arguments:
		// first_clasher == player_t
		// second_clasher == player_t

events["PlayerHit"] = {}
// PlayerHit:
	// Runs when the player hits another player.
	// Arguments:
		// attacker == player_t
		// victim == player_t

events["PlayerAirDodge"] = {}
// PlayerAirDodge:
	// Runs when the player air-dodges.
	// Arguments:
		// player == player_t

events["PlayerScanAttack"] = {}
// PlayerScanAttack:
	// Runs before the check to scan around the player to attack.
	// return true/false: Runs the attack scan.
	// Arguments:
		// player == player_t

events["Round2"] = {}
// Round2:
	// Runs when the player heads to the teleporter for the second part of Final Demo stages.
	// return true: Stops the code from running.
	// Arguments:
		// player == player_t

events["Music"] = {handler = handler_snapany}
// Music:
	// Returns the appropriate music that should be playing.
	// return string: Overrides the music that's supposed to be playing with the returned string.
	// Arguments:
		// song == string

HeistHook.addHook = function(hooktype, func, typefor)
	if events[hooktype] then
		table.insert(events[hooktype], {
			func = func,
			typedef = typefor,
			errored = false
		})
	else
		error("\x82WARNING:\x80 Hook type \""..hooktype.."\" does not exist.", 2)
	end
end

HeistHook.runHook = function(hooktype, ...)
	if not events[hooktype] then
		error("\x82WARNING:\x80 Can't run a nonexistant hooktype! (\""..hooktype..'"', 2)
	end
	
	local handler = events[hooktype].handler or handler_default
	local override = handler.initial

    for i,v in ipairs(events[hooktype]) do
		if events[hooktype].typefor ~= nil
			if events[hooktype].typefor( ({...})[1], v.typedef) == false then continue end
		end
		
		local status, result = pcall(v.func, ...)
		if status then
			override = handler.func(override, result)
		elseif not v.errored then
			v.errored = true
			print("\x82WARNING:\x80 Hook " .. hooktype .. " handler #" .. i .. " error:")
			print(result)
		end
    end

    return override
end

--check for new events...
for event_name, event_t in pairs(events)
	if (HeistHook.events[event_name] == nil)
		HeistHook.events[event_name] = event_t
	else
		print("\x80 Hooklib found an existing hookevent, not adding. (\""..event_name..'")')
	end
end