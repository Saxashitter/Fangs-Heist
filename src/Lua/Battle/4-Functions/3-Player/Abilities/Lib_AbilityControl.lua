local B = CBW_Battle
local S = B.SkinVars

B.TailsCatchPlayer = function(player1,player2)
	if P_MobjFlip(player1.mo) != P_MobjFlip(player2.mo) then return end
	local flip = P_MobjFlip(player1.mo)
	//Determine who's who
	local tails,passenger
	if player1.mo.z*flip < player2.mo.z*flip
		tails = player2
		passenger = player1
	else
		tails = player1
		passenger = player2
	end
	
	//Get Z distance
	local zdist
	if flip == 1 then
		zdist = abs(tails.mo.z-(passenger.mo.z+passenger.mo.height))
	else
		zdist = abs(passenger.mo.z-(tails.mo.z+tails.mo.height))
	end
	
	//Apply gates
	if tails.panim != PA_ABILITY
	or not(tails.pflags&PF_CANCARRY)
	or zdist > FixedDiv(passenger.mo.height,passenger.mo.scale)/2
-- 	or passenger.carried_time < 15
	or passenger.powers[pw_carry]
	or passenger.mo.momz*flip > 0
	or passenger.exhaustmeter <= 0
	or passenger.powers[pw_tailsfly]
	or passenger.mo.state == S_PLAY_FLY_TIRED
		return
	end
	//Assign carry states
	B.DebugPrint("Latching "..passenger.name.." onto "..tails.name,DF_PLAYER)
	B.ResetPlayerProperties(passenger,false,false)
	passenger.mo.tracer = tails.mo
	passenger.powers[pw_carry] = CR_PLAYER
	passenger.carried_time = 0
-- 	tails.carry_id = passenger.mo
	S_StartSound(passenger.mo,sfx_s3k4a)
end

local glide = function(player)
	if not (player and player.mo and player.mo.valid)
		return
	end
	local mo = player.mo
	if (mo.state == S_PLAY_GLIDE or mo.state == S_PLAY_SWIM) and player.glidetime and not P_IsObjectOnGround(mo)
		if player.glidetime > 16 //Downward force when gliding very slowly
			if (player.speed < 12 * FRACUNIT)
				P_SetObjectMomZ(mo, FRACUNIT * -3/4, true)
			elseif (player.speed < 24 * FRACUNIT)
				P_SetObjectMomZ(mo, FRACUNIT * -1/2, true)
			end
		end
	end
end

local legacykill = function(player)
	local mo = player.mo
	if not (mo and mo.valid) return end
	
	local glide = ((mo.state == S_PLAY_GLIDE or mo.state == S_PLAY_SWIM) and player.glidetime and not P_IsObjectOnGround(mo))
	local hammer = (mo.state == S_PLAY_MELEE or mo.state == S_PLAY_MELEE_LANDING or mo.state == S_PLAY_MELEE_FINISH)
	
	if glide or hammer
		if not (player.pflags & PF_DIRECTIONCHAR)//Begin directionchar gliding
			player.waslegacy = true
			player.pflags = $ | PF_DIRECTIONCHAR
		end
		
	elseif player.waslegacy//End directionchar gliding
		player.waslegacy = nil
		player.pflags = $ & ~PF_DIRECTIONCHAR
	end
end

local homingthok = function(p)
	if p.homing and p.target and p.target.valid and p.target.player and p.target.player.valid and p.target.player.intangible
		p.homing = 0//Air dodging can "shake off" a player that is homing on to you
	else
		p.homing = min($,10)
	end
end

local popgun = function(player)
	if P_PlayerInPain(player) and player.charability2 == CA2_GUNSLINGER then
		player.weapondelay = TICRATE/3
	end
end

local weight = function(player)
	if not(player.mo) then return end
	
	local w
	if S[player.skinvars].weight then
		w = S[player.skinvars].weight
	else
		w = S[-1].weight
	end
	
	player.mo.weight = FRACUNIT*w/100
end

local exhaust = function(player)
	if not (player and player.mo and player.mo.valid)
		return
	end
	local mo = player.mo
	
	//Do func_exhaust
	local defaultfunc = S[-1].func_exhaust
	local func = S[player.skinvars].func_exhaust
	local override = nil
	if not func
		func = defaultfunc
	end
	if func
		override = func(player)
	end
	
	//Common exhaust states
	local warningtic = FRACUNIT/3
	/*if player.pflags & PF_STARTDASH
		override = true
		local maxtime = 5*TICRATE
		player.exhaustmeter = max(0,$-FRACUNIT/maxtime)
		if player.exhaustmeter <= 0
			player.exhaustmeter = FRACUNIT
			player.pflags = $ & ~(PF_STARTDASH|PF_SPINNING)
			mo.state = S_PLAY_STND
		end
	end*/
	if player.powers[pw_carry] == CR_MACESPIN and player.mo.tracer
		local maxtime = 4*TICRATE
		player.exhaustmeter = max(0,$-FRACUNIT/maxtime)
		if player.exhaustmeter <= 0
			//player.exhaustmeter = FRACUNIT
			player.powers[pw_carry] = CR_NONE
			player.mo.tracer = nil
			player.powers[pw_flashing] = TICRATE/4
		end
	end
	if player.powers[pw_tailsfly]
		local maxtime = 5*TICRATE
		if mo.momz * P_MobjFlip(mo) > 5*FRACUNIT
			maxtime = 2*TICRATE
		elseif mo.momz * P_MobjFlip(mo) > 3*FRACUNIT
			maxtime = 3*TICRATE
		end
		player.exhaustmeter = max(0,$-FRACUNIT/maxtime)
		
		if player.exhaustmeter <= 0
			//player.exhaustmeter = FRACUNIT
			if P_MobjFlip(mo) == 1
				mo.momz = min($, 5*FRACUNIT)
			else
				mo.momz = max($, -5*FRACUNIT)
			end
			player.powers[pw_tailsfly] = 0
		end
	end
	if player.charability == CA_GLIDEANDCLIMB
		if player.climbing == 5
			if player.exhaustmeter and (player.exhaustmeter > warningtic) then
				player.exhaustmeter = max(warningtic,$-FRACUNIT/4)
			else
				player.exhaustmeter = max(0,$-FRACUNIT/4)
			end
		end
		if (mo.state == S_PLAY_GLIDE or mo.state == S_PLAY_SWIM) and not P_IsObjectOnGround(mo)
			local maxtime = 5*TICRATE
			player.exhaustmeter = max(0,$-FRACUNIT/maxtime)
			if player.exhaustmeter <= 0
				//player.exhaustmeter = FRACUNIT
				mo.state = S_PLAY_FALL
				player.pflags = $ & ~PF_GLIDING & ~PF_JUMPED | PF_THOKKED
				player.glidetime = 0
			end
		elseif player.climbing
			local maxtime = 5*TICRATE
			player.exhaustmeter = max(0,$-FRACUNIT/maxtime)
			if player.exhaustmeter <= 0
				//player.exhaustmeter = FRACUNIT
				player.climbing = 0
				player.pflags = $|PF_JUMPED|PF_THOKKED
				mo.state = S_PLAY_ROLL
			end
		end
	end
	if player.prevfloat == nil
		player.prevfloat = false
	end
	if player.charability == CA_FLOAT and player.secondjump and (player.pflags & PF_THOKKED) and not (player.pflags & PF_JUMPED) and not (player.pflags & PF_SPINNING)
		if not player.prevfloat
			player.exhaustmeter = max(0,$-FRACUNIT/20)
		end
		player.prevfloat = true
		local maxtime = 3*TICRATE
		player.exhaustmeter = max(0,$-FRACUNIT/maxtime)
		if player.exhaustmeter <= 0
			//player.exhaustmeter = FRACUNIT
			player.secondjump = 0
			mo.state = S_PLAY_FALL
			player.pflags = $ & ~PF_JUMPED | PF_THOKKED
		end

	else
		player.prevfloat = false
	end
	
	//Refill meter
	if (P_IsObjectOnGround(mo) or P_PlayerInPain(player)) and not player.actionstate and not override
		player.exhaustmeter = FRACUNIT
	end
	
	//Exhaust warning / color
	if mo.exhaustcolor == nil then
		mo.exhaustcolor = false
	end
	if mo.exhaustcolor == true and player.exhaustmeter == FRACUNIT
		mo.colorized = false
		mo.color = player.skincolor
		mo.exhaustcolor = false
	end
	local colorflip = false
	if player.exhaustmeter < warningtic and not(player.exhaustmeter == 0) then
		if not(leveltime&7)
			S_StartSound(mo,sfx_s3kbb,player)
		end
		if (leveltime&4)
			colorflip = true
		end
	end
	if colorflip == true
		mo.exhaustcolor = true
		mo.colorized = true
		mo.color = SKINCOLOR_BRONZE
	elseif mo.exhaustcolor == true
		mo.exhaustcolor = false
		mo.colorized = false
		mo.color = player.skincolor		
	end
end

local flashingnerf = function(player)
	if not B.BattleGametype() return end
	if player.powers[pw_flashing] < (3 * TICRATE - 1)
		player.powers[pw_flashing] = min($, 2*TICRATE)
	end
end

B.CharAbilityControl = function(player)
	B.ArmaCharge(player)
	glide(player)
	homingthok(player)
	popgun(player)
	//pogo(player)
	weight(player)
	exhaust(player)
	legacykill(player)
	flashingnerf(player)
end

B.MidAirAbilityAllowed = function(player)
	return not player.gotflagdebuff
-- 		not player.gotcrystal
-- 		and not player.gotflag
end