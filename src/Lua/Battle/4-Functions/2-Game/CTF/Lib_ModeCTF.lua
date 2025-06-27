local B = CBW_Battle
local CV = B.Console
local F = B.CTF
local grace1 = CV.CTFdropgrace
local grace2 = CV.CTFrespawngrace
F.RedFlag = nil
F.BlueFlag = nil

F.FlagSpawn = function(mo)
	mo.renderflags = $|RF_FULLBRIGHT|RF_NOCOLORMAPS -- Improve object visibility in dark or foggy areas
	if B.DiamondGametype()
	or B.BattleballGametype()
		mo.flags = $|MF_NOTHINK
	end
end

F.TrackRed = function(mo)
	F.RedFlag = mo
end
F.TrackBlue = function(mo)
	F.BlueFlag = mo
end

F.FlagThinker = function(mo)
	if mo.flags & MF_NOTHINK
		return true
	end
	F.FlagFX(mo)
	F.FlagPhysics(mo)
	if mo.type == MT_REDFLAG
		F.TrackRed(mo)
	elseif mo.type == MT_BLUEFLAG
		F.TrackBlue(mo)
	end
	return F.FlagIntangible(mo)
end

F.FlagFX = function(mo)
	if mo.fuse
		-- Do flag spin
		mo.renderflags = $|RF_PAPERSPRITE
		mo.angle = $+ANG10 * (mo.type == MT_REDFLAG and 1 or -1)
		if R_PointToAngle(mo.x, mo.y) - mo.angle > 0
			mo.renderflags = $|RF_HORIZONTALFLIP
		else
			mo.renderflags = $&~RF_HORIZONTALFLIP
		end		
	end
	if leveltime % 4 == 0
		-- Do sparkle
		local r = mo.radius/FRACUNIT
		local h = mo.height/FRACUNIT
		local x = P_RandomRange(-r, r) * FRACUNIT
		local y = P_RandomRange(-r, r) * FRACUNIT
		local z = P_RandomRange(0, h) * FRACUNIT
		P_SpawnMobjFromMobj(mo, x, y, z, MT_BOXSPARKLE)
	end
end

F.FlagPhysics = function(mo)
	if P_IsObjectOnGround(mo)
	and mo.extravalue1 != 0
		mo.momz = -mo.extravalue1*9/10
	end
	mo.extravalue1 = mo.momz
end

F.TouchFlag = function(mo, pmo)
	local player = pmo.player
	if not mo.fuse
		return
	end
	if player.guard
	--or player.airdodge > 0
	or player.powers[pw_flashing]
		B.ZLaunch(mo, FRACUNIT*10)
		--B.XYLaunch(mo, R_PointToDist2(pmo.x, pmo.y, mo.x, mo.y), FRACUNIT*7)
		return true -- Disallow grabbing the flag while in one of these states
	end
end

F.FlagIntangible = function(mo)
	if B.CPGametype() then
		mo.flags2 = $&~MF2_DONTDRAW
		mo.flags = $&~MF_SPECIAL
	return end
	//Get spawntime
	local spawntype = 1 //flag is at base
	if mo.fuse then spawntype = 2 end //flag has been dropped

	//Initiate mo.intangibletime
	if mo.intangibletime == nil then
		if spawntype == 2 then
			mo.intangibletime = TICRATE*grace1.value
		else
			mo.intangibletime = TICRATE*grace2.value
		end
	end
	
	//Countdown
	mo.intangibletime = max(0,$-1)
	
	//Determine blink frame
	local blink = 0
	if spawntype == 2 or (spawntype == 1 and mo.intangibletime > TICRATE*2) then
		blink = mo.intangibletime&1
	else
		blink = mo.intangibletime&4
	end
	
	if blink then
		mo.flags2 = $|MF2_DONTDRAW
	else
		mo.flags2 = $&~MF2_DONTDRAW
	end
	
	//Determine tangibility
	if mo.intangibletime then
		mo.flags = $&~MF_SPECIAL
	else
		mo.flags = $|MF_SPECIAL
	end
end