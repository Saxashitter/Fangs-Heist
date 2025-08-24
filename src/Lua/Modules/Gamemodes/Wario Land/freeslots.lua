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
"MT_WLPORTALSMALL","MT_WLPORTALMEDIUM","MT_WLPORTALLARGE","MT_KOMBIFROGSWITCH","MT_COINLOSSEFFECT","MT_FROGSWITCHANIMATOR","MT_WLPORTALSPAWNER",
-- Longsprites
"SPR_WLPS","SPR_WLPM","SPR_WLPL","SPR_KOMBIFROGSWITCH","SPR_WLC2","SPR_WL4STOPWATCH",
-- Wario's Voice (Hurry Up!)
"sfx_hurry0","sfx_hurry1","sfx_hurry2","sfx_hurry3","sfx_hurry4",
-- Kero SFX
"sfx_wlohno","sfx_wlclos"
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

mobjinfo[MT_WLPORTALSMALL] = {
spawnstate = S_WARSPORT,
spawnhealth = 1000,
deathstate = S_WARSPORT,
radius = 24*FRACUNIT,
height = 48*FRACUNIT,
dispoffset = 5,
flags = MF_SCENERY|MF_NOGRAVITY|MF_NOCLIPHEIGHT,
}

mobjinfo[MT_WLPORTALMEDIUM] = {
spawnstate = S_WARMPORT,
spawnhealth = 1000,
deathstate = S_WARMPORT,
radius = 24*FRACUNIT,
height = 48*FRACUNIT,
dispoffset = 4,
flags = MF_SCENERY|MF_NOGRAVITY|MF_NOCLIPHEIGHT,
}

mobjinfo[MT_WLPORTALLARGE] = {
spawnstate = S_WARLPORT,
spawnhealth = 1000,
deathstate = S_WARLPORT,
radius = 24*FRACUNIT,
height = 48*FRACUNIT,
dispoffset = 3,
flags = MF_SCENERY|MF_NOGRAVITY|MF_NOCLIPHEIGHT|MF_SPECIAL,
}

mobjinfo[MT_WLPORTALSPAWNER] = {
doomednum = 2049,
spawnstate = S_WARLPORT,
spawnhealth = 1000,
deathstate = S_WARLPORT,
radius = 24*FRACUNIT,
height = 48*FRACUNIT,
dispoffset = 3,
flags = MF_SCENERY|MF_NOGRAVITY|MF_NOCLIPHEIGHT|MF_SPECIAL,
}

mobjinfo[MT_KOMBIFROGSWITCH] = {
doomednum = 2048,
spawnstate = S_HURRYUP,
spawnhealth = 1000,
deathstate = S_HURRYUP,
radius = 12*FRACUNIT,
height = 36*FRACUNIT,
dispoffset = 3,
flags = MF_SCENERY|MF_NOGRAVITY|MF_NOCLIPHEIGHT|MF_SOLID,
}

mobjinfo[MT_FROGSWITCHANIMATOR] = {
spawnstate = S_HURRYUP,
spawnhealth = 1000,
deathstate = S_HURRYUP,
radius = 12*FRACUNIT,
height = 36*FRACUNIT,
dispoffset = 3,
flags = MF_SCENERY|MF_NOGRAVITY|MF_NOCLIPHEIGHT,
}