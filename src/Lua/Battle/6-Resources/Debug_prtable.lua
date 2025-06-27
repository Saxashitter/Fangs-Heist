/*
	Debug function for obtaining table information.
	Shoutouts to LJ for being a champ
*/
rawset(_G, "prtable", function(text, t, prefix, cycles)
    prefix = $ or ""
    cycles = $ or {}

    print(prefix..text.." = {")

    for k, v in pairs(t)
        if type(v) == "table"
            if cycles[v]
                print(prefix.."    "..tostring(k).." = "..tostring(v))
            else
                cycles[v] = true
                prtable(k, v, prefix.."    ", cycles)
            end
        elseif type(v) == "string"
            print(prefix.."    "..tostring(k)..' = "'..v..'"')
        else
			if type(v) == "userdata" and v.valid and v.name
				v = v.name
			end
            print(prefix.."    "..tostring(k).." = "..tostring(v))
        end
    end

    print(prefix.."}")
end)

COM_AddCommand("getnavai",function(player, string)
	if string == "navai"
		prtable("NavAI",NavAI)
	elseif string == "players"
		for player in players.iterate
			prtable(player.name..": Nav",player.nav)
			prtable(player.name..": AI",player.ai)
		end
	else
		print("Valid arguments: navai, players")
	end
end, COM_LOCAL)