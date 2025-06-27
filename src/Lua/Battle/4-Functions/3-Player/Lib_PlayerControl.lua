local B = CBW_Battle
local CV = B.Console
local S = B.SkinVars

B.InitPlayer = function(player)
	local mo = player.mo or player.realmo
	B.DebugPrint("Initializing "..player.name.."'s player variables",DF_PLAYER)

	//Battle related skin stats
	B.GetSkinVars(player)
	
	//Battle related variables
	player.battlespflags = $ or 0
	player.battlespshield = $ or 0
	player.scale = $ or FRACUNIT
	player.battlevars = {
		jumpfunc_active = false,
		spinfunc_active = false,
		doublejumpfunc_active = false,
		jumpspinfunc_active = false
	}

	player.actionsuper = false
	player.actionrings = 0
	player.action2rings = 0
	player.actiondebt = 0
	player.actiontime = 0
	player.actionstate = 0
	player.actioncooldown = TICRATE
	player.actionallowed = true
	player.actiontext = nil
	player.actiontextflags = 0
	player.action2text = nil
	player.action2textflags = 0
	player.charmed = false
	player.charmedtime = 0
	player.backdraft = 0
	player.spendrings = 0
	player.disableringslinger = false
	player.iseggrobo = false
	player.eggrobo_transforming = false
	player.capturing = false
	player.captureamount = 0
	player.gotflagdebuff = false
	player.pushed_creditplr = nil
	player.pushed_credittime = 0
	player.shieldstock = {}
	player.shieldmax = 2
	player.exhaustmeter = FRACUNIT
	player.gotcrystal = false
	player.gotcrystal_time = 0
	//player.lifeshards = 0
	player.shieldswap_cooldown = 0
	player.airdodge = 0
	player.tumble = 0
	player.melee_state = 0
	player.thinkmoveangle = 0
	player.thinkmovethrust = 0
	player.thinkbuttons = 0
	player.thinkbuttons_last = 0
	player.intangible = false
	player.lockaim = false
	player.lockmove = false
	player.lockjumpframe = 0
	player.rank = 0
	player.canguard = true
	player.guard = 0
	player.guardtics = 0
	player.reflectarmor = 0
	player.reflectarmor_time = 0
	player.carried_time = 0
	player.roulette_x = 0
	player.roulette_prev_left = 0
	player.roulette_prev_right = 0
	
	player.pr_exploding = 0
	player.pr_electrocuted = 0
	player.gotpowercard = nil
	
	if player.respawnpenalty == nil then
		player.respawnpenalty = 0
	end
	if player.spectatortime == nil then
		player.spectatortime = 0
	end
	
	//Player Config
	if player.battleconfig_dodgecamera == nil
		player.battleconfig_dodgecamera = true
	end
	if player.battleconfig_guard == nil then
		player.battleconfig_guard = BT_FIRENORMAL
	end
	if player.battleconfig_special == nil then
		player.battleconfig_special = BT_ATTACK
	end
	if player.battleconfig_aimsight == nil then
		player.battleconfig_aimsight = true
	end
	if player.battleconfig_autospectator == nil then
		player.battleconfig_autospectator = true
	end
	
	if player.revenge == nil then
		player.revenge = false
	end
	player.isjettysyn = false
	if player.mo then
		player.charflags = skins[player.mo.skin].flags
	end
	if not (player.lastcolor) then
		player.lastcolor = 0
	end
	
	if not starposttime
		player.starpostnum = 99
		player.starpostx = mo.x/FRACUNIT
		player.starposty = mo.y/FRACUNIT
		player.starpostz = mo.z/FRACUNIT
		player.starpostscale = mo.scale
		player.starpostangle = mo.angle
	end
end

B.ResetPlayerProperties = function(player,jumped,thokked)
	local mo = player.mo
	if not(mo) then return end
	//Reset pflags
	local pflags = player.pflags&~(PF_GLIDING|PF_BOUNCING)
	if jumped == true then
		pflags = $|PF_JUMPED&~PF_STARTJUMP
		if player.charflags&SF_NOJUMPDAMAGE
			pflags = $|PF_NOJUMPDAMAGE
		end
		if not(player.charflags&SF_NOJUMPSPIN)
			mo.state = S_PLAY_ROLL
		else
			mo.state = S_PLAY_SPRING
		end
	elseif jumped == false then
		pflags = $&~(PF_JUMPED|PF_SPINNING)
		if not(P_IsObjectOnGround(mo)) and not(P_PlayerInPain(player)) then
			mo.state = S_PLAY_FALL
		end
	end
	if thokked == true then
		pflags = ($|PF_THOKKED)&~PF_SHIELDABILITY
	elseif thokked == false then
		pflags = $&~(PF_THOKKED|PF_SHIELDABILITY)
	end
	player.pflags = pflags
	//Reset other variables
	local skin = skins[mo.skin]
	mo.flags = $&~(MF_NOCLIPTHING)
	mo.flags2 = $&~(MF2_DONTDRAW)
	player.charability = skin.ability
	player.charability2 = skin.ability2
	player.normalspeed = skin.normalspeed
	player.thrustfactor = skin.thrustfactor
	player.mindash = skin.mindash
	player.maxdash = skin.maxdash
	player.climbing = 0
	player.secondjump = 0
	if not(player.actionsuper) then
		player.actionstate = 0
		player.actiontime = 0
	end
	//player.exhaustmeter = FRACUNIT
	player.otherscore = nil
end

B.PlayerMobjSpawn = function(mo)
	mo.hitstun_tics = 0
	mo.hitstun_disrupt = false
end


B.GetSkinVars = function(player)
	player.skinvars = skins[player.skin].name
	return player.skinvars
end

B.GetSkinVarsFlags = function(player, value)
	if value == nil
		return S[player.skinvars].flags
	else
		return S[player.skinvars].flags&value
	end
end

B.GetSkinVarsValue = function(player, str)
	return S[player.skinvars][str]
end

local warning = false
B.DrawSVSprite = function(player,value)
	if not warning
		warning = true
		assert(false, "CBW_DrawSVSprite is deprecated!")
	end
	local s = player.skinvars
	if not(player.mo)
	or s == -1
	or S[s].sprites == nil 
	or S[s].sprites[value] == nil
		return false
	end
	P_SetMobjStateNF(player.mo,S[s].sprites[value])
	return true
end

local warning = false
B.GetSVSprite = function(player,value)
	if not warning
		warning = true
		assert(false, "CBW_GetSVSprite is deprecated!")
	end
	local s = player.skinvars
	//Return nil have skinvars undefined
	if not(player.mo)
	or s == -1 
	or S[s].sprites == nil 
		return nil
	end
	//Get value-defined skinvar state
	if not(value == nil)
		if S[s].sprites[value] == nil
			return nil
		else
			return S[s].sprites[value]
		end
	else //Get player's current skinvar state
		for n = 1, #S[s].sprites do
			if player.mo.state == S[s].sprites[n]
				return S[s].sprites[n]
			end
		end
	end
end

B.PlayerButtonPressed = function(player,button,held,check_stasis)
	if B.Exiting then return end
	if not(player.cmd.buttons&button) then return false end
	if held == true and not(player.buttonhistory&button) then return false end
	if held == false and player.buttonhistory&button then return false end
	if(check_stasis) and player.powers[pw_nocontrol] then return false end
	return true
end

B.MyTeam = function(player,myplayer) //Also accepts player.mo
	//Check yourself before you wreck yourself
	if myplayer == player then return true end
	if (player == nil) or (myplayer == nil) //One of these is invalid!
		B.Warning("Attempted to use a nil argument in function MyTeam()!")
	return end
	//Are we using mo's instead of players? Let's fix that.
	if player.player then player = player.player end
	if myplayer.player then myplayer = myplayer.player end
	//FriendlyFire
	if CV_FindVar("friendlyfire").value then
		return false
	end
	//CTF checks
	if G_GametypeHasTeams() then
		if player.ctfteam == myplayer.ctfteam then return true
		else return false
		end
	end
	//Tag checks
	if B.TagGametype() then
		if player.pflags&PF_TAGIT == myplayer.pflags&PF_TAGIT then return true
		else return false
		end
	end
	//Battle check
	if not(gametyperules & (GTR_FRIENDLY | GTR_TEAMS)) then
		return false
	end
	//default
	return true
end

B.RestoreColors = function(player)
	if G_GametypeHasTeams() then
		if player.skincolor
		and player.lastcolor == 0
			player.lastcolor = player.skincolor
		end
	else
		if player.skincolor
		and player.lastcolor != 0
			player.skincolor = player.lastcolor
			player.lastcolor = 0
		end
	end	
end

B.DrawAimLine = function(player,angle)
	if not(player.mo) then return end
	if not(player.battleconfig_aimsight) then return end
	if not(leveltime&1) then return end
	if angle == nil then angle = player.mo.angle end
	for n = 1,8 do
		local dist = FRACUNIT*64*n
		local x = player.mo.x+P_ReturnThrustX(nil,angle,dist)
		local y = player.mo.y+P_ReturnThrustY(nil,angle,dist)
		local z = player.mo.z+player.mo.height/4
-- 		if P_MobjFlip(player.mo) == -1 then
-- 			z = $+player.mo.height
-- 		end
		local b = P_SpawnMobj(x,y,z,MT_CPBONUS)
		if b and b.valid then
			b.fuse = 1
			b.color = B.Choose(SKINCOLOR_ORANGE,SKINCOLOR_YELLOW,SKINCOLOR_SILVER,SKINCOLOR_GREEN,SKINCOLOR_GREY,SKINCOLOR_FOREST,SKINCOLOR_PURPLE,SKINCOLOR_COBALT,SKINCOLOR_RED)
			b.color = player.skincolor
			//Only the user is supposed to see this
			if not(player == displayplayer or player == secondarydisplayplayer) then 
				b.flags2 = $|MF2_DONTDRAW 
			end
		end
	end
end

B.DoPlayerFlinch = function(player, time, angle, thrust, force)
	//Uncurl
	if P_IsObjectOnGround(player.mo) then
		player.panim = 0
		player.mo.state = S_PLAY_SKID
		player.pflags = $&~(PF_SPINNING|PF_STARTDASH|PF_SLIDING)
	else
		player.panim = PA_FALL
		player.mo.state = S_PLAY_FALL
		player.pflags = $&~(PF_GLIDING|PF_JUMPED|PF_BOUNCING|PF_SPINNING|PF_THOKKED|PF_SHIELDABILITY)
		player.secondjump = 0
	end
	//Apply recoil
	player.powers[pw_nocontrol] = max($,min(time or 0,TICRATE))
	player.mo.recoilangle = angle
	player.mo.recoilthrust = thrust
	if not(player.actionsuper) then
		player.actionstate = 0
	end
	if force == true then
		P_InstaThrust(player.mo,angle,thrust)
	end

	player.mo.hitstun_tics = 5
	player.mo.hitstun_disrupt = true
end

B.DoPlayerTumble = function(player, time, angle, thrust, force)
	time = $ or 45
	if angle == nil
		angle = player.mo.angle + ANGLE_180
	end

	player.panim = PA_PAIN
	player.mo.state = S_PLAY_PAIN
	player.pflags = $&~(PF_GLIDING|PF_JUMPED|PF_BOUNCING|PF_SPINNING|PF_THOKKED|PF_SHIELDABILITY)
	
	player.guard = 0
	player.tumble = time
	player.airdodge_spin = 0
	if not(player.actionsuper)
		player.actionstate = 0
	end
	
	S_StartSound(player.mo, sfx_s3k98)
	S_StartSoundAtVolume(player.mo, sfx_kc38, 70)
	
	if thrust and force
		P_InstaThrust(player.mo,angle,thrust)
	end
	
	player.mo.hitstun_tics = 10
	player.mo.hitstun_disrupt = true
end

B.Tumble = function(player)
	if not (player and player.valid and player.mo and player.mo.valid)
		return
	end
	local mo = player.mo
	
	if player.tumble
		
		//End tumble
		if player.isjettysyn
			or player.powers[pw_carry]
			or (P_PlayerInPain(player) and player.powers[pw_flashing] == 3*TICRATE)
			
			player.tumble = nil
			player.lockmove = false
			player.drawangle = mo.angle
			S_StopSoundByID(mo, sfx_kc38)
			B.ResetPlayerProperties(player,false,false)
		
		//Do tumble animation
		else
			if mo.tumble_prevmomz == nil
				mo.tumble_prevmomz = mo.momz
			end
			
			if P_IsObjectOnGround(mo) and (mo.momz * P_MobjFlip(mo) <= 0)
				S_StartSound(mo, sfx_s3k49)
				mo.momz = mo.tumble_prevmomz * -2/3
				
				if mo.momz * P_MobjFlip(mo) < 6 * FRACUNIT
					mo.momz = 6 * FRACUNIT * P_MobjFlip(mo)
				elseif mo.momz * P_MobjFlip(mo) > 13 * FRACUNIT
					mo.momz = 13 * FRACUNIT * P_MobjFlip(mo)
				end
			end
			
			mo.tumble_prevmomz = mo.momz

			player.tumble = $ - 1
			if player.tumble <= 0
				
				player.tumble = nil
				player.lockmove = false
				player.drawangle = mo.angle
				S_StopSoundByID(mo, sfx_kc38)
				player.panim = PA_FALL
				B.ResetPlayerProperties(player,false,false)
				if P_IsObjectOnGround(mo)
					mo.state = S_PLAY_FALL
				end
				
			else
				//player.powers[pw_nocontrol] = max($, 2)
				player.pflags = $ | PF_FULLSTASIS
				player.panim = PA_PAIN
				player.mo.state = S_PLAY_PAIN
				
				player.airdodge_spin = $ + ANGLE_45
				player.drawangle = mo.angle + player.airdodge_spin

				if not (player.tumble % 4)// and not P_PlayerInPain(player)
					local g = P_SpawnGhostMobj(mo)
					g.color = SKINCOLOR_BLACK
					g.colorized = true
					g.destscale = g.scale * 2
				end
			end
		end
	end
end

B.PlayerCreditPusher = function(player,source)
	if source and source.valid and source.player
		player.pushed_creditplr = source.player
	end
end

B.PlayerCanRoulette = function(player)
	return B.PreRoundWait()
		and not B.Timeout
		and not(player.spectator or player.playerstate != PST_LIVE) 
		and (netgame or CV.Debug.value & DF_PLAYER)
		and CV_FindVar('hidetime').value
end

B.PlayerSetupPhase = function(player)
	if not(B.PreRoundWait() and player.mo) return end
	
	local mo = player.mo
	if B.PlayerCanRoulette(player)
		local skinnum = #skins[mo.skin]
		//If we're changing skins, this is the set of instructions we'll use
		local skinchanged = false
		local function newskin()
			if not(R_SkinUsable(mo.player, skinnum)) return end		
	-- 		COM_BufInsertText(mo.player, skintext..tostring(skinnum))
			R_SetPlayerSkin(player,skinnum)
			S_StartSound(nil,sfx_menu1,player)
			S_StartSound(nil,sfx_kc50,player)
			B.GetSkinVars(player)
			B.SpawnWithShield(player)
			skinchanged = true
		end
		
		//Roulette
		local change = 0
		if (leveltime > 60) and (leveltime + 17 < CV_FindVar("hidetime").value*TICRATE)
			local deadzone = 20
			local right = player.cmd.sidemove >= deadzone
			local left = player.cmd.sidemove <= -deadzone
			local scrollright = player.roulette_prev_right > 18 and player.roulette_prev_right % 4 == 0
			local scrollleft = player.roulette_prev_left > 18 and player.roulette_prev_left % 4 == 0
			if right and (scrollright or not player.roulette_prev_right)
				repeat
					skinnum = $+1
					if skinnum >= #skins then skinnum = 0 end
					newskin()
				until skinchanged == true
				change = 1
			end
			if left and (scrollleft or not player.roulette_prev_left)
				repeat
					skinnum = $-1
					if skinnum < 0 then skinnum = #skins-1 end
					newskin()
				until skinchanged == true
				change = -1
			end
			player.roulette_prev_right = (right and $+1) or 0
			player.roulette_prev_left = (left and $+1) or 0
		end
		
		if (leveltime + 17 == CV_FindVar("hidetime").value*TICRATE) and player != secondarydisplayplayer
			S_StartSound(nil, sfx_s251, player)
		end
		
		//Roulette scrolling (to be used by the HUD later)
		if change == 0
			player.roulette_x = $*6/10
			if abs(player.roulette_x) < FRACUNIT
				player.roulette_x = 0
			end
		else
			player.roulette_x = (40*FRACUNIT*change)
		end
	end
	
	//No control
	player.powers[pw_nocontrol] = 2
	//Don't kill me
	player.powers[pw_flashing] = TICRATE
	if player.powers[pw_underwater] then
		player.powers[pw_underwater] = max(30*TICRATE,$)
	end
	
	//State
	if not(P_IsObjectOnGround(mo)) then
		mo.state = S_PLAY_FALL
	end
	
	//Update history
	player.buttonhistory = player.cmd.buttons
end

B.PlayerRegulateRings = function(player)
	if player.battlespflags & BSP_RINGFLAGS == BSP_NORINGS
	and player.rings
		player.rings = 0
	end
end

B.PlayerMoveBlocked = function(mo)
	if mo.player.tumble or P_PlayerInPain(mo.player)
        if P_IsObjectOnGround(mo)
			mo.z = $ + P_MobjFlip(mo)
		end
        P_BounceMove(mo)
    end
end