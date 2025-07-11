freeslot "spr_msud"
freeslot "S_X3UPDASH"
freeslot "sfx_msupds"
states[S_X3UPDASH] = {
	sprite = SPR_MSUD,
	frame = A|FF_ANIMATE|FF_FULLBRIGHT,
	var1 = 8,
	var2 = 1,
	tics = 9,
	nextstate = S_NULL
	}
//Some values to modify it!

//DRIFT TURN SPEED!
local DTS = ANG10

//MINIMUN SPEED FOR DRIFT!
local MINSPEED = FU * 15

//It's easy to comprehend.
local DASHMODETICS = 90

//Minimum speed for getting dash mode!
local MINDASHMODE = 26 * FU

//Drift speed loss over time! 
local DSLOT = FU / 8
local DSMAX = FU * 46

local DMBASESPEED = 36 * FU
local DMSPEEDUP = FU/8
local DMMAXSPEED = 46 * FU

local AIRDASHSPEED = 15 * FU

addHook("PlayerThink", function(p)
	if p.mo and p.mo.valid then
		p.dashmode = 0
		if not p.metalsonic then
			p.metalsonic = {dmt = 0, drift = false, drifthold = false, da = 0, speed = 0, dmspeed = DMBASESPEED, airdash = false, adp = 0, sspd = 0}
			end
		if p.speed > MINDASHMODE then
			p.metalsonic.dmt = $ + 1
		elseif P_IsObjectOnGround(p.mo) and not (p.pflags & PF_SPINNING) and not p.metalsonic.drifthold then
			p.mo.color = p.skincolor
			p.metalsonic.dmt = 0
			end
		if p.speed > MINSPEED and p.cmd.buttons & BT_SPIN and not (p.lastbuttons & BT_SPIN) and P_IsObjectOnGround(p.mo) and not p.metalsonic.drift then
			p.metalsonic.drift = true
			end
		if p.metalsonic.dmt > DASHMODETICS then
			p.metalsonic.dmspeed = min($ + DMSPEEDUP, DMMAXSPEED)
			p.normalspeed = p.metalsonic.dmspeed
			if p.mo.state == S_PLAY_RUN then
				p.mo.state = S_PLAY_DASH
				end
			if leveltime%4 < 2 then
				p.mo.color = skincolors[p.skincolor].invcolor
			else
				p.mo.color = p.skincolor + leveltime%2
				p.normalspeed = skins[p.mo.skin].normalspeed
				end
			end
		if p.metalsonic.airdash then
			p.metalsonic.adp = $ + 1
			if p.metalsonic.adp < 7 then
				p.mo.state = S_PLAY_SPINDASH
				p.mo.momx = 0
				p.mo.momy = 0
				p.mo.momz = (FU/2) * P_MobjFlip(p.mo)
				p.pflags = $&~PF_JUMPED&~PF_SPINNING
				end
			if p.metalsonic.adp == 7 then
				local dust = P_SpawnGhostMobj(p.mo)
				dust.fuse = 99999
				dust.state = S_X3UPDASH
				dust.scale = (FU * 2) + (FU/2)
				S_StartSound(p.mo, sfx_msupds)
				end
			if p.metalsonic.adp > 7 then
				p.mo.momz = (AIRDASHSPEED * P_MobjFlip(p.mo))
				p.mo.state = S_PLAY_SPRING
				end
			if p.metalsonic.adp > 24 or not (p.cmd.buttons & BT_SPIN) then
				p.metalsonic.airdash = false
				p.mo.state = S_PLAY_FALL
				p.mo.momz = $/3
				p.mo.momx = FixedMul(p.metalsonic.sspd, cos(p.drawangle))/(1 + (p.metalsonic.adp / 6))
				p.mo.momy = FixedMul(p.metalsonic.sspd, sin(p.drawangle))/(1 + (p.metalsonic.adp / 6))
				p.metalsonic.adp = 0
				end
			end
		if p.metalsonic.drift then
			if p.cmd.sidemove != 0 then
				if not p.metalsonic.drifthold then
					p.metalsonic.speed = p.speed
					p.metalsonic.da = p.drawangle
					p.metalsonic.drifthold = true
					end
				end
			if not (p.cmd.buttons & BT_SPIN) and p.metalsonic.drifthold or not P_IsObjectOnGround(p.mo) or p.speed < MINSPEED then
				p.mo.rollangle = 0
				p.pflags = $&~PF_SPINNING
				if P_IsObjectOnGround(p.mo) then
					p.mo.state = S_PLAY_WALK
				else
					if p.mo.state != S_PLAY_SPRING and p.mo.state != S_PLAY_ROLL then
						p.mo.state = S_PLAY_FALL
						end
					end
				p.metalsonic.drifthold = false
				p.metalsonic.drift = false
				p.metalsonic.speed = 0
				return
				end
			if p.cmd.sidemove > 0 then
				--left
				p.metalsonic.da = $ - max((DTS - (ANG1 * (p.speed/FU/10))), ANG2)
				p.mo.state = S_PLAY_SPINDASH
				p.mo.rollangle = 0 - ANGLE_22h
				p.drawangle = p.metalsonic.da - ANGLE_22h
				end
			if p.cmd.sidemove < 0 then
				--right 
				p.metalsonic.da = $ + max((DTS - (ANG1 * (p.speed/FU/10))), ANG2)
				p.mo.state = S_PLAY_SPINDASH
				p.mo.rollangle = ANGLE_22h
				p.drawangle = p.metalsonic.da + ANGLE_22h
				end
			if p.metalsonic.drifthold then
				p.mo.momx = FixedMul(p.metalsonic.speed, cos(p.metalsonic.da))
				p.mo.momy = FixedMul(p.metalsonic.speed, sin(p.metalsonic.da))
				p.metalsonic.speed = $ - (DSLOT/12)
				if p.metalsonic.speed > DSMAX then
					p.metalsonic.speed = $ - DSLOT
					end
				local dust = P_SpawnMobjFromMobj(p.mo, 0, 0, 0, MT_SPINDUST)
				dust.fuse = 5
				end
			end
		end
	end)
addHook("JumpSpinSpecial", function(p)
	if p.mo and p.mo.valid then
	if p.mo.skin != "metalsonic" then return end
	if p.pflags & PF_THOKKED then return end
	if p.mo.state == S_PLAY_PAIN or p.mo.state == S_PLAY_DEAD then return end
	if (p.lastbuttons & BT_SPIN) then return end
		p.metalsonic.airdash = true
		p.metalsonic.sspd = p.speed
		p.pflags = $|PF_THOKKED&~PF_SPINNING
		end
	end)
	
	
	
	
	
	
	
	
	
	
	
	
	