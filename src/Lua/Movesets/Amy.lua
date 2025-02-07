local function canAttack(p)
	return not (p.heist.blocking or p.heist.attack_cooldown)
end

FangsHeist.makeCharacter("amy", {
	pregameBackground = "FH_PREGAME_AMY",
	attackRange = tofixed("1.3"),
	attackZRange = tofixed("1.5"),
	isAttacking = function(self, p)
		return (p.powers[pw_strong] & STR_ATTACK)
	end,
	onAttack = function(self, p)
		return true
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

local function check(p)
	if not (p and p.mo and p.mo.skin == "amy" and p.heist) then
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

local function twinSpin(p)
	if not FangsHeist.isMode() then return end
	if not check(p) then
		return
	end

	if not canAttack(p) then
		return true
	end

	if p.pflags & PF_JUMPED
	and not (p.pflags & PF_THOKKED) then
		p.heist.attack_cooldown = 50
	end
end

addHook("PlayerThink", function(p)
	if not FangsHeist.isMode() then return end
	if not (p and p.mo and p.mo.skin == "amy" and p.heist) then
		return
	end

	p.powers[pw_strong] = $ & ~STR_SPRING -- not so overpowered arent you now
end)

addHook("AbilitySpecial", twinSpin)
addHook("JumpSpinSpecial", twinSpin)
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

	if p.heist.attack_cooldown then
		return true
	end

	p.heist.attack_cooldown = 50
end)