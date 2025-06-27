local B = CBW_Battle
local D = B.Diamond
local CV = B.Console
D.ID = nil
D.Spawns = {}
D.Advantage = 0
D.CheckPoint = nil

local rotatespd = ANG20
local diamondtext = "\x83".."Diamond".."\x80"

local idletics = TICRATE*16
local advantagetics = TICRATE*8
local waittics = TICRATE*4
local freetics = TICRATE
local bounceheight = 10

local timeout = function()
	B.Timeout = TICRATE*3
-- 	for player in players.iterate do
-- 		if not player.spectator and player.playerstate == PST_LIVE
-- 			player.exiting = TICRATE*3+2
-- 		end
-- 	end
end

D.GameControl = function()
	if not(B.DiamondGametype())or not(#D.Spawns) or B.PreRoundWait() 
	then return end
	if D.ID == nil or not(D.ID.valid) then
		D.SpawnDiamond()
	end
end


D.Reset = function()
	if not(B.DiamondGametype()) then return end
	D.ID = nil
	D.Spawns = {}
	B.DebugPrint("Diamond mode reset",DF_GAMETYPE)
end

D.GetSpawns = function()
	if not(B.DiamondGametype()) then return end
	for thing in mapthings.iterate do
		local t = thing.type
		if t == 3630 -- Diamond Spawn object
			D.Spawns[#D.Spawns+1] = thing
			B.DebugPrint("Added Diamond spawn #"..#D.Spawns.. " from mapthing type "..t,DF_GAMETYPE)
		end
	end
	if not(#D.Spawns)
		B.DebugPrint("No diamond spawn points found on map. Checking for backup spawn positions...",DF_GAMETYPE)
		for thing in mapthings.iterate do
			local t = thing.type
			if t == 1 -- Player 1 Spawn
			or (t >= 330 and t <= 335) -- Weapon Ring Panels
			or (t == 303) -- Infinity Ring
			or (t == 3640) -- Control Point
				D.Spawns[#D.Spawns+1] = thing
				B.DebugPrint("Added Diamond spawn #"..#D.Spawns.. " from mapthing type "..t,DF_GAMETYPE)
			end
		end
	end
end

local function free(mo)
	mo.fuse = freetics
	mo.flags = $&~MF_SPECIAL
	mo.flags = $|MF_GRENADEBOUNCE
	mo.idle = idletics
end

D.SpawnDiamond = function()
	B.DebugPrint("Attempting to spawn diamond",DF_GAMETYPE)
	local s, x, y, z
	local fu = FRACUNIT
	if D.CheckPoint and D.CheckPoint.valid
		s = D.CheckPoint
		x = s.x
		y = s.y
		z = s.z
	else
		s = D.Spawns[P_RandomRange(1,#D.Spawns)]
		x = s.x*fu
		y = s.y*fu
		z = s.z*fu
		local subsector = R_PointInSubsector(x,y)
-- 		z = $+subsector.sector.ceilingheight
		z = $+subsector.sector.floorheight
	end
	D.ID = P_SpawnMobj(x,y,z,MT_DIAMOND)
	local mo = D.ID
	if mo and mo.valid 
		print("The "..diamondtext.." has been spawned!")
		B.DebugPrint("Diamond coordinates: "..mo.x/fu..","..mo.y/fu..","..mo.z/fu,DF_GAMETYPE)
		mo.ctfteam = 0
		if gametyperules & GTR_TEAMFLAGS
			B.DebugPrint("Advantage: "
				..(D.Advantage == 0 and "neutral" or D.Advantage == 1 and "red team" or D.Advantage == 2 and "blue team"))
			mo.ctfteam = D.Advantage
			D.Advantage = 0
			if mo.ctfteam
				mo.idle = advantagetics
			end
			mo.fuse = waittics
			B.ZLaunch(mo, FRACUNIT * 30)
			mo.renderflags = $|RF_FULLBRIGHT|RF_NOCOLORMAPS
		end
	end
end

D.Collect = function(mo,toucher)
	if mo.target == toucher or not(toucher.player) -- This toucher has already collected the item, or is not a player
	or P_PlayerInPain(toucher.player) or toucher.player.powers[pw_flashing] -- Can't touch if we've recently taken damage
	or toucher.player.tossdelay -- Can't collect if tossflag is on cooldown
	or mo.ctfteam and mo.ctfteam != toucher.player.ctfteam
		return
	end
	local previoustarget = mo.target
	mo.target = toucher
	free(mo)
	mo.idle = nil
	mo.ctfteam = 0
	S_StartSound(mo,sfx_lvpass)
	if not(previoustarget) then
		B.PrintGameFeed(toucher.player," picked up the "..diamondtext.."!")
	else
		B.PrintGameFeed(toucher.player," stole the "..diamondtext.." from ",previoustarget.player,"!")
	end
	if gametyperules & GTR_TEAMS
		D.Advantage = 3 ^^ toucher.player.ctfteam -- This gets us the team opposite of the player's team
	end
end

local points = function(player)
	if (B.Exiting) return end
	local p = 1
	P_AddPlayerScore(player,p)
	if not (gametyperules & GTR_TEAMS)
		player.gotcrystal_time = $ + 1
	end
	if gametyperules & (GTR_TEAMS|GTR_TEAMFLAGS) == GTR_TEAMS
		if player.ctfteam == 1 then
			redscore = $+p
		else
			bluescore = $+p
		end
	end
end

local capture = function(mo, player)
	P_AddPlayerScore(player,CV.DiamondCaptureBonus.value)
	S_StartSound(nil, sfx_prloop)
	for p in players.iterate() do
		if p == player or (G_GametypeHasTeams() and p.ctfteam == player.ctfteam) or p.spectator
			S_StartSound(nil, sfx_s3k68, p)
			continue
		end
		if G_GametypeHasTeams()
			S_StartSound(nil, sfx_lose, p)
			continue
		end
		S_StartSound(nil, sfx_s243, p)
	end
	P_RemoveMobj(mo)
	COM_BufInsertText(server, "csay "..player.name.."\\captured the "..diamondtext.."!\\\\")-- Not sure how to color this text...
	if D.CheckPoint and D.CheckPoint.valid
		P_RemoveMobj(D.CheckPoint)
		D.CheckPoint = nil
	end
end

D.Thinker = function(mo)
	mo.shadowscale = FRACUNIT>>2
	-- Idle timer
	if mo.idle != nil then 
		mo.idle = $-1
		if mo.idle == 0
			if mo.ctfteam
				-- Remove team protection
				mo.idle = nil
				mo.ctfteam = 0
			else
				-- Remove object
				P_SpawnMobj(mo.x,mo.y,mo.z,MT_SPARK)
				P_RemoveMobj(mo)
				return
			end
		end
	end
	
	-- Blink
	if mo.fuse&1
		mo.flags2 = $|MF2_DONTDRAW
	else
		mo.flags2 = $&~MF2_DONTDRAW
	end
	if mo.target
		mo.destscale = FRACUNIT
	else
		mo.destscale = FRACUNIT*2
	end
	
	-- Sparkle
	if not(leveltime&3)
		local i = P_SpawnMobj(mo.x,mo.y,mo.z-mo.height/4,MT_IVSP)
-- 		i.flags2 = $|MF2_SHADOW
		i.scale = mo.scale
		i.color = B.FlashRainbow(mo)
		i.colorized = true
		local g = P_SpawnGhostMobj(mo)
		g.color = B.FlashRainbow(mo)
		g.colorized = true
	end
	
	-- Color
	mo.colorized = true	
	if not(mo.target)
		mo.color = 
			mo.ctfteam == 1 and B.FlashColor(SKINCOLOR_SUPERRED1,SKINCOLOR_SUPERRED5)			
			or mo.ctfteam == 2 and B.FlashColor(SKINCOLOR_SUPERSKY1,SKINCOLOR_SUPERSKY5)			
			or B.FlashColor(SKINCOLOR_SUPERSILVER1,SKINCOLOR_SUPERSILVER5)			
	else
		mo.color = B.FlashRainbow(mo)
	end
	mo.angle = $+rotatespd
	
	local sector = P_ThingOnSpecial3DFloor(mo) or mo.subsector.sector
	-- Checkpoint sector
	if mo.target and mo.target.valid and GetSecSpecial(sector.special, 4) == 1
-- 		B.DebugGhost(mo, D.CheckPoint)
		if not (D.CheckPoint and D.CheckPoint.valid)
			D.CheckPoint = P_SpawnMobjFromMobj(mo.target, 0, 0, 0, 1)
			D.CheckPoint.flags2 = $|MF2_SHADOW
		else
			P_TeleportMove(D.CheckPoint, mo.target.x, mo.target.y, mo.target.z)
		end
		if mo.target.player.ctfteam == 1
			D.CheckPoint.state = S_REDFLAG
		elseif mo.target.player.ctfteam == 2
			D.CheckPoint.state = S_BLUEFLAG
		end
	end
	
	-- Remove object if on "remove ctf flag" sector type
	if not(mo.target and mo.target.valid) and P_IsObjectOnGround(mo)
	and GetSecSpecial(sector.special, 4) == 2
	or mo.target and mo.target.valid and P_PlayerTouchingSectorSpecial(mo.target.player, 4, 2)
-- 		print('fell into removal sector')
		if mo.target and mo.target.valid
			P_DoPlayerPain(mo.target.player)
			B.PrintGameFeed(player," dropped the "..diamondtext..".")
		end
		P_RemoveMobj(mo)
		return
	end
	for player in players.iterate do
		-- !!! I'm not sure why I resorted to an iterate function. I guess it's one way to ensure no other player thinks they have a crystal, but it's not cheap. Should be optimized later.
		if not player.mo 
			continue
		end
		if player.mo == mo.target
			-- Toss diamond
			if B.ButtonCheck(player,BT_TOSSFLAG) == 1 
			and not(player.tossdelay)
				B.PrintGameFeed(player," tossed the "..diamondtext..".")
				free(mo)
				mo.target = nil
				player.actioncooldown = TICRATE
				player.gotcrystal = false
				player.gotcrystal_time = 0
				P_TeleportMove(mo,player.mo.x,player.mo.y,player.mo.z)
				P_InstaThrust(mo,player.mo.angle,FRACUNIT*5)
				B.ZLaunch(mo,FRACUNIT*bounceheight/2)
				player.tossdelay = TICRATE*2
				player.shieldswap_cooldown = max($, 2)
			else
				points(player)
				player.gotcrystal = true
			end
		else
			player.gotcrystal = false
			player.gotcrystal_time = 0
		end
	end
	
	-- Owner has been pushed by another player
	if mo.flags&MF_SPECIAL and mo.target and mo.target.valid 
	and mo.target.pushed_last and mo.target.pushed_last.valid
		D.Collect(mo,mo.target.pushed_last)
	end
	
	-- Owner has taken damage or has gone missing
	if mo.target 
		if not(mo.target.valid)
		or P_PlayerInPain(mo.target.player)
		or mo.target.player.playerstate != PST_LIVE
			if mo.target and mo.target.valid and mo.target.player then
				B.PrintGameFeed(mo.target.player," dropped the "..diamondtext..".")
			end
			mo.target = nil
			B.ZLaunch(mo,FRACUNIT*bounceheight/2,true)
			B.XYLaunch(mo,mo.angle,FRACUNIT*5)	
			free(mo)
		end
	end
	
	-- Unclaimed behavior
	if not(mo.target and mo.target.player) then
		mo.flags = ($|MF_BOUNCE)&~(MF_SLIDEME|MF_NOGRAVITY)
		if mo.flags & MF_GRENADEBOUNCE == 0
			-- Float behavior
			if mo.z < mo.floorz+mo.scale*12 then
				mo.momz = $+mo.scale
			end
		elseif P_IsObjectOnGround(mo)
			-- Bounce behavior
			B.ZLaunch(mo, FRACUNIT*bounceheight/2, true)
		end
		return
	end
	
	-- Claimed behavior
	mo.flags = ($&~MF_BOUNCE)|MF_NOGRAVITY|MF_SLIDEME
	local t = mo.target
	local player = t.player
	local ang = mo.angle + t.angle
	local dist = mo.target.radius*3
	local x = t.x+P_ReturnThrustX(mo,ang,dist)
	local y = t.y+P_ReturnThrustY(mo,ang,dist)
	local z = t.z+abs(leveltime&63-31)*FRACUNIT/2 -- Gives us a hovering effect
	if P_MobjFlip(t) == 1 -- Make sure our vertical orientation is correct
		mo.flags2 = $&~MF2_OBJECTFLIP
	else
-- 		z = $+t.height
		mo.flags2 = $|MF2_OBJECTFLIP
	end
	P_TeleportMove(mo,t.x,t.y,t.z)
	P_InstaThrust(mo,R_PointToAngle2(mo.x,mo.y,x,y),min(FRACUNIT*60,R_PointToDist2(mo.x,mo.y,x,y)))
	mo.z = max(mo.floorz,min(mo.ceilingz+mo.height,z)) -- Do z pos while respecting level geometry
	
	if (B.Exiting) return end -- Diamond capturing behavior down below
	
	 -- Rugby capture mechanics
	if gametyperules & GTR_TEAMFLAGS
		if not P_IsObjectOnGround(t)
			return
		end
		if player.ctfteam == 1 and P_PlayerTouchingSectorSpecial(player, 4, 3)
			redscore = $+1
			capture(mo, player)
			timeout()
		elseif player.ctfteam == 2 and P_PlayerTouchingSectorSpecial(player, 4, 4)
			bluescore = $+1
			capture(mo, player)
			timeout()
		end
		return
	end
	
	-- Diamond in the Rough capture mechanics
	local captime = CV.DiamondCaptureTime.value * TICRATE
	if (player.gotcrystal_time == captime - 1 * TICRATE)
	or (player.gotcrystal_time == captime - 2 * TICRATE)
	or (player.gotcrystal_time == captime - 3 * TICRATE)
		S_StartSound(nil, sfx_s227) -- Countdown sound effect
	end
	if player.gotcrystal_time >= captime
		player.gotcrystal_time = 0
		capture(mo, player)
	end
end

