FangsHeist.Characters = {}

states[freeslot "S_FH_PANIC"] = {
	sprite = SPR_PLAY,
	frame = SPR2_CNT1,
	tics = 4,
	nextstate = S_FH_PANIC
}

states[freeslot "S_FH_INSTASHIELD"] = {
	sprite = freeslot"SPR_TWSP",
	frame = A|FF_ANIMATE|FF_FULLBRIGHT,
	tics = G,
	var1 = G,
	var2 = 1
}

states[freeslot "S_FH_SHIELD"] = {
	sprite = freeslot"SPR_FHSH",
	frame = A|FF_FULLBRIGHT|FF_TRANS30,
	tics = -1
}

local DEFAULT = {
	difficulty = FHD_UNKNOWN,
	pregameBackground = "FH_PREGAME_UNKNOWN",
	customPregameBackground = nil,

	panicState = S_FH_PANIC,

	forceSpeedCap = false,

	attackCooldown = TICRATE,
	attackRange = tofixed("4"),
	attackZRange = tofixed("2.35"),

	damageRange = tofixed("1.5"),
	damageZRange = tofixed("1.5"),

	useDefaultAttack = true,
	useDefaultBlock = true,

	attackEffectState = S_FH_INSTASHIELD,
	blockShieldState = S_FH_SHIELD,

	onAttack = function(self, p) end,
	onClash = function(self, p) end,
	onHit = function(self, p, sp) end,

	isAttacking = function(self, p)
		return (p.heist.attack_time)
	end,
	isBlocking = function(self, p)
		return p.heist.blocking
	end,

	controls = {
		{
			key = "FIRE",
			name = "Attack",
			cooldown = function(self, p)
				return (p.heist.attack_cooldown)
			end,
			visible = function(self, p)
				return not p.heist.blocking
			end
		},
		{
			key = "FIRE NORMAL",
			name = "Block",
			cooldown = function(self, p)
				return (p.heist.attack_cooldown or p.heist.block_cooldown)
			end,
			visible = function(self, p)
				return true
			end
		}
	}
}

setmetatable(FangsHeist.Characters, {
	__index = function(self, val)
		if rawget(self, val) == nil then
			return DEFAULT
		end
	end
})

function FangsHeist.makeCharacter(skin, data)
	setmetatable(data, {__index = DEFAULT})
	FangsHeist.Characters[skin] = data
end

FangsHeist.makeCharacter("tails", {pregameBackground = "FH_PREGAME_TAILS"})
FangsHeist.makeCharacter("knuckles", {pregameBackground = "FH_PREGAME_KNUCKLES"})
FangsHeist.makeCharacter("metalsonic", {pregameBackground = "FH_PREGAME_METAL"})