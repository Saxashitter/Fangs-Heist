local module = {}

module.thokThinker = function(p)
	if p.charability ~= CA_THOK then return end
	if P_IsObjectOnGround(p.mo)
	or not (p.pflags & PF_JUMPED) then
		p.canairthok = false
		return
	end
	if not p.canairthok then return end

	if p.cmd.buttons & BT_SPIN
	and not (p.lastbuttons & BT_SPIN) then
		p.canairthok = false
		P_SetObjectMomZ(p.mo, 7*FU)
	end
end

module.onThok = function(p)
	p.canairthok = true
end

return module