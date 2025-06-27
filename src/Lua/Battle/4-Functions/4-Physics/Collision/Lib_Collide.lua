local B = CBW_Battle
local CV = B.Console
local CP = B.ControlPoint

B.GetInteractionType = function(smo,tmo)
	-- 0 = No interaction. 1 = Bump. 3 = Full damage code
	-- 2 was supposed to be some sort of "half-damage" type interaction, but this was never completed. Currently unused.
	if not(smo and smo.valid and smo.health and tmo and tmo.valid and tmo.health)
		then 
		return 0 --Invalid interaction with missing or dead objects
	end
	if (smo.player and smo.player.spectator)
		or (tmo.player and tmo.player.spectator)
		then
		return 0 -- Interactions with spectators are invalid
	end
	if not(smo.player or tmo.player) then -- Two inanimate objects
		return 3
	end
	if not(smo.player and tmo.player) -- One of us is inanimate
		if not(smo.pushed and tmo.pushed) then return 1 end
		-- Determine team alliances
		local myteam = true
		if tmo.pushed.player and not(smo.pushed.player) then
			if tmo.target == nil then
				myteam = false
			else
				myteam = B.MyTeam(tmo.target.player,smo.player)
				if(myteam) then tmo.battle_atk = 0 myteam = false end
			end
		elseif smo.pushed.player and not(tmo.pushed.player) then
			if smo.target == nil then
				myteam = false
			else
				myteam = B.MyTeam(smo.target.player,tmo.player)
				if(myteam) then smo.battle_atk = 0 myteam = false end
			end
		end
		if myteam then
			return 1
		else
			return 3
		end
	end
	-- Collision FriendlyFire
	if CV.Collision.value and CV_FindVar("friendlyfire").value return 3 end
	-- Egg Robo Tag
	if gametype == GT_EGGROBOTAG return 1 end
	-- Battle gametype
	if B.BattleGametype() and not(B.MyTeam(smo.player,tmo.player)) then return 3 end
	-- Tag with collision
	if G_TagGametype() and CV.Collision.value return 1 end
	-- Ringslinger with collision
	if G_RingSlingerGametype() and CV.Collision.value and not(B.MyTeam(smo.player,tmo.player)) return 3 end
	-- Platforming with collision
	if CV.Collision.value return 1 end
	-- Default
	return 0
end

B.CheckHeightCollision = function(mo,othermo)
	if mo.z+mo.height < othermo.z then return false end
	if mo.z > othermo.z+othermo.height then return false end
	return true
end

B.GetCollideRelativeAngle = function(mo,collide,drawangle)
-- 	if not (mo and mo.valid and mo.health and collide and collide.valid and collide.health)
-- 		then return nil
-- 	end
	local collideangle
	if mo.player and drawangle then
		collideangle = mo.player.drawangle - R_PointToAngle2(mo.x-mo.momx,mo.y-mo.momy,collide.x-collide.momx,collide.y-collide.momy)
	else
		collideangle = mo.angle - R_PointToAngle2(mo.x-mo.momx,mo.y-mo.momy,collide.x-collide.momx,collide.y-collide.momy)
	end
	-- Pretty sure this is redundant
	if collideangle >= 180*ANG1 then
		collideangle = $- 360*ANG1
	elseif collideangle <= -180*ANG1 then
		collideangle = $+360*ANG1
	end
	return collideangle
end

B.GetZCollideAngle = function(mo,collide)
-- 	if not(mo and mo.valid and mo.health and collide and collide.valid and collide.health)
-- 		then
-- 		print("\x82 Error:\x80 An object in GetZCollideAngle() does not exist!")
-- 		return 0
-- 	end
	local x = mo.x - mo.momx
	local y = mo.y - mo.momy
	local z = mo.z+mo.height/2 - mo.momz
	local cx = collide.x - collide.momx
	local cy = collide.y - collide.momy
	local cz = collide.z+collide.height/2 - collide.momz
	local zdist = z-cz
	local xydist = FixedHypot(x-cx,y-cy)
	local collideangle = R_PointToAngle2(0,0,xydist,zdist)
	return collideangle
end

B.DoPlayerCollisionDamage = function(smo,tmo)
	local s = 1
	local t = 2
	local mo = {smo,tmo}
	local atk = {}
	local def = {}
	local bias = {}
	local power = {false,false}
	local tagit = {false,false}
	local invuln = {true,true} -- Default, for nonplayer objects
	for n = 1,2 do
		if mo[n].player then
			atk[n] = mo[n].player.battle_atk
			def[n] = mo[n].player.battle_def
		else
			atk[n] = mo[n].battle_atk
			def[n] = mo[n].battle_def
		end
		if atk[n] == nil then atk[n] = 0 end
		if def[n] == nil then def[n] = 0 end
	end
	
	
	bias[s] = def[s]-atk[t] --  0 == uncurl. -1 == take damage
	bias[t] = def[t]-atk[s]
	for n = 1,2 do
		if mo[n].player then
			power[n] = (mo[n].player.powers[pw_super] or mo[n].player.powers[pw_invulnerability])
			tagit[n] = (mo[n].player.pflags&PF_TAGIT)
			invuln[n] = (mo[n].player.powers[pw_flashing])
		elseif mo[n].sentient then
			invuln[n] = false
		end
	end
	local ssrc = smo
	local tsrc = tmo
	if not(smo.player) then ssrc = smo.target end
	if not(tmo.player) then tsrc = tmo.target end
	if power[s] and not(power[t] or invuln[t]) then
		P_DamageMobj(tmo,smo,ssrc,0)
		return 1
	elseif power[t] and not(power[s] or invuln[s]) then
		P_DamageMobj(smo,tmo,tsrc,0)
		return -1
	else
		local ret = 0
		if bias[s] < 0 and not(invuln[s] or power[s]) then
			P_DamageMobj(smo,tmo,tsrc,0)
			ret = -1
		end
		if bias[t] < 0 and not(invuln[t] or power[t]) then
			P_DamageMobj(tmo,smo,ssrc,0)
			if ret == -1
				ret = 2
			else
				ret = 1
			end
		end
		return ret
	end
	return 0
	--  0: nobody was hurt
	--  1: t was hurt by s
	-- -1: s was hurt by t
	--  2: both hurt
end

B.UpdateRecoilState = function(mo)
	if not(mo and mo.valid and mo.health and mo.player) then return nil -- Object invalid
	elseif mo.player.powers[pw_nocontrol] > 0 and mo.recoilangle != nil and mo.recoilthrust != nil then
		if P_PlayerInPain(mo.player) then
			mo.recoilangle = nil
			mo.recoilthrust = nil
			return false
		end
		if P_IsObjectOnGround(mo) then -- Grounded
			if not(mo.player.charability == CA_GLIDEANDCLIMB) then
				mo.state = S_PLAY_SKID
				mo.player.panim = 0
				mo.frame = 0
			else
				mo.state = S_PLAY_GLIDE_LANDING
				mo.player.powers[pw_nocontrol] = $-1
			end
			if mo.player.skidtime == 0 and mo.recoilthrust > mo.scale*5 then
				S_StartSound(mo, sfx_skid)
			end
			mo.player.powers[pw_nocontrol] = min($,TICRATE)
			mo.player.skidtime = mo.player.powers[pw_nocontrol]
			-- Apply recoil thrust
			P_InstaThrust(mo,mo.recoilangle,mo.recoilthrust)
			-- Add friction
			mo.recoilthrust = ($+FixedMul($,FixedMul(mo.friction,mo.movefactor)))/2
		else -- Aerial
			-- Keep our variables up with current trajectory
			mo.recoilthrust = FixedHypot(mo.momx,mo.momy)
			mo.recoilangle = R_PointToAngle2(0,0,mo.momx,mo.momy)
			mo.player.panim = PA_FALL
			mo.state = S_PLAY_FALL
		end
		mo.player.drawangle = mo.recoilangle+ANGLE_180
		return true
	else -- Not in disadvantage state, reset variables
		mo.recoilangle = nil
		mo.recoilthrust = nil
		return false
	end
end

B.PlayerTouch = function(smo,tmo)
	if not(smo and smo.valid and tmo and tmo.valid and smo.player and tmo.player)
	or not(smo.health and tmo.health)
	or (smo.player.exiting or tmo.player.exiting)
	or (smo.player.battlespawning or tmo.player.battlespawning)
	or B.PreRoundWait()
		return true -- Avoid collisions with invalid, dead, spawning or exiting players
	end
	if not(B.GetInteractionType(smo,tmo))
		B.TailsCatchPlayer(smo.player,tmo.player)
		return true -- Disallow collisions with players on our team
	end 
	
	 -- Register "pushed" instance; will be read by B.DoPlayerInteract()
	smo.pushed = tmo
	tmo.pushed = smo
	-- Disallow multiple collisions per frame
	smo.flags = $&~MF_SPECIAL
	tmo.flags = $&~MF_SPECIAL
	-- Prevent Tails from carrying enemies
	tmo.player.pflags = $&~PF_CANCARRY
	smo.player.pflags = $&~PF_CANCARRY
	return true
end

B.TouchSpecial = function(special,pmo)
	if B.PreRoundWait() then return true end -- in preround phase
	if pmo.player.battlespawning then return true end -- player is spawning
	if (pmo.player.revenge or pmo.player.isjettysyn) then return true end -- player is jettysyn
end

B.UpdateCollisionHistory = function(pmo)
	-- Needs comments
	-- Initialize
	if pmo.pushtics == nil then pmo.pushtics = 0 end
	-- If we've recently been pushed
	if pmo.pushed or pmo.pushed_last then
		-- Update the timer
		if pmo.pushtics == 0 then
			pmo.pushtics = 1
		else
			pmo.pushtics = $+1
			-- After a certain time, clean the slate
			if pmo.pushtics > 12 then
				pmo.pushed_last = nil
				pmo.pushed = nil
				pmo.pushtics = 0
			end
		end
	else
		-- No pusher, no need for pushtics
		if pmo.pushtics then
			pmo.pushtics = 0 -- !! If this is reset just off of pushed being nil, and pushed is reset per frame, then when is this not 1 or 0??
		end
	end
	-- Update other player object's pushed stats
	if pmo.pushed and pmo.pushed.valid and pmo.pushed.pushed == pmo and not(pmo.pushtics) then
		pmo.pushed.flags = $|MF_SPECIAL
		pmo.pushed.pushed_last = pmo
		pmo.pushed.pushed = nil
	end
	pmo.flags = $|MF_SPECIAL -- Reallow collisions
	if pmo.pushed then
		pmo.pushed_last = pmo.pushed -- History
		pmo.pushed = nil -- Done with this
	end
	local player = pmo.player
	if player.pushed_creditplr != nil
		if player.pushed_creditplr.valid and P_IsObjectOnGround(pmo) and not(player.powers[pw_nocontrol] or player.powers[pw_flashing]) then
			player.pushed_creditplr = nil
		end
	end
end