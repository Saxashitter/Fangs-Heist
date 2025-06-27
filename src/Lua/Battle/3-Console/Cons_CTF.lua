local CV = CBW_Battle.Console

CV.CTFdropgrace = CV_RegisterVar{
	name = "ctf_flagdrop_graceperiod",
	defaultvalue = 2,
	flags = CV_NETVAR,
	PossibleValue = {MIN = 0, MAX = 3}
}

CV.CTFrespawngrace = CV_RegisterVar{
	name = "ctf_flagrespawn_graceperiod",
	defaultvalue = 6,
	flags = CV_NETVAR,
	PossibleValue = {MIN = 0, MAX = 15}
}