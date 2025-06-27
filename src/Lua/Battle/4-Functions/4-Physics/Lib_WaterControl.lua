local B = CBW_Battle

B.WaterFactor = function(mo)
	if mo.eflags&MFE_UNDERWATER then return 2 end
	return 1
end

B.UnderwaterMissile = function(mo)
	//Set underwater physics
	if mobjinfo[mo.type].donotwaterslow return end
	if mo.eflags&MFE_UNDERWATER and not(mo.waterslow) then
		mo.waterslow = true
		P_InstaThrust(mo,R_PointToAngle2(0,0,mo.momx,mo.momy),FixedHypot(mo.momx,mo.momy)/2)
		mo.momz = $/2
		if not(mo.staticfuse) then
			mo.fuse = $*2
		end
	end
	//Cancel underwater slowdown
	if not(mo.eflags&MFE_UNDERWATER) and(mo.waterslow) then
		mo.waterslow = false
		P_InstaThrust(mo,R_PointToAngle2(0,0,mo.momx,mo.momy),FixedHypot(mo.momx,mo.momy)*2)
		mo.momz = $*2
		if not(mo.staticfuse) and mo.fuse > 2 then
			mo.fuse = $/2
		end
	end
end

