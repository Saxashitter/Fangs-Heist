addHook("PlayerThink", function(p)
	if not FangsHeist.isMode() then return end
	if not (p.heist and p.heist:isAlive()) then return end
	if p.mo.skin ~= "eggman" then return end

	p.gotflagdebuff = p.heist:isNerfed()
end)