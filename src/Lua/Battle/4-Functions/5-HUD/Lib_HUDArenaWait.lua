local B = CBW_Battle
local A = B.Arena
local CV = B.Console

local yo = 152

//Enable/disable spectator controls hud
B.SpectatorControlHUD = function(v,player,cam)
	if not (B.HUDAlt) then return end
	if player.spectatortime != nil
	and (player.spectatortime < TICRATE*9 or (player.spectatortime < TICRATE*10 and player.spectatortime&1))
		hud.enable("textspectator")
	else
		hud.disable("textspectator")
	end
end

//Waiting to join
A.WaitJoinHUD = function(v, player, cam)
	if not (B.HUDAlt) then return end
	if not (gametyperules&GTR_LIVES) or (gametyperules&GTR_FRIENDLY) then return end //Competitive lives only
	local dead = (player.spectator and not(A.SpawnLives))
		or (player.playerstate == PST_DEAD and player.revenge)
	if not (dead) then return end
	if not(CV.Revenge.value) or B.SuddenDeath then
-- 		local t = "\x85".."You've been ELIMINATED!"
-- 		v.drawString(160,160,t,V_HUDTRANS|V_SNAPTOTOP|V_SNAPTOLEFT|V_PERPLAYER,"center")
		local t = "\x85".."Wait until next round to join"
		v.drawString(160,yo,t,V_HUDTRANSHALF|V_SNAPTOTOP|V_SNAPTOLEFT|V_PERPLAYER,"center")
	elseif CV.Revenge.value then
		local t = "\x85".."You've been ELIMINATED!"
		v.drawString(160,yo,t,V_HUDTRANS|V_SNAPTOTOP|V_SNAPTOLEFT|V_PERPLAYER,"center")
-- 		if B.SuddenDeath
-- 			local t = "\n\x85".."Wait until next round to join"
-- 			v.drawString(160,yo,t,V_HUDTRANS|V_SNAPTOTOP|V_SNAPTOLEFT|V_PERPLAYER,"center")
-- 		else
			t = "\n\x80".."But you can still respawn as a \x86".."jetty-syn"
			v.drawString(160,yo,t,V_HUDTRANS|V_SNAPTOTOP|V_SNAPTOLEFT|V_PERPLAYER,"center")
-- 		end
	end	
end

//Revenge JettySyn
local revengehud = false
A.RevengeHUD = function(v,player,cam)
	if not (B.HUDAlt)
		revengehud = false
		return
	end
	if player.revenge and not(revengehud) then
		hud.disable("lives")
		hud.disable("rings")
		revengehud = true
	end
	if not(player.revenge) and revengehud then
		hud.enable("lives")
		hud.enable("rings")
		revengehud = false
	end
end