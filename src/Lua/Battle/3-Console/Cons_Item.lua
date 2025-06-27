local B = CBW_Battle
local I = B.Item
local CV = B.Console

CV.ItemRate = CV_RegisterVar{
	name = "item_rate",
	defaultvalue = 2,
	flags = CV_NETVAR,
	PossibleValue = {MIN = 1, MAX = 3}
}

CV.ItemGlobalSpawn = CV_RegisterVar{
	name = "item_global",
	defaultvalue = 1,
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff
}

CV.ItemLocalSpawn = CV_RegisterVar{
	name = "item_local",
	defaultvalue = 1,
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff
}

CV.ItemType = CV_RegisterVar{
	name = "item_type",
	defaultvalue = -1,
	flags = CV_NETVAR,
	PossibleValue = {MIN = -1, MAX = 16}
}