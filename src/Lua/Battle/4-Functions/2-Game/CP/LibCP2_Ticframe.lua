local B = CBW_Battle
local CP = B.ControlPoint
local CV = B.Console

--SFX vars
local sfx_cphint = sfx_prloop
local sfx_startcapture = sfx_drill1
local sfx_capturing = sfx_drill2
local sfx_blockcapture = sfx_ngskid
local sfxtic = 1
local sfx_countdown = sfx_s3ka7


local function randomcolor(mo) 
	return G_GametypeHasTeams() and mo.color
		or SKINCOLOR_SUPERSILVER5 + P_RandomRange(0,8)*5 
end

CP.ThinkFrame = do
end

CP.MobjThinker = function(mo)
	--Get CP attributes
	local radius
	local height
	local meter
	if CV.CPRadius.value > 0 then --Calculate radius
		radius = CP.CalcRadius(CV.CPRadius.value)
	else
		radius = mo.cp_radius
	end
	if CV.CPHeight.value > 0 then --Calculate height
		height = CP.CalcHeight(CV.CPHeight.value)
	elseif CV.CPHeight.value == -1 then
		height = mo.ceilingz - mo.floorz
	elseif mo.cp_height > 0 then
		height = mo.cp_height
	else
		height = mo.ceilingz - mo.floorz
	end
	if CV.CPMeter.value > 0 then --Calculate meter
		meter = CP.CalcMeter(CV.CPMeter.value)
	else
		meter = mo.cp_meter
	end	

	--Get Orientation and surfaces
	local flip = P_MobjFlip(mo)
	local floor
	local ceil
	if flip == 1 then
		floor = mo.floorz
		ceil = mo.ceilingz
	else
		floor = mo.ceilingz
		ceil = mo.floorz
	end

	--Do Active/Inactive Thinker instructions
	if mo.capture_status
		CP.ActiveThinker(mo,floor,flip,ceil,radius,height,meter)
	else
		CP.InertThinker(mo)
	end
	-- Do visual instructions
	CP.PointHover(mo,floor,flip,height)
	CP.UpdateFX(mo)
end

CP.InertThinker = function(mo)
	--Countdown to activate capture point
	if mo.fuse == TICRATE*10 then
		S_StartSound(nil,sfx_cphint)
	elseif (mo.fuse == TICRATE or mo.fuse == TICRATE*2 or mo.fuse == TICRATE*3) then
		S_StartSound(nil,sfx_countdown)
	end
end

CP.ActiveThinker = function(mo,floor,flip,ceil,radius,height,meter)	
	mo.color = SKINCOLOR_JET
	local capture_status = CP_ACTIVE
	--Get capturers
	local team = {0,0}
	local activeplayers = 0
	local captureplayers = {}
	for n = 0, 31 do
		if not(players[n] and players[n].playerstate == PST_LIVE) or players[n].spectator
			mo.capture_amount[n] = 0
		end
	end
	
	for player in players.iterate() do
		if player.spectator
			continue
		end
		
		activeplayers = $+1
		
		if not(player.playerstate == PST_LIVE and not(player.powers[pw_flashing]) and player.mo and player.mo.valid)
		or player.mo.flags&MF_NOCLIPTHING
		or not(P_CheckSight(mo,player.mo)) 
		or not(R_PointToDist2(player.mo.x,player.mo.y,mo.x,mo.y) < radius) 
			continue
		end
		
		local zpos1 = player.mo.z-floor
		local zpos2 = player.mo.z+player.mo.height-floor
		
		if flip == 1 and (zpos1 > height or zpos2 < 0) 
		or flip == -1 and (zpos2 < -height or zpos1 > 0)
			continue
		end
		
		player.capturing = mo.cpnum
		local t = player.ctfteam
		table.insert(captureplayers, player)
		
		if t then
			team[t] = $+1
		end
	end
	if G_GametypeHasTeams()
		-- Team modes
		if team[1] > 0 and team[2] > 0 then	--Contested point
			if team[1] != team[2] then --Uneven player amounts (Allow capture)
				capture_status = CP_CAPTURING
				--Color flash
				if leveltime&4 then
					mo.color = SKINCOLOR_GREY
				elseif team[1] > team[2] then
					mo.color = SKINCOLOR_RED
				else
					mo.color = SKINCOLOR_BLUE
				end
				--Points calculation
				if team[1] > team[2] then
					mo.capture_amount[1] = $+team[1]-team[2]
				else
					mo.capture_amount[2] = $+team[2]-team[1]
				end
			else --Blocked point
				capture_status = CP_BLOCKED
				mo.color = SKINCOLOR_YELLOW
				if mo.capture_status != capture_status then
					print("\x82 Capture blocked!")
					S_StartSound(mo,sfx_blockcapture)
				end
			end
		elseif G_GametypeHasTeams() -- Team capturing
			for t = 1,2 do
				local amt = team[t]
				mo.capture.amount[t] = $+amt
			end
			if team[1] > team[2] then
				mo.color = SKINCOLOR_RED
			end
			if team[2] > team[1] then
				mo.color = SKINCOLOR_BLUE
			end
		end		
		-- Get high score/leader
		if mo.capture_amount[1] > mo.capture_amount[2]
			mo.capture_leader = 1
			mo.capture_highscore = mo.capture_amount[1]
		elseif mo.capture_amount[2] > mo.capture_amount[1]
			mo.capture_leader = 2
			mo.capture_highscore = mo.capture_amount[2]
		end
	else --Free for all capture
		if #captureplayers
			capture_status = CP_CAPTURING
		end
		for _,player in ipairs(captureplayers) do
			local n = #player+1
			local amt = 2
			mo.capture_amount[n] = $+amt
			mo.capture_highscore = max($,mo.capture_amount[n])
			if mo.capture_amount[n] == mo.capture_highscore and mo.capture_leader != n then
				mo.capture_leader = n
				print(player.name.." has taken the capture lead!")
			end
			if n == mo.capture_leader then
				mo.color = player.skincolor
			end
			if not(leveltime&3)
				P_AddPlayerScore(player,amt)
			end
		end
	end
	
	--Update capturing state
	if #captureplayers == 0 or capture_status == CP_BLOCKED
		sfxtic = 1
	elseif capture_status == CP_CAPTURING and capture_status != mo.capture_status
		S_StartSound(mo,sfx_startcapture)
	elseif capture_status == CP_CAPTURING and not(S_SoundPlaying(mo,sfx_startcapture)) then
		if sfxtic == 1 then
			S_StartSound(mo,sfx_capturing)
		end
		sfxtic = $%8 + 1
	end
	mo.capture_status = capture_status
	
	--Seize Point
	if mo.capture_highscore >= meter then
		CP.SeizePoint(mo)
	end

	-- Do aesthetic color trail to player
	local interval = 3
	if not(leveltime&(1<<interval - 1)) then
		for _, player in ipairs(captureplayers) do
			local b = P_SpawnMobj(mo.x,mo.y,mo.z,MT_CPBONUS)
			b.target = player.mo
			b.tracer = mo
			b.fuse = 10
			b.extravalue1 = b.fuse
			b.color = randomcolor(player.mo)
			b.scale = $*2
			table.insert(mo.fx, b)
		end
	end
end