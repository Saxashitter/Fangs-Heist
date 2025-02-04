-- Fang the Sniper Moveset for Fang's Heist.
-- Fang is supposed to be more like a bullet hell than other characters, who rely on melee attacks.

--[[TO-DO: Add character hooks and character data.
	FangsHeist.Characters["fang"] = {
		attack = false,
		block = false,
		difficulty = 2 -- hard
	}
]]

local SHOT_COOLDOWN = 8
local FLOATGUNS_AMMO = 2
local FLOATGUNS_COOLDOWN = 2

freeslot("SPR2_FAIR","S_PLAY_AIRFIRE1","S_PLAY_AIRFIRE2")
states[S_PLAY_AIRFIRE1] = {
        sprite = SPR_PLAY,
        frame = SPR2_FAIR||FF_SPR2,
        tics = -1,
}
states[S_PLAY_AIRFIRE2] = {
        sprite = SPR_PLAY,
        frame = SPR2_FAIR,
        tics = -1,
}

local function init(p)
	p.fang = {
		shootcooldown = 0,
		gunsammo = FLOATGUNS_AMMO,
		gunscooldown = 0,
		guns = {} -- cache mobjs in this
	}
end

local function canMove(p)
	return not ((player.pflags & (PF_SLIDING|PF_BOUNCING|PF_THOKKED)) or (player.exiting) or (P_PlayerInPain(player) or p.mo.health == 0))
end

local function airSling(p)
	if not canMove(p) then
		return
	end

	if P_IsObjectOnGround(p.mo) then return end

	if not (p.cmd.buttons & BT_SPIN
	and not (p.lastbuttons & BT_SPIN)) then
		return
	end
end

addHook("PlayerThink", function(p)
	if not (FangsHeist.isMode() and p.mo and p.heist) then return end
	if p.mo.skin ~= "fang" then return end

end)