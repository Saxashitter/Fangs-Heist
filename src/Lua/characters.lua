FangsHeist.Characters = {}

local DEFAULT = {
	difficulty = FHD_UNKNOWN,
	pregameBackground = "FH_PREGAME_UNKNOWN",
	attackCooldown = TICRATE,

	onAttack = function(self, p) end
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
FangsHeist.makeCharacter("amy", {pregameBackground = "FH_PREGAME_AMY"})
FangsHeist.makeCharacter("metalsonic", {pregameBackground = "FH_PREGAME_METAL"})