-- Colors
freeslot("SKINCOLOR_REALLYREALLYBLACK")
skincolors[SKINCOLOR_REALLYREALLYBLACK] = {
    name = "GUHHH",
    ramp = {31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31},
    invcolor = SKINCOLOR_BLACK,
    invshade = 9,
    chatcolor = V_BLUEMAP,
    accessible = false
}


-- Actions
function A_ForceFrame(mo, var1, var2)
	mo.frame = ($ & ~FF_FRAMEMASK)|var1
end

--Sprites
freeslot "SPR2_FHBN"
freeslot "SPR_THIK"

-- States
states[freeslot "S_FH_PANIC"] = {
	sprite = SPR_PLAY,
	frame = SPR2_CNT1,
	tics = 4,
	nextstate = S_FH_PANIC
}

states[freeslot "S_FH_WHIFF"] = {
	sprite = freeslot"SPR_MMWH",
	frame = A|FF_ANIMATE|FF_FULLBRIGHT,
	tics = G,
	var1 = G,
	var2 = 1,
	nextstate = S_NULL
}

states[freeslot "S_FH_THIK"] = {
	sprite = SPR_THIK,
	frame = A|TR_TRANS20,
	tics = 1,
	nextstate = S_FH_THIK
}

states[freeslot "S_FH_STUN"] = {
	sprite = SPR_PLAY,
	frame = SPR2_PAIN,
	tics = -1,
	nextstate = S_FH_STUN
}

states[freeslot "S_FH_CLASH"] = {
	sprite = SPR_PLAY,
	frame = SPR2_FALL,
	tics = -1,
	nextstate = S_PLAY_STND
}

states[freeslot "S_FH_GUARD"] = {
	sprite = SPR_PLAY,
	frame = SPR2_TRNS,
	tics = -1,
	nextstate = S_PLAY_WALK,
	action = A_ForceFrame,
	var1 = C
}

states[freeslot "S_FH_DROPDASH"] = {
	sprite = SPR_PLAY,
	frame = freeslot "SPR2_DRPD",
	tics = 2,
	nextstate = S_FH_DROPDASH
}

states[freeslot "S_FH_STOMP"] = {
	sprite = SPR_PLAY,
	frame = SPR2_FALL,
	tics = -1,
	nextstate = S_FH_STOMP
}

states[freeslot "S_FH_FLYRELEASE_HOLD"] = {
	sprite = SPR_PLAY,
	frame = SPR2_FLY_,
	tics = 2,
	nextstate = S_FH_FLYRELEASE_HOLD
}

states[freeslot "S_FH_FLYRELEASE"] = {
	sprite = SPR_PLAY,
	frame = SPR2_FLY_,
	tics = 1,
	nextstate = S_FH_FLYRELEASE_HOLD
}

states[freeslot "S_FH_FLYWINDUP"] = {
	sprite = SPR_PLAY,
	frame = SPR2_SPNG,
	tics = 1,
	nextstate = S_FH_FLYRELEASE
}

states[freeslot "S_FH_AMY_TWIRL"] = {
	sprite = SPR_PLAY,
	frame = freeslot "SPR2_TWRL",
	tics = 1,
	nextstate = S_FH_AMY_TWIRL
}

states[freeslot "S_FH_FANG_GUN_GRND2"] = {
	sprite = SPR_PLAY,
	frame = SPR2_FIRE,
	action = A_ForceFrame,
	var1 = D,
	tics = -1
}

states[freeslot "S_FH_FANG_GUN_GRND1"] = {
	sprite = SPR_PLAY,
	frame = SPR2_FIRE|FF_SPR2ENDSTATE,
	tics = 3,
	nextstate = S_FH_FANG_GUN_GRND1,
	var1 = S_FH_FANG_GUN_GRND2
}

states[freeslot "S_FH_FANG_GUN_AIR2"] = {
	sprite = SPR_PLAY,
	frame = SPR2_MLEE,
	tics = -1,
	action = A_ForceFrame,
	var1 = D
}

states[freeslot "S_FH_FANG_GUN_AIR1"] = {
	sprite = SPR_PLAY,
	frame = SPR2_MLEE|FF_SPR2ENDSTATE,
	tics = 3,
	nextstate = S_FH_FANG_GUN_AIR1,
	var1 = S_FH_FANG_GUN_AIR2
}

states[freeslot "S_FH_MS_DRIFT"] = {
	sprite = SPR_PLAY,
	frame = SPR2_SKID,
	tics = -1,
	nextstate = S_FH_MS_DRIFT
}

-- Amy Hammer
states[freeslot "S_FH_THROWNHAMMER"] = {
	sprite = freeslot "SPR_AHMR",
	frame = FF_ANIMATE,
	tics = -1,
	var1 = H,
	var2 = 1
}

states[freeslot "S_FH_MARVQUEEN"] = {
	sprite = freeslot "SPR_MAQU",
	frame = A,
	tics = -1
}

-- Mobjs
mobjinfo[freeslot "MT_FH_THIK"] = {
	spawnstate = S_FH_THIK,
	radius = 32*FU,
	height = 64*FU,
	flags = MF_NOBLOCKMAP|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY|MF_SCENERY
}

mobjinfo[freeslot "MT_FH_THROWNHAMMER"] = {
	spawnstate = S_FH_THROWNHAMMER,
	radius = 30*FU,
	height = 26*FU,
	flags = MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY
}

mobjinfo[freeslot "MT_FH_SIGN"] = {
	spawnstate = S_SIGN,
	flags = UNGRABBED_FLAGS,
	radius = 40*FU,
	height = mobjinfo[MT_SIGN].height
}

-- Sounds
for i = 1, 4 do
	sfxinfo[freeslot("sfx_dmga"..i)].caption = "Attack"
	sfxinfo[freeslot("sfx_dmgb"..i)].caption = "Attack"
end

for i = 1, 2 do
	sfxinfo[freeslot("sfx_parry"..i)].caption = "Parry"
end
sfxinfo[freeslot "sfx_fhclsh"].caption = "Clink!"

sfxinfo[freeslot "sfx_gogogo"].caption = "G-G-G-GO! GO! GO!"

sfxinfo[freeslot "sfx_cwdscr"].caption = "WOO!!!!! YAY!!!!!"

sfxinfo[freeslot "sfx_nargam"].caption = "GAME!"
sfxinfo[freeslot "sfx_narsud"].caption = "Sudden death..."
sfxinfo[freeslot "sfx_nartgw"].caption = "This game's winner is..."
sfxinfo[freeslot "sfx_narcon"].caption = "Congratulations!"

sfxinfo[freeslot "sfx_sbounc"].caption = "Bounce"

for i = 1, 3 do
	sfxinfo[freeslot("sfx_tlfly"..i)].caption = "Flight"
end

sfxinfo[freeslot "sfx_msdrft"].caption = "Drifting"

freeslot("sfx_fhwrn1","sfx_fhwrn2")