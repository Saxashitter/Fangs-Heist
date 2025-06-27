local B = CBW_Battle
local A = B.Arena
local PR = CBW_PowerCards

B.PlayerPreThinkFrame = function(player)
	if player.deadtimer < 0 and player.deadtimer >= -TICRATE then player.deadtimer = 0 end -- Fix for HUD counter inaccuracies

	//Initiate support mobj
	B.SpawnTargetDummy(player)
	
	//History
	if player.versusvars == nil then
		player.buttonhistory = player.cmd.buttons
		player.thinkbuttons_last = player.thinkbuttons
		B.InitPlayer(player)
		player.versusvars = true
	end
	
	//Spectator functions
	B.PreAutoSpectator(player)
	B.SpectatorControl(player)

	//Arena death functions
	A.ForceRespawn(player)
	A.GameOverControl(player)
	
	//Dead control unlock
	if player.playerstate != PST_LIVE then
		player.lockaim = false
		player.lockmove = false
	end
	
	//Spawning, end of round
	if player.playerstate == PST_LIVE then
		//Battle spawn animation
		//Pre Round Setup
		if not(B.PlayerBattleSpawning(player))
			B.PlayerSetupPhase(player)
		end
		//Post round invuln
		if B.Exiting
			player.powers[pw_flashing] = TICRATE
		end
	end
	
	//Control inputs
	B.PreGunslinging(player)
	B.InputControl(player)
end

B.PlayerMobjThinker = function(player)
	if player.mo.hitstun_tics
		return true
	end
	B.AbilityTicFrame(player)
end

B.PlayerThink = function(player)
	B.AutoSpectator(player)
	if player.mo and player.mo.hitstun_tics
		return true
	end
	PR.PlayerThink(player)
	if not player.mo
		return
	end
	B.PlayerRegulateFlashing(player)
	B.PlayerRegulateRings(player)
end

B.PlayerThinkFrame = function(player)
	local pmo = player.mo
		
	//Sanity checks
	if player.versusvars == nil then return end
	if not(pmo and pmo.valid) or player.playerstate != PST_LIVE then return end
	if maptol&(TOL_NIGHTS|TOL_XMAS) then return end
	if pmo.hitstun_tics
		return true
	end
	
	// Squash and stretch control
	if (pmo and pmo.valid) and ((not player.squashstretch) or player.playerstate != PST_LIVE)
		pmo.spritexscale = FRACUNIT
		pmo.spriteyscale = FRACUNIT
		player.squashstretch = nil
	end
	
	//Shield Stock usage
	B.ShieldStock(player)
	B.ShieldMax(player) //Regulate shield capacity
	
	//Lock-aim
	if player.lockaim then
		player.lockaim = false
		player.drawangle = player.mo.angle
	end
	if player.lockmove then
		player.lockmove = false
	end
	
	//Skinvars
	B.GetSkinVars(player)
	
	//Tumble state
	B.Tumble(player)
	
	//Ability control
	B.GuardControl(player)//Check if guard is allowed
	B.CharAbilityControl(player)//Exhaust and ability behavior
	
	//Update timers/stats
	B.GotFlagStats(player)
	player.charmedtime = max(0,$-1)
	player.actioncooldown = max(0,$-1)
	B.DoBackdraft(player)
	if player.reflectarmor_time == 0
		player.reflectarmor = 0
	else
		player.reflectarmor_time = max(0, $-1)
	end
	
	//Special thinkers
	A.JettySynThinker(player)
	A.RingSpill(player)
	B.PlayerMovementControl(player)
	
	//Perform Actions
	local doaction = B.ButtonCheck(player,player.battleconfig_special)
	B.MasterActionScript(player,doaction)

	//Defensive actions
	local doguard = B.ButtonCheck(player,player.battleconfig_guard)
	B.StunBreak(player,doguard)
	B.AirDodge(player,doguard)
	B.Guard(player,doguard)
	
	//Abilities
	B.CustomGunslinger(player)
	B.ShieldTossFlagButton(player)
	
	//PvP Collision
	B.DoPriority(player)
	B.DoPlayerInteract(pmo,pmo.pushed)
	B.UpdateRecoilState(pmo)
	B.UpdateCollisionHistory(pmo)
end

B.PlayerPostThinkFrame = function(player)
	local mo = player.mo
	
	if mo and mo.hitstun_tics
		mo.hitstun_tics = max(0, $-1)
		mo.flags = $|MF_NOTHINK
		if mo.hitstun_tics and mo.hitstun_disrupt
			mo.spritexoffset = P_RandomRange(8, -8) * FRACUNIT
			mo.spriteyoffset = P_RandomRange(2, 2) * FRACUNIT
		elseif not(mo.hitstun_tics)
			mo.spritexoffset = 0
			mo.spriteyoffset = 0
			mo.hitstun_disrupt = false
			mo.flags = $ &~ MF_NOTHINK
		end
		return true
	end

	if not(B.PreRoundWait())
		player.buttonhistory = player.cmd.buttons
	end
	if player.mo
		//Lock jump timer
		if player.lockjumpframe
			player.lockjumpframe = $ - 1
		end
		//Shadow character
		if player.battlespflags & BSP_SHADOW
			B.DrawShadowCharacter(player)
		else
			//Resolve SP color conflicts
			for p in players.iterate do
				if #p > #player break end //Lower player# colors take priority
				local pmo = p.mo and p.mo.valid and p.mo or p.realmo
				if p != player and p.ctfteam == 2 and pmo.skin == player.mo.skin and p.skincolor == player.skincolor
					player.skincolor = ($+11) % 69
					player.mo.color = player.skincolor
				end
			end
		end
	end
end