local CV = CBW_Battle.Console

CV.DiamondCaptureTime = CV_RegisterVar{
	name = "diamond_capture_time",
	defaultvalue = 30,
	flags = CV_NETVAR,
	PossibleValue = {MIN = 10, MAX = 60}
}

CV.DiamondCaptureBonus = CV_RegisterVar{
	name = "diamond_capture_bonus",
	defaultvalue = 1000,
	flags = CV_NETVAR,
	PossibleValue = {MIN = 0, MAX = 100000}
}