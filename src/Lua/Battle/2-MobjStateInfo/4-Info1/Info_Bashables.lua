freeslot(
	"mt_chessknight",
	"mt_chessking",
	"mt_chessqueen",
	"mt_chesspawn",
	"s_chessknight",
	"s_chessking",
	"s_chessqueen",
	"s_chesspawn",
	"spr_chss",
	"mt_sparringdummy",
	"s_tailsdoll1",
	"s_tailsdoll2",
	"s_tailsdoll3",
	"spr_tdol",
	"s_colorcommander1",
	"s_colorcommander2",
	"s_colorcommander3",	
	"spr_gcom",
	"mt_bashboulder",
	"mt_battleball"
)


//Sparring dummy
mobjinfo[MT_SPARRINGDUMMY] = {
	//$Name "BattleMod Sparring Dummy"
	//$Sprite GCOMA1
	//$Category "BattleMod Bashable Objects"
	doomednum = 3650,           
	spawnstate = S_TAILSDOLL1, 
	spawnhealth = 1000,
	radius = 16*FRACUNIT,
	height = 40*FRACUNIT,
	flags = MF_SLIDEME|MF_SPECIAL|MF_ENEMY|MF_SHOOTABLE
}
mobjinfo[MT_SPARRINGDUMMY].battle_bashable	= true
mobjinfo[MT_SPARRINGDUMMY].battle_sentient	= true
mobjinfo[MT_SPARRINGDUMMY].battle_smooth	= false

states[S_COLORCOMMANDER1] = {
	sprite = SPR_GCOM,
	frame = A,
	nextstate = S_COLORCOMMANDER2,
	tics = 1
}
states[S_COLORCOMMANDER2] = {
	sprite = SPR_GCOM,
	frame = B,
	nextstate = S_COLORCOMMANDER1,
	tics = 1
}
states[S_COLORCOMMANDER3] = {
	sprite = SPR_GCOM,
	frame = C,
	nextstate = S_COLORCOMMANDER3
}


states[S_TAILSDOLL1] = {
	sprite = SPR_TDOL,
	frame = A,
	nextstate = S_TAILSDOLL1
}
states[S_TAILSDOLL2] = {
	sprite = SPR_TDOL,
	frame = B,
	nextstate = S_TAILSDOLL2
}

//Chess Knight
mobjinfo[MT_CHESSKNIGHT] = {
	//$Name "Chess Knight"
	//$Sprite CHSSA3A7
	//$Category "BattleMod Bashable Objects"
	doomednum = 3651,
	spawnstate = S_CHESSKNIGHT,
	spawnhealth = 1000,
	radius = 24*FRACUNIT,
	height = 96*FRACUNIT,
	damage = 1,
	activesound = sfx_statu2,
	flags = MF_SLIDEME|MF_SOLID|MF_PUSHABLE
}
mobjinfo[MT_CHESSKNIGHT].battle_bashable	= true
mobjinfo[MT_CHESSKNIGHT].battle_weight		= 80
mobjinfo[MT_CHESSKNIGHT].battle_friction	= 2
mobjinfo[MT_CHESSKNIGHT].battle_smooth		= true

mobjinfo[MT_CHESSKING] = {
	//$Name "Chess King"
	//$Sprite CHSSB0
	//$Category "BattleMod Bashable Objects"
	doomednum = 3652,
	spawnstate = S_CHESSKING,
	spawnhealth = 1000,
	radius = 24*FRACUNIT,
	height = 108*FRACUNIT,
	damage = 1,
	activesound = sfx_statu2,
	flags = MF_SLIDEME|MF_SOLID|MF_PUSHABLE
}
mobjinfo[MT_CHESSKING].battle_bashable		= true
mobjinfo[MT_CHESSKING].battle_weight		= 100
mobjinfo[MT_CHESSKING].battle_friction		= 5
mobjinfo[MT_CHESSKING].battle_smooth		= true

mobjinfo[MT_CHESSQUEEN] = {
	//$Name "Chess Queen"
	//$Sprite CHSSC0
	//$Category "BattleMod Bashable Objects"
	doomednum = 3653,
	spawnstate = S_CHESSQUEEN,
	spawnhealth = 1000,
	radius = 24*FRACUNIT,
	height = 108*FRACUNIT,
	damage = 1,
	activesound = sfx_statu2,
	flags = MF_SLIDEME|MF_SOLID|MF_PUSHABLE
}
mobjinfo[MT_CHESSQUEEN].battle_bashable		= true
mobjinfo[MT_CHESSQUEEN].battle_weight		= 100
mobjinfo[MT_CHESSQUEEN].battle_friction		= 1
mobjinfo[MT_CHESSQUEEN].battle_smooth		= true

mobjinfo[MT_CHESSPAWN] = {
	//$Name "Chess Pawn"
	//$Sprite CHSSD0
	//$Category "BattleMod Bashable Objects"
	doomednum = 3654,
	spawnstate = S_CHESSPAWN,
	spawnhealth = 1000,
	radius = 24*FRACUNIT,
	height = 72*FRACUNIT,
	damage = 1,
	activesound = sfx_statu2,
	flags = MF_SLIDEME|MF_SOLID|MF_PUSHABLE
}
mobjinfo[MT_CHESSPAWN].battle_bashable		= true
mobjinfo[MT_CHESSPAWN].battle_weight		= 60
mobjinfo[MT_CHESSPAWN].battle_friction		= 3
mobjinfo[MT_CHESSPAWN].battle_smooth		= true


-- {sprite, frame, tics, action, var1, var2, nextstate}
states[S_CHESSKNIGHT] = {
	sprite = SPR_CHSS,
	frame = A,
	nextstate = S_CHESSKNIGHT
}

states[S_CHESSKING] = {
	sprite = SPR_CHSS,
	frame = B,
	nextstate = S_CHESSKING
}

states[S_CHESSQUEEN] = {
	sprite = SPR_CHSS,
	frame = C,
	nextstate = S_CHESSQUEEN
}

states[S_CHESSPAWN] = {
	sprite = SPR_CHSS,
	frame = D,
	nextstate = S_CHESSPAWN
}

//Bash Boulder
mobjinfo[MT_BASHBOULDER] = {
	//$Name "Bashable Boulder"
	//$Sprite PUMIA1A5
	//$Category "BattleMod Bashable Objects"
	doomednum = 3655,
	spawnstate = S_ROLLOUTROCK,
	reactiontime = 8,
	painchance = 0,
	painsound = sfx_s3k49,
	spawnhealth = 1000,
	speed = 32*FRACUNIT,
	radius = 30*FRACUNIT,
	height = 60*FRACUNIT,
	mass = 100,
	damage = 0,
	flags = MF_PUSHABLE|MF_SOLID|MF_SLIDEME
}
mobjinfo[MT_BASHBOULDER].battle_bashable	= true
mobjinfo[MT_BASHBOULDER].battle_weight		= 60
mobjinfo[MT_BASHBOULDER].battle_friction	= 3
mobjinfo[MT_BASHBOULDER].battle_smooth		= true

--Snowman
mobjinfo[MT_SNOWMAN].battle_bashable		= true
mobjinfo[MT_SNOWMAN].battle_smooth			= true

--Snowman w/ hat
mobjinfo[MT_SNOWMANHAT].battle_bashable		= true
mobjinfo[MT_SNOWMANHAT].battle_smooth		= true

//Bash Boulder
mobjinfo[MT_BATTLEBALL] = {
	//$Name "Battleball"
	//$Sprite PUMIA1A5
	//$Category "BattleMod Bashable Objects"
	doomednum = 3656,
	spawnstate = S_ROLLOUTROCK,
	reactiontime = 8,
	painchance = 0,
	painsound = sfx_s3k49,
	spawnhealth = 1000,
	speed = 32*FRACUNIT,
	radius = 30*FRACUNIT,
	height = 60*FRACUNIT,
	mass = 100,
	damage = 0,
	flags = MF_SLIDEME|MF_SPECIAL--|MF_SOLID|MF_PUSHABLE
}
mobjinfo[MT_BATTLEBALL].battle_bashable		= true
mobjinfo[MT_BATTLEBALL].battle_weight		= 40
mobjinfo[MT_BATTLEBALL].battle_friction		= 1
mobjinfo[MT_BATTLEBALL].battle_smooth		= true
mobjinfo[MT_BATTLEBALL].battle_bounce		= 70
