local ENABLED = false
local DC

addHook("PlayerThink", function(p)
	if not ENABLED then return end

	if not FangsHeist.isMode() then return end
	if not (p.mo and p.mo.valid) then return end
	--if p.mo.skin ~= "bean" then return end
end)

local function loadSupport()
	if ENABLED then return end
	if not DeltaChars then return end

	DC = DeltaChars
	ENABLED = true

	local MobjIsDestructable = DC.MobjIsDestructable

	function DC.MobjIsDestructable(mo)
		if FangsHeist.isMode()
		and mo.type == MT_PLAYER then
			return false
		end

		return MobjIsDestructable(mo)
	end
end

loadSupport()
if ENABLED then return end

addHook("AddonLoaded", loadSupport)
