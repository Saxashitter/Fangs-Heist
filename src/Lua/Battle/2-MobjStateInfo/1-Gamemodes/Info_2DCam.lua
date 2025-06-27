--
-- Resource file for Mobj objects, states and sounds
-- 
-- By Flame
-- 3/24/20
--


freeslot("MT_PLAYCAM")
freeslot("MT_CAMMIN")
freeslot("MT_CAMMAX")

--Let's get started!
local thing

thing = MT_PLAYCAM
mobjinfo[thing].spawnstate = S_INVISIBLE
mobjinfo[thing].radius = 16*FRACUNIT
mobjinfo[thing].height = 16*FRACUNIT
mobjinfo[thing].flags = MF_NOBLOCKMAP|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY|MF_SCENERY

mobjinfo[MT_CAMMIN] = {
	//$Name "2D Camera Start"
	//$Category "BattleMod Camera"
	doomednum = 3095,
	spawnstate = S_INVISIBLE,
	radius = 16*FRACUNIT,
	height = 16*FRACUNIT,
	flags = MF_NOBLOCKMAP|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY|MF_SCENERY
}
mobjinfo[MT_CAMMAX] = {
	//$Name "2D Camera End"
	//$Category "BattleMod Camera"
	doomednum = 3096,
	spawnstate = S_INVISIBLE,
	radius = 16*FRACUNIT,
	height = 16*FRACUNIT,
	flags = MF_NOBLOCKMAP|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY|MF_SCENERY
}