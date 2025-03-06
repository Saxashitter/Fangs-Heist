addHook("PlayerThink", function(p)
	if not FangsHeist.isMode() then return end
	if not FangsHeist.isPlayerAlive(p) then return end
	if p.mo.skin ~= "eggman" then return end

	p.gotflagdebuff = FangsHeist.isPlayerNerfed(p)
end)