freeslot(
	"mt_item_bubble",
	"mt_item_bubble_overlay",
	"s_item_bubble",
	
	"mt_item_prespawn",
	"s_item_prespawn1",
	"s_item_prespawn2",
	
	"mt_item_spawn"
)

//Bubble pre-spawn telegraph
mobjinfo[MT_ITEM_PRESPAWN] = {
        doomednum = -1,
        spawnstate = S_ITEM_PRESPAWN1,
        spawnhealth = 1,
        seestate = S_ITEM_PRESPAWN1,
        seesound = sfx_None,
        reactiontime = 40,
        attacksound = sfx_None,
        painstate = S_NULL,
        painchance = 0,
        painsound = sfx_None,
        meleestate = S_NULL,
        missilestate = S_NULL,
        xdeathstate = S_NULL,
        speed = 1,
        radius = 8*FRACUNIT,
        height = 20*FRACUNIT,
        dispoffset = 0,
        mass = 100,
        activesound = sfx_None,
        flags = MF_SPECIAL|MF_NOGRAVITY|MF_BOUNCE|MF_NOBLOCKMAP,
        raisestate = S_NULL
}

states[S_ITEM_PRESPAWN1] = {
        sprite = SPR_BUBL,
        frame = FF_FULLBRIGHT|TR_TRANS40|A,
        nextstate = S_ITEM_BUBBLE
}

states[S_ITEM_PRESPAWN2] = {
        sprite = SPR_BUBL,
        frame = FF_FULLBRIGHT|TR_TRANS40|B,
        nextstate = S_ITEM_BUBBLE
}

//Item Bubble Object
mobjinfo[MT_ITEM_BUBBLE] = {
        doomednum = -1,
        spawnstate = 1,
        spawnhealth = 1,
        seestate = S_RING, //Item animation overrides
        reactiontime = 40,
        painchance = 0,
        speed = 1,
        radius = 18*FRACUNIT,
        height = 40*FRACUNIT,
        dispoffset = 0,
        mass = 100,
        activesound = sfx_None,
        flags = MF_SPECIAL|MF_NOGRAVITY,
        raisestate = S_NULL
}

//Item Bubble's Graphical Overlay Object
mobjinfo[MT_ITEM_BUBBLE_OVERLAY] = {
        spawnstate = S_ITEM_BUBBLE,
        spawnhealth = 1,
        radius = 18*FRACUNIT,
        dispoffset = 1,
        activesound = sfx_None,
        flags = MF_NOGRAVITY|MF_NOCLIPHEIGHT|MF_NOBLOCKMAP,
        raisestate = S_NULL
}

//Item Bubble State
states[S_ITEM_BUBBLE] = {
        sprite = SPR_BUBL,
        frame = FF_FULLBRIGHT|TR_TRANS40|E,
--         tics = 1,
--         action = A_MoveRelative,
--         var1 = 0,
--         var2 = 5,
        nextstate = S_ITEM_BUBBLE
}

//Item Bubble Spawns
mobjinfo[MT_ITEM_SPAWN] = {
        doomednum = -1, //Custom/Debug spawned
        spawnstate = 1,
        spawnhealth = 1,
        seestate = 1,
        reactiontime = 40,
        radius = 32*FRACUNIT,
        height = 40*FRACUNIT,
        dispoffset = 0,
        mass = 100,
        activesound = sfx_None,
        flags = MF_NOGRAVITY|MF_NOCLIPHEIGHT|MF_NOBLOCKMAP|MF_SCENERY,
        raisestate = S_NULL
}

