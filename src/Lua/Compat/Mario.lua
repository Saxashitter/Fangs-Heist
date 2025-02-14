addHook("PlayerThink", function(p)
	if not FangsHeist.isMode() then return end
	if not (p.mo and p.mo.valid) then return end
	if not (IsMario and IsMario(p.mo)) then return end

	if FangsHeist.playerHasSign(p) then
		-- Safety check to make sure Mario isn't running 24/7
		p.runspeed = p.normalspeed*2

		-- No spinning for you, paisano!
		p.mariodidcircle = 0

		-- Force Mario to only do a singular jump with the sign
		p.mariotriple = 0

		-- Disable walljumping
		p.lastlinehit = -1
		p.lastsidehit = -1
		p.mariowallslide = 0
		p.mariolongbonk = 0

		-- Hmm... Maybe we should cap his speed too.
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