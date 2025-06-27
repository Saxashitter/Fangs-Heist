local B = CBW_Battle
local CV = B.Console
local A = B.Arena
local S = B.SkinVars

local function buttoncheck(player,button)
	if player.cmd.buttons&button then
		if player.buttonhistory&button then
			return 2
		else
			return 1
		end
	end
	return 0
end


//Shield Spawn

function A_GiveShield(actor,var1,var2)
	if not(actor.target and actor.target.player) then return end
	local player = actor.target.player
	if player.shieldmax < 0
		P_GivePlayerRings(player, 50)
		S_StartSound(player.mo, sfx_s3kb3)
		return
	end
	if CV.ShieldStock.value and (gametyperules&GTR_PITYSHIELD)
		B.UpdateShieldStock(player,2)
	end
	if player.powers[pw_shield]&SH_ARMAGEDDON then
		player.powers[pw_shield] = $&~SH_ARMAGEDDON
	end
	P_SwitchShield(player, var1)
	S_StartSound(player.mo, actor.info.seesound)
end

B.UpdateShieldStock = function(player,addshield)
	local shieldtype = player.battlespshield or SH_PITY
	local power = player.powers[pw_shield]&SH_NOSTACK
	local pity = (player.powers[pw_shield]&SH_STACK)|shieldtype
	local fill = (addshield == 2)
	local subtract = (addshield == -1)
	
	//No shield stock allowed for this character
	if (player.shieldmax <= 0)
		if #player.shieldstock
			player.shieldstock = {} //replace all shields with blank table
		end
		return //Cannot perform any other shield stock related actions
	end
	
	//Using a shield; move shield stock positions inward
	if subtract
		for n = 1,player.shieldmax do
			player.shieldstock[n] = player.shieldstock[n+1]
		end
	end

	//Fill shield stock
	if fill then
		if not(power) and player.shieldmax >= 0 then
			player.powers[pw_shield] = pity //Give us a shield to add to reserve
		end
		for n = 1, player.shieldmax do
			if not(player.shieldstock[n]) then
				player.shieldstock[n] = shieldtype
			end
		end
	end
	//Add one shield
	if power and addshield
		local n = player.shieldmax
		while n > 1 do
			player.shieldstock[n] = player.shieldstock[n-1]
			n = $-1
		end
		player.shieldstock[1] = player.powers[pw_shield]&SH_NOSTACK 
	end
end

B.ShieldMax = function(player)
	if not(CV.ShieldStock.value) then return end	
	local mo
	if player.realmo and player.realmo.valid then mo = player.realmo
	elseif player.mo and player.mo.valid then mo = player.mo
	else
		return
	end //Can't continue if we can't find the player's skin!
	
		//Get shield max
		if player.battlespflags&BSP_SHIELDFLAGS == BSP_NOSHIELDS
			player.shieldmax = 0
		else
			local skinmax = nil
			if player.skinvars and S[player.skinvars]
				skinmax = S[player.skinvars].shields
			end
			local oldshieldmax = player.shieldmax
			if skinmax == nil then
				player.shieldmax = S[-1].shields
			else
				player.shieldmax = skinmax
			end
			if player.battlespflags&BSP_SHIELDFLAGS == BSP_LESSSHIELDS
				player.shieldmax = $/2
			elseif player.battlespflags&BSP_SHIELDFLAGS == BSP_MORESHIELDS
				player.shieldmax = $*2+1
			end
		end
		//Force limit shield stock max
		if oldshieldmax and oldshieldmax > player.shieldmax then
			for n = player.shieldmax+1, oldshieldmax
				player.shieldstock[n] = nil
			end
		end
end

B.ShieldStock = function(player)
	if not(CV.ShieldStock.value) then return end	
	//Go no further if we're not in the game
	if (player.spectator) then return end
	player.pity = 0 //Disable the "pity" mechanic from ringslinger.
	
	local currentshield = player.powers[pw_shield]&SH_NOSTACK

	//Are we not shielded? Use our next reserve
	if not(P_PlayerInPain(player)) and not(currentshield) and player.shieldstock[1] and not(player.charmed) then
		local power = player.shieldstock[1]
		
		if power == SH_PITY
			S_StartSound(player.mo,sfx_shield)
		elseif power == SH_WHIRLWIND
			S_StartSound(player.mo,sfx_wirlsg)
		elseif power == SH_FORCE|1
			S_StartSound(player.mo,sfx_forcsg)//Full force shield
		elseif power == SH_FORCE
			S_StartSound(player.mo,sfx_frcssg)//Half force shield
		elseif power == SH_ELEMENTAL
			S_StartSound(player.mo,sfx_elemsg)
		elseif power == SH_ATTRACT
			S_StartSound(player.mo,sfx_attrsg)
		elseif power == SH_ARMAGEDDON
			S_StartSound(player.mo,sfx_armasg)
		elseif power == SH_BUBBLEWRAP
			S_StartSound(player.mo,sfx_s3k3f)
		elseif power == SH_FLAMEAURA
			S_StartSound(player.mo,sfx_s3k3e)
		elseif power == SH_THUNDERCOIN
			S_StartSound(player.mo,sfx_s3k41)
		end
		
		B.UpdateShieldStock(player,-1)
		P_SwitchShield(player, power)
	end
	
end

B.SpawnWithShield = function(player)
	if B.SuddenDeath then return end
	if gametyperules&GTR_PITYSHIELD and not(player.spectator) then
		local shieldtype = player.battlespshield or SH_PITY
		B.ShieldMax(player)
		//Revenge gate
		if A.CheckRevenge(player)
		and player.shieldmax < 0
			P_SwitchShield(player, 0)
			player.pity = 0
			return
		end
		//Normal start behavior
		if player.battlespflags&BSP_SHIELDFLAGS != BSP_NOSHIELDS
			P_SwitchShield(player, shieldtype)
		end
		player.pity = 0
		//Players start with max shields in Arena gametypes and pre-round setup
		if B.ArenaGametype() or B.PreRoundWait() and CV.ShieldStock.value then
			for n = 1, player.shieldmax do
				player.shieldstock[n] = shieldtype
			end
		end
	end
end

B.AddPinkShield = function(player,sourceplayer)
	if (player.charability2 == CA2_MELEE) //Non-Amy players only
	or player.shieldmax < 0
		return false
	end
	if not(player.powers[pw_shield])
		P_AddPlayerScore(sourceplayer,25)
		P_SwitchShield(player,4)
		S_StartSound(player.mo,sfx_shield)
		return true
	end
	if(CV.ShieldStock.value and gametyperules&GTR_PITYSHIELD and #player.shieldstock < player.shieldmax) then
		P_AddPlayerScore(sourceplayer,25)
		S_StartSound(player.mo,sfx_monton)
		player.shieldstock[#player.shieldstock+1] = SH_PINK
		return true
	end
	return false
end

B.OverlayHide = function(mo,owner)
	if not(owner and owner.valid) then return nil end
	if owner.flags&MF_NOCLIPTHING or owner.flags2&MF2_DONTDRAW then mo.flags2 = $|MF2_DONTDRAW return true
	else mo.flags2 = $&~MF2_DONTDRAW return false
	end
end

