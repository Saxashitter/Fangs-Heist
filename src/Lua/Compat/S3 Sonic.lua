addHook("PlayerThink", function(p)
	if not FangsHeist.isMode() then return end
	if not (p.mo and p.mo.valid) then return end
	if p.mo.skin ~= "s3sonic" then return end

	if FangsHeist.playerHasSign(p) then
		-- S3 Sonic's momentum allows him to bypass the speed limit.
		-- Oh no you don't! Cap his speed, ALWAYS!
		local speed = FixedHypot(p.rmomx, p.rmomy)
		local maxspeed = 24*p.mo.scale

		if speed > maxspeed then
			local angle = R_PointToAngle2(0,0, p.rmomx, p.rmomy)

			local x = P_ReturnThrustX(p.mo, angle, maxspeed)
			local y = P_ReturnThrustY(p.mo, angle, maxspeed)

			p.mo.momx = p.cmomx+x
			p.mo.momy = p.cmomy+y

			p.rmomx = x
			p.rmomy = y
		end
	end
end)