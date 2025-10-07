FH.Characters = {}
FH.CharList = {}
FH.BannedChars = {}

addHook("NetVars", function(sync)
	FH.BannedChars = sync($)
	FH.CharList = sync($)
end)

local function _NIL() end

local DEFAULT = {
	PregameBackground = "FH_PREGAME_UNKNOWN",
	PregameBGFunc = nil,
	PanicState = S_FH_PANIC,
	ForceSpeedCap = false,
	AltSkin = false,
	Voicelines = {},
	Skins = {},
}
DEFAULT.__index = DEFAULT

setmetatable(FangsHeist.Characters, {
	__index = function(self, val)
		if rawget(self, val) == nil then
			return DEFAULT
		end
	end
})

function FH:AddCharacter(skin, data)
	setmetatable(data, DEFAULT)

	FH.Characters[skin] = data
	FH:ReloadCharacters()
end

function FH:ReloadCharacters()
	FH.CharList = {}

	for i = 0, #skins-1 do
		local name = skins[i].name

		if FH.Characters[name].AltSkin then
			continue
		end

		if FH.BannedChars[name] then
			continue
		end

		table.insert(FH.CharList, skins[i])
	end
end

addHook("AddonLoaded", FH.ReloadCharacters)