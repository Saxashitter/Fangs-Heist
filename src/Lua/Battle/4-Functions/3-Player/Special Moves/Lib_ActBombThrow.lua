local B = CBW_Battle

local state_bombthrow = 1
local state_bombthrown = 2
local state_bombjump = 10
local cooldown = TICRATE
local bombfuse = 4*TICRATE
local bjhorz = FRACUNIT*8 //bomb jump horizontal thrust
local bjvert = FRACUNIT*16 //bomb jump vertical thrust
//16
//12

local function throwbomb(mo)
	local player = mo.player
	local bomb = P_SPMAngle(mo,MT_FBOMB,mo.angle,0)
	local bombfuse = 5
	B.ApplyCooldown(player,cooldown)
	if bomb and bomb.valid then
		if G_RingSlingerGametype() or B.BattleGametype() then
			//Do skincolor
			bomb.state = S_COLORBOMB1
			bomb.color = player.skincolor
		end
		
		//Do Physics
		local water = B.WaterFactor(mo)
		bomb.momz = bomb.scale*4*P_MobjFlip(mo)/water
		bomb.flags = $|MF_BOUNCE|MF_GRENADEBOUNCE
		bomb.fuse = bombfuse*TICRATE
		bomb.staticfuse = true
	end
	return bomb
end

B.Action.BombThrow=function(mo,doaction,throwring,tossflag)
	local player = mo.player
	if P_PlayerInPain(player) then
		player.actionstate = 0
	return end

	if not(B.CanDoAction(player)) then return end
	//Action info
-- 	player.actiontext = "Throw Bomb"
-- 	if player.pflags&PF_BOUNCING
		player.actiontext = "Drop Bomb"
-- 	end
	player.actionrings = 10

	player.actiontime = $+1
	
	//Weapon control
	if player.actionstate != 0 then
		player.weapondelay = max($, 2)
	end
	
	//Neutral
	if player.actionstate == 0 and not(player.weapondelay) then
		if not(player.actioncooldown) and doaction==1 then
-- 			//Bomb Throw
-- 			if not(player.pflags&PF_BOUNCING)
-- 				player.actionstate = state_bombthrow
-- 				player.actiontime = 0
-- 			else //Bomb Drop
				local bomb = throwbomb(mo)
				if bomb and bomb.valid then
					P_InstaThrust(bomb,mo.angle,FRACUNIT*10)
-- 					bomb.momx = $+mo.momx/2
-- 					bomb.momy = $+mo.momy/2
				end
				if not(player.pflags&PF_BOUNCING)
					mo.state = S_PLAY_LOB
				end
-- 			end
			B.PayRings(player,player.actionrings)
		else return end
	end
-- 	//Prep Bomb
-- 	if player.actionstate == state_bombthrow then
-- 		player.drawangle = mo.angle
-- 		player.lockmove = true
-- 		if player.actiontime < 6
-- 		else
-- 			player.actionstate = state_bombthrown
-- 			player.actiontime = 0
-- 			//Throw bomb
-- 			throwbomb(mo)
-- 		end
-- 	end
	//Bomb thrown
	if player.actionstate == state_bombthrown then
		player.drawangle = mo.angle
		player.lockmove = true
-- 		B.DrawSVSprite(player,3)
		if player.actiontime > 12 then
			B.ResetPlayerProperties(player,false,true)
			mo.state = S_PLAY_WALK
			player.lockmove = false
			player.pflags = $|PF_JUMPDOWN
		end
	return end
	//Bomb jump
	if player.actionstate == state_bombjump then
		if ((P_IsObjectOnGround(mo) or P_MobjFlip(mo)*mo.momz < 0) and player.actiontime > 1)
		or player.actiontime > TICRATE*4
		then
			player.actionstate = 0
			mo.state = S_PLAY_FALL
		return end
		mo.state = S_PLAY_FASTEDGE
		if player.actiontime & 1
			local z = P_MobjFlip(mo) == -1 and mo.height - mobjinfo[MT_SMOKE].height
				or 0
			P_SpawnMobjFromMobj(mo, 0, 0, z, MT_SMOKE)
		end
	return end
end



B.FBombThink=function(mo)
	//Bomb jump
	if mo.state == S_FBOMB_EXPL1 and mo.tics == 1 then
		if not(mo.target and mo.target.valid and mo.target.player)
		or (mo.target.player.playerstate != PST_LIVE)
		or P_PlayerInPain(mo.target.player)
		then return end
		local dist = FixedHypot(mo.z+mo.height/2-(mo.target.z+mo.target.height/2),R_PointToDist2(mo.x,mo.y,mo.target.x,mo.target.y))
		local radius = FRACUNIT*96
		if dist < radius then
			local angle = R_PointToAngle2(mo.x,mo.y,mo.target.x,mo.target.y)
			mo.target.player.actionstate = state_bombjump
			mo.target.player.actiontime = 0
			mo.target.player.pflags = $&~(PF_JUMPED|PF_THOKKED|PF_BOUNCING)
			mo.target.state = S_PLAY_FALL
			P_SetObjectMomZ(mo.target,bjvert,1)
			P_Thrust(mo.target,angle,bjhorz)
		end
	end
	
	//Bomb physics
	if not(mo.flags&MF_MISSILE) then 
		mo.shadowscale = 0
	return end
	mo.shadowscale = FRACUNIT/2
	if mo.flags&(MF_MISSILE|MF_GRENADEBOUNCE) and P_IsObjectOnGround(mo) then
		P_SetObjectMomZ(mo,FRACUNIT*4)
	end
	//Set collision properties
	local vthreshold = mo.scale*12
	local hthreshold = mo.scale*8
	if mo.bombtype == 1 then
		if abs(mo.momz) > vthreshold then
			mo.flags = $&~MF_GRENADEBOUNCE
		else
			mo.flags = $|MF_GRENADEBOUNCE
		end
		if FixedHypot(mo.momx,mo.momz) > hthreshold then
			mo.flags = $&~MF_BOUNCE
		else
			mo.flags = $|MF_BOUNCE
		end
	end
end

B.FBombDetonate=function(mo)
	mo.momx = 0
	mo.momy = 0
	mo.momz = 0
	S_StartSound(mo,sfx_s3k4e)
	P_KillMobj(mo)
	return true
end

B.FBombSpawn = function(mo)
	mo.fuse = bombfuse
	mo.bombtype = 1
end

B.PlayerBombDamage = function(pmo,mo,source)
	if mo and mo.valid and mo.type == MT_FBOMB and mo.fuse and pmo and pmo.valid and pmo.player and source and source.valid and source.player
		and B.PlayerCanBeDamaged(pmo.player) and not(B.MyTeam(pmo.player,source.player))
		then mo.fuse = 1
	end
end

B.BombCollide = function(bomb,mo)
	if mo and mo.valid and mo.flags&(MF_MISSILE|MF_ENEMY|MF_BOSS|MF_MONITOR) and bomb.target != mo and bomb and bomb.valid and bomb.fuse > 1 
	and B.ZCollide(bomb,mo)
		then
		bomb.fuse = 1
		if mo.flags&MF_MONITOR 
		and not(G_GametypeHasTeams() and bomb.target and bomb.target.player
			and (
				(mo.type == MT_RING_REDBOX and bomb.target.player.ctfteam == 2)
				or (mo.type == MT_RING_BLUEBOX and bomb.target.player.ctfteam == 1)
			)
		)
		P_KillMobj(mo,bomb,bomb.target) end
	end
end