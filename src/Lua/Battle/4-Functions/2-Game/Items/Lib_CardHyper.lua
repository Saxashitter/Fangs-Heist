/*
	Hyper powerup
	Preps a stat boost to the player's speed, cooldown, and ability2.
*/
local PR = CBW_PowerCards

local DoColorGhost = function(player,time,color)
	if time%3 return end
	local ghost = P_SpawnGhostMobj(player.mo)
	ghost.colorized = true
	ghost.color = color
	if PR.FirstPerson(player)
		ghost.flags2 = $|MF2_DONTDRAW
	end
end

//Hyper
PR.HyperHoldFunc = function(mo,player)
	if mo.health > 1
		local skin = skins[player.mo.skin]
		//Timer
		mo.health = $-1 - player.actioncooldown/4 //Using actions reduces hyper time
		//Status effect
	-- 		player.normalspeed = FixedMul(skin.normalspeed,FRACUNIT*4/3)
-- 		player.thrustfactor = skin.thrustfactor*2
-- 		player.jumpfactor = FixedMul(skin.jumpfactor,FRACUNIT*3/2)
		player.actioncooldown = 0
		//Spindash boost
		if player.pflags&PF_STARTDASH
			player.dashspeed = player.maxdash
		end
		//Piko Wave charge
		if player.melee_state == 1
			player.melee_charge = FRACUNIT
		end
		//Popgun enhancements
		if CBW_Battle.GetSkinVarsFlags(player)&SKINVARS_GUNSLINGER
			if player.weapondelay > 0
				player.weapondelay = $-2
				mo.tics = max(1,$-2)
			end
			if player.weapondelay <= 0 and player.airgun == true
				player.airgun = false
				player.pflags = $&~PF_THOKKED
				mo.state = S_PLAY_FALL
			end
		end
		
		//Visual
		if not(player.isjettysyn)
			DoColorGhost(player,mo.health,SKINCOLOR_GREEN)
		end
	else
		PR.DiscardDeath(mo,player)
		return true
	end
end

PR.HyperTouchFunc = function(mo,player)
	S_StartSound(player.mo,sfx_s25f)
end

PR.HyperUnsetFunc = function(mo,player)
	if player and player.mo
		local skin = skins[player.mo.skin]
-- 		player.thrustfactor = skin.thrustfactor
-- 		player.jumpfactor = skin.jumpfactor
-- 		player.gotflagdebuff = 0 //Let the previous stats get overwritten by CTF if necessary
	end
end