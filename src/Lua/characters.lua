FangsHeist.Characters = {}

local function _NIL() end

local DEFAULT = {
	pregameBackground = "FH_PREGAME_UNKNOWN",
	customPregameBackground = nil,
	panicState = S_FH_PANIC,
	forceSpeedCap = false,
	attackPriority = _NIL,
	controls = {
	--[[	{
			key = "FIRE",
			name = "Swipe",
			cooldown = function(self, p)
				return (p.heist.attack_cooldown)
			end,
			visible = function(self, p)
				return p.mo.state ~= S_FH_GUARD
				and p.mo.state ~= S_FH_STUN
				and p.mo.state ~= S_FH_CLASH
			end
		},]]
		{
			key = "FIRE NORMAL",
			name = "Parry",
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

FangsHeist.makeCharacter("knuckles", {pregameBackground = "FH_PREGAME_KNUCKLES"})