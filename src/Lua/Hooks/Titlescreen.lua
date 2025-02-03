local vars = {}

local function isTitlescreen()
	return gamestate == GS_TITLESCREEN and S_MusicName() == "_TITLE"
end

addHook("HUD", function(v)
	v.drawFill()
	v.drawString(160, 100-4, "Fang's Heist Alpha (Titlescreen W.I.P)", V_ALLOWLOWERCASE, "center")
end, "title")