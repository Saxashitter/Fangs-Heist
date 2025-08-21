return function(p)
	p.dashmode = 0

	-- skins probably shouldnt be here, but i got no reason to make a new file for it, considering its just a few lines
	if p.mo
	and p.mo.valid then
		if p.heist.alt_skin then
			p.mo.eflags = ($ & ~MFE_FORCENOSUPER)|MFE_FORCESUPER
		else
			p.mo.eflags = ($ & ~MFE_FORCESUPER)|MFE_FORCENOSUPER
		end
	end

	local spindash_limit = 45*FU
	if p.heist:isNerfed() then
		p.heist.corrected_speed = false
		p.climbing = 0
		p.normalspeed = min(FH_NERFSPEED, $)
		p.runspeed = 9999*FU
		p.mindash = min($, spindash_limit)
		p.maxdash = min($, spindash_limit)
		p.jumpfactor = max(FU, $) -- makes characters like knux jump higher, while others like amy still have their bigger jump height

		if not p.heist.exiting then
			p.camerascale = ease.linear(FU/3, $, tofixed("1.65"))
		end

		-- effect for running with the sign
		if p.mo
		and p.mo.health
		and P_IsObjectOnGround(p.mo)
		and p.speed > 17*p.mo.scale then
			-- dust

			local dust = P_SpawnMobjFromMobj(p.mo,
				P_RandomRange(-p.mo.radius/FU, p.mo.radius/FU)*FU,
				P_RandomRange(-p.mo.radius/FU, p.mo.radius/FU)*FU,
				0,
			MT_DUST)
		end
	else
		if not p.heist.exiting then
			p.camerascale = ease.linear(FU/3, $, tofixed("1"))
		end
		if not p.heist.corrected_speed then
			p.heist.corrected_speed = true
			p.normalspeed = skins[p.skin].normalspeed
			p.mindash = skins[p.skin].mindash
			p.maxdash = skins[p.skin].maxdash
			p.runspeed = skins[p.skin].runspeed
			p.jumpfactor = skins[p.skin].jumpfactor
		end
	end
end