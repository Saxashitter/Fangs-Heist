local B = CBW_Battle
local CV = B.Console

CV.Debug = CV_RegisterVar{
	name = "battledebug",
	defaultvalue = 0,
	flags = CV_NETVAR,
	PossibleValue = {MIN = 0, MAX = 31}
}
//See Lib_Debug for debug flag names

CV.DevCamera = CV_RegisterVar{
	name = "devcam",
	defaultvalue = 0,
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff
}


COM_AddCommand("test",function(player)
	if B.TestScript then
		print("Executing test script")
		B.TestScript(player)
	else
		CONS_Printf(player,"No test script available for loading.")
	end
end,1)