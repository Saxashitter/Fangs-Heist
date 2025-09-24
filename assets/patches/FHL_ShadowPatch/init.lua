-- Intended to patch Shadow by Inazuma.

local loaded = false

local function loadMod()
	if loaded then return end
	if not FangsHeist then return end

	loaded = true

	addHook("PlayerThink", function(p)
		if not FangsHeist then return end
		if not FangsHeist.isMode() then return end
		if not p.heist then return end
		if not p.heist:isAlive() then return end
		if not p.heist:hasSign() then return end
	
		-- TODO: extend into external addon
		-- and clean up too
		if p.mo.skin == "shadow"
		and p.shadow
		and p.shadow.flags & SHF_WARPING
		and p.shadow.warptype then
			local momz = p.mo.momz * P_MobjFlip(p.mo)
			if p.shadow.warptype == 1 then
				if momz < -8*p.mo.scale then
					P_SetObjectMomZ(p.mo, -8*p.mo.scale)
				end
			elseif p.shadow.warptype == 2 then
				if p.speed >= 30*FU then
					P_InstaThrust(p.mo, R_PointToAngle2(0,0,p.mo.momx,p.mo.momy), 30*FU)
				end
			elseif p.shadow.warptype == 3 then
				if momz > 8*p.mo.scale then
					P_SetObjectMomZ(p.mo, 8*p.mo.scale)
				end
			end
		end
	end)

	local function isTeamLeaderSkin(team, skin, notMostImportant)
		if not (team and team[1] and team[1].valid and team[1].mo) then
			if not notMostImportant then
				return true
			end

			return false
		end

		return team[1].mo.skin == skin
	end

	local function isSpecial(team1, team2)
		return isTeamLeaderSkin(team2, "shadow", false)
		and isTeamLeaderSkin(team1, "sonic", true)
	end

	FangsHeist.addHook("2TeamsLeft", function(team1, team2)
		if isSpecial(team1, team2) or isSpecial(team2, team1) then
			return "FH_SVS"
		end
	end)
end

loadMod()

if not loaded then
	addHook("AddonLoaded", loadMod)
end