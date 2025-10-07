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
	teamlimit = 1,
	spillallrings = false,
	preferredhud = {
		pos = {x = 8, y = 8, flags = V_SNAPTOLEFT|V_SNAPTOTOP},
		profit = {enabled = true},
		rings = {enabled = true},
		rank = {enabled = true},
		timer = {enabled = true},
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
	profitgain = _NIL,
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

FH.Gamemodes = {}
FH.GametypeIDs = {}

function FH:AddGamemode(gt)
	for k,v in pairs(DEFAULT) do
		if gt[k] == nil
		or type(gt[k]) ~= type(v) then
			gt[k] = v
		end
	end

	gt.index = #self.Gamemodes+1

	G_AddGametype({
	    name = gt.name,
	    identifier = "FH_"..gt.id,
	    typeoflevel = gt.tol,
	    intermissiontype = int_none,
	    rules = GTR_FRIENDLYFIRE|GTR_SPAWNINVUL|GTR_DEATHPENALTY|GTR_SPAWNENEMIES,
	    headerleftcolor = 195,
	    headerrightcolor = 112,
		description = gt.desc
	})

	gt.gametype = _G["GT_FH_"..gt.id]
	table.insert(self.Gamemodes, gt)

	self.GametypeIDs[_G["GT_FH_"..gt.id]] = #self.Gamemodes

	return #self.Gamemodes
end

function FH:GetGamemode()
	local i = self.GametypeIDs[gametype]

	if not self.Gamemodes[i] then
		return self.Gamemodes[1]
	end

	return self.Gamemodes[i]
end

FH.SoloGamemode = dofile "gamemodes/Solo/def.lua"
FH.DuoGamemode = dofile "gamemodes/Duo/def.lua"
FH.TrioGamemode = dofile "gamemodes/Trio/def.lua"
FH.CoopGamemode = dofile "gamemodes/Co-op/def.lua"
FH.SignlessGamemode = dofile "gamemodes/Signless/def.lua"