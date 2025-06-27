local B = CBW_Battle
local Bb = B.Battleball
local CV = B.Console
Bb.ID = nil
Bb.Spawns = {}
Bb.CheckPoint = nil

local rotatespd = ANG20
local objecttext = "\x88".."ball".."\x80"

local idletics = TICRATE*30
local bounceheight = 10

local startremove = function(mo)
	mo.dying = true
	mo.hitstun_tics = 10
end

local timeout = function()
	B.Timeout = TICRATE*3
-- 	for player in players.iterate do
-- 		if not player.spectator and player.playerstate == PST_LIVE
-- 			player.exiting = TICRATE*3+2
-- 		end
-- 	end
end

Bb.GameControl = function()
	if not(B.BattleballGametype())or not(#Bb.Spawns) or B.PreRoundWait() 
	then return end
	if Bb.ID == nil or not(Bb.ID.valid) then
		Bb.SpawnBall()
	end
end

Bb.Reset = function()
	if not(B.BattleballGametype()) then return end
	Bb.ID = nil
	Bb.Spawns = {}
	B.DebugPrint("Ball mode reset",DF_GAMETYPE)
end

Bb.GetSpawns = function()
	if not(B.BattleballGametype()) then return end
	for thing in mapthings.iterate do
		local t = thing.type
		if t == 3630 -- Ball Spawn object
			Bb.Spawns[#Bb.Spawns+1] = thing
			B.DebugPrint("Added Ball spawn #"..#Bb.Spawns.. " from mapthing type "..t,DF_GAMETYPE)
		end
	end
	if not(#Bb.Spawns)
		B.DebugPrint("No diamond spawn points found on map. Checking for backup spawn positions...",DF_GAMETYPE)
		for thing in mapthings.iterate do
			local t = thing.type
			if t == 1 -- Player 1 Spawn
			or (t >= 330 and t <= 335) -- Weapon Ring Panels
			or (t == 303) -- Infinity Ring
			or (t == 3640) -- Control Point
				Bb.Spawns[#Bb.Spawns+1] = thing
				B.DebugPrint("Added Ball spawn #"..#Bb.Spawns.. " from mapthing type "..t,DF_GAMETYPE)
			end
		end
	end
end

Bb.SpawnBall = function()
	B.DebugPrint("Attempting to spawn diamond",DF_GAMETYPE)
	local s, x, y, z
	local fu = FRACUNIT
	if Bb.CheckPoint and Bb.CheckPoint.valid
		s = Bb.CheckPoint
		x = s.x
		y = s.y
		z = s.z
	else
		s = Bb.Spawns[P_RandomRange(1,#Bb.Spawns)]
		x = s.x*fu
		y = s.y*fu
		z = s.z*fu
		local subsector = R_PointInSubsector(x,y)
-- 		z = $+subsector.sector.ceilingheight
		z = $+subsector.sector.floorheight
	end
	Bb.ID = P_SpawnMobj(x,y,z,MT_BATTLEBALL)
	local mo = Bb.ID
	if mo and mo.valid 
		print("The "..objecttext.." has been spawned!")
		B.DebugPrint("Ball coordinates: "..mo.x/fu..","..mo.y/fu..","..mo.z/fu,DF_GAMETYPE)
		B.ZLaunch(mo, FRACUNIT * 15)
		mo.renderflags = $|RF_FULLBRIGHT|RF_NOCOLORMAPS
	end
end

local points = function(player)
	if (B.Exiting) return end
	local p = 1
	P_AddPlayerScore(player,p)
	if gametyperules & (GTR_TEAMS|GTR_TEAMFLAGS) == GTR_TEAMS
		if player.ctfteam == 1 then
			redscore = $+p
		else
			bluescore = $+p
		end
	end
end

local capture = function(mo, team, player)
	if player and player.ctfteam == team
		P_AddPlayerScore(player,CV.DiamondCaptureBonus.value)
	end
	S_StartSound(nil, sfx_prloop)
	for p in players.iterate() do
		if p.spectator or p.ctfteam == team
			S_StartSound(nil, sfx_s3k68, p)
		else
			S_StartSound(nil, sfx_s243, p)
		end
	end
	startremove(mo)
	COM_BufInsertText(server, "csay "..(team == 1 and "red team" or "blue team").."\\scored a goal!\\\\")-- Not sure how to color this text...
	if Bb.CheckPoint and Bb.CheckPoint.valid
		P_RemoveMobj(Bb.CheckPoint)
		Bb.CheckPoint = nil
	end
end

Bb.Thinker = function(mo)
	if not(mo and mo.valid) or mo.hitstun_tics return end
	if mo.dying
		P_RemoveMobj(mo)
		return
	end
	local player = mo.target and mo.target.valid and mo.target.player
	-- Idle timer
	if player
		mo.fuse = idletics
		points(player)
		mo.flags2 = $&~MF2_DONTDRAW
	end
	
	-- Sparkle
	if not(leveltime&3) and player
		local i = P_SpawnMobj(mo.x,mo.y,mo.z-mo.height/4,MT_IVSP)
-- 		i.flags2 = $|MF2_SHADOW
		i.scale = mo.scale<<1
		i.color = B.FlashRainbow(mo)
		i.colorized = true
		local g = P_SpawnGhostMobj(mo)
		g.color = B.FlashRainbow(mo)
		g.colorized = true
	end
	
	-- Color
	mo.colorized = true	
	if not player
		mo.color = B.FlashColor(SKINCOLOR_SUPERSILVER1,SKINCOLOR_SUPERSILVER5)			
	else
		mo.color = 
			player.ctfteam == 1	and		B.FlashColor(SKINCOLOR_SUPERRED1,SKINCOLOR_SUPERRED5)			
			or player.ctfteam == 2 and	B.FlashColor(SKINCOLOR_SUPERSKY1,SKINCOLOR_SUPERSKY5)			
			or 							B.FlashRainbow(mo)
	end	
	local sector = P_ThingOnSpecial3DFloor(mo) or mo.subsector.sector
	-- Checkpoint sector
	if GetSecSpecial(sector.special, 4) == 1
		if not (Bb.CheckPoint and Bb.CheckPoint.valid)
			Bb.CheckPoint = P_SpawnMobjFromMobj(mo, 0, 0, 0, 1)
			Bb.CheckPoint.flags2 = $|MF2_SHADOW
		else
			P_TeleportMove(Bb.CheckPoint, mo.x, mo.y, mo.z)
		end
		Bb.CheckPoint.state = S_STARPOST_IDLE
	end
	
	-- Remove object if on "remove ctf flag" sector type
	if P_IsObjectOnGround(mo)
	and GetSecSpecial(sector.special, 4) == 2
-- 		print('fell into removal sector')
		startremove(mo)
		return
	end
	
	if (B.Exiting) return end -- Ball capturing behavior down below

	if gametyperules & GTR_TEAMFLAGS
		if not P_IsObjectOnGround(mo)
			return
		end
		if GetSecSpecial(sector.special, 4) == 3
			redscore = $+1
			capture(mo, 1, player)
			timeout()
		elseif GetSecSpecial(sector.special, 4) == 4
			bluescore = $+1
			capture(mo, 2, player)
			timeout()
		end
		return
	end
end

