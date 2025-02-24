addHook("PlayerThink", function(p)
	if not FangsHeist.isMode() then return end
	if not (p.mo and p.mo.valid) then return end
	if p.mo.skin ~= "bean" then return end

	if FangsHeist.isPlayerNerfed(p) then
		-- QUICK! Don't let him throw bombs!
		p.mo.bean_throwcooldown = 2
	end
end)