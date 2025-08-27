freeslot("TOL_HEIST")
freeslot("TOL_HEISTROUND2")

local function _NIL() end
local DEFAULT = {
	name = "Default",
	desc = "Placeholder text.",

	id = "ID",
	tol = TOL_HEIST|TOL_HEISTROUND2,

	pvp = true,
	teams = true,
	friendlyfire = false,
	teamlimit = 3,
	signnerf = false,
	spillallrings = false,
	dontdivprofit = false,
	preferredhud = {
		pos = {x = 312, y = 8},
		Profit = true,
		Rings = true,
		Rank = true,
		Timer = true,
	},
	pregametheme = "FH_PRG",

	init = _NIL,
	load = _NIL,
	prethink = _NIL,
	update = _NIL,
	postthink = _NIL,
	shouldend = _NIL,
	start = _NIL,
	finish = _NIL,
	playerspawn = _NIL,
	playerinit = _NIL,
	preplayerthink = _NIL,
	playerthink = _NIL,
	postplayerthink = _NIL,
	playerdamage = _NIL,
	playerdeath = _NIL,
	shouldinstakill = _NIL,
	trackplayer = _NIL,
	signblacklist = _NIL,
	treasureblacklist = _NIL,
	info = _NIL,
}

FangsHeist.Gamemodes = {}
FangsHeist.GametypeIDs = {}

function FangsHeist.addGamemode(gt)
	for k,v in pairs(DEFAULT) do
		if gt[k] == nil
		or type(gt[k]) ~= type(v) then
			gt[k] = v
		end
	end

	gt.index = #FangsHeist.Gamemodes+1

	G_AddGametype({
	    name = "FH: "..gt.name,
	    identifier = "FANGSHEIST"..gt.id,
	    typeoflevel = gt.tol,
	    intermissiontype = int_none,
	    rules = GTR_FRIENDLYFIRE|GTR_SPAWNINVUL|GTR_DEATHPENALTY|GTR_SPAWNENEMIES,
	    headerleftcolor = 195,
	    headerrightcolor = 112,
		description = gt.desc
	})

	gt.gametype = _G["GT_FANGSHEIST"..gt.id]
	table.insert(FangsHeist.Gamemodes, gt)
	FangsHeist.GametypeIDs[_G["GT_FANGSHEIST"..gt.id]] = #FangsHeist.Gamemodes

	return #FangsHeist.Gamemodes
end

function FangsHeist.getGamemode()
	local i = FangsHeist.GametypeIDs[gametype]

	if not FangsHeist.Gamemodes[i] then
		return FangsHeist.Gamemodes[1]
	end

	return FangsHeist.Gamemodes[i]
end

FangsHeist.Escape = dofile "Modules/Gamemodes/Escape/def.lua"
-- FangsHeist.TagTeam = dofile "Gamemodes/Tag Team/def.lua"

-- EXTREEEEEMELY important!! don't comment out or remove or even SEE it...
-- or WARIO will come to your house and steal all your precious valuables
FangsHeist.WL4 = dofile "Modules/Gamemodes/Wario Land/def.lua"
FangsHeist.Remix = dofile "Modules/Gamemodes/Remix/def.lua"
