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

--Sprites
freeslot "SPR2_FHBN"

-- States
states[freeslot "S_FH_PANIC"] = {
	sprite = SPR_PLAY,
	frame = SPR2_CNT1,
	tics = 4,
	nextstate = S_FH_PANIC
}

mobjinfo[freeslot "MT_FH_SIGN"] = {
	spawnstate = S_SIGN,
	flags = UNGRABBED_FLAGS,
	radius = 40*FU,
	height = mobjinfo[MT_SIGN].height
}

-- Sounds
for i = 1,4 do
	sfxinfo[freeslot("sfx_dmga"..i)].caption = "Attack"
	sfxinfo[freeslot("sfx_dmgb"..i)].caption = "Attack"
end
for i = 1,2 do
	sfxinfo[freeslot("sfx_parry"..i)].caption = "Parry"
end
sfxinfo[freeslot "sfx_fhclsh"].caption = "Clink!"

sfxinfo[freeslot "sfx_gogogo"].caption = "G-G-G-GO! GO! GO!"

sfxinfo[freeslot "sfx_cwdscr"].caption = "WOO!!!!! YAY!!!!!"

sfxinfo[freeslot "sfx_nargam"].caption = "GAME!"
sfxinfo[freeslot "sfx_narsud"].caption = "Sudden death..."
sfxinfo[freeslot "sfx_nartgw"].caption = "This game's winner is..."
sfxinfo[freeslot "sfx_narcon"].caption = "Congratulations!"

freeslot("sfx_fhwrn1","sfx_fhwrn2")