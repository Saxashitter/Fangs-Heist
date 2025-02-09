return function(p)
	p.dashmode = 0

	local spindash_limit = 45*FU
	if FangsHeist.playerHasSign(p) then
		p.heist.corrected_speed = false
		p.normalspeed = min(24*FU, $)
		p.runspeed = min(16*FU, $)
		p.mindash = min($, spindash_limit)
		p.maxdash = min($, spindash_limit)
		p.jumpfactor = max(FU, $) -- makes characters like knux jump higher, while others like amy still have their bigger jump height
	elseif not p.heist.corrected_speed then
		p.heist.corrected_speed = true
		p.normalspeed = skins[p.skin].normalspeed
		p.mindash = skins[p.skin].mindash
		p.maxdash = skins[p.skin].maxdash
		p.runspeed = skins[p.skin].runspeed
		p.jumpfactor = skins[p.skin].jumpfactor
	end
end