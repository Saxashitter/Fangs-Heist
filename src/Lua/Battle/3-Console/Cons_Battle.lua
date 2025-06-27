local CV = CBW_Battle.Console
//Battle Variables
CV.Collision = CV_RegisterVar{
	name = "battle_collision",
	defaultvalue = 0,
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff
}

CV.LaunchFactor = CV_RegisterVar{
	name = "battle_launchfactor",
	defaultvalue = 7,
	flags = CV_NETVAR,
	PossibleValue = {MIN = 1, MAX = 20}
}

CV.Slipstream = CV_RegisterVar{
	name = "battle_slipstream",
	defaultvalue = 1,
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff
}

CV.Actions = CV_RegisterVar{
	name = "battle_special",
	defaultvalue = 1,
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff
}

CV.ShieldStock = CV_RegisterVar{
	name = "battle_shieldstock",
	defaultvalue = 1,
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff
}

CV.PreRound = CV_RegisterVar{
	name = "battle_preround",
	defaultvalue = 1,
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff
}

CV.Guard = CV_RegisterVar{
	name = "battle_guard",
	defaultvalue = 1,
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff
}

CV.TailsDoll = CV_RegisterVar{
	name = "battle_training",
	defaultvalue = 1,
	flags = CV_NETVAR,
	PossibleValue = {MIN = 0, MAX = 2}
}

CV.RespawnTime = CV_RegisterVar{
	name = "battle_maxrespawntime",
	defaultvalue = 10,
	flags = CV_NETVAR,
	PossibleValue = {MIN = 3, MAX = 30}
}