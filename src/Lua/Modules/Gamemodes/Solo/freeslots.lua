sfxinfo[freeslot "sfx_fhtick"].caption = "Tick..."
sfxinfo[freeslot "sfx_fhuhoh"].caption = "Uh oh!"

states[freeslot "S_FH_GOALPORTAL"] = {
	sprite = freeslot "SPR_GORI",
	frame = FF_ANIMATE,
	tics = -1,
	var1 = F,
	var2 = 3,
	nextstate = S_FH_GOALPORTAL
}

states[freeslot "S_FH_ROUNDPORTAL"] = {
	sprite = freeslot "SPR_R2RI",
	frame = FF_ANIMATE,
	tics = -1,
	var1 = F,
	var2 = 3,
	nextstate = S_FH_ROUNDPORTAL
}

states[freeslot "S_FH_ROUNDINDICATOR"] = {
	sprite = freeslot "SPR_ROU2",
	tics = -1,
	nextstate = S_FH_ROUNDINDICATOR
}

mobjinfo[freeslot "MT_FH_ROUNDINDICATOR"] = {
	spawnstate = S_FH_ROUNDINDICATOR,
	radius = 1,
	height = 1,
	flags = MF_SCENERY|MF_NOGRAVITY|MF_NOCLIP|MF_NOCLIPHEIGHT
}

local LOOP_TIME = 2*TICRATE
local HEIGHT = 15

addHook("MobjSpawn", function(mo)
	mo.ticing = 0
end, MT_FH_ROUNDINDICATOR)

addHook("MobjThinker", function(mo)
	local y = mo.target and mo.target.valid and mo.target.spriteyoffset
	mo.ticing = ($+1) % LOOP_TIME
	mo.spriteyoffset = y + HEIGHT + HEIGHT*cos(FixedAngle(360*FixedDiv(mo.ticing, LOOP_TIME)))
end, MT_FH_ROUNDINDICATOR)