/*
	Ring-Up powerup.
	Grants rings to the holder over an extended period of time.
*/
local PR = CBW_PowerCards
local ring_rate = 12
local ring_fuse = TICRATE*5

PR.RingUpHoldFunc = function(mo,player)
	if mo.health > 1
		mo.health = $-1
		if mo.health%ring_rate == 0
			local ring = P_SpawnMobjFromMobj(player.mo,0,0,0,MT_FLINGRING)
			if ring and ring.valid
				ring.scale = mo.destscale
				ring.flags = ($|MF_BOUNCE)&~MF_NOGRAVITY
				ring.fuse = ring_fuse
				P_InstaThrust(ring,FixedAngle(P_RandomRange(0,359)<<FRACBITS),P_RandomRange(1,10)*ring.scale)
				CBW_Battle.ZLaunch(ring,P_RandomRange(5,10)*FRACUNIT,false)
			end
		end
	else
		PR.DiscardDeath(mo,player)
		return true
	end
end

PR.RingUpIdleFunc = function(mo,player)
	if not(mo.dropped) return end
	if mo.health > 1
		mo.health = $-1
		mo.fuse = mo.health
		if mo.health%ring_rate == 0
			local ring = P_SpawnMobjFromMobj(mo,0,0,0,MT_FLINGRING)
			if ring and ring.valid
				ring.scale = mo.destscale
				ring.flags = ($|MF_BOUNCE)&~MF_NOGRAVITY
				ring.fuse = ring_fuse
				P_InstaThrust(ring,FixedAngle(P_RandomRange(0,359)<<FRACBITS),P_RandomRange(1,10)*ring.scale)
				CBW_Battle.ZLaunch(ring,P_RandomRange(5,10)*FRACUNIT,false)
			end
		end	
	else
		PR.DiscardDeath(mo,player)
		return true
	end
end

