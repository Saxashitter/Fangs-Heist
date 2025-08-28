FangsHeist.Characters = {}
FangsHeist.CharList = {}

local function _NIL() end

local DEFAULT = {
	pregameBackground = "FH_PREGAME_UNKNOWN",
	customPregameBackground = nil,
	panicState = S_FH_PANIC,
	forceSpeedCap = false,
	altSkin = false,
	voicelines = {},
	skins = {},
	attackPriority = _NIL,
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
	FangsHeist.defCharList()
end

function FangsHeist.defCharList()
	FangsHeist.CharList = {}

	for i = 0, #skins-1 do
		local name = skins[i].name

		if FangsHeist.Characters[name].altSkin then
			print("Alt skin: "..name)
			continue
		end

		print("Skin: "..name)
		table.insert(FangsHeist.CharList, skins[i])
	end
end

FangsHeist.makeCharacter("knuckles", {
	pregameBackground = "FH_PREGAME_KNUCKLES",
	skins = {
		{name = "UglyKnux"},
	},
})

addHook("AddonLoaded", FangsHeist.defCharList)