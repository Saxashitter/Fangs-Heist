local B = CBW_Battle
local state_swipe = 1
local state_thrust = 2
local cooldown_swipe = TICRATE*7/5
local cooldown_dash = TICRATE*6/5
local cooldown_throw = cooldown_dash
local sideangle = ANG30 --+ ANG10
local throw_strength = 30
local throw_lift = 10
local thrustpower = 16

local function sbvars(m,pmo)
	if m and m.valid then
		m.fuse = 45
		if (pmo.player.pflags & PF_THOKKED)
			m.momz = -P_MobjFlip(m)*R_PointToDist2(m.momx, m.momy, 0, 0) * 2/3
			m.momx = $/3
			m.momy = $/3
		end
		m.momx = $ + pmo.momx/2
		m.momy = $ + pmo.momy/2
		S_StartSoundAtVolume(m,sfx_s3kb8,190)
	end
end

local function domissile(mo,thrustfactor)
	//Projectile
	local m = P_SPMAngle(mo,MT_SONICBOOM,mo.angle+sideangle,0)
	sbvars(m,mo)
	//Do Side Projectiles
	local m = P_SPMAngle(mo,MT_SONICBOOM,mo.angle-sideangle,0)
	sbvars(m,mo)
	local m = P_SPMAngle(mo,MT_SONICBOOM,mo.angle,0)
	sbvars(m,mo)
	//Thrust
	if not(P_IsObjectOnGround(mo))
		P_Thrust(mo,mo.angle+ANGLE_180,thrustfactor*5)
	else
		P_Thrust(mo,mo.angle+ANGLE_180,thrustfactor*10)
	end
end

local function dodust(mo)
	if P_IsObjectOnGround(mo)
		local player = mo.player
		local dust = P_SpawnMobjFromMobj(mo,0,0,0,MT_DUST)
		P_InstaThrust(dust,player.drawangle,mo.scale*12)
	end
end

B.SonicBoomThinker = function(mo)
	if not(mo.flags&MF_MISSILE) then return end
	P_SpawnGhostMobj(mo)
	local radius = mo.radius/FRACUNIT
	local r = do
		return P_RandomRange(-radius,radius)*FRACUNIT
	end
	local s = P_SpawnMobjFromMobj(mo,r(),r(),0,MT_SPARK)
	s.scale = $*3/4
	if P_RandomRange(0,1) then
		s.colorized = true
		s.color = SKINCOLOR_SKY
	end
	P_Thrust(mo,R_PointToAngle2(0,0,mo.momx,mo.momy) + ANGLE_180,R_PointToDist2(0,0,mo.momx,mo.momy) / 16)
end

B.Action.TailSwipe = function(mo,doaction)
	local player = mo.player
	if not(B.CanDoAction(player)) 
		if player.actionstate
			B.ResetPlayerProperties(player,false,true)
		end
	return end
	
	local flying = S_PLAY_TAILSFLY
	local carrying = false
	for otherplayer in players.iterate do
		if otherplayer.mo and otherplayer.mo.valid
		and otherplayer.mo.tracer == mo
		and otherplayer.powers[pw_carry] == CR_PLAYER
			carrying = true
			break
		end
	end
	
-- 	local swipetrigger = (player.actionstate == 0 and doaction == 1 and not(flying or carrying))
-- 	local thrusttrigger = (player.actionstate == 0 and doaction == 1 and flying and not(carrying))
	local throwtrigger = (player.actionstate == 0 and doaction == 1 and carrying)
	local swipetrigger = (player.actionstate == 0 and doaction == 1 and not(flying and carrying))
	//Get thrust speed multiplier
	local thrustfactor = mo.scale
	if mo.eflags&MFE_UNDERWATER
		thrustfactor = $>>1
	end
	if mo.flags2&MF2_TWOD or twodlevel
		thrustfactor = $>>1
	end
	
	player.actionrings = 6
	if not(flying) then
		player.actiontext = "Tail Swipe"
	elseif not(carrying)
		player.actiontext = "Flight Dash"
	else
		player.actiontext = "Throw Partner"
	end
	
	if player.actionstate != 0 then
		player.exhaustmeter = FRACUNIT
	end
	
	//Activate swipe
	if swipetrigger 
		B.PayRings(player)
		B.ApplyCooldown(player,cooldown_swipe)
		//Missile attack
		domissile(mo,thrustfactor)
		//Set state
		mo.state = S_TAILS_SWIPE
		player.actionstate = state_swipe
		player.actiontime = 0
		player.pflags = $&~(PF_SPINNING|PF_JUMPED)
		
		//Physics
		if not(P_IsObjectOnGround(mo))
			P_SetObjectMomZ(mo,FRACUNIT*5,false)
		end
		//Effects
		P_SpawnParaloop(mo.x,mo.y,mo.z,mo.scale*64,12,MT_DUST,ANGLE_90,nil,true)
		S_StartSound(mo,sfx_spdpad)
	end

	//Activate thrust
-- 	if thrusttrigger
-- 		B.PayRings(player)
-- 		//Tails can get as much as 4x cooldown for using flight dash after flying for a while
-- 		if mo.state == S_PLAY_FLY_TIRED
-- 			B.ApplyCooldown(player, cooldown_dash * 3)
-- 		else
-- 			B.ApplyCooldown(player, min(cooldown_dash * 3, max(cooldown_dash, (cooldown_dash * 5) - (player.exhaustmeter * 300/FRACUNIT))))
-- 		end
-- 		//Set state
-- 		player.powers[pw_tailsfly] = 0
-- 		player.pflags = ($|PF_JUMPED|PF_THOKKED)
-- 		player.actionstate = state_thrust
-- 		player.actiontime = 0
-- 		mo.state = S_PLAY_ROLL
-- 		//Physics
-- 		P_Thrust(mo,mo.angle,thrustfactor*thrustpower)
-- 		P_SetObjectMomZ(mo,FRACUNIT*3,false)
-- 		//Effects
-- 		local radius = mo.radius/FRACUNIT
-- 		local height = mo.height/FRACUNIT
-- 		local r1 = do
-- 			return P_RandomRange(-radius,radius)*FRACUNIT
-- 		end
-- 		local r2 = do
-- 			return P_RandomRange(0,height)*FRACUNIT
-- 		end
-- 		for n = 1,16
-- 			P_SpawnMobjFromMobj(mo,r1(),r1(),r2(),MT_DUST)
-- 		end
-- 		S_StartSound(mo,sfx_zoom)
-- 	end
	
	//Activate throw
	if throwtrigger 
		B.PayRings(player)
		B.ApplyCooldown(player,cooldown_throw)
		//Set state
		player.powers[pw_tailsfly] = 0
		player.pflags = ($|PF_JUMPED|PF_THOKKED)
		player.actionstate = state_thrust
		player.actiontime = 0
		mo.state = S_PLAY_ROLL
	
		//Throw Partner
		for otherplayer in players.iterate do
-- 			print(otherplayer.mo.tracer)
-- 			print(otherplayer.powers[pw_carry])
			if not(
				otherplayer.mo and otherplayer.mo.valid
				and otherplayer.mo.tracer == mo
				and otherplayer.powers[pw_carry] == CR_PLAYER
			)
				continue
			end
			local partner = otherplayer.mo
			partner.tracer = nil
			otherplayer.powers[pw_carry] = 0
			partner.state = S_PLAY_ROLL
			otherplayer.pflags = $|PF_SPINNING|PF_THOKKED
			P_InstaThrust(partner,mo.angle,thrustfactor*throw_strength)
			partner.momx = $ + mo.momx/2
			partner.momy = $ + mo.momy/2
			partner.momz = throw_lift*mo.scale*P_MobjFlip(mo) + mo.momz/2
		end
-- 		//Free carry ID
-- 		player.carry_id = nil
		
		//Physics
		if not(P_IsObjectOnGround(mo))
			P_SetObjectMomZ(mo,FRACUNIT*5,false)
		end
		//Effects
		P_SpawnParaloop(mo.x,mo.y,mo.z,mo.scale*64,12,MT_DUST,ANGLE_90,nil,true)
		S_StartSound(mo,sfx_spdpad)
	end
	
	//Swipe state
	if player.actionstate == state_swipe
		player.actiontime = $+1
		if P_IsObjectOnGround(mo)
			player.lockaim = true
		end
		player.lockmove = true
-- 		player.powers[pw_nocontrol] = $|2
		//Anim states
		if player.actiontime < 4
			//Fast Spin anim
			player.drawangle = mo.angle-ANGLE_90*(player.actiontime-4)
			dodust(mo)
		elseif player.actiontime < 12
			//Medium Spin anim
			player.drawangle = mo.angle-ANGLE_45*(player.actiontime-4)
			dodust(mo)
		else
			//Teeter anim
			player.drawangle = mo.angle-ANGLE_45/2*(player.actiontime-4)
			mo.state = S_PLAY_EDGE
			mo.frame = 0
			mo.tics = 0
		end
		//Reset to neutral
		if player.actiontime >= 22
			player.actionstate = 0
			player.drawangle = mo.angle
			mo.state = S_PLAY_WALK
			mo.frame = 0
		end
	end
	//Thrust state
	if player.actionstate == state_thrust
-- 		P_SetMobjStateNF(player.followmobj,S_NULL)
-- 		B.DrawSVSprite(player,1)
		player.actiontime = $+1
		player.drawangle = mo.angle-ANG60*player.actiontime
		P_SpawnGhostMobj(mo)
		local radius = mo.radius/FRACUNIT
		local height = mo.height/FRACUNIT
		local r1 = do
			return P_RandomRange(-radius,radius)*FRACUNIT
		end
		local r2 = do
			return P_RandomRange(0,height)*FRACUNIT
		end
		local s = P_SpawnMobjFromMobj(mo,r1(),r1(),r2(),MT_SPARK)
		s.colorized = true
		s.color = SKINCOLOR_WHITE
		s.scale = $/3
		s.momx = mo.momx/2
		s.momy = mo.momy/2
		s.momz = mo.momz/2
		s.flags2 = $|MF2_SHADOW
		//Reset to neutral
		if P_IsObjectOnGround(mo) then
			player.actionstate = 0
			player.drawangle = mo.angle
			mo.state = S_PLAY_WALK
			mo.frame = 0
		end
	end
end