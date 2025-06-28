FH.Characters = {}

local function null() end

local DEFAULT = {
	pregameBackground = "FH_PREGAME_UNKNOWN",
	customPregameBackground = nil,
	panicState = S_FH_PANIC,
	--[[controls = {
		{
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
		},
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
	}]]
}

function FH:MakeCharacter(skin, data)
	setmetatable(data, {__index = DEFAULT})
	FangsHeist.Characters[skin] = data
end

setmetatable(FH.Characters, {
	__index = function(self, val)
		if rawget(self, val) == nil then
			return DEFAULT
		end
	end
})

--FangsHeist.makeCharacter("knuckles", {pregameBackground = "FH_PREGAME_KNUCKLES"})