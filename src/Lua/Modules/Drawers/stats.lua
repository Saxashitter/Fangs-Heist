addHook("PlayerThink", function(player)
if player.fhbadnikstat == nil then player.fhbadnikstat = 0
end;end)

addHook("PlayerThink", function(player)
if player.fhhitsstat == nil then player.fhhitsstat = 0
end;end)

addHook("MobjDamage", function(trg, inf, src)
	if src and src.valid and src.player
	and trg and trg.valid and trg.flags & MF_ENEMY

		src.player.fhbadnikstat = $+1
	end
end)

addHook("MobjDamage", function(trg, inf, src)
	if src and src.valid and src.player
	and trg and trg.valid and trg.player

		src.player.fhhitsstat = $+1
	end
end)

//Personal stat display

local function heiststats(v)
    for player in players.iterate
		if player.mo and player.mo.valid and consoleplayer == player
			v.draw(25,5,v.cachePatch("FHSTAT1"),V_SNAPTOTOP|V_SNAPTORIGHT)	
			FangsHeist.DrawString(v,42*FU,6*FU,FU,tostring(player.fhbadnikstat),"FHTXT",nil,V_SNAPTOTOP|V_SNAPTORIGHT)
			v.draw(55,5,v.cachePatch("FHSTAT2"),V_SNAPTOTOP|V_SNAPTORIGHT)	
			FangsHeist.DrawString(v,72*FU,6*FU,FU,tostring(player.fhhitsstat),"FHTXT",nil,V_SNAPTOTOP|V_SNAPTORIGHT)
		end
	end
end
hud.add(heiststats, "scores")