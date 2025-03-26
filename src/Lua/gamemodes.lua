local function _NIL() end
local DEFAULT = {
	name = "Default",
	desc = "Placeholder text.",

	retakes = true,
	pvp = true,
	teams = true,
	friendlyfire = false,
	teamlimit = 3,
	signnerf = true,

	init = _NIL,
	load = _NIL,
	update = _NIL,
	shouldend = _NIL,
	sync = _NIL,
	start = _NIL,
	finish = _NIL,
	playerinit = _NIL,
	playerthink = _NIL,
	playerdeath = _NIL,
	signcapture = _NIL,
}

FangsHeist.Gamemodes = {}

function FangsHeist.addGamemode(gt)
	for k,v in pairs(DEFAULT) do
		if gt[k] == nil
		or type(gt[k]) ~= type(v) then
			gt[k] = v
		end
	end

	table.insert(FangsHeist.Gamemodes, gt)
	return #FangsHeist.Gamemodes
end

function FangsHeist.getGamemode()
	if not FangsHeist.Net.gamemode then
		return FangsHeist.Gamemodes[1]
	end

	local i = FangsHeist.Net.gamemode

	if not FangsHeist.Gamemodes[i] then
		return FangsHeist.Gamemodes[1]
	end

	return FangsHeist.Gamemodes[i]
end

FangsHeist.Escape = dofile "Gamemodes/Escape/def"