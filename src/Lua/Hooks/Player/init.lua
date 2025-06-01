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

addHook("PlayerSpawn", function(p)
	if not FangsHeist.isMode() then return end
	if not (p and p.heist) then
		FangsHeist.initPlayer(p)
	end

	local gamemode = FangsHeist.getGamemode()
	gamemode:playerspawn(p)
end)

addHook("PlayerThink", function(p)
	-- Force every PlayerThink hook to run before our code here.
	for _,data in ipairs(FangsHeist._HOOKS.PlayerThink) do
		data.func(p)
	end

	if not (p and p.valid) then return end

	if not FangsHeist.isMode() then 
		p.heist = nil
		return
	end

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

/*addHook("TouchSpecial", function(special, pmo)
	if not FangsHeist.isMode() then return end
	if not (pmo.player.heist and pmo.player.heist:isAlive()) then return end

	pmo.player.heist:gainProfit(8)
end, MT_RING)*/

addHook("MobjDeath", function(ring, _, pmo)
	if not FangsHeist.isMode() then return end
	if not (ring and ring.valid) then return end
	if not (pmo and pmo.valid and pmo.type == MT_PLAYER) then return end
	if not (pmo.player.heist and pmo.player.heist:isAlive()) then return end
	
	pmo.player.heist:gainProfit(8)
end, MT_RING)

-- this check is goofy lol
function A_RingBox(actor, var1,var2)
    local player = actor.target.player
    if FangsHeist.isMode()
    and player.heist
    and player.heist:isAlive() then
        player.heist:gainProfit(8*actor.info.reactiontime)
    end
    
    --run original action
    super(actor, var1,var2)
end

addHook("MobjDeath", function(t,i,s)
	if not FangsHeist.isMode() then return end

	if not (s and s.player and s.player.heist) then return end

	if t.flags & MF_ENEMY then
		s.player.heist.enemies = $+1
		s.player.heist:gainProfit(35)
	end
	if t.flags & MF_MONITOR then
		s.player.heist.monitors = $+1
		s.player.heist:gainProfit(12)
	end
end)

addHook("MobjDeath", function(t,i,s)
	if not FangsHeist.isMode() then return end
	if not (t and t.player and t.player.heist) then return end

	local gamemode = FangsHeist.getGamemode()

	gamemode:playerdeath(t.player)
end, MT_PLAYER)

local function RingSpill(p, dontSpill)
	if not p.rings then
		return false
	end
	local gamemode = FangsHeist.getGamemode()

	local rings_spill = min(5+(8*FangsHeist.Save.retakes), p.rings)
	if gamemode.spillallrings then
		rings_spill = p.rings
	end

	if not dontSpill then
		P_PlayerRingBurst(p, rings_spill)
	end
	S_StartSound(p.mo, sfx_s3kb9)
	p.rings = $-rings_spill
	p.heist:gainProfit(-8*rings_spill)


	return rings_spill
end

local function RemoveCarry(p)
	if p.powers[pw_carry] == CR_ROLLOUT then
		local rollout = p.mo.tracer

		if rollout and rollout.valid then
			rollout.tracer = nil
			rollout.flags = $|MF_PUSHABLE
		end

		p.mo.tracer = nil
	else
		local mo = p.mo.tracer

		if mo and mo.valid then
			mo.tracer = nil
		end

		p.mo.tracer = nil
	end

	p.powers[pw_carry] = CR_NONE
end

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

	local gamemode = FangsHeist.getGamemode()
	gamemode:playerdamage(t.player)

	local givenSign = false

	if s
	and s.player
	and s.player.heist then
		local team = s.player.heist:getTeam()

		if t.player.heist:hasSign()
		and s.player.heist:isEligibleForSign() then
			FangsHeist.giveSignTo(s.player)
			givenSign = true
		end

		if not (t.health) then
			s.player.heist.deadplayers = $+1
			s.player.heist:gainProfit(50)
		else
			s.player.heist.hitplayers = $+1
			s.player.heist:gainProfit(28)
		end
	end

	if not givenSign
	and t.player.heist:hasSign() then
		local sign = FangsHeist.Net.sign
		sign.holder = nil

		local launch_angle = FixedAngle(P_RandomRange(0, 360)*FU)

		P_InstaThrust(sign, launch_angle, 8*FU)
		P_SetObjectMomZ(sign, 4*FU)
	end

	if dt & DMG_DEATHMASK then
		return
	end

	if t.player.powers[pw_shield] then return end
	local rings = RingSpill(t.player)

	if not rings then return end

	RemoveCarry(t.player)
	P_DoPlayerPain(t.player, s, i)
	return true
end, MT_PLAYER)

addHook("AbilitySpecial", function (p)
	if not FangsHeist.isMode() then return end

	if p.charability ~= CA_TWINSPIN then
		return p.heist:isNerfed()
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
	if p.heist:isPartOfTeam(mo.target.player) then
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