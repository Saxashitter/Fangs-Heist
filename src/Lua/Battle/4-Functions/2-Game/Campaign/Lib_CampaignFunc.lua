local B = CBW_Battle
local A = B.Arena
local CV = B.Console

B.RemoveAllBots = do
	if BATTLE_AI_LOADED
		NavFunc.RemoveAllBots()
	end
end

local validskins
local multiplevalidskins = false
B.GetP1Skin = do
	--Get Player 1 skin, but only for single player games. Otherwise return nothing.
	if not(multiplayer) and consoleplayer
		if consoleplayer.mo
			return consoleplayer.mo.skin
		else
			return consoleplayer.realmo.skin
		end
	end
end
local setupValidSkins = do
	validskins = {}
	for skindata in skins.iterate do
		if R_SkinUsable(server, skindata.name)
			table.insert(validskins, skindata.name)
		end
	end
-- 	print("validskins",unpack(validskins))
	multiplevalidskins = #validskins > 1
end
local pullRandomValidSkin = function(allowsame)
	local p1skin = B.GetP1Skin()
	local skin
	repeat
		local n
		if not(#validskins) -- None left? Rebuild table
			setupValidSkins()
		end
		n = P_RandomRange(1, #validskins)
-- 		print("#"..n..": "..tostring(validskins[n])..", table length: "..#validskins)
		skin = validskins[n]
-- 		print("GET: "..tostring(skin))
		table.remove(validskins, n) -- Don't let us choose this skin again
	until allowsame or not(multiplevalidskins) or not(p1skin and skins[p1skin] == skins[skin])
	return skin
end
local validcolors
local setupValidColors = do
    validcolors = {}
    for i = 1, #skincolors - 1 do
        if skincolors[i].accessible
            table.insert(validcolors, i)
        end
    end
end
local pullRandomValidColor = function(oldcolor)
	local newcolor
	if not(#validcolors) -- None left? Rebuild table
		setupValidColors()
	end
	repeat
		local n = P_RandomRange(1, #validcolors)
		newcolor = validcolors[n]
		table.remove(validcolors, n) -- Don't let us choose this color again
	until oldcolor != newcolor
	return newcolor
end

--We reset these on map load anyway, but just in case.
setupValidSkins()
setupValidColors()


B.GetCampaignHeader = function(map)
	if map == -1 or mapheaderinfo[gamemap].battlecampaign == "-1"
	or map == "default" or mapheaderinfo[gamemap].battlecampaign == "default"
		return B.Campaign["default"]
	end
	if map == "bonus"
		return B.Campaign["bonus"]
	end
	map = $ or gamemap
	local defaultheader = B.Campaign["default"]
	local index = mapheaderinfo[gamemap].battlecampaign
	if tonumber(index)
		index = tonumber($)
	elseif index == nil -- Default to gamemap number if mapheader parameter BattleCampaign is undefined
		index = gamemap
	end
	local header = B.Campaign[index] or defaultheader
	
	if CV.Debug.value & 1
		if header == B.Campaign[index]
-- 			B.DebugPrint('Got campaign header info '..tostring(index))
		else
-- 			B.DebugPrint('No campaign header info found (argument '..tostring(index)..')')
		end
	end
	return header
end

local getqueuefighter = function(ally)
	for n, fighter in pairs(B.QueueFighters) do
		if type(fighter) != "table"
			B.Warning("Invalid fighter entry "..tostring(n).." (got "..type(fighter)..", expected table)")
			table.remove(B.QueueFighters, n)
			continue
		end
		if (ally == true) == (fighter.ally == true)
			return n, fighter
		end
	end
end

local getSkin = function(fighter)
	local skin = fighter.skin
	--Skin is a typical valid argument
	if skin != nil and skins[skin]
		return skin
	end
	--Skin has special argument or is otherwise unknown
	local random, same
	if type(skin) == "string"
		local arg = string.sub(skin, 1)
		random = (arg == "?" or arg == "*")
		same = (arg == "=" or arg == "*")
	end
	if random
		return pullRandomValidSkin(same)
	elseif same
		skin = B.GetP1Skin() --Returns nil in multiplayer
		if skin == nil
			return pullRandomValidSkin(true)
		else
			return skin
		end
	end
	--Fallthrough: Undefined or unknown entry
	return pullRandomValidSkin(false)
end

local getShield = function(fighter)
	local shield = fighter.shield
	if not(shield)
		return SH_PITY
	end
	if shield == -1
		return B.Choose(SH_PITY, SH_ELEMENTAL, SH_FORCE|1, SH_WHIRLWIND, SH_ATTRACT, SH_ARMAGEDDON, SH_BUBBLEWRAP, SH_THUNDERCOIN, SH_FLAMEAURA)
	end
	return shield
end

local getColor = function(fighter, skin, shield, index, fighters)
	local color, flags, team =
		fighter.color,
		fighter.flags or 0,
		fighter.ally and 2 or 1
	
	-- Shadow character
	if flags & BSP_SHADOW
		local fx = B.GetShadowCharacterFX(shield, true)
		if fx.color
			return fx.color
		end
	end
	if not(skin and skins[skin])
		skin = 0
	end
	if color == -1 -- Special argument -1: get random color
		color = pullRandomValidColor(color)
	end
	if not(color and skincolors[color]) -- Undefined or unknown
		-- Get default skincolor
		color = skins[skin].prefcolor
	end
	-- Avoid occupying the same color as other players, if we can
	for player in players.iterate do
		if player.skincolor == color
			color = pullRandomValidColor(color)
			if color == 0 -- No more valid options
				return color
			end
		end
	end
	-- Allies should avoid the same color with ALL other fighters, if possible
	if team == 2 
		for player in players.iterate do -- Check players on field
			if player.skincolor == color
				color = pullRandomValidColor(color)
			end
		end
		for n,t in ipairs(fighters) do -- Check CPU fighters
			if t.skin == skin and t.color == color
				color = pullRandomValidColor(color)
			end
		end			
	end
	return color
end

local getName = function(fighter, skin)
	if fighter.name
		return fighter.name
	end
	return skins[skin].realname
end

--Error handler for improperly set campaigns. Nils out bad field settings to prevent further errors.
B.CampaignCheckIntegrity = function()
	local errors = 0
	for n,st in pairs(B.Campaign) do
		--Check HUD icon stuff
		if st.hudicon != nil and type(st.hudicon) != "number" and type(st.hudicon) != "string"
			B.Warning("Got "..type(st.hudicon).." argument for stage "..n.." hudicon (expected nil, string or number)")
			st.hudicon = nil
			errors = $+1
		end
		if st.hudiconcolor != nil and type(st.hudiconcolor) != "number"
			B.Warning("Got "..type(st.hudiconcolor).." argument for stage "..n.." hudiconcolor (expected nil or SKINCOLOR_ constant)")
			st.hudiconcolor = nil
			errors = $+1
		end
		if st.hudiconcolor and not(skincolors[st.hudiconcolor])
			B.Warning("Number argument "..st.hudiconcolor.." for stage "..n.." hudiconcolor out of bounds! (Max range: 0-"..#skincolors..")")
			st.hudiconcolor = nil
			errors = $+1
		end
		if st.hudiconcolormap != nil and type(st.hudiconcolormap) != "number"
			B.Warning("Got "..type(st.hudiconcolormap).." argument for stage "..n.." hudiconcolormap (expected nil or number)")
			st.hudiconcolormap = nil
			errors = $+1
		end
		if st.hudname != nil and type(st.hudname) != "string"
			B.Warning("Got "..type(st.hudname).." argument for stage "..n.." hudname (expected nil or string)")
			st.hudname = nil
			errors = $+1
		end
		if st.hudbonus != nil and type(st.hudbonus) != "string"
			B.Warning("Got "..type(st.hudbonus).." argument for stage "..n.." hudbonus (expected nil or string)")
			st.hudbonus = nil
			errors = $+1
		end
		--Check gameplay settings
		if st.teamsize != nil and type(st.teamsize) != "number"
			B.Warning("Got "..type(st.teamsize).." argument for stage "..n.." teamsize (expected nil or number)")			
			st.teamsize = nil
			errors = $+1
		end
		--Check fighters
		if st.fighters != nil and type(st.fighters) != "table"
			B.Warning("Got "..type(st.fighters).." argument for stage "..m.." fighters (expected nil or table)")
			st.fighters = nil
			errors = $+1
		end
		if st.fighters
			for m,t in pairs(st.fighters) do
				--Got non-numbered entry.
				if type(m) != "number"
					B.Warning("Stage "..n.." fighters table is incorrectly formatted! Is each fighter properly encased in sub-brackets?")
					st.fighters = nil
					break
				end
				--Not a fighter table.
				if type(t) != "table"
					B.Warning("Got "..type(t).." argument for fighter "..m.." in stage "..n.." (expected table)")
					table.remove(st.fighters, t)
					errors = $+1
					continue
				end
				--Check table contents
				if t.skin != nil and type(t.skin) != "number" and type(t.skin) != "string"
					B.Warning("Got "..type(t.skin).." argument for fighter "..m.." skin in stage "..n.." (expected nil, string or number)")
					t.skin = nil
					errors = $+1
				end
				if t.color != nil and type(t.color) != "number"
					B.Warning("Got "..type(t.color).." argument for fighter "..m.." color in stage "..n.." (expected nil or SKINCOLOR_ constant)")
					t.color = nil
					errors = $+1
				elseif t.color != nil and t.color < -1
					B.Warning("Got "..t.color.." for fighter "..m.." color in stage "..n.." (expected positive number, 0, or -1)")
					t.color = nil
					errors = $+1
				end
				if t.flags != nil and type(t.flags) != "number"
					B.Warning("Got "..type(t.flags).." argument for fighter "..m.." flags in stage "..n.." (expected nil, 0, or positive number)")
					t.flags = nil
					errors = $+1
				elseif t.flags != nil and t.flags < 0
					B.Warning("Got "..t.flags.." for fighter "..m.." flags in stage "..n.." (expected nil, 0, or positive number)")
					t.flags = nil
					errors = $+1
				end
				if t.shield != nil and type(t.shield) != "number"
					B.Warning("Got "..type(t.shield).." argument for fighter "..m.." shield in stage "..n.." (expected nil or SH_ constant)")
					t.shield = nil
					errors = $+1
				elseif t.shield != nil and t.shield < -1
					B.Warning("Got "..t.shield.." for fighter "..m.." shield in stage "..n.." (expected SH_ constant, 0, or -1)")
					t.shield = nil
					errors = $+1
				end
				if t.scale != nil and type(t.scale) != "number"
					B.Warning("Got "..type(t.scale).." argument for fighter "..m.." flags in stage "..n.." (expected nil or positive fixed number)")
					t.scale = nil
					errors = $+1
				elseif t.scale != nil and t.scale <= 0
					B.Warning("Got "..t.scale.." for fighter "..m.." scale in stage "..n.." (expected nil or positive fixed number)")
					t.scale = nil
					errors = $+1
				end
			end
		end
	end
	
	--Fill in missing stages
	local laststage = 0
	for n,st in pairs(B.Campaign) do
		if tonumber(n)
			laststage = max($,tonumber(n))
		end
	end
	if laststage
		local str
		local fill = 0
		for n = 1, laststage do
			if not(B.Campaign[n])
				B.Campaign[n] = {
					hudicon = "~ERROR16",
					fighters = {
						{skin = "?"}
					}
				}
				if str == nil
					str = tostring(n)
				else
					str = $..", "..tostring(n)
				end
				fill = $+1
				errors = $+1
			end
		end
		if fill
			B.Warning(fill.." stage definitions missing in a campaign of "..laststage.." stages. The following stages are missing definitions: "..str)
		end
	end
	return errors
end

B.CampaignMapChange = do
	if not BATTLE_CAMPAIGN_LOADED
	or not BATTLE_AI_LOADED
		return
	end
	B.Horde = 0
	while #B.QueueFighters do
		--Reset QueueFighters for this frame
		table.remove(B.QueueFighters, 1)
	end
	if B.BattleCampaign()
	or titlemapinaction or not(consoleplayer or netgame)
		B.RemoveAllBots()
	end
end

B.CampaignMapStart = do
	if not BATTLE_CAMPAIGN_LOADED
	or not BATTLE_AI_LOADED
		return
	end
	--Get header info
	local errors = B.CampaignCheckIntegrity()
	if errors
		print('\x85'..errors..' errors were detected in campaign settings. See log or console for more details.')
	end
	local defaultheader
	if gamemap >= sstage_start and gamemap <= sstage_end
	or gamemap >= smpstage_start and gamemap <= smpstage_end
		defaultheader = B.GetCampaignHeader("bonus")
	else
		defaultheader = B.GetCampaignHeader(-1)
	end
	local header = B.GetCampaignHeader()
	
	if not B.BattleCampaign()
		return
	end
	local fighters = header.fighters or defaultheader.fighters
	if fighters
		for n,fighter in pairs(fighters) do
			if fighter.ally and multiplayer --No CPU allies allowed in multiplayer
				continue
			end
			--Create new table, extrapolating from fighter data
			local t = {}
			t.skin = getSkin(fighter)
			t.shield = getShield(fighter)
			t.color = getColor(fighter, t.skin, t.shield, n, B.QueueFighters)
			t.name = getName(fighter, t.skin)
			t.flags = fighter.flags or 0
			t.scale = fighter.scale or FRACUNIT
			t.team = fighter.ally and 2 or 1 --Translate ally boolean into ctfteam data;  allies are on blue, enemies on red.
			B.DebugPrint('Adding fighter to queue with skin '..tostring(t.skin)..', color '..tostring(t.color)..', name '..tostring(t.name)..', team '..tostring(t.team))
			table.insert(B.QueueFighters, t)
		end
	end
	B.SetVSHUD(header)
	B.Horde = header.teamsize and header.teamsize < #B.QueueFighters
end

local removeDeceased = do
	for n = 0, 31 do 
		if players[n] and players[n].ctfteam == 1 and players[n].deadtimer > TICRATE*2
			G_RemovePlayer(n)
			return true
		end
	end
end

B.CampaignUpdateFighters = do
	-- Return true to indicate that fighters still need to be spawned in. Return false to indicate otherwise.
	if not BATTLE_CAMPAIGN_LOADED
	or not BATTLE_AI_LOADED
	or not #B.QueueFighters -- No fighters are queued
	or B.Exiting
		return false
	end
	if leveltime < TICRATE*5 -- Too soon! Wait until we can see our characters
	or leveltime%TICRATE -- We spawn fighters incrementally. This is the amount of time to wait before trying to spawn a new fighter.
		return true
	end
	local defaultheader = B.GetCampaignHeader(-1)
	local header = B.GetCampaignHeader()
	if header.teamsize and #A.RedFighters >= header.teamsize --Enemy team is full
		if not(removeDeceased()) -- This will report if it was able to remove a dead player to make room
			return true -- If not, we'll try again next time.
		end
	end
	-- Find fighter to pull from queue
	local n, fighter = getqueuefighter(true) -- Look for allies first
	if not(n and fighter)
		n, fighter = getqueuefighter(false) -- Then look for enemies next
	end
	if not(n and fighter) -- This should only happen if there was a bad entry found in the table.
		B.Warning("Reached the end of QueueFighters, no valid entry found")
		return true
	end
	-- Found a fighter. Before doing anything else, let's remove it from the queue
	table.remove(B.QueueFighters, n)
	
	-- The MapStart function should have already processed the fighter variables, so we just have to feed them into AddBot.
	B.DebugPrint('Attempting to spawn fighter from queue with skin '..tostring(fighter.skin)..', color '..tostring(fighter.color)..', name '..tostring(fighter.name)..', team '..tostring(fighter.team))
	NavFunc.AddBot(fighter.skin, fighter.color, fighter.name, fighter.team, fighter.flags, fighter.shield, fighter.scale, fighter.difficulty) --Add the fighter CPU to the server.
	return true
end


--For debugging
COM_AddCommand("getcampaign", function(player, str)
	if consoleplayer == player
		if str == nil --No argument provided
			--Show campaign length
			print('Campaign length: '..#B.Campaign)
			--List all entries
			str = 'Entries: '
			local separate = false
			for n,t in pairs(B.Campaign) do
				if separate == true
					str = $..', '
				end
				str = $+tostring(n)
				separate = true
			end
			print(str)
			print('Type getcampaign <entry> for more details.')
			return
		end
		--Fallthrough, find stage entry
		if tonumber(str)
			str = tonumber(str)
		end
		local stage = B.Campaign[str]
		if not(stage) --Entry doesn't exist
			print('Campaign stage ID "'..str..'" not found.')
			return
		end
		--Fallthrough, display stage entry details
		prtable("Stage "..tostring(str),stage)
	end
end)