local scripts = {
	playerthink = {},
	thinkframe = {},
	prethinkframe = {},
	postthinkframe = {}
}

FangsHeist.PlayerScripts = scripts

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

local function _draw(self, v, p, c, result, trans)
	local mo = self.mo
	local plyr = mo.player

	local plyr_spr, plyr_scale
	if skins[plyr.mo.skin].sprites[SPR2_SIGN].numframes then
		plyr_spr = v.getSprite2Patch(plyr.mo.skin, SPR2_SIGN, false, A, 0)
		plyr_scale = skins[plyr.mo.skin].highresscale
	else
		plyr_spr = v.getSpritePatch(SPR_SIGN, S, 0)
		plyr_scale = FU
	end
	plyr_scale = $/4

	local x = result.x + plyr_spr.leftoffset*plyr_scale
	local y = result.y + plyr_spr.topoffset*plyr_scale

	v.drawScaled(x - plyr_spr.width*plyr_scale/2,
		y,
		plyr_scale,
		plyr_spr,
		trans,
		v.getColormap(mo.skin, plyr.skincolor))
end

addHook("PreThinkFrame", do
	if not FangsHeist.isMode() then
		return
	end
	local gamemode = FangsHeist.getGamemode()

	for p in players.iterate do
		if not p.heist then continue end

		p.heist.lastbuttons = p.heist.buttons
		p.heist.buttons = p.cmd.buttons

		p.heist.lastforw = p.heist.forwardmove
		p.heist.lastside = p.heist.sidemove

		p.heist.forwardmove = p.cmd.forwardmove
		p.heist.sidemove = p.cmd.sidemove

		if (p.heist:isAlive()
		and p.heist.exiting)
		or FangsHeist.Net.game_over
		or FangsHeist.Net.pregame then
			p.cmd.buttons = 0
			p.cmd.forwardmove = 0
			p.cmd.sidemove = 0
		end

		for _,script in ipairs(scripts.prethinkframe) do
			script(p)
		end
		gamemode:preplayerthink(p)
	end
end)


addHook("PlayerThink", function(p)
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

	if p ~= displayplayer
	and p.heist:isAlive()
	and not p.heist.exiting then
		local variables = gamemode:trackplayer(p)

		if variables and #variables > 0 then
			variables.color = p.skincolor
			FangsHeist.trackObject(p.mo, variables, _draw)
		end
	end

	local skin, super = FangsHeist.getRealSkin(p)

	if skins[p.skin].name ~= skin then
		R_SetPlayerSkin(p, skin)
	end

	if p.mo and p.mo.valid and super then
		p.mo.eflags = ($ & ~MFE_FORCENOSUPER)|MFE_FORCESUPER
	elseif p.mo and p.mo.valid then
		p.mo.eflags = ($ & ~MFE_FORCESUPER)|MFE_FORCENOSUPER
	end

	p.score = 0
end)

addHook("ThinkFrame", function(p)
	if not FangsHeist.isMode() then return end
	local gamemode = FangsHeist.getGamemode()

	for p in players.iterate do
		if not (p and p.valid and p.heist) then continue end

		for _,script in ipairs(scripts.thinkframe) do
			script(p)
		end
		gamemode:postplayerthink(p)
	end
end)

addHook("PostThinkFrame", function(p)
	if not FangsHeist.isMode() then return end

	for p in players.iterate do
		if not (p and p.valid and p.heist) then continue end

		for _,script in ipairs(scripts.postthinkframe) do
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
	
	pmo.player.heist:gainProfitMultiplied(FH_RINGPROFIT)
end, MT_RING)

-- this check is goofy lol
function A_RingBox(actor, var1,var2)
    local player = actor.target.player
    if FangsHeist.isMode()
    and player.heist
    and player.heist:isAlive() then
        player.heist:gainProfitMultiplied(FH_RINGPROFIT*actor.info.reactiontime)
    end
    
    --run original action
    super(actor, var1,var2)
end

addHook("MobjDeath", function(t,i,s)
	if not FangsHeist.isMode() then return end

	if not (s and s.player and s.player.heist) then return end

	if t.flags & MF_ENEMY then
		s.player.heist.enemies = $+1
		s.player.heist:gainProfitMultiplied(FH_ENEMYPROFIT)
	end
	if t.flags & MF_MONITOR then
		s.player.heist.monitors = $+1
		s.player.heist:gainProfitMultiplied(FH_MONITORPROFIT)
	end
end)

addHook("MobjDeath", function(t,i,s)
	if not FangsHeist.isMode() then return end
	if not (t and t.player and t.player.heist) then return end

	local gamemode = FangsHeist.getGamemode()

	gamemode:playerdeath(t.player)
	FangsHeist.playVoiceline(t.player, "death")
	t.player.heist.health = 0
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
add("PVP")
add("Sign Toss")
add("Map Vote")

type = "thinkframe"

add("Spectator")