local B = CBW_Battle
B.MakeDeadJunk = function(mo, mask)
	local junk = P_SpawnMobjFromMobj(mo,0,0,0,MT_BATTLEJUNK)
	if mask == nil
		mask = mo
	end
	if junk and junk.valid
		//Inherit looks
		junk.sprite = mask.sprite
		junk.frame = mask.frame
		junk.color = mask.color
		//Inherit momentum
		junk.momx = mo.momx
		junk.momy = mo.momy
		junk.momz = mo.momz
		junk.renderflags = mo.renderflags
		//Random variance
		P_Thrust(junk, FixedAngle(P_RandomRange(0,360)<<FRACBITS), P_RandomRange(0,10)*mo.scale)
		P_SetObjectMomZ(junk, P_RandomRange(-10,10)*FRACUNIT, true)
	end
	P_RemoveMobj(mo)
	local junk
end