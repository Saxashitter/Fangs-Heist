local B = CBW_Battle

local maxsentries = 2
local fist_stanceangle = ANGLE_45
local followheight = -FRACUNIT*16

B.Action.Sentry=function(mo,doaction)
	mo.player.actionstate = 0
	if mo.player.sentrycount == nil then
		mo.player.sentrycount = 0
		mo.player.sentrycountlast = 0
	end
-- 	//Run checks
-- 	if P_PlayerInPain(mo.player) or not(B.CanDoAction(mo.player)) then
-- 		mo.player.sentrycount = 0
-- 		return
-- 	end
	
	//Action Info
	if mo.player.sentrycount then
		mo.player.actiontext = "Attack"
		mo.player.actionrings = 0
	end
	mo.player.action2text = "Sentry "..mo.player.sentrycount.."/"..maxsentries
	mo.player.action2rings = 10
-- 	mo.player.actiontime = max(0,$-1)
	local spawnsentry = 0
	local firesentry = 0
	if mo.player.sentrycount// and throwring == 1 
	and not(mo.player.actioncooldown) then
		firesentry = 1
	end
	//Spawn Sentry
	if mo.player.sentrycount < maxsentries then //Below spawn limit
		local sentry = P_SpawnMobj(mo.x,mo.y,mo.z,MT_BUZZBUDDY)
		if sentry and sentry.valid then
			print('make')
			sentry.target = mo
			sentry.scale = $/2
			sentry.ctfteam = mo.player.ctfteam
			sentry.followdist = 64*mo.scale
			mo.player.actioncooldown = TICRATE/2
-- 				S_StartSound(sentry,sfx_s3kb8)
-- 				for l = 0,7
-- 					P_SpawnParaloop(mo.x,mo.y,mo.z+mo.height/2,128*mo.scale,16,MT_NIGHTSPARKLE,mo.angle+45*l*ANG1,nil,1)
-- 				end
		end
	end
	//Command Sentry to Attack
	if firesentry and B.PlayerButtonPressed(mo.player,BT_SPIN,false) then
		if mo.player.sentrycount > 0 then
			mo.player.actionstate = 1
		else
			mo.player.spendrings = -1
		end
	end
	mo.player.sentrycountlast = mo.player.sentrycount
	mo.player.sentrycount = 0
end

B.BuzzBuddyThinker=function(mo)
	if not(mo.health) then return end
	if mo.attacking == nil then
		mo.attacking = false
		mo.collision = true
	end
	//Do color
	if mo.target then
		mo.color = mo.target.color
		if mo.target.player and mo.target.player.sentrycount != nil then
			mo.target.player.sentrycount = $+1
		end
	end
	if mo.fuse and mo.target then
		mo.color = P_RandomRange(1,60)
	end
	
	//Air Drag
	local spd = FixedHypot(mo.momx,mo.momy)
	local dir = R_PointToAngle2(0,0,mo.momx,mo.momy)
-- 	P_Thrust(mo,dir,min(spd,mo.scale))
	if mo.target and mo.target.flags2&MF2_OBJECTFLIP then
		mo.flags2 = $|MF2_OBJECTFLIP
	else
		mo.flags2 = $&~MF2_OBJECTFLIP
	end
	if mo.target and mo.target.valid and mo.target.health and mo.target.player and B.SkinVars['eggman'].special == B.Action.Sentry then
		//Initiate attack
		if mo.target.player.actionstate == 1 and not(mo.tracer or mo.fuse) then
			mo.target.player.actionstate = 0
			//Autoaim targeting
			if mo.target.player.autoaim then
				local near = B.GetNearestPlayer(mo.target,90,-1)
				if not(near) then
					near = B.SearchObject(mo.target,mo.target.angle,90,640*FRACUNIT,MF_ENEMY|MF_BOSS|MF_MONITOR,mo,-1)
				else
					near = near.mo
				end
				if near and near.valid then
					mo.tracer = near
					mo.fuse = 20
					S_StartSound(mo,sfx_s3kc5s)
					mo.attacking = true
					mo.collision = true
					mo.flags = $&~MF_NOCLIP
				return end
			//Manual targeting
			end
			mo.tracer = mo.target
			mo.fuse = 20
			S_StartSound(mo,sfx_s3kc5s)
			mo.attacking = true
			mo.collision = true
			mo.flags = $&~MF_NOCLIP
			return
		end

		if mo.followdist == nil then
			mo.followdist = 64*mo.target.scale
		end

		//Follow offset
		local x = mo.target.x
		local y = mo.target.y
		
		//Do formations
		if mo.target.player.sentrycountlast == 1 then //Single formation
			x = $+P_ReturnThrustX(mo.target,mo.target.angle,mo.followdist)
			y = $+P_ReturnThrustY(mo.target,mo.target.angle,mo.followdist)
		elseif mo.target.player.sentrycountlast == maxsentries then //Double formation
			if mo.target.player.sentrycount == 1 then
				x = $+P_ReturnThrustX(mo.target,mo.target.angle+fist_stanceangle,mo.followdist)
				y = $+P_ReturnThrustY(mo.target,mo.target.angle+fist_stanceangle,mo.followdist)
			elseif mo.target.player.sentrycount == 2 then
				x = $+P_ReturnThrustX(mo.target,mo.target.angle-fist_stanceangle,mo.followdist)
				y = $+P_ReturnThrustY(mo.target,mo.target.angle-fist_stanceangle,mo.followdist)
			end
-- 		elseif mo.target.player.sentrycountlast == maxsentries then //Triple formation
-- 			if mo.target.player.sentrycount == 1 then
-- 				x = $+P_ReturnThrustX(mo.target,mo.target.angle+ANGLE_180,mo.followdist)
-- 				y = $+P_ReturnThrustY(mo.target,mo.target.angle+ANGLE_180,mo.followdist)
-- 			elseif mo.target.player.sentrycount == 2 then
-- 				x = $+P_ReturnThrustX(mo.target,mo.target.angle+ANGLE_135,mo.followdist)
-- 				y = $+P_ReturnThrustY(mo.target,mo.target.angle+ANGLE_135,mo.followdist)
-- 			elseif mo.target.player.sentrycount == 3 then
-- 				x = $+P_ReturnThrustX(mo.target,mo.target.angle-ANGLE_135,mo.followdist)
-- 				y = $+P_ReturnThrustY(mo.target,mo.target.angle-ANGLE_135,mo.followdist)
-- 			end
		end
	
		local dist = R_PointToDist2(mo.x,mo.y,x,y)
		local angle = R_PointToAngle2(mo.x,mo.y,x,y)
-- 		local angle = mo.target.angle
		local zdist = (mo.target.z+mo.target.height)/2+FixedMul(mo.scale,followheight)*P_MobjFlip(mo) - (mo.z+mo.height)/2
		local water = B.WaterFactor(mo)
		if not(mo.fuse) then
			//Follow
			local clipdist = mo.target.scale*256
			if dist > clipdist then
				mo.flags = $|MF_NOCLIP 
			else
				mo.flags = $&~MF_NOCLIP
			end
			if dist < clipdist or P_CheckSight(mo,mo.target) then
				P_InstaThrust(mo,angle,max(0,(dist)/8))
				if abs(zdist) > 4*mo.scale
					mo.momz = max(min(8*mo.scale/water,$+zdist/16/water),-8*mo.scale/water)
				end
				mo.angle = mo.target.angle
			else //Warp
				P_TeleportMove(mo,mo.target.x,mo.target.y,mo.target.z+mo.target.height/2)
			end
			
		//Attack ready; V-Align to tracer
		elseif mo.tracer and mo.tracer.valid then
			//Auto target
			if mo.tracer != mo.target
				mo.angle = R_PointToAngle2(mo.x,mo.y,mo.tracer.x,mo.tracer.y)
			//Manual target
			else
				mo.angle = R_PointToAngle2(mo.x,mo.y,mo.tracer.x+P_ReturnThrustX(mo.tracer,mo.tracer.angle,mo.tracer.scale*1280),mo.tracer.y+P_ReturnThrustY(mo.tracer,mo.tracer.angle,mo.tracer.scale*1280))
			end
			mo.momz = (mo.tracer.z-mo.z)/8/water
			P_InstaThrust(mo,R_PointToAngle2(0,0,mo.momx,mo.momy),FixedHypot(mo.momx,mo.momy)/10*9)
		end
		//Smoketrail
		if mo.attacking and not(mo.fuse&3) then
			local x = mo.x+P_ReturnThrustX(nil,mo.angle+180,mo.scale*3)
			local y = mo.y+P_ReturnThrustY(nil,mo.angle+180,mo.scale*3)
			P_SpawnMobj(x,y,mo.z+mo.height,MT_SPINDUST)
		end
		//Stunned
		if mo.attacking and not(mo.collision) then
			mo.angle = $+ANG30
		end
	elseif (mo.flags&MF_SPECIAL)
		then
		//Self-destruct timer
		mo.fuse = TICRATE
		mo.flags = $&~(MF_SPECIAL|MF_ENEMY|MF_NOGRAVITY)
		mo.attacking = false
		mo.collision = false
		mo.momz = 0
		mo.momx = 0
		mo.momy = 0		
	end
end

B.BuzzBuddyFuse=function(mo)
	//Kill object if no owner
-- 	if not(mo.flags&MF_SPECIAL) then
-- 		print('!')
-- 		P_KillMobj(mo)
-- 		return true
-- 	end
	//Thrust toward target
	if mo.tracer and mo.tracer.valid then
		mo.collision = true
		local water = B.WaterFactor(mo)
		P_InstaThrust(mo,mo.angle,mo.scale*60/water)
		mo.fuse = TICRATE*water
		mo.tracer = nil
		P_SetObjectMomZ(mo,FRACUNIT/water)
		S_StartSound(mo,sfx_zoom)
	else //Reset state
		mo.collision = true
		mo.attacking = false
	end
	
	return true
end

B.BuzzBuddyTouch=function(buzzmo,othermo)
	//Not a valid target
	if not(buzzmo.target and buzzmo.target.valid) then return end
	//Enemy or opposing player
	if not(buzzmo.target.player) or not(othermo.player) or B.MyTeam(othermo.player,buzzmo.target.player) == false then 
		//non-player enemies
		if not(othermo.player)
			if buzzmo.collision then
				P_DamageMobj(othermo,buzzmo,buzzmo.target)
				return true
			else
				return false
			end
		end
		//Neither buzz nor player are in attack frames
		if not(buzzmo.attacking) and B.PlayerCanBeDamaged(othermo.player) and not(othermo.player.battle_atk or othermo.player.battle_def)
			then
			P_DamageMobj(othermo,buzzmo,buzzmo.target)
			return true
		end
		//Buzz is attacking
		if buzzmo.attacking then
			//Buzz was just dazed, cannot damage or be damaged
			if not(buzzmo.collision) and buzzmo.fuse > TICRATE-5 then return true end
			local atk = othermo.player.battle_atk
			local def = othermo.player.battle_def
			local water = B.WaterFactor(buzzmo)
			//Enemy has superior attack
			if atk > 1 then return false end
			//Enemy has weaker attack but strong defense
			if def > 1 and buzzmo.collision then
				local thrust = FixedHypot(buzzmo.momx,buzzmo.momy)/2
				//Thrust enemy player
				P_Thrust(othermo,buzzmo.angle,thrust)
				//Thrust buzz
				buzzmo.collision = false
				buzzmo.fuse = TICRATE
				buzzmo.tracer = nil
				buzzmo.angle = $+P_RandomRange(90,270)*ANG1
				P_InstaThrust(buzzmo,buzzmo.angle,FRACUNIT*6/water)
				P_SetObjectMomZ(buzzmo,FRACUNIT*6/water,0)
				S_StartSound(mo,sfx_s3k7b)
				return true
			end
			//Enemy has 1 defense or attack
			if def|atk == 1 and buzzmo.collision then
				local thrust = FixedHypot(buzzmo.momx,buzzmo.momy)/2
				//Knockback player
				P_InstaThrust(othermo,buzzmo.angle,thrust)
				othermo.player.powers[pw_nocontrol] = max($,thrust*2)
				othermo.recoilthrust = thrust
				othermo.recoilangle = buzzmo.angle
				//Knockback buzz
				buzzmo.collision = false
				buzzmo.fuse = TICRATE
				buzzmo.tracer = nil
				buzzmo.angle = $+P_RandomRange(90,270)*ANG1
				P_InstaThrust(buzzmo,buzzmo.angle,FRACUNIT*6/water)
				P_SetObjectMomZ(buzzmo,FRACUNIT*6/water,0)
				S_StartSound(mo,sfx_s3k7b)
				return true
			end
			//Buzz cannot deal damage
			if not(buzzmo.collision) then return true end
			//Enemy has no defense
			P_DamageMobj(othermo,buzzmo,buzzmo.target) return true
		end
		//Do rest of code
		return
	end
	//Default (for friendly collisions)
	if othermo.player then othermo.player.homing = 0 end
	return true
end

B.BuzzBuddyDamage = function(buzzmo,inflictor,source)
	if buzzmo and buzzmo.valid and buzzmo.target and buzzmo.target.valid and buzzmo.target.player
		if source and source.valid and source.player
			if B.MyTeam(buzzmo.target.player,source.player)
				return false //Don't damage if a projectile is on our team
			else
				return true
			end
		elseif inflictor and inflictor.valid and inflictor.player	
			if B.MyTeam(buzzmo.target.player,inflictor.player)
				return false //Don't damage if inflictor is on our team
			else
				return true
			end
		end
	end
end

B.BuzzBuddyCollide = function(buzzmo,othermo)
	if not(buzzmo.valid and othermo.valid) then return end
	if buzzmo.z > othermo.z+othermo.height then return end
	if othermo.z > buzzmo.z+buzzmo.height then return end
	if not(othermo.flags&(MF_MONITOR|MF_ENEMY|MF_BOSS) and othermo.health) then return end
	B.BuzzBuddyTouch(buzzmo,othermo)
end

addHook("MobjFuse",function(mo) return B.BuzzBuddyFuse(mo) end,MT_BUZZBUDDY)
addHook("MobjMoveCollide",function(bmo,omo) B.BuzzBuddyCollide(bmo,omo) return false end,MT_BUZZBUDDY)
addHook("MobjThinker",function(mo) B.BuzzBuddyThinker(mo) end,MT_BUZZBUDDY)
addHook("ShouldDamage",function(mo,inflictor,source) return B.BuzzBuddyDamage(mo,inflictor,source) end,MT_BUZZBUDDY)
addHook("TouchSpecial",function(smo,pmo) return B.BuzzBuddyTouch(smo,pmo) end,MT_BUZZBUDDY)

-- addHook("MobjRemoved",function(mo)
-- 	print(mo.flags & MF_SPECIAL)
-- end, MT_BUZZBUDDY)