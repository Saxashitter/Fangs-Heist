local gamemode = {}

local spawnpos = FangsHeist.require "Modules/Libraries/spawnpos"

function gamemode:initSignPosition()
	local signpost_pos

	for thing in mapthings.iterate do
		if self.signThings[thing.type] then
			if thing and thing.mobj and thing.mobj.valid then
				P_RemoveMobj(thing.mobj)
			end

			local x = thing.x*FU
			local y = thing.y*FU
			local z = spawnpos.getThingSpawnHeight(MT_FH_SIGN, thing, x, y)
			local a = FixedAngle(thing.angle*FU)

			signpost_pos = {x, y, z, a}
			break
		end
	end

	if not (signpost_pos) then return false end

	FangsHeist.Net.signpos = signpost_pos
	return signpost_pos
end

function gamemode:getSignSpawn()
	local pos = FangsHeist.Net.signpos

	if FangsHeist.Net.round_2
	and FangsHeist.Net.escape then
		local pos2 = FangsHeist.Net.round_2_teleport.pos

		local count = 0
		local secondCount = 0

		for p in players.iterate do
			if not (p.heist and p.heist:isAlive() and not p.heist.exiting) then continue end

			count = $+1
			if p.heist.reached_second then
				secondCount = $+1
			end
		end

		if secondCount >= count/2 then
			return pos2
		end
	end

	return pos
end

function gamemode:spawnSign()
	local pos = self:getSignSpawn()

	FangsHeist.Net.sign = FangsHeist.Carriables:new("Sign", pos[1], pos[2], pos[3], pos[4])
end

function gamemode:respawnSign()
	return FangsHeist.respawnSign(self:getSignSpawn())
end

function gamemode:manageSign()
	--[[if not (FangsHeist.Net.sign
		and FangsHeist.Net.sign.valid) then
			self:spawnSign()
	end]]
end

return gamemode