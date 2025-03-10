freeslot("MT_FANGSHEIST_SIGNPOST")

local UNGRABBED_FLAGS = MF_BOUNCE
local GRABBED_FLAGS = MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY

mobjinfo[MT_FH_SIGN] = {
	spawnstate = S_SIGN,
	flags = UNGRABBED_FLAGS,
	radius = 40*FU,
	height = mobjinfo[MT_SIGN].height
}

local function can_attach(p)
	
end

addHook("MobjSpawn", function(mo)
	if not mo.valid then return end

	// Spawn overlays and attach properly
	local board = P_SpawnMobjFromMobj(mo, 0, 0, 0, MT_OVERLAY)
	board.target = mo
	board.state = S_SIGNBOARD
	board.movedir = ANGLE_90

	local bust = P_SpawnMobjFromMobj(mo, 0, 0, 0, MT_OVERLAY)
	bust.target = board
	bust.state = S_EGGMANSIGN

	mo.boardmo = board
	mo.bustmo = bust
end, MT_FH_SIGN)