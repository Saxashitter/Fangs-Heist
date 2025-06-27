addHook('MobjSpawn',function(mo)
	mo.fuse = P_RandomRange(TICRATE, TICRATE*2)
	mo.extravalue2 = P_RandomRange(-3,3)
end,MT_BATTLEJUNK)


addHook('MobjThinker',function(mo)
	mo.flags2 = $^^MF2_DONTDRAW
	if P_IsObjectOnGround(mo)
		mo.momz = mo.extravalue1
	end
	mo.extravalue1 = -mo.momz*3/4 //Store bounce strength
	mo.angle = $ + mo.extravalue2 * ANG20
end,MT_BATTLEJUNK)