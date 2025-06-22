FangsHeist.makeCharacter("sonic", {
	pregameBackground = "FH_PREGAME_SONIC"
})

-- drop dash
local DROPDASH_TICS = 15
local DROPDASH_UPWALL_TICS = 5
local DROPDASH_STARTSPEED = 28*FU
local DROPDASH_ENDSPEED = 45*FU

-- stomp
local STOMP_TICS = 40
local STOMP_START = 20*FU
local STOMP_END = 48*FU

local function initDropDash(sonic)
	sonic.jumpheld = false

	sonic.dropdash_tics = 0
	sonic.dropdash_delay = 0
	sonic.dropdashing = false
	sonic.cantdrop = false
end

local function initStomp(sonic)
	sonic.stomp_tics = 0
end

local function init(p)
	p.sonic = {}

	initDropDash(p.sonic)
	initStomp(p.sonic)
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
	and p.heist
	and p.heist:isAlive()
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
		if not p.sonic.dropdashing then
			S_StartSound(p.mo, sfx_spndsh)
			p.mo.state = S_FH_DROPDASH
			p.pflags = $ & ~PF_SPINNING
		end

		p.sonic.dropdashing = true
	else
		if canDropDash(p)
		and p.sonic.dropdashing then
			p.mo.state = S_PLAY_JUMP
		end

		initDropDash(p.sonic)
	end

	if p.sonic.dropdashing then
		p.sonic.dropdash_tics = min($+1, DROPDASH_TICS)
	end

	if p.mo.state == S_FH_STOMP then
		p.mo._stomp = true
		p.sonic.stomp_tics = min($+1, STOMP_TICS)
		if not P_IsObjectOnGround(p.mo) then
			local speed = -FixedMul(
				ease.linear(
					FixedDiv(
						p.sonic.stomp_tics,
						STOMP_TICS
					),
					STOMP_START,
					STOMP_END
				),
				p.mo.scale
			)
	
			P_SetObjectMomZ(p.mo, speed)
			p.powers[pw_strong] = $|STR_HEAVY
		end
	else
		initStomp(p.sonic)
		p.powers[pw_strong] = $ & ~STR_HEAVY
	end
end)

addHook("ThinkFrame", do
	if not FangsHeist.isMode() then return end

	for p in players.iterate do
		if not (p.heist and p.heist:isAlive() and p.sonic) then
			if p.mo
			and p.mo.valid then
				p.mo._stomp = false
			end

			continue
		end

		if P_IsObjectOnGround(p.mo)
		and p.sonic.cantdrop then
			p.sonic.cantdrop = false
		end

		if p.sonic.dropdashing
		and P_IsObjectOnGround(p.mo) then
			initDropDash(p)

			p.pflags = $|PF_SPINNING
			p.mo.state = S_PLAY_ROLL

			local ddspeed = ease.linear(FixedDiv(p.sonic.dropdash_tics, DROPDASH_TICS),
				DROPDASH_STARTSPEED,
				DROPDASH_ENDSPEED)
	
			P_InstaThrust(p.mo, p.mo.angle, FixedMul(ddspeed, p.mo.scale))
			p.drawangle = p.mo.angle
			S_StartSound(p.mo, sfx_zoom)
		end

		if p.mo._stomp
		and (p.mo.state ~= S_FH_STOMP
		or P_IsObjectOnGround(p.mo)) then
			p.mo._stomp = false
			p.powers[pw_strong] = $ & ~STR_HEAVY
	
			if P_IsObjectOnGround(p.mo) then
				S_StartSound(p.mo, sfx_s3k4c)
			end
		end
	end
end)

addHook("AbilitySpecial", function(p)
	if not FangsHeist.isMode() then return end
	if not p.heist then return end
	if not p.heist:isAlive() then return end
	if not p.sonic then return end
	if p.pflags & PF_THOKKED then return end
	if p.sonic.cantdrop then return end

	p.sonic.jumpheld = true
end)

addHook("JumpSpinSpecial", function(p)
	if not FangsHeist.isMode() then return end
	if not p.heist then return end
	if not p.heist:isAlive() then return end
	if not p.sonic then return end

	if p.mo.state ~= S_FH_STOMP
	and not P_IsObjectOnGround(p.mo)
	and hasControl(p)
	and not (p.pflags & PF_SPINDOWN) then
		p.mo.state = S_FH_STOMP
		p.pflags = ($|PF_THOKKED) & ~(PF_JUMPED|PF_SPINNING)
		p.powers[pw_strong] = $|STR_HEAVY
		S_StartSound(p.mo, sfx_zoom)
	end
end)

addHook("PlayerCanDamage", function(p)
	if not FangsHeist.isMode() then return end
	if not p.heist then return end
	if not p.heist:isAlive() then return end
	if not p.sonic then return end

	if p.mo.state == S_FH_STOMP then
		return true
	end
end)

addHook("MobjMoveBlocked", function(pmo, mo, line)
	if not (pmo and pmo.player and pmo.player.valid) then return end

	local p = pmo.player

	if not FangsHeist.isMode() then return end
	if not p.heist then return end
	if not p.heist:isAlive() then return end
	if not p.sonic then return end
	if not p.sonic.dropdashing then return end
	if p.sonic.dropdash_tics < DROPDASH_UPWALL_TICS then return end

	initDropDash(p)
	p.sonic.jumpheld = false
	p.sonic.cantdrop = true

	local ddspeed = ease.linear(FixedDiv(p.sonic.dropdash_tics, DROPDASH_TICS),
		DROPDASH_STARTSPEED,
		DROPDASH_ENDSPEED)/3

	P_SetObjectMomZ(p.mo, FixedMul(ddspeed, p.mo.scale))
	S_StartSound(p.mo, sfx_zoom)

	p.pflags = ($ & ~PF_SPINNING)|PF_JUMPED|PF_THOKKED
	p.mo.state = S_PLAY_JUMP
end, MT_PLAYER)