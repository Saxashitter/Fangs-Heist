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

function FangsHeist.addPlayerScript(type, func)
	table.insert(scripts[type], func)
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
	
	pmo.player.heist:gainProfit(FH_RINGPROFIT)
end, MT_RING)

-- this check is goofy lol
function A_RingBox(actor, var1,var2)
    local player = actor.target.player
    if FangsHeist.isMode()
    and player.heist
    and player.heist:isAlive() then
        player.heist:gainProfit(FH_RINGPROFIT*actor.info.reactiontime)
    end
    
    --run original action
    super(actor, var1,var2)
end

addHook("MobjDeath", function(t,i,s)
	if not FangsHeist.isMode() then return end

	if not (s and s.player and s.player.heist) then return end

	if t.flags & MF_ENEMY then
		s.player.heist.enemies = $+1
		s.player.heist:gainProfit(FH_ENEMYPROFIT)
	end
	if t.flags & MF_MONITOR then
		s.player.heist.monitors = $+1
		s.player.heist:gainProfit(FH_MONITORPROFIT)
	end
end)

addHook("MobjDeath", function(t,i,s)
	if not FangsHeist.isMode() then return end
	if not (t and t.player and t.player.heist) then return end

	local gamemode = FangsHeist.getGamemode()

	gamemode:playerdeath(t.player)
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
add("PVP")
add("Nerfs")
add("Treasures")
add("Panic")
add("Sign Toss")
add("Map Vote")

type = "thinkframe"

add("Spectator")