local function canAttack(p)
	return not (p.heist.blocking or p.heist.attack_cooldown)
end

states[freeslot "S_FH_AMY_TWIRL"] = {
	sprite = SPR_PLAY,
	frame = freeslot "SPR2_TWRL",
	tics = 1,
	nextstate = S_FH_AMY_TWIRL
}

FangsHeist.makeCharacter("amy", {
	pregameBackground = "FH_PREGAME_AMY",
	attackRange = tofixed("1.3"),
	attackZRange = tofixed("1.5"),
	isAttacking = function(self, p)
		return (p.powers[pw_strong] & STR_ATTACK)
	end,
	onHit = function(self, p, projectile, sound)
		if projectile then return end

		S_StartSound(p.mo, sound)
		p.mo.momx = $*-1
		p.mo.momy = $*-1

		if not P_IsObjectOnGround(p.mo) then
			p.mo.state = S_PLAY_FALL
			return true
		end

		p.mo.state = S_PLAY_STND
		return true
	end,
	useDefaultAttack = false,

	controls = {
		{
			key = "SPIN/JUMP",
			name = "Attack (Twinspin)",
			cooldown = function(self, p)
				return not canAttack(p)
			end,
			visible = function(self, p)
				return not p.heist.blocking
			end
		},
		FangsHeist.Characters.sonic.controls[2]
	}
})

local function init(p)
	p.amy = {
		twirl = false,
		twirlframes = 0
	}
end

local function check(p)
	if not (p and p.mo and p.mo.skin == "amy" and p.heist and p.amy) then
		return false
	end

	if p.pflags & PF_STASIS then
		return false
	end

	if p.exiting then
		return false
	end

	if P_PlayerInPain(p) or p.mo.health == 0 then
		return false
	end

	return true
end
addHook("PlayerThink", function(p)
	if not FangsHeist.isMode() then 
		p.amy = nil
		return
	end
	if not (p and p.mo and p.mo.skin == "amy" and p.heist) then
		p.amy = nil
		return
	end

	if not (p.amy) then
		init(p)
	end

	local attackFlags = STR_ATTACK|STR_WALL|STR_CEILING

	if p.mo.state == S_FH_AMY_TWIRL then
		local gravity = 3

		if FangsHeist.playerHasSign(p) then
			gravity = 9
		end

		p.pflags = $|PF_JUMPSTASIS
		p.mo.momz = max(-gravity*p.mo.scale, $)

		p.amy.twirl = true
		p.powers[pw_strong] = $|attackFlags

		if p.amy.twirlframes -- stupid abilityspecial runnig before playerthink
		and p.cmd.buttons & BT_JUMP
		and not (p.lastbuttons & BT_JUMP) then
			p.mo.state = S_PLAY_FALL
		end

		p.amy.twirlframes = $+1
	end

	if p.mo.state ~= S_FH_AMY_TWIRL
	and p.amy.twirl then
		p.amy.twirl = false
		p.amy.twirlframes = 0
		p.powers[pw_strong] = $ & ~attackFlags
	end

	p.powers[pw_strong] = $ & ~STR_SPRING -- not so overpowered arent you now
end)

addHook("AbilitySpecial", function(p)
	if not FangsHeist.isMode() then return end
	if not check(p) then
		return
	end

	if not canAttack(p)
	or not p.amy then
		return true
	end

	if p.pflags & PF_JUMPED
	and not (p.pflags & PF_THOKKED) then
		p.heist.attack_cooldown = 85
		P_SetObjectMomZ(p.mo, 7*FU)
		p.mo.state = S_FH_AMY_TWIRL
		p.pflags = $|PF_THOKKED
		p.amy.twirlframes = 0
		return true
	end
end)
addHook("JumpSpinSpecial", function(p)
	if not FangsHeist.isMode() then return end
	if not check(p) then
		return
	end

	if p.powers[pw_shield] then
		return
	end

	if not canAttack(p) then
		return true
	end

	if p.pflags & PF_JUMPED
	and not (p.pflags & PF_THOKKED) then
		p.heist.attack_cooldown = 50
	end
end)

addHook("SpinSpecial", function(p)
	if not FangsHeist.isMode() then return end
	if not check(p) then
		return
	end

	local canstand = (not p.mo.standingslope
		or p.mo.standingslope.flags & SL_NOPHYSICS
		or abs(p.mo.standingslope.zdelta) < FU/2)

	if not (p.panim ~= PA_ABILITY2
	and p.cmd.buttons & BT_SPIN
	and not (p.mo.momz)
	and P_IsObjectOnGround(p.mo)
	and not (p.pflags & PF_SPINDOWN)
	and canstand) then
		return
	end

	if p.heist.attack_cooldown
	or p.heist.blocking then
		return true
	end

	p.heist.attack_cooldown = 50
end)