local scripts = {
	PlayerThink = {},
	ThinkFrame = {},
	PreThinkFrame = {}
}
local type = "PlayerThink"

FH.PlayerScripts = scripts

local function add(file)
	local result = dofile("behaviors/player/"..file)

	if result then
		table.insert(scripts[type], result)
	end
end

addHook("PlayerSpawn", function(p)
	if not FH:IsMode() then return end
	if not (p and p.heist) then
		FH:InitPlayer(p)
	end

	local gamemode = FH:GetGamemode()
	gamemode:PlayerSpawn(p)
end)

addHook("PlayerThink", function(p)
	-- Force every PlayerThink hook to run before our code here.
	for _,data in ipairs(FH._HOOKS.PlayerThink) do
		data.func(p)
	end

	if not (p and p.valid) then return end

	if not FH:IsMode() then return end
		p.heist = nil
		return
	end

	local gamemode = FH:GetGamemode()

	if not (p and p.heist) then
		FH:InitPlayer(p)
	end

	for _,script in ipairs(scripts.PlayerThink) do
		script(p)
	end

	gamemode:PlayerThink(p)

	if p.skin ~= p.heist.locked_skin then
		R_SetPlayerSkin(p, p.heist.locked_skin)
	end
	p.score = 0
end)

addHook("ThinkFrame", function(p)
	if not FH:IsMode() then return end

	for p in players.iterate do
		if not (p and p.valid and p.heist) then continue end

		for _,script in ipairs(scripts.ThinkFrame) do
			script(p)
		end
	end
end)

addHook("MobjDeath", function(ring, _, pmo)
	if not FH:IsMode() then return end
	if not (ring and ring.valid) then return end
	if not (pmo and pmo.valid and pmo.type == MT_PLAYER) then return end
	if not (pmo.player.heist and pmo.player.heist:isAlive()) then return end
	
	pmo.player.heist:GainProfitMultiplied(FH_RINGPROFIT)
	ring.flags2 = $|MF2_DONTRESPAWN
end, MT_RING)

-- this check is goofy lol
function A_RingBox(actor, var1,var2)
	local player = actor.target.player
	
	if FH:IsMode()
	and player.heist
	and player.heist:isAlive() then
		player.heist:GainProfitMultiplied(FH_RINGPROFIT*actor.info.reactiontime)
	end

    --run original action
    super(actor, var1,var2)
end

addHook("MobjDeath", function(t,i,s)
	if not FH:IsMode() then return end

	if not (s and s.player and s.player.heist) then return end

	if t.flags & MF_ENEMY then
		s.player.heist.enemies = $+1
		s.player.heist:GainProfitMultiplied(FH_ENEMYPROFIT)
	end
	if t.flags & MF_MONITOR then
		s.player.heist.monitors = $+1
		s.player.heist:GainProfitMultiplied(FH_MONITORPROFIT)
	end
end)

addHook("MobjDeath", function(t,i,s)
	if not FH:IsMode() then return end
	if not (t and t.player and t.player.heist) then return end

	local gamemode = FH:GetGamemode()

	gamemode:playerdeath(t.player)
end, MT_PLAYER)

addHook("AbilitySpecial", function (p)
	if not FH:IsMode() then return end

	if p.charability ~= CA_TWINSPIN then
		return p.heist:isNerfed()
	end
end)

-- added this to Player.lua
-- since its technically a player thing soo
-- -pac
addHook("MobjCollide", function(pmo, mo)
	if not FH:IsMode() then return end

	if not (mo.flags & MF_MISSILE)
	or not (mo.target and mo.target.valid)
	or not (mo.target.player and mo.target.player.valid) then return end
	
	local p = pmo.player
	if p.heist:IsPartOfTeam(mo.target.player) then
		return false
	end
	if p == mo.target.player then
		return false
	end
end, MT_PLAYER)

function FH:AddPlayerScript(type, func)
	table.insert(scripts[type], func)
end

add("pregame")
add("sign")
add("vote")

type = "ThinkFrame"

add("spectator")