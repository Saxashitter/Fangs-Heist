local B = CBW_Battle

local specialstate = 1
local cooldown = TICRATE*7/4
local specialtime = 20
local specialendtime = 21
local instathrust = FRACUNIT*14
local thrust = FRACUNIT*3
local friction = FRACUNIT*10/10
local zfriction = FRACUNIT*9/10
local limit = FRACUNIT*36

B.Action.PikoSpin_Priority = function(player)
	if player.actionstate == specialstate
		B.SetPriority(player,2,2,nil,2,2,"piko spin technique")
	end
end

local function sparkle(mo)
	local spark = P_SpawnMobj(mo.x,mo.y,mo.z,MT_SPARK)
	if spark and spark.valid then
		B.AngleTeleport(spark,{mo.x,mo.y,mo.z},mo.player.drawangle,0,mo.scale*64)
	end
end

local function spinhammer(mo)
	mo.state = S_PLAY_MELEE_LANDING
	mo.frame = 0
	//mo.player.pflags = ($ | PF_JUMPED | PF_THOKKED) & ~PF_NOJUMPDAMAGE
	mo.sprite2 = SPR2_MLEL
end

local DoThrust = function(mo)
	local factor = 1
	if mo.player.thinkbuttons & (BT_JUMP|BT_SPIN) == BT_JUMP
		B.ZLaunch(mo, FRACUNIT+gravity, true)
		factor = 2
	elseif mo.player.thinkbuttons & (BT_JUMP|BT_SPIN) == BT_SPIN
		B.ZLaunch(mo, -FRACUNIT-gravity, true)
		factor = 2
	elseif not P_IsObjectOnGround(mo)
		B.ZLaunch(mo, gravity, true)
	end

	local xythrust = FixedMul(thrust, mo.player.thinkmovethrust)/factor
	P_Thrust(mo, mo.player.thinkmoveangle, xythrust)
	B.ControlThrust(mo,friction,limit/factor,zfriction,nil)
end

local function hammerjump(player,power)
	local h = power and 6 or 2
	local v = power and 13 or 10
		
	local mo = player.mo
	//P_DoJump(player,false)
	B.ZLaunch(mo,FRACUNIT*v,true)
	P_Thrust(mo,player.drawangle,h*mo.scale)
	S_StartSound(mo,sfx_cdfm37)
	S_StartSoundAtVolume(mo,sfx_s3ka0,power and 255 or 100)
	player.pflags = ($ | PF_JUMPED | PF_STARTJUMP) & ~(PF_NOJUMPDAMAGE | PF_THOKKED)
	mo.state = S_PLAY_ROLL
	player.panim = PA_ROLL
end

B.Action.PikoSpin = function(mo,doaction)
	local player = mo.player
	if P_PlayerInPain(player) then
		player.actionstate = 0
		player.actiontime = 0
	end
	if not(B.CanDoAction(player)) and not(player.actionstate) 
		if player.actiontime and mo.state == S_PLAY_MELEE_FINISH
			if mo.tics == -1
				mo.tics = 15
			else
				mo.tics = min($,15)
			end
			player.actiontime = 0
		end
		return
	end
	player.actiontime = $+1
	//Action Info
	player.actiontext = "Piko Spin"
	player.actionrings = 5
	
	//Neutral
	if player.actionstate == 0
		//Trigger
		if (doaction == 1) then
			B.PayRings(player)
			B.ApplyCooldown(player,cooldown)
			player.actionstate = specialstate
			player.actiontime = 0
			player.pflags = $ | PF_THOKKED
			mo.momz = $ / 2
			if player.thinkmovethrust
				P_InstaThrust(mo, player.thinkmoveangle, instathrust)
			end
			DoThrust(mo)
			S_StartSoundAtVolume(mo,sfx_3db16,130)
			S_StartSound(mo,sfx_s3ka0)
		end
	
	//Special
	elseif player.actionstate == specialstate then
		player.reflectarmor = max($, 4)
		player.charability2 = CA2_MELEE
		player.powers[pw_nocontrol] = max($,2)
		sparkle(mo)
		player.drawangle = player.cmd.angleturn<<FRACBITS+ANGLE_45*(player.actiontime&7)
		DoThrust(mo)
		if player.actiontime&7 == 4 then
			S_StartSound(mo,sfx_s3k42)
		end
		if not(player.actiontime > specialtime)
			spinhammer(mo)
			return
		end
		player.actionstate = $ + 1
		player.actiontime = 0
		player.drawangle = mo.angle
		B.ZLaunch(mo, FRACUNIT*3, true)
		mo.momx = $ * 2/3
		mo.momy = $ * 2/3
		player.melee_state = st_release
		mo.state = S_PLAY_MELEE
		S_StartSound(mo,sfx_s3k52)
	
	//End lag
	elseif player.actionstate == specialstate+1 
		//player.powers[pw_nocontrol] = max($,2)
		if player.actiontime >= specialendtime and not (player.cmd.buttons&BT_JUMP)
			mo.state = S_PLAY_FALL
			player.actionstate = 0
			player.actiontime = 0
			return
		end
		if P_IsObjectOnGround(mo)
			if player.cmd.buttons&BT_JUMP
				hammerjump(player,true)
			end
			player.actionstate = 0
			player.actiontime = 0
			return
		end
	end
end