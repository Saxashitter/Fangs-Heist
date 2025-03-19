local scripts = {
	playerthink = {},
	thinkframe = {}
}

local type = "playerthink"
local function add(file)
	local result = dofile("Hooks/Player/Scripts/"..file)

	if result then
		table.insert(scripts[type], result)
	end
end

addHook("PlayerThink", function(p)
	-- Force every PlayerThink hook to run before our code here.
	for _,data in ipairs(FangsHeist._HOOKS.PlayerThink) do
		data.func(p)
	end

	if not FangsHeist.isMode() then return end
	if not (p and p.valid) then return end

	local gamemode = FangsHeist.getGamemode()

	if not (p and p.heist) then
		FangsHeist.initPlayer(p)
	end

	for _,script in ipairs(scripts.playerthink) do
		script(p)
	end
	gamemode:playerthink(p)

	if p.skin ~= p.heist.locked_skin then
		R_SetPlayerSkin(p, p.heist.locked_skin)
	end
	p.score = 0
end)

addHook("ThinkFrame", function(p)
	if not FangsHeist.isMode() then return end

	for p in players.iterate do
		if not (p and p.valid and p.heist) then continue end

		for _,script in ipairs(scripts.thinkframe) do
			script(p)
		end
	end
end)

addHook("TouchSpecial", function(special, pmo)
	if not FangsHeist.isMode() then return end
	if not FangsHeist.isPlayerAlive(pmo.player) then return end

	FangsHeist.gainProfit(pmo.player, 8)
end, MT_RING)

addHook("MobjDeath", function(t,i,s)
	if not FangsHeist.isMode() then return end

	if not (s and s.player and s.player.heist) then return end

	if t.flags & MF_ENEMY then
		s.player.heist.enemies = $+1
		FangsHeist.gainProfit(s.player, 35)
	end
	if t.flags & MF_MONITOR then
		s.player.heist.monitors = $+1
		FangsHeist.gainProfit(s.player, 12)
	end
end)

addHook("MobjDeath", function(t,i,s)
	if not FangsHeist.isMode() then return end
	if not (FangsHeist.Net.escape or FangsHeist.Net.is_boss) then return end
	if not (t and t.player and t.player.heist) then return end

	local gamemode = FangsHeist.getGamemode()

	gamemode:playerdeath(t.player)
end, MT_PLAYER)

addHook("MobjDamage", function(t,i,s,dmg,dt)
	if not FangsHeist.isMode() then return end
	if not (t and t.player and t.player.heist) then return end

	for _,tres in ipairs(t.player.heist.treasures) do
		if not (tres.mobj.valid) then continue end

		local angle = FixedAngle(P_RandomRange(1, 360)*FU)

		P_InstaThrust(tres.mobj, angle, 12*FU)
		P_SetObjectMomZ(tres.mobj, 4*FU)

		tres.mobj.target = nil
	end
	t.player.heist.treasures = {}

	if dt & DMG_DEATHMASK then return end

	local givenSign = false

	if s
	and s.player
	and s.player.heist then
		if FangsHeist.playerHasSign(t.player) then
			FangsHeist.giveSignTo(s.player)
			givenSign = true
		end

		if not (t.health) then
			s.player.heist.deadplayers = $+1
			FangsHeist.gainProfit(s.player, 50)
		else
			s.player.heist.hitplayers = $+1
			FangsHeist.gainProfit(s.player, 28)
		end
	end

	if not givenSign
	and FangsHeist.playerHasSign(t.player) then
		local sign = FangsHeist.Net.sign
		sign.holder = nil

		local launch_angle = FixedAngle(P_RandomRange(0, 360)*FU)

		P_InstaThrust(sign, launch_angle, 8*FU)
		P_SetObjectMomZ(sign, 4*FU)
	end

	if t.player.powers[pw_shield] then return end
	if not t.player.rings then return end

	local rings_spill = min(5+(8*FangsHeist.Save.retakes), t.player.rings)

	S_StartSound(t, sfx_s3kb9)

	P_PlayerRingBurst(t.player, rings_spill)
	
	t.player.rings = $-rings_spill
	t.player.powers[pw_shield] = 0

	P_DoPlayerPain(t.player, s, i)
	FangsHeist.gainProfit(t.player, -8*rings_spill)
	return true
end, MT_PLAYER)

addHook("AbilitySpecial", function (p)
	if not FangsHeist.isPlayerNerfed(p)
	and FangsHeist.isPlayerAlive(p)
	and p.charability == CA_THOK
	and not (p.pflags & PF_THOKKED) then
		p.actionspd = 40*FU
	end
	
	if p.charability ~= CA_TWINSPIN then
		return FangsHeist.isPlayerNerfed(p)
	end
end)

-- added this to Player.lua
-- since its technically a player thing soo
-- -pac
addHook("MobjCollide", function(pmo, mo)
	if not FangsHeist.isMode() then return end

	if not (mo.flags & MF_MISSILE)
	or not (mo.target and mo.target.valid)
	or not (mo.target.player and mo.target.player.valid) then return end
	
	local p = pmo.player
	if FangsHeist.isPartOfTeam(p, mo.target.player) then
		return false
	end
	if p == mo.target.player then
		return false
	end
end, MT_PLAYER)

add("Pregame")
add("Nerfs")
add("Treasures")
add("Panic")
add("Sign Toss")

type = "thinkframe"

add("Spectator")
add("PVP")