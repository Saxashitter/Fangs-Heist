local PR = CBW_PowerCards
local disable_time = 12*TICRATE

PR.DisableHoldFunc = function(mo,player)
	if mo.health > 1
		mo.health = $-1
		if mo.health == TICRATE/2
		or mo.health == TICRATE
		or mo.health == TICRATE*3/2
			S_StartSound(nil,sfx_s3kc3s,foe)
		end
	else
		//Search foes
		for foe in players.iterate do
			if foe != player //Don't damage ourselves!
			and foe.playerstate == PST_LIVE and not(foe.spectator or foe.exiting)
			and not(gametyperules&GTR_TEAMS and foe.ctfteam == player.ctfteam) //Don't damage teammates
				PR.DoCharmed(foe,disable_time)
			end
		end
		//Destroy item
		PR.RewardDeath(mo,player)
		return true
	end
end