FangsHeist.makeCharacter("sonic", {
	difficulty = FHD_EASY,
	pregameBackground = "FH_PREGAME_SONIC"
})

states[freeslot "S_FH_DROPDASH"] = {
	sprite = SPR_PLAY,
	frame = freeslot "SPR2_DRPD",
	tics = 2,
	nextstate = S_FH_DROPDASH
}
local DELAY = 8
local TICS = 15
local STARTSPEED = 20*FU
local ENDSPEED = 44*FU

local function initDropDash(sonic)
	sonic.dropdash_tics = 0
	sonic.dropdash_delay = 0
	sonic.jumpheld = false
	sonic.dropdashing = false
end

local function init(p)
	p.sonic = {}

	initDropDash(p.sonic)
end

local function hasControl(p)
	if p.pflags & PF_STASIS then return false end
	if p.pflags & PF_FULLSTASIS then return false end
	if p.pflags & PF_SLIDING then return false end
	if p.powers[pw_nocontrol] then return false end
	if P_PlayerInPain(p) then return false end
	if not (p.mo.health) then return false end

	return true
end

local function canDropDash(p)
	if not hasControl(p) then
		return false
	end
	if p.heist:isNerfed() then
		return false
	end

	return not P_IsObjectOnGround(p.mo) and p.pflags & PF_JUMPED > 0
end

addHook("PlayerThink", function(p)
	if not (FangsHeist.isMode()
	and FangsHeist.isPlayerAlive(p)
	and p.mo.skin == "sonic") then
		p.sonic = nil
		return
	end

	if not p.sonic then
		init(p)
	end

	if p.sonic.jumpheld
	and not (p.cmd.buttons & BT_JUMP) then
		p.sonic.jumpheld = false
	end

	if canDropDash(p)
	and p.sonic.jumpheld then
		if p.sonic.dropdash_delay < DELAY then
			p.mo.tics = min($, 1)
			p.sonic.dropdash_delay = $+1

			if p.sonic.dropdash_delay == DELAY then
				S_StartSound(p.mo, sfx_spndsh)
				p.mo.state = S_FH_DROPDASH
			end
		end

		p.sonic.dropdashing = p.sonic.dropdash_delay == DELAY
	else
		if canDropDash(p)
		and p.sonic.dropdashing then
			p.mo.state = S_PLAY_JUMP
		end

		initDropDash(p.sonic)
	end

	if p.sonic.dropdashing then
		p.sonic.dropdash_tics = min($+1, TICS)
	end
end)

addHook("ThinkFrame", do
	if not FangsHeist.isMode() then return end

	for p in players.iterate do
		if not (FangsHeist.isPlayerAlive(p) and p.sonic) then
			continue
		end

		if p.sonic.dropdashing
		and P_IsObjectOnGround(p.mo) then
			initDropDash(p)

			p.pflags = $|PF_SPINNING
			p.mo.state = S_PLAY_ROLL

			local ddspeed = ease.linear(FixedDiv(p.sonic.dropdash_tics, TICS),
				STARTSPEED,
				ENDSPEED)
	
			P_InstaThrust(p.mo, p.mo.angle, FixedMul(ddspeed, p.mo.scale))
			p.drawangle = p.mo.angle
			S_StartSound(p.mo, sfx_zoom)
		end
	end
end)

addHook("AbilitySpecial", function(p)
	if not FangsHeist.isMode() then return end
	if not FangsHeist.isPlayerAlive(p) then return end
	if not p.sonic then return end

	p.sonic.jumpheld = true
end)