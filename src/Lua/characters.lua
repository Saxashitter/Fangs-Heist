FangsHeist.Characters = {}

local DEFAULT = {
	difficulty = FHD_UNKNOWN,
	pregameBackground = "FH_PREGAME_UNKNOWN",
	customPregameBackground = nil,

	panicState = S_FH_PANIC,

	forceSpeedCap = false,

	onAttack = function(self, p) end,
	onClash = function(self, p) end,
	onHit = function(self, p, sp) end,

	isAttacking = function(self, p)
		return (p.heist.attack_time)
	end,

	controls = {
		{
			key = "FIRE",
			name = "Attack",
			cooldown = function(self, p)
				return (p.heist.attack_cooldown)
			end,
			visible = function(self, p)
				return p.mo.state ~= S_FH_GUARD
				and p.mo.state ~= S_FH_STUN
				and p.mo.state ~= S_FH_CLASH
			end
		},
		{
			key = "FIRE NORMAL",
			name = "Guard",
			cooldown = function(self, p)
				return (p.heist.parry_cooldown)
			end,
			visible = function(self, p)
				return p.mo.state ~= S_FH_GUARD
				and p.mo.state ~= S_FH_STUN
				and p.mo.state ~= S_FH_CLASH
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