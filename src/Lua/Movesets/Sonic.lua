FangsHeist.makeCharacter("sonic", {
	pregameBackground = "FH_PREGAME_SONIC"
})

-- drop dash
local DROPDASH_LAUNCH = 12
local DROPDASH_GRAVITY = tofixed("3.7")

local DROPDASH_MOMZSTART = 5
local DROPDASH_MOMZEND = 20

local DROPDASH_SPEEDSTART = 12
local DROPDASH_SPEEDEND = 50

local DROPDASH_BOUNCESTART = 5
local DROPDASH_BOUNCEEND = 20

local function hasControl(p)
	if p.pflags & PF_STASIS then return false end
	if p.pflags & PF_FULLSTASIS then return false end
	if p.pflags & PF_SLIDING then return false end
	if p.powers[pw_nocontrol] then return false end
	if P_PlayerInPain(p) then return false end
	if not (p.mo.health) then return false end

	return true
end

addHook("PlayerThink", function(p)
	if not (FangsHeist.isMode()
	and p.heist
	and p.heist:isAlive()
	and p.mo.skin == "sonic") then
		p.mo.sonic = nil
		return
	end

	if not p.mo.sonic then
		p.mo.sonic = {}
	end

	p.mo.sonic.dropdash = nil
	if p.mo.state == S_FH_DROPDASH then
		local gravity = P_GetMobjGravity(p.mo)

		p.mo.momz = $ - gravity + FixedMul(gravity, DROPDASH_GRAVITY)
		p.mo.sonic.dropdash = -p.mo.momz*P_MobjFlip(p.mo)

		local mo = P_SpawnGhostMobj(p.mo)
		mo.fuse = 6
	end
end)

local function DropDashLand(p)
	local momz = p.mo.sonic.dropdash
	local momzstart = max(momz - DROPDASH_MOMZSTART*p.mo.scale, 0)
	local t = FixedDiv(momzstart, (DROPDASH_MOMZEND-DROPDASH_MOMZSTART)*p.mo.scale)

	FangsHeist.Particles:new("Tails Double Jump", p)

	if p.cmd.buttons & BT_JUMP then
		local bounce = 3*p.mo.scale
		local speed = R_PointToDist2(0,0, p.rmomx, p.rmomy)

		P_SetObjectMomZ(p.mo, bounce)
		p.mo.state = S_PLAY_JUMP
		p.pflags = ($|PF_JUMPED|PF_STARTJUMP|PF_THOKKED) & ~PF_SPINNING
		S_StartSound(p.mo, sfx_sbounc)

		if speed > p.normalspeed then
			local speedang = R_PointToAngle2(0,0, p.rmomx, p.rmomy)

			P_InstaThrust(p.mo, speedang, speed/2)
		end
		return
	end

	local speed = ease.linear(min(t, FU), DROPDASH_SPEEDSTART*p.mo.scale, DROPDASH_SPEEDEND*p.mo.scale)

	p.mo.state = S_PLAY_ROLL
	p.pflags = ($|PF_SPINNING) & ~PF_STARTDASH
	P_InstaThrust(p.mo, p.mo.angle, speed)
	S_StartSound(p.mo, sfx_zoom)
end

addHook("ThinkFrame", do
	if not FangsHeist.isMode() then return end

	for p in players.iterate do
		if not (p.heist and p.heist:isAlive() and p.mo.sonic) then
			continue
		end

		if p.mo.sonic.dropdash
		and P_IsObjectOnGround(p.mo) then
			DropDashLand(p)
		end
	end
end)

addHook("AbilitySpecial", function(p)
	if not FangsHeist.isMode() then return end
	if not p.heist then return end
	if not p.heist:isAlive() then return end
	if not p.mo.sonic then return end
	if p.pflags & PF_THOKKED then return end

	p.mo.state = S_FH_DROPDASH
	p.mo.sonic.dropdash = true
	p.pflags = $|PF_THOKKED
	P_SetObjectMomZ(p.mo, DROPDASH_LAUNCH*p.mo.scale)
	S_StartSoundAtVolume(p.mo, sfx_s3k82, 150)
end)