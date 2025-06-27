local B = CBW_Battle

//Charge time thresholds
local threshold1 = 6
local threshold2 = threshold1+35
local state_charging = 1
local state_energyblast = 2
local state_dashslicer = 3
local cooldown_dash = TICRATE * 5/2
local cooldown_blast = TICRATE * 5/4
local cooldown_slice = TICRATE * 2
local cooldown_cancel = TICRATE
local sideangle = ANG15/4 //Horizontal spread
local vertwidth = ANG15/2 //Vertical spread
local blastcount1 = 3
local blastcount2 = 5

local resetdashmode = function(p)
	p.dashmode = 0
	p.normalspeed = skins[p.skin].normalspeed
	p.jumpfactor = skins[p.skin].jumpfactor
end

B.Action.EnergyAttack_Priority = function(player)
	if player.actionstate == state_charging then
		B.SetPriority(player,1,1,nil,1,1,"energy charge aura")
	end
	if player.actionstate == state_dashslicer then
		B.SetPriority(player,3,3,nil,3,3,"dash slicer")
	end
end

B.Action.EnergyAttack=function(mo,doaction,throwring,tossflag)
	local player = mo.player
	if P_PlayerInPain(player)
		player.actionstate = 0
	end
		
	//Action info
	player.actiontext = "Energy Attack"
	player.actionrings = 10
	player.actiontime = $+1
	if player.exhaustmeter < FRACUNIT and player.actionstate == 1 then
		player.action2text = "Overheat "..100*player.exhaustmeter/FRACUNIT.."%"
	end
	
	if not(B.CanDoAction(player) or player.actionstate >= state_dashslicer)
		if S_PLAY_PREPATK
			B.ResetPlayerProperties(player,false,false)
		return end
	return end
	
	//Action triggers
	local attackready = (player.actiontime >= threshold1 and player.actionstate == state_charging)
	local charging = player.exhaustmeter and ((B.PlayerButtonPressed(player,player.battleconfig_special,true) or not(attackready)) and player.actionstate == state_charging)
	local slashtrigger = attackready and B.PlayerButtonPressed(player,BT_SPIN,false)
	local blasttrigger = not(slashtrigger) and attackready and doaction == 0 and attackready
	local chargehold = (attackready and B.PlayerButtonPressed(player,player.battleconfig_special,true))
	local dashtrigger = not(slashtrigger) and attackready and doaction == 2 and B.PlayerButtonPressed(player,BT_JUMP,false)
	local canceltrigger =
		not(blasttrigger or slashtrigger or dashtrigger)
		and player.actionstate == state_charging
		and doaction == 2
		and (
			player.exhaustmeter == 0
			or B.PlayerButtonPressed(player,player.battleconfig_guard,false)
		)
	local chargetrigger = (player.actionstate == 0 and doaction == 1)
	
	//Intercepted while charging
	if (player.actionstate == state_charging or player.actionstate == state_energyblast) and player.powers[pw_nocontrol] then
		player.actionstate = 0
		B.ApplyCooldown(player,cooldown_cancel)
		return
	end
	
	//Start charging blast
	if chargetrigger
		B.PayRings(player,player.actionrings)
		player.actionstate = 1
		player.actiontime = 0
		player.exhaustmeter = FRACUNIT
		if player.dashmode >= TICRATE*3 then
			player.actiontime = threshold1
		end
		resetdashmode(player)
		player.pflags = $&~(PF_SPINNING|PF_SHIELDABILITY)
		player.canguard = false
		S_StartSound(mo,sfx_s3k7a)
		local a = P_SpawnMobj(mo.x,mo.y,mo.z,MT_ENERGYAURA)
		if a and a.valid then 
			a.target = mo
			a.scale = mo.scale
			a.spriteyoffset = -16*FRACUNIT
		end
	end
	
	//Charging Blast
	if charging then
		//Do aim sights
		B.DrawAimLine(player,mo.angle)
		if player.actiontime > threshold2
			B.DrawAimLine(player,mo.angle+sideangle*(blastcount2>>1))
			B.DrawAimLine(player,mo.angle-sideangle*(blastcount2>>1))
		end
		player.canguard = false
		player.pflags = $|PF_JUMPSTASIS
		player.exhaustmeter = max(0,$-(FRACUNIT/TICRATE/2))
		
		//Gather spheres
		local gather = P_SpawnMobj(mo.x,mo.y,mo.z+mo.height/2,MT_ENERGYGATHER)
		if gather and gather.valid then
			gather.target = mo
			gather.fuse = 35
			gather.extravalue1 = P_RandomRange(0,359)*ANG1
			gather.extravalue2 = P_RandomRange(0,359)*ANG1
			gather.scale = mo.scale/4
		end
		
		//Speed Cap
		local speed = FixedHypot(mo.momx,mo.momy)
		if speed > mo.scale then
			local dir = R_PointToAngle2(0,0,mo.momx,mo.momy)
			P_InstaThrust(mo,dir,FixedMul(speed,mo.friction))
		end
		//Blast Powerup
		if chargehold then
			if not(player.actiontime&3)
				then
				S_StartSound(mo,sfx_s3k5c)
-- 				P_SpawnThokMobj(player)
			end
			if player.actiontime == threshold2 then
			S_StartSound(mo,sfx_s1c3)
				for l = 0,8 do
					P_SpawnParaloop(mo.x,mo.y,mo.z+mo.height/2,256*mo.scale,16,MT_NIGHTSPARKLE,mo.angle+45*l*ANG1,nil,1)
				end
			end
			/*
			if player.actiontime >= threshold2 then
				local thok = P_SpawnMobj(mo.x+P_RandomRange(-mo.radius/FRACUNIT,mo.radius/FRACUNIT)*FRACUNIT,mo.y+P_RandomRange(-mo.radius/FRACUNIT,mo.radius/FRACUNIT)*FRACUNIT,mo.z,MT_THOK)
				if thok and thok.valid then
					thok.scale = $/16
					P_SetObjectMomZ(thok,FRACUNIT*16*8)
					thok.momx = mo.momx
					thok.momy = mo.momy
					thok.color = SKINCOLOR_WHITE
				end
			end
			*/
		end
	end
	
	//Dash burst
	if dashtrigger then
		B.ResetPlayerProperties(player,true,true)
-- 		player.pflags = $|PF_NOJUMPDAMAGE&~PF_JUMPDOWN
		player.pflags = $&~PF_JUMPED
		player.actiontime = -1
		S_StartSound(mo,sfx_s3k54)
		P_InstaThrust(mo,mo.angle,FixedMul(player.normalspeed,mo.scale))
		mo.state = S_PLAY_DASH
		B.ApplyCooldown(player,cooldown_dash)
		player.dashmode = TICRATE*3
	end
	
	//Unable to charge
	if canceltrigger then
		B.ResetPlayerProperties(player,false,false)
		player.actiontime = -1
		S_StartSound(mo,sfx_s3k7d)
		B.ApplyCooldown(player,cooldown_cancel)
	end
	
	//Release blast
	if blasttrigger then
		player.actionstate = 2
		S_StartSound(mo,sfx_s3k54)
		local set = blastcount1
		local decay = 1
		local vset = 3
		local vwidth = vertwidth/2
		if player.actiontime >= threshold2 then
			set = blastcount2
			decay = 0
			vset = 6
			vwidth = vertwidth
		end
		local angle = mo.angle
		//Projectiles
		for i = 1,set do
			if i > 1 and i&1 then angle = mo.angle-sideangle*(i>>1) end
			if i > 1 and not(i&1) then angle = mo.angle+sideangle*(i>>1) end
			local m = (vset)
			if i > 1 and decay then m = 0 end
			for n = 0, m do
				local blast = P_SPMAngle(mo,MT_ENERGYBLAST,angle,0)
				if blast and blast.valid then
					blast.scale = (mo.scale/400)*(200+player.actiontime)
					local speed = FixedMul(blast.info.speed,mo.scale)
					local xyangle = R_PointToAngle2(0,0,blast.momx,blast.momy)
					local zangle
					if m == 0 then zangle = 0
					else zangle = B.FixedLerp(-vwidth,vwidth,FRACUNIT*n/m)
					end
					B.InstaThrustZAim(blast,xyangle,zangle,speed,0)
					if G_GametypeHasTeams() then
						blast.colorized = true
						blast.color = mo.color
					end
				end
			end
		end
		//Apply recoil
		P_InstaThrust(mo,mo.angle+ANGLE_180,6*mo.scale)
		player.actiontime = 0
		B.ApplyCooldown(player,cooldown_blast)
	end
	
	//Update states
	if player.actionstate == state_charging then
		mo.state = S_PLAY_PREPATK
		player.drawangle = mo.angle
		player.pflags = ($|PF_JUMPED)&~PF_NOJUMPDAMAGE
		P_SetObjectMomZ(mo,FRACUNIT/2,false) //Rise slowly
	elseif (player.actiontime == -1) then
		player.actiontime = 0
	end
	
	//Charge release state
	if player.actionstate == state_energyblast then
		mo.state = S_PLAY_SPRING
-- 		player.pflags = $|(PF_JUMPED|PF_NOJUMPDAMAGE|PF_THOKKED)&~PF_JUMPDOWN
		player.pflags = $&~PF_JUMPED
		player.exhaustmeter = FRACUNIT
		player.secondjump = 0
		mo.momz = 0
		if player.actiontime > 15 then
			player.actiontime = 0
			player.actionstate = 0
		end
	end

	//Slasher
	if slashtrigger then
		//Next state
		player.actionstate = state_dashslicer
		player.actiontime = 0
		S_StartSound(mo,sfx_cdfm01)
	end
	
	//Slash-dashing
	if player.actionstate == state_dashslicer then
		player.lockaim = true
		player.lockmove = true
		//player.dashmode = TICRATE*3
		player.powers[pw_nocontrol] = max($,2)
		mo.state = S_PLAY_DASH
		mo.frame = 0
		mo.sprite2 = SPR2_DASH
		mo.momz = 1
-- 		mo.state = S_PLAY_ROLL
		local r = mo.radius/FRACUNIT/2
		local x = mo.x+P_RandomRange(-r,r)*FRACUNIT
		local y = mo.y+P_RandomRange(-r,r)*FRACUNIT
		local z = mo.z+P_RandomRange(0,mo.height/FRACUNIT)*FRACUNIT
		local spark = P_SpawnMobj(x,y,z,MT_SUPERSPARK)
		if spark and spark.valid
			spark.scale = mo.scale
		end
		P_SpawnGhostMobj(mo)
		local spd = FixedMul(player.normalspeed/B.WaterFactor(mo),mo.scale)
		if twodlevel or mo.flags2&MF2_TWOD then
			spd = $*3/4
		end
		P_InstaThrust(mo,mo.angle,spd)
		player.pflags = $|PF_SPINNING
		
		
		//Release the slicer
		if not(player.actiontime >= TICRATE/3) then return end
		local missile = P_SPMAngle(mo,MT_DASHSLICER,mo.angle,0)
		/*if missile and missile.valid then
			local spd = FixedHypot(missile.momx,missile.momy)/B.WaterFactor(mo)
			if mo.flags2&MF2_TWOD or twodlevel then
				spd = $/2
			end
			P_InstaThrust(missile,mo.angle,spd)
		end*/
		//Next state
		player.actionstate = state_dashslicer+1
		player.actiontime = 0
		B.ZLaunch(mo,FRACUNIT*24,0)
		mo.momx = $ * 2/3
		mo.momy = $ * 2/3
		player.pflags = $|(PF_SPINNING|PF_JUMPED)
		mo.state = S_PLAY_ROLL
		S_StartSound(mo,sfx_s3ka0)
		S_StartSound(mo,sfx_cdfm14)
		B.ApplyCooldown(player,cooldown_slice)
	end
	
	//Slash-striking
	if player.actionstate == state_dashslicer+1 then
		player.lockaim = true
		player.lockmove = true
		if not(player.pflags&(PF_SPINNING|PF_JUMPED)) then
			mo.state = S_PLAY_WALK
		else
			mo.state = S_PLAY_ROLL
		end
		player.powers[pw_nocontrol] = max($,2)
		B.ControlThrust(mo,FRACUNIT*90/100)
		if not(player.actiontime >= TICRATE*3/8) then return end
		
		//Back to neutral
		player.actionstate = 0
		mo.state = S_PLAY_SPRING
		player.pflags = $&~(PF_SPINNING|PF_JUMPED|PF_THOKKED)
		player.secondjump = 0
	end
end


//-Metal Energy Aura-
B.MetalAura = function(mo,target)
	if not(target and target.valid and target.player and target.player.actionstate == state_charging
		and target.player.playerstate == PST_LIVE)
		P_RemoveMobj(mo)
	return end
	mo.scale = target.scale
	if P_MobjFlip(target) == 1
		mo.eflags = $&~MFE_VERTICALFLIP
		P_TeleportMove(mo,target.x,target.y,target.z+target.height/4)
	else
		mo.eflags = $|MFE_VERTICALFLIP
		P_TeleportMove(mo,target.x,target.y,target.z+target.height*3/4)
	end
end

//-Metal Sonic "gather" spheres-
B.EnergyGather = function(mo,target,xyangle,zangle)
	if not(target and target.valid and target.player and target.player.actionstate == state_charging) then
		P_RemoveMobj(mo)
	return end
	local dist = mo.scale*4*16*mo.fuse
	local xydist = P_ReturnThrustX(nil,zangle,dist)
	local zdist = P_ReturnThrustY(nil,zangle,dist)
	local x = target.x+P_ReturnThrustX(nil,xyangle,xydist)
	local y = target.y+P_ReturnThrustY(nil,xyangle,xydist)
	local z = target.z+zdist+target.height/2
	P_TeleportMove(mo,x,y,z)
end

B.DashSlicerSpawn=function(mo)
	mo.fuse = 8
	mo.time = 0
end

B.DashSlicerThinker=function(mo)
	if not(mo and mo.valid and mo.target and mo.target.valid and mo.target.health) then return end
	mo.time = $+1
	
	//Effects
	local x,y,z,dist,angoff
	dist = mo.radius
	angoff = P_RandomRange(90,270)*ANG1
	x = mo.x+P_ReturnThrustX(nil,mo.angle+angoff,dist)
	y = mo.y+P_ReturnThrustY(nil,mo.angle+angoff,dist)
	z = mo.z
	P_SpawnMobj(x,y,z,MT_DUST)
	
	if mo.time < 3 then return end
	//Slashes
	local dist = mo.radius
	local x,y,z,s
	local angoff = ANGLE_90
	z = mo.z
	if mo.time&1 then
		x = mo.x+P_ReturnThrustX(nil,mo.angle+angoff,dist)
		y = mo.y+P_ReturnThrustY(nil,mo.angle+angoff,dist)
		s = S_SLASH3
	else
		x = mo.x+P_ReturnThrustX(nil,mo.angle-angoff,dist)
		y = mo.y+P_ReturnThrustY(nil,mo.angle-angoff,dist)
		s = S_SLASH1
		S_StartSound(mo.target,sfx_rail1)
	end
	local missile = P_SpawnXYZMissile(mo.target,mo,MT_SLASH,x,y,z)
	if missile and missile.valid then
		missile.state = s
		missile.scale = $*2
	end
end
