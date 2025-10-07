return function(p)
	p.dashmode = 0

	if p.heist:hasSign() then
		p.heist.corrected_speed = false
		p.normalspeed = min(FH_NERFSPEED, $)
		p.jumpfactor = max(FU, $) -- makes characters like knux jump higher, while others like amy still have their bigger jump height
	else
		if not p.heist.exiting then
			p.camerascale = ease.linear(FU/3, $, tofixed("1"))
		end
		if not p.heist.corrected_speed then
			p.heist.corrected_speed = true
			p.normalspeed = skins[p.skin].normalspeed
			p.jumpfactor = skins[p.skin].jumpfactor
		end
	end
end