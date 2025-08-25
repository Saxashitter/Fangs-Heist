-- PORT FROM: MY OWN MOD!! Yes you can steal- i mean permanently borrow these ONLY WITH CREDIT! and by that i mean plaster my face all over your mod

-- Heist's Round 2 portal as of writing this comment is one of them portals in Ohio
-- So I use my own here

-- This function SHOULD reduce wasted freeslots?
local function SafeFreeSlot(...)
	for _,slot in ipairs({...}) do
		if not rawget(_G, slot) freeslot(slot) end
	end
end

SafeFreeSlot(
-- Skincolor
"SKINCOLOR_KOMBI_FROGSWITCH",
-- States
"S_WARSPORT","S_WARMPORT","S_WARLPORT","S_HURRYUP","S_COINLOSS",
-- Objects
"MT_WLPORTALSMALL_ALT","MT_WLPORTALMEDIUM_ALT","MT_WLPORTALLARGE_ALT","MT_KOMBIFROGSWITCH_ALT","MT_COINLOSSEFFECT","MT_FROGSWITCHANIMATOR_ALT","MT_WLPORTALSPAWNER",
-- Longsprites
"SPR_WLPS","SPR_WLPM","SPR_WLPL","SPR_KOMBIFROGSWITCH","SPR_WLC2","SPR_WL4STOPWATCH",
-- Wario's Voice (Hurry Up!)
"sfx_hurry0","sfx_hurry1","sfx_hurry2","sfx_hurry3","sfx_hurry4",
-- Kero SFX
"sfx_wlohno","sfx_wlclos",

-- WLCoins
"S_WARIOLAND10COIN","MT_WARIOLAND10COIN_ALT","SPR_WLC1","sfx_wlcoi1",
"S_WARIOLAND50COIN","MT_WARIOLAND50COIN_ALT","SPR_WLC2","sfx_wlcoi2",
"S_WARIOLAND100COIN","MT_WARIOLAND100COIN_ALT","SPR_WLC3","sfx_wlcoi3",
"S_WARIOLAND500COIN","MT_WARIOLAND500COIN_ALT","SPR_WLC4","sfx_wlcoi4"
)

-- My custom skincolor based off WL4's frog switch :DD
-- Also built for the Frog Switch's sprite... That's what we call proper planning
skincolors[SKINCOLOR_KOMBI_FROGSWITCH] = {
	name = "Frog Switched",
	ramp = {0,1,128,129,131,132,133,133,148,148,149,149,150,153,168,31},
	invcolor = SKINCOLOR_CRIMSON,
	invshade = 10,
	accessible = true
}

mobjinfo[MT_WLPORTALSMALL_ALT] = {
spawnstate = S_WARSPORT,
spawnhealth = 1000,
deathstate = S_WARSPORT,
radius = 24*FRACUNIT,
height = 48*FRACUNIT,
dispoffset = 5,
flags = MF_SCENERY|MF_NOGRAVITY|MF_NOCLIPHEIGHT,
}

mobjinfo[MT_WLPORTALMEDIUM_ALT] = {
spawnstate = S_WARMPORT,
spawnhealth = 1000,
deathstate = S_WARMPORT,
radius = 24*FRACUNIT,
height = 48*FRACUNIT,
dispoffset = 4,
flags = MF_SCENERY|MF_NOGRAVITY|MF_NOCLIPHEIGHT,
}

mobjinfo[MT_WLPORTALLARGE_ALT] = {
spawnstate = S_WARLPORT,
spawnhealth = 1000,
deathstate = S_WARLPORT,
radius = 24*FRACUNIT,
height = 48*FRACUNIT,
dispoffset = 3,
flags = MF_SCENERY|MF_NOGRAVITY|MF_NOCLIPHEIGHT|MF_SPECIAL,
}

mobjinfo[MT_KOMBIFROGSWITCH_ALT] = {
doomednum = 2048,
spawnstate = S_HURRYUP,
spawnhealth = 1000,
deathstate = S_HURRYUP,
radius = 12*FRACUNIT,
height = 36*FRACUNIT,
dispoffset = 3,
flags = MF_SCENERY|MF_NOGRAVITY|MF_NOCLIPHEIGHT|MF_SOLID,
}

mobjinfo[MT_FROGSWITCHANIMATOR_ALT] = {
spawnstate = S_HURRYUP,
spawnhealth = 1000,
deathstate = S_HURRYUP,
radius = 12*FRACUNIT,
height = 36*FRACUNIT,
dispoffset = 3,
flags = MF_SCENERY|MF_NOGRAVITY|MF_NOCLIPHEIGHT,
}

states[S_WARSPORT] = {
	sprite = SPR_WLPS,
	frame = FF_ANIMATE|A,
	tics = -1,
	var1 = 32,
	var2 = 10,
	nextstate = S_WARSPORT,
}

states[S_WARMPORT] = {
	sprite = SPR_WLPM,
	frame = FF_ANIMATE|A,
	tics = -1,
	var1 = 32,
	var2 = 10,
	nextstate = S_WARMPORT,
}

states[S_COINLOSS] = {
	sprite = SPR_WLC2,
	frame = FF_ANIMATE|A,
	tics = 36,
	var1 = 5,
	var2 = 2,
	nextstate = S_NULL,
}

states[S_WARLPORT] = {
	sprite = SPR_WLPL,
	frame = FF_ANIMATE|A,
	tics = -1,
	var1 = 32,
	var2 = 10,
	nextstate = S_WARLPORT,
}

states[S_HURRYUP] = {
	sprite = SPR_KOMBIFROGSWITCH,
	frame = A,
	tics = -1,
	var1 = 0,
	var2 = 0,
	nextstate = S_HURRYUP,
}

mobjinfo[MT_WARIOLAND500COIN_ALT] = {
spawnstate = S_WARIOLAND500COIN,
spawnhealth = 1000,
radius = 16*FRACUNIT,
height = 12*FRACUNIT,
dispoffset = 4,
flags = MF_SCENERY|MF_SPECIAL,
}

states[S_WARIOLAND500COIN] = {
	sprite = SPR_WLC4,
	frame = FF_ANIMATE|A,
	tics = -1,
	var1 = 6,
	var2 = 2,
	nextstate = S_WARIOLAND500COIN,
}

mobjinfo[MT_WARIOLAND100COIN_ALT] = {
spawnstate = S_WARIOLAND100COIN,
spawnhealth = 1000,
radius = 16*FRACUNIT,
height = 12*FRACUNIT,
dispoffset = 4,
flags = MF_SCENERY|MF_SPECIAL,
}

states[S_WARIOLAND100COIN] = {
	sprite = SPR_WLC3,
	frame = FF_ANIMATE|A,
	tics = -1,
	var1 = 5,
	var2 = 2,
	nextstate = S_WARIOLAND100COIN,
}

mobjinfo[MT_WARIOLAND50COIN_ALT] = {
spawnstate = S_WARIOLAND50COIN,
spawnhealth = 1000,
radius = 16*FRACUNIT,
height = 12*FRACUNIT,
dispoffset = 4,
flags = MF_SCENERY|MF_SPECIAL,
}

states[S_WARIOLAND50COIN] = {
	sprite = SPR_WLC2,
	frame = FF_ANIMATE|A,
	tics = -1,
	var1 = 5,
	var2 = 2,
	nextstate = S_WARIOLAND50COIN,
}

mobjinfo[MT_WARIOLAND10COIN_ALT] = {
spawnstate = S_WARIOLAND10COIN,
spawnhealth = 1000,
radius = 16*FRACUNIT,
height = 12*FRACUNIT,
dispoffset = 4,
flags = MF_SCENERY|MF_SPECIAL,
}

states[S_WARIOLAND10COIN] = {
	sprite = SPR_WLC1,
	frame = FF_ANIMATE|A,
	tics = -1,
	var1 = 3,
	var2 = 2,
	nextstate = S_WARIOLAND10COIN,
}