local PR = CBW_PowerCards

local DoParticleExplosion = function(player)
	local mo = player.mo
	local type = MT_BOXSPARKLE
-- 	local state = S_LHRT
	local width = FRACUNIT*256
	local z = mo.z+FixedMul(mo.height-mobjinfo[type].height,mo.scale>>2)
	P_SpawnParaloop(mo.x,mo.y,z,width,16,type,0,state,true)
	P_SpawnParaloop(mo.x,mo.y,z,width,16,type,ANGLE_22h,state,true)
	P_SpawnParaloop(mo.x,mo.y,z,width,16,type,ANGLE_45,state,true)
	P_SpawnParaloop(mo.x,mo.y,z,width,16,type,ANGLE_67h,state,true)
	P_SpawnParaloop(mo.x,mo.y,z,width,16,type,ANGLE_112h,state,true)
	P_SpawnParaloop(mo.x,mo.y,z,width,16,type,ANGLE_135,state,true)
	P_SpawnParaloop(mo.x,mo.y,z,width,16,type,ANGLE_157h,state,true)
end

PR.BlessingHoldFunc = function(mo,player)
	if mo.health > 1
		mo.health = $-1
		if mo.health%TICRATE == 0
			local ghost = P_SpawnGhostMobj(player.mo)
			ghost.state = S_LHRT
			ghost.scale = $<<2
			if PR.FirstPerson(player)
				ghost.flags2 = $|MF2_DONTDRAW
			end
		end
	else
		if not(player) return end
		if gametyperules & GTR_CAMPAIGN and player.bot -- Bots are not allowed to gain lives in SP.
			P_GivePlayerRings(player, 100)
		elseif not(player.isjettysyn) -- Revenge jettysyns will spawn back into the game immediately instead of gaining a stock.
			A_ExtraLife(mo)
		else
			CBW_Battle.Arena.Avenge(player)
		end
		DoParticleExplosion(player)
		//Destroy Item
		PR.RewardDeath(mo,player)
		return true
	end
end