local B = CBW_Battle
local CV = B.Console

local pinchtime = 31
local pinchmusic = "BPNCH1"
local overtimemusic = "BPNCH2"

B.PreRoundWait = function()
	if ((CV.PreRound.value or (gametyperules & GTR_CAMPAIGN and not(CV.Debug.value)))
		and not(B.TagGametype()))
	and gametyperules&GTR_STARTCOUNTDOWN and leveltime < CV_FindVar("hidetime").value*TICRATE
	or B.Timeout
		then return true
	else return false end
end

B.GetPinch = function()
	B.PinchTics = max(0,$-1)
	if B.Exiting then 
		B.SuddenDeath 	= false
		B.Pinch 		= false
		B.Overtime	 	= false
	return end
	//Get vars
	local t 			= CV_FindVar("timelimit")
	local ot 			= CV_FindVar("overtime")
	local pre_pinch 	= (t.value*60-pinchtime)
	local timeleft 		= pre_pinch-leveltime/TICRATE
	local pinch 		= timeleft < 0
	local overtime 		= ((ot.value) and (gametyperules & GTR_OVERTIME) and t.value*60-leveltime/TICRATE <= 0)
	local suddendeath 	= (B.Gametypes.SuddenDeath[gametype] and overtime and CV.SuddenDeath.value == 1)
	//Check game mode conditions
	if not(B.PreRoundWait())
	and gametyperules&GTR_TIMELIMIT and t.value and pinch
		//Pinch state
		if not(overtime)
			B.SuddenDeath 	= false
			B.Overtime 		= false
			//Do pinch indicators
			if B.Pinch == false then
				B.Pinch = true
				B.DebugPrint("Pinch mode triggered",DF_GAMETYPE)
				S_StartSound(nil,sfx_s3k63)
				B.PinchMusic(consoleplayer)
				B.PinchTics = TICRATE*2
			end
		end
		//Overtime state
		if overtime then
			B.Pinch = false
			//Enable sudden death
			if suddendeath and not(B.SuddenDeath)
				B.DebugPrint("Sudden death triggered",DF_GAMETYPE)
				B.SuddenDeath = true
				B.PinchTics = TICRATE*2
	 			S_StartSound(nil,sfx_s253)
			end
			//Do overtime indicators
			if B.Overtime == false then
				B.DebugPrint("Overtime triggered",DF_GAMETYPE)
				B.Overtime = true
				B.OvertimeMusic(consoleplayer)
			end
		end
	else
		if not(B.Exiting or B.Timeout) and (B.Pinch or B.SuddenDeath or B.Overtime) then
			B.DebugPrint("Pinch mode / sudden death / overtime deactivated",DF_GAMETYPE)
			B.Pinch = false
			B.SuddenDeath = false
			B.Overtime = false
			for player in players.iterate
	-- 			P_RestoreMusic(player)
				COM_BufInsertText(player,"tunes -default")
			end
		end
	end
end

B.SuddenDeathBomb = function()
	if leveltime&7 then return end
	if B.PinchTics then return end
	local unlucky = {} //Raffle of players to choose to bomb
	for player in players.iterate()
		if player.spectator or player.playerstate != PST_LIVE then continue end
		if player.exiting then continue end
		if not(player.mo) then continue end
		if player.revenge then continue end
		unlucky[#unlucky+1] = player.mo //Can be bombed
	end
	if not(#unlucky) then return end //No one to bomb
	
	local mo = unlucky[P_RandomRange(1,#unlucky)] //And our unlucky winner is...
	
	local z 
	if P_MobjFlip(mo) == 1 then
		z = B.FixedLerp(mo.z,mo.ceilingz,P_RandomRange(FRACUNIT/2,FRACUNIT))
	else
		z = B.FixedLerp(mo.z,mo.floorz,P_RandomRange(FRACUNIT/2,FRACUNIT))
	end
	local b = P_SpawnMobj(mo.x,mo.y,z,MT_FBOMB)
-- 	b.bombtype = 0
-- 	b.flags = $|MF_GRENADEBOUNCE
	if P_MobjFlip(mo) == -1 then
		b.flags2 = MF2_OBJECTFLIP
	end
	local dist = P_RandomRange(0,512)*FRACUNIT
	local ang = P_RandomRange(0,359)*ANG1
	local x = b.x+P_ReturnThrustX(b,ang,dist)
	local y = b.y
	if not(twodlevel) then
		y = $+P_ReturnThrustY(b,ang,dist)
	end
	P_TryMove(b,x,y,false)
end

B.SuddenDeathGrow = function(player)
	for player in players.iterate()
		if player.spectator
		or player.playerstate != PST_LIVE
		or player.exiting 
		or not(player.mo)
		or player.revenge then continue end
		player.mo.scale = $+FRACUNIT/400
	end
end

B.PinchMusic = function(player)
	if B.Exiting then return end
	if player == nil then return end
	if B.Pinch and player == consoleplayer then
		B.DebugPrint("Starting pinch music",DF_GAMETYPE)
		COM_BufInsertText(player,"tunes "..pinchmusic)
	return true end
	return false
end

B.OvertimeMusic = function(player)
	if B.Exiting then return end
	if player == nil then return end
	if B.Overtime and player == consoleplayer then
		B.DebugPrint("Starting overtime music",DF_GAMETYPE)
		COM_BufInsertText(player,"tunes "..overtimemusic)
	return true end
	return false
end

B.PinchControl = function()
	B.GetPinch()
	if B.SuddenDeath then
		B.SuddenDeathGrow()
	end
end