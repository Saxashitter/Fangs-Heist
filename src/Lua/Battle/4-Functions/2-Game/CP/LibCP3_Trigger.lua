local B = CBW_Battle
local CP = B.ControlPoint
local CV = B.Console

-- Display/sfx vars
local sfx_cpappear = sfx_ngdone
local sfx_cpwin = sfx_hidden
local sfx_cplose = sfx_nxitem
local appearmsg = "A\x82\ Control Point\x80\ has been unlocked!"
local capturemsg = "\x80\ captured a control point!"

-- Shuffle CP activation order. Done on mapload and after all CP indexes have been iterated through.
CP.Shuffle = do
	CP.ID = B.Shuffle($)
end

-- Reset CP properties, typically after capturing.
CP.ResetPoint = function(mo)
	for n = 1, 32 do
		mo.capture_amount[n] = 0
	end
	mo.capture_leader = 0
	mo.capture_highscore = 0
	mo.capture_status = CP_INERT
	
	CP.ResetFX(mo)
end



-- CP timer reaches zero
CP.MobjFuse = function(mo)
	CP.ActivatePoint(mo)
	return true
end

-- Directly or remotely activate a control point
CP.ActivatePoint = function(arg)
	local mo, num
	if type(arg) == 'userdata'
		mo = arg
		num = mo.cpnum
	elseif type(arg) == 'number'
		num = arg
	end
	if not(mo) -- Search by CP.ID index
		num = $ or CP.Num or 1
		if not(CP.Num) then CP.Num = num end 
		mo = CP.ID[num]
		if not(mo and mo.valid) then
			print("\x82 WARNING:\x80 Next control point is invalid! Attempting to spawn backup CP...")
			mo = CP.BackupGenerate()
			if mo != nil then
				CP.ID[num] = mo
			end
		end
	end
	if mo.capture_status == CP_INERT
		mo.capture_status = CP_ACTIVE
		CP.Mode = true
		CP.ActivateFX(mo)
		CP.ActiveCount = $+1
		S_StartSound(nil,sfx_cpappear)
		print(appearmsg)
	else
		B.Warning("Attempted to activate CP #"..num.." (already active)")
	end
end

-- Directly or remotely deactivate a control point
CP.DeactivatePoint = function(arg)
	local mo, num
	if type(arg) == 'userdata'
		mo = arg
		num = mo.cpnum
	elseif type(arg) == 'number'
		num = arg
	end
	if not(mo) -- Search by CP.ID index
		num = $ or CP.Num or 1
		if not(CP.Num) then CP.Num = num end
		mo = CP.ID[num]
		assert(mo and mo.valid, "Attempted to deactivate a CP that does not exist (index "..num..", out of "..#CP.ID..")")
	end
	if mo.capture_status != CP_INERT
		CP.ResetPoint(mo)
		CP.ActiveCount = $-1
		print("!Deactivated point "..mo.cpnum)
	end
end

-- Set the next CP to activate
CP.TryNextPoint = function(activate)
	activate = $ or 1
	local attempts = #CP.ID
	-- Iterate through CPs until all CPs have been tried or we've marked a certain number of CPs for activation
	while (activate > 0 and attempts > 0) do
		attempts = $-1
		CP.Num = $ % #CP.ID + 1 -- Wrap to the first index if max number has already been reached
		if CP.Num == 1 -- Shuffle indices on wrap-around
			CP.Shuffle()
		end
		local mo = CP.ID[CP.Num]
		if mo.capture_status == CP_INERT and not(mo.fuse)
			activate = $-1
			mo.fuse = CV.CPWait.value*TICRATE
		end
	end
end

-- CP is captured
CP.SeizePoint = function(mo)
	if G_GametypeHasTeams() 
	
		--Team capture
		local victor = 0
		if mo.capture_amount[1] > mo.capture_amount[2] 
			victor = 1
			print("\x85 Red Team"..capturemsg)
			redscore = $+1
		elseif mo.capture_amount[2] > mo.capture_amount[1] 
			victor = 2			
			print("\x84 Blue Team"..capturemsg)
			bluescore = $+1
		end
		
		-- SFX
		if consoleplayer and consoleplayer.ctfteam == victor 
			S_StartSound(nil,sfx_cpwin)
		else
			S_StartSound(nil,sfx_cplose)
		end
		
	elseif mo.capture_leader and players[mo.capture_leader-1]
		
		-- Free for all capture
		local player = players[mo.capture_leader-1]
		print(player.name..capturemsg)
		P_AddPlayerScore(player,CV.CPBonus.value)
		
		-- SFX
		if consoleplayer == player 
			S_StartSound(nil,sfx_cpwin)
		else
			S_StartSound(nil,sfx_cplose)
		end
	end
	CP.ResetPoint(mo)
	CP.TryNextPoint()
-- 	CP.Timer = CV.CPWait.value*TICRATE
end