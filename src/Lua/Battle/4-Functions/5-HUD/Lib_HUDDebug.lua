local B = CBW_Battle
local CV = B.Console
local A = B.Arena
local D = B.Diamond
local CP = B.ControlPoint
local I = B.Item
local S = B.SkinVars

local scroll = 0

local scroll = CV_RegisterVar(
	{
		name = "battledebug_offset", 
		defaultvalue = 0, 
		flags = 0, 
		PossibleValue = { MIN = 0, MAX = 200 }
	}
)

B.DebugHUD = function(v, player, cam)
	local debug = CV.Debug.value	
	if ((not B.VersionPublic) or debug)
		local flags = V_ALLOWLOWERCASE|V_HUDTRANS|V_SNAPTORIGHT|V_SNAPTOTOP
		local flags2 = V_ALLOWLOWERCASE|V_HUDTRANSHALF|V_SNAPTORIGHT|V_SNAPTOTOP
		local xx = v.width()/v.dupx()
		local align = "small-right"
		v.drawString(320,	-4*scroll.value,	"v"..B.VersionNumber.."."..B.VersionSub.." [\x82"..B.VersionCommit.."\x80]\n",	flags,	align)
		v.drawString(317,	4 - 4*scroll.value,	B.VersionBranch,																flags2,	align)
		v.drawString(317,	8 - 4*scroll.value,	B.VersionDate.." ["..B.VersionTime.."]",										flags2,	align)
	end

	if not(debug) then return end
	
	local xoffset = 320
	local yoffset = 14 - 4*scroll.value
	local flags = V_HUDTRANS|V_SNAPTOTOP|V_SNAPTORIGHT|V_PERPLAYER
	local align = "small-right"
	local nextline = 4
	local mo = player.mo or player.realmo
	--Double the scale for smaller screens (illegible otherwise)
	if v.height() < 400 then 
		align = "right"
		nextline = 8
	end
	local addspace = function()
		yoffset = $+nextline
	end
	local addline = function(string,string2)
		string = "\x86"+tostring($)+": \x80"+tostring(string2)
		v.drawString(xoffset,yoffset,string,flags,align)
		yoffset = $+nextline
	end
	local addheader = function(string)
		yoffset = $+nextline
		string = "\x82"+string
		v.drawString(xoffset,yoffset,string,flags,align)
		yoffset = $+nextline
	end
	local subheader = function(string)
		string = "\x88"+string
		v.drawString(xoffset,yoffset,string,flags,align)
		yoffset = $+nextline
	end
	--****
	--Execute drawing
	--****
	if B.ArenaGametype() then
		--Making room for Arena's HUD
		addspace()
		addspace()
	end
	--Gametypes
	if debug&DF_GAMETYPE then
		local onlyflag = (debug&DF_GAMETYPE == DF_GAMETYPE)
		if onlyflag
			addline("EXE Loaded", MODID == 20)
			addline("AI Loaded", BATTLE_AI_LOADED)
			addline("Skins Loaded", BATTLE_SKINS_LOADED)
			addline("Campaign Loaded", BATTLE_CAMPAIGN_LOADED)
		end
		
		addheader("Gametype")
		if onlyflag or gametyperules & GTR_TEAMS
			addline("RedScore",B.RedScore)
			addline("BlueScore",B.BlueScore)
		end
		if onlyflag or gametyperules & GTR_TIMELIMIT
			addline("Pinch",B.Pinch)
			addline("Overtime",B.Overtime)
			addline("SuddenDeath",B.SuddenDeath)
			addline("PinchTics",B.PinchTics)
		end
		addline("Exiting",B.Exiting)
		
		if B.BattleCampaign() then
			subheader("Campaign")
			addline("QueueFighters",#B.QueueFighters)
			addline("Horde",B.Horde)
		end
		
		if B.ArenaGametype() then
			subheader("Arena")
			addline("Fighters",#A.Fighters)
			addline("RedFighters",#A.RedFighters)
			addline("BlueFighters",#A.BlueFighters)
			addline("Survivors",#A.Survivors)
			addline("RedSurvivors",#A.RedSurvivors)
			addline("BlueSurvivors",#A.BlueSurvivors)
			addline("SpawnLives",A.SpawnLives)
			addline("GameOvers",A.GameOvers)
		end
		
		if B.CPGametype() then
			subheader("Control Point")
			addline("IDs",#CP.ID)
			addline("Num",CP.Num)
			addline("ActiveCount",CP.ActiveCount)
		end
		
		if B.DiamondGametype() then
			subheader("Diamond")
			addline("Spawnpoints",#D.Spawns)
			addline("Spawned",(D.ID != nil and D.ID.valid))
			if(D.ID and D.ID.valid and D.ID.target and D.ID.target.player) then
				addline("Holder",(D.ID.target.player.name))
			end
			if(D.ID and D.ID.valid) then
				addline("Idle",(D.ID.idle))
			end
		end
	end
	
	--Items	
	if debug&DF_ITEM
		addheader("Items")
		addline("Global Spawns",#I.Spawns)
		addline("Global Timer",I.SpawnTimer/TICRATE.."/"..(4-CV.ItemRate.value)*I.GlobalRate/2)
		addline("GlobalChance Entries",#I.GlobalChance)
		addline("Global Item Rate",I.GlobalRate)
		addline("Local Item Rate",I.LocalRate)
		addline("Item Type",CV.ItemType.value)
	end
	
	--Player
	if debug&DF_PLAYER
		if player.mo and player.mo.eggchampionvars and debug == DF_PLAYER
			local vars = player.mo.eggchampionvars
			addheader("Egg Champion")
			addline("mode", vars.mode)
			addline("state", vars.state)
			addline("tics", vars.tics)
			addline("cycle", vars.cycle)
			addline("shieldhp", vars.shieldhp)
			for n,arm in pairs(vars.arms) do
				if not(arm and arm.valid) continue end
				subheader(n.." Arm")
				addline("side", arm.side)
				addline("chain", #arm.chain)
				addline("armtype", arm.armtype)
				addline("attackstate", arm.attackstate)
				addline("attacktics", arm.attacktics)
				addline("owner", arm.owner)
				addline("target", arm.target)
				addline("shield", arm.shield)
				addline("ready", arm.ready)
			end
			addline("activespecial", vars.activespecial)
			addline("specials", #vars.specials)
		end
		addheader("Player")
		addline("SkinVars",player.skinvars)
		addline("SkinVars.flags",B.GetSkinVarsFlags(player))
		addline("Rank",player.rank)
		addline("PreserveScore",player.preservescore)
		addline("Exhaust",player.exhaustmeter*100/FRACUNIT.."%")
		addline("Revenge",player.revenge)
		addline("LifeShards",player.lifeshards)
		addline("IsEggRobo",player.iseggrobo)
		addline("IsJettySyn",player.isjettysyn)
-- 			addline("Carry_ID",player.carry_id)
-- 			addline("Carried_Time",player.carried_time)
		addline("BattleSpawning",player.battlespawning)
		addline("SpectatorTime",player.spectatortime)
		addline("DeadTimer",player.deadtimer)
		addline("RespawnPenalty",player.respawnpenalty)
		addline("Intangible",player.intangible)
		addline("AirGun",player.airgun)
		addline("Tumble",player.tumble)
		addline("ReflectArmor",player.reflectarmor)
		
		subheader("Action")
		addline("Allowed",player.actionallowed)
		addline("super",player.actionsuper)
		addline("state",player.actionstate)
		addline("time",player.actiontime)
		addline("rings",player.actionrings)
		--addline("debt",player.actiondebt)
		addline("cooldown",player.actioncooldown)
		
		subheader("Battle")
		addline("sfunc",player.battle_sfunc)
		addline("atk",player.battle_atk)
		addline("def",player.battle_def)
		addline("satk",player.battle_satk)
		addline("sdef",player.battle_sdef)
		addline("text",player.battle_hurttxt)
		
		subheader("Guard")
		addline("CanGuard",player.canguard)
		addline("guard",player.guard)
		addline("guardtics",player.guardtics)
		
		if player.mo and player.mo.valid then
			subheader("General")
			addline("ID",player.mo)
			addline("target",player.mo.target)
			addline("tracer",player.mo.tracer)
			addline("Carry",player.powers[pw_carry])
			addline("Flashing",player.powers[pw_flashing])
			addline("NoControl",player.powers[pw_nocontrol])
			addline("Exiting",player.exiting)
			addline("JumpFactor",player.jumpfactor)
			addline("ThrustFactor",player.thrustfactor)
			addline("Lock Aim",player.lockaim)
			addline("Lock Move",player.lockmove)
			addline("Pushed Credit",player.pushed_creditplr)
		end
	end
	
	--Collision
	if debug&DF_COLLISION
		addheader("Collision")
		if player and player.valid and player.mo and player.mo.valid then
			subheader("player.mo")
			addline("pushed_last",player.mo.pushed_last)
			addline("pushtics",player.mo.pushtics)
			addline("weight",player.mo.weight*100/FRACUNIT.."%")
		end
		local T = B.TrainingDummy
		if T and T.valid then
			subheader("Training Dummy")
			addline("Hits",B.HitCounter)
			addline("Fuse",T.fuse)
			addline("Pain",T.pain)
			addline("AI",T.ai)
			addline("Attacking",T.attacking)
			addline("Phase",T.phase)
			addline("Invisibility",(T.flags&MF_NOCLIPTHING))
		end
	end

	if debug&DF_CAMERA
		addheader("Camera")
		local c = player == displayplayer and B.Camera[1]
			or player == secondarydisplayplayer and B.Camera[2]
			or nil
		if c
			addline("player",c.player and c.player.name)
			addline("scale",(c.scale or 0)*100/FRACUNIT.."%")
			addline("x",c.x/FRACUNIT)
			addline("y",c.y/FRACUNIT)
			addline("z",c.z/FRACUNIT)
			addline("momx",c.momx/FRACUNIT)
			addline("momy",c.momy/FRACUNIT)
			addline("momz",c.momz/FRACUNIT)
			addline("angle",AngleFixed(c.angle)>>FRACBITS)
			addline("turn_speed",AngleFixed(c.turn_speed)/FRACUNIT)
			addline("aiming",AngleFixed(c.aiming)>>FRACBITS)
			addline("waittics",c.waittics)
			addline("dest_x", c.dest_x/FRACUNIT)
			addline("dest_y", c.dest_y/FRACUNIT)
			addline("dest_z", c.dest_z/FRACUNIT)
			addline("dest_momx", c.dest_momx/FRACUNIT)
			addline("dest_momy", c.dest_momy/FRACUNIT)
			addline("dest_momz", c.dest_momz/FRACUNIT)
			addline("dest_x_final", c.dest_x_final/FRACUNIT)
			addline("dest_y_final", c.dest_y_final/FRACUNIT)
			addline("dest_z_final", c.dest_z_final/FRACUNIT)
			addline("focus_momx", c.focus_momx/FRACUNIT)
			addline("focus_momy", c.focus_momy/FRACUNIT)
			addline("focus_momz", c.focus_momz/FRACUNIT)
			addline("focus_x_final", c.focus_x_final/FRACUNIT)
			addline("focus_y_final", c.focus_y_final/FRACUNIT)
			addline("focus_z_final", c.focus_z_final/FRACUNIT)
		end
		addspace()
		subheader("Camera Waypoint")
		addline("index", mo.camera_waypoint)
		local waypoint = B.CamWaypoints[mo.camera_waypoint or 0]
		if waypoint
			addspace()
			subheader("Startpoint")
			addline("Set", waypoint.flags1 & CF_SET != 0)
			addline("Fixed XY", waypoint.flags1 & CF_XY != 0)
			addline("Fixed Z", waypoint.flags1 & CF_Z != 0)
			addline("Fixed Angle", waypoint.flags1 & CF_ANGLE != 0)
			addline("x", waypoint.x1/FRACUNIT)
			addline("y", waypoint.y1/FRACUNIT)
			addline("z", waypoint.z1/FRACUNIT)
			addline("angle", AngleFixed(waypoint.angle1)>>FRACBITS)
			addspace()
			subheader("Endpoint")
			addline("Set", waypoint.flags2 & CF_SET != 0)
			addline("Fixed XY", waypoint.flags2 & CF_XY != 0)
			addline("Fixed Z", waypoint.flags2 & CF_Z != 0)
			addline("Fixed Angle", waypoint.flags2 & CF_ANGLE != 0)
			addline("x", waypoint.x2/FRACUNIT)
			addline("y", waypoint.y2/FRACUNIT)
			addline("z", waypoint.z2/FRACUNIT)
			addline("angle", AngleFixed(waypoint.angle2)>>FRACBITS)
		end
	end
end