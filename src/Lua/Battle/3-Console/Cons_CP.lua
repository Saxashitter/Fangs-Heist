local B = CBW_Battle
local CV = B.Console
local CP = B.ControlPoint

//CP Variables
CV.CPMeter = CV_RegisterVar{
	name = "cp_meter",
	defaultvalue = 0,
	flags = CV_NETVAR,
	PossibleValue = {MIN = 0, MAX = 15}
}

CV.CPWait = CV_RegisterVar{
	name = "cp_wait",
	defaultvalue = 30,
	flags = CV_NETVAR,
	PossibleValue = {MIN = 10, MAX = 255}
}

CV.CPBonus = CV_RegisterVar{
	name = "cp_bonus",
	defaultvalue = 500,
	flags = CV_NETVAR,
	PossibleValue = {MIN = 0, MAX = 100000}
}

CV.CPRadius = CV_RegisterVar{
	name = "cp_radius",
	defaultvalue = 0,
	flags = CV_NETVAR,
	PossibleValue = {MIN = 0, MAX = 359}
}

CV.CPHeight = CV_RegisterVar{
	name = "cp_height",
	defaultvalue = 0,
	flags = CV_NETVAR,
	PossibleValue = {MIN = -1, MAX = 4}
}

CV.CPSpawnBounce = CV_RegisterVar{
	name = "cp_spawnbounce",
	defaultvalue = 1,
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff
}

CV.CPSpawnAuto = CV_RegisterVar{
	name = "cp_spawnauto",
	defaultvalue = 1,
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff
}

CV.CPSpawnScatter = CV_RegisterVar{
	name = "cp_spawnscatter",
	defaultvalue = 1,
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff
}

CV.CPSpawnBomb = CV_RegisterVar{
	name = "cp_spawnbomb",
	defaultvalue = 1,
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff
}

CV.CPSpawnGrenade = CV_RegisterVar{
	name = "cp_spawngrenade",
	defaultvalue = 1,
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff
}

CV.CPSpawnRail = CV_RegisterVar{
	name = "cp_spawnrail",
	defaultvalue = 0,
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff
}

CV.CPSpawnInfinity = CV_RegisterVar{
	name = "cp_spawninfinity",
	defaultvalue = 0,
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff
}

COM_AddCommand("cp_create", function(player, ...)
	local defaulttext = "cp_create <radius 0 to 359> <height -1 to 4> <meter 0 to 15> <flip 0/1>"
	//Not enough arguments
	if ... == nil then
		CONS_Printf(player,defaulttext)
	return end
	local args = {}
	local n = 1
	for _,i in ipairs{...}
		args[n] = i
		n = $+1
	end
	if not(#args >= 4)
		CONS_Printf(player,defaulttext)
	return end
	//Not in CP gametype
	if not(B.CPGametype()) then
		CONS_Printf(player,"This command can only be used in a Control Point gametype!")
	return end
	//Player object not valid
	if not(player and player.valid and player.realmo and player.realmo.valid) then
		CONS_Printf(player,"You must be inside a game to use this command.")
	return end
	//Execute
	local pmo = player.realmo
	local mo = P_SpawnMobj(pmo.x,pmo.y,pmo.z,MT_CONTROLPOINT)
	if mo and mo.valid then
		mo.cp_radius = CP.CalcRadius(tonumber(args[1]))
		mo.cp_height = CP.CalcHeight(tonumber(args[2]))
		mo.cp_meter = CP.CalcMeter(tonumber(args[3]))
		local flip = 0
		if tonumber(args[4]) then
			mo.eflags = $|MFE_VERTICALFLIP
			flip = 1
		end
		local fu = FRACUNIT
		CP.ID[#CP.ID+1] = mo
		print("Control Point #"..#CP.ID.." created at coordinates "..mo.x/fu..","..mo.y/fu..","..mo.z/fu
			..",\n  radius "..mo.cp_radius/fu..", height "..mo.cp_height/fu..", meter "..mo.cp_meter..", flip "..flip)
	end
end,1)

local function Wrap(num,size)
	if num > size then
		num = $-size
	end
	return num
end

COM_AddCommand("cp_next", function(player)
	//Not in CP gametype
	if not(B.CPGametype()) then
		CONS_Printf(player,"This command can only be used in a Control Point gametype!")
	return end
	//Player object not valid
	if not(player and player.valid and player.realmo and player.realmo.valid) then
		CONS_Printf(player,"You must be inside a game to use this command.")
	return end
	//Execute
	CP.Num = Wrap($+1,#CP.ID)
	CONS_Printf(player,"Remote activating Control Point #"..CP.Num)
	CP.ActivatePoint()
end, 1)

COM_AddCommand("cp_shuffle", function(player)
	//Not in CP gametype
	if not(B.CPGametype()) then
		CONS_Printf(player,"This command can only be used in a Control Point gametype!")
	return end
	//Player object not valid
	if not(player and player.valid and player.realmo and player.realmo.valid) then
		CONS_Printf(player,"You must be inside a game to use this command.")
	return end
	CP.Shuffle()
	print("Shuffled all CP ids")
end, 1)