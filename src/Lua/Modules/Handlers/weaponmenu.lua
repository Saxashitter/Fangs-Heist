local weaponnames = {
	"redring",
	"railring"
}

return function(p)
	if not p.heist.weapon_hud then return end

	if p.heist.buttons & BT_SPIN then
		p.heist.weapon_hud = false
		return
	end

	if p.heist.buttons & BT_JUMP then
		p.heist.weapon_hud = false
		FangsHeist.giveWeapon(p, weaponnames[p.heist.weapon_selected])
		return
	end

	if p.heist.sidemove <= -25 then
		p.heist.weapon_selected = 1
	end
	if p.heist.sidemove >= 25 then
		p.heist.weapon_selected = 2
	end
end