FangsHeist.Characters = {}

states[freeslot "S_FH_PANIC"] = {
	sprite = SPR_PLAY,
	frame = SPR2_CNT1,
	tics = 4,
	nextstate = S_FH_PANIC
}

local DEFAULT = {
	difficulty = FHD_UNKNOWN,
	pregameBackground = "FH_PREGAME_UNKNOWN",

	panicState = S_FH_PANIC,

	attackCooldown = TICRATE,
	attackRange = tofixed("4"),
	attackZRange = tofixed("2.35"),

	damageRange = tofixed("1.5"),
	damageZRange = tofixed("1.5"),

	useDefaultAttack = true,
	useDefaultBlock = true,

	onAttack = function(self, p) end,
	onClash = function(self, p) end,
	onHit = function(self, p, sp) end,

	isAttacking = function(self, p)
		return (p.heist.attack_time)
	end,
	isBlocking = function(self, p)
		return p.heist.blocking
	end

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

rawset(_G, "FHD_EASY", 0)
rawset(_G, "FHD_MEDIUM", 1)
rawset(_G, "FHD_HARD", 2)
rawset(_G, "FHD_UNKNOWN", 3)

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

FangsHeist.makeCharacter("sonic", {pregameBackground = "FH_PREGAME_SONIC"})
FangsHeist.makeCharacter("tails", {pregameBackground = "FH_PREGAME_TAILS"})
FangsHeist.makeCharacter("knuckles", {pregameBackground = "FH_PREGAME_KNUCKLES"})
FangsHeist.makeCharacter("metalsonic", {pregameBackground = "FH_PREGAME_METAL"})