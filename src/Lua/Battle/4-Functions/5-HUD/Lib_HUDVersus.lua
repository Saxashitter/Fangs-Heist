local B = CBW_Battle

local APPEARDELAY = TICRATE
local DISAPPEARSTART = TICRATE*5
local APPEARTIME = 15
local APPEARSTAGGER = 2
local APPEARDISTX = 200
local APPEARDISTY = 128

local width = 256
local height = 128
local scrolldelay = TICRATE*5
local scrolltics = TICRATE
local scrolldist = 100
local scrollspeed = 3

--Debug print wrapper
local dprint = function(str)
	B.DebugPrint(str, DF_GAMETYPE)
end

--Group tables
local plays = {}
local allies = {}
local foes = {}
local horde = {}


-- Stage data
local currentstage = 2
local centergraphic
local stagetext
local stages = {}

--Time-based interpolation - is used to slide the coordinates of various HUD elements in and out of view
local doInterp = function(stagger,delay)
	local cv_hidetime = CV_FindVar('hidetime')
	local interp
	delay = not($) and APPEARDELAY or TICRATE*2
	if leveltime < DISAPPEARSTART
		interp = FRACUNIT*(leveltime - (delay+APPEARTIME+APPEARSTAGGER*stagger))/APPEARTIME

	else
		interp = FRACUNIT*(APPEARTIME + DISAPPEARSTART - leveltime)/APPEARTIME
	end
	return min(max(interp, 0), FRACUNIT)
end


--Draw scrolling bars
local drawscroll = function(v,player,cam,x,y,patch,scroll,scrollspeed,bottom)
	local scrolltime = FixedSqrt(min(scrolldelay,leveltime)*FRACUNIT/scrolldelay)
	scrollspeed = FixedMul(scrolltime,$*FRACUNIT)
	local uncovertime = max(leveltime-scrolldelay,0)
	local uncoveramt = FRACUNIT*max(scrolltics-uncovertime,0)/scrolltics
	if bottom == true
		y = B.FixedLerp($,200-12,uncoveramt)
	else
		y = B.FixedLerp($,-128+12,uncoveramt)
	end
	
	patch = v.cachePatch($ or "CHECKER1")
	if scroll == "right"
		for n = 1, (320/width)+3 do
			local x = x+(((leveltime*scrollspeed/FRACUNIT)%width)+width*(n-3))
			v.draw(x,y,patch,0)
		end
	elseif scroll == "left"
		for n = 1, (320/width)+3 do
			local x = x-(((leveltime*scrollspeed/FRACUNIT)%width)+width*(n-3))
			v.draw(x,y,patch,0)
		end
	end
end

--Draw background fill
local doFill = function(v, player, cam)
	local addx = (v.width()/v.dupx() - 320)/2+1 --Add this to the sides of the screen to compensate for non-green resolutions
	local addy = (v.height()/v.dupy() - 200)+2 --Add this to the top and bottom to compensate for non-green resolutions
	local lerpamt = min(FRACUNIT*max(scrolldelay+scrolltics-leveltime, 0)/scrolltics, FRACUNIT)
	local width = B.FixedLerp(0, addx+160, lerpamt)
	v.drawFill(-addx, -addy/2, width, 200+addy)
	v.drawFill(addx+320-width, -addy/2, width, 200+addy)
end

--Draw "VS" text
local drawVS = function(v,player,cam)
	local flags = 0
	local space = FRACUNIT*8
	local interp = doInterp(0, true)
	local x = 152*FRACUNIT
	local y = 100*FRACUNIT
	local V = v.cachePatch('LTFNT086')
	local S = v.cachePatch('LTFNT083')
	local dir = CV_FindVar('hidetime').value < leveltime
	local y1 = B.FixedLerp(-APPEARDISTY*FRACUNIT, y, interp)
	local y2 = B.FixedLerp((200+APPEARDISTY)*FRACUNIT, y, interp)
	if dir
		y1, y2 = y2, y1
	end
	local scale = FRACUNIT
	v.drawScaled(x-space,y1,scale,V,flags)
	v.drawScaled(x+space,y2,scale,S,flags)
end

--Group constants
local PLAYER = 0
local ALLY = 1
local FOE = 2
local HORDE = 3
local CENTER = 4

--Draw character
local drawChar = function(v,player,cam,skin,color,colormap,position,subpos,groupsize)
	local x, y, scale, patch, flags = 0, 0, FRACUNIT, nil, 0
	local xo, yo = 0, 0
	local resetx, resety, resetnum, resetcount = 0, 0, 0, 0
	local halign = 0
	local valign = 0
	local xradius = 64
	local yradius = 64
	if position == PLAYER
		x = 80
		y = 100
		xo = -40
		yo = 40
	elseif position == ALLY
		x = 30
		y = 80
		xo = 40
		yo = -40
		flags = $|V_SNAPTOLEFT|V_SNAPTOTOP
		scale = $*2/3
	elseif position == FOE
		flags = $|V_FLIP
		x = 240
		y = 100
		xo = -40
		yo = -40
	elseif position == HORDE
		flags = $|V_FLIP|V_SNAPTORIGHT
		x = 240
		y = 100
		xo = -30
		yo = -60
		resetx = -80
		resety = 0
		resetnum = 2 + groupsize/4
	elseif position == CENTER
		x = 160
		y = 100
	end
	scale = $*8/(7 + groupsize)
	
	--Compensate for changes in scale
	if scale != FRACUNIT
		xo = FixedMul(scale, $)
		yo = FixedMul(scale, $)
		xradius = FixedMul(scale, $)
		yradius = FixedMul(scale, $)
		resetx = FixedMul(scale, $)
		resety = FixedMul(scale, $)
	end
	
	--Compensate for sprite flipping
	if flags & V_FLIP
		xradius = -$
	end

	
	--Apply group offsets
	if resetnum
		groupsize = min($, resetnum)
		resetcount = groupsize/resetnum
	end
	if halign == 0
		x = $ - (xo*(groupsize+1)/2)
	elseif halign == 1
		x = $ - (xo*(groupsize))
	end
	
	if valign == 0
		y = $ - (yo*(groupsize+1)/2)
	elseif valign == 1
		y = $ - (yo*(groupsize))
	end
	
	if resetnum
		x = $ + ((subpos/resetnum)-resetcount) * resetx
		y = $ + ((subpos/resetnum)-resetcount) * resety
		x = $ + xo*(subpos%resetnum + 1)
		y = $ + yo*(subpos%resetnum + 1)
	else
		x = $ + xo*(subpos)
		y = $ + yo*(subpos)
	end
	
	x = $ - xradius
	y = $ - yradius
		
	--Do scaled positioning
	x,y = $*FRACUNIT, $*FRACUNIT
	
	--Do interpolation
	local interp = doInterp(subpos)
	if position == CENTER
		y = B.FixedLerp(-APPEARDISTY*FRACUNIT, y, interp)
	elseif flags & V_FLIP
		x = B.FixedLerp((320+APPEARDISTX)*FRACUNIT, x, interp)
	else
		x = B.FixedLerp(-APPEARDISTX*FRACUNIT, x, interp)
	end
	
	--Get patch
	if string.sub(skin,1,1) != "~"
		patch = v.getSprite2Patch(skin, 'XTRA', false, 1)
	else
		patch = v.cachePatch(string.sub(skin,2,#skin))
	end
	if not(patch) --Handle unknown/invalid graphic
		patch= v.cachePatch("UNKNA0")
	end
	if color
		color = v.getColormap(colormap, $)
	else
		color = nil
	end
	--Process
	v.drawScaled(x,y,scale,patch,flags,color)
end

--Perform character groups and name text
local drawGroup = function(v, player, cam, group, position, sorting, name)
	if not(group and #group) return end
	if sorting == 0
		local n = #group
		while n > 0 do
			drawChar(v,player,cam,group[n][1],group[n][2],group[n][3],position,n,#group)
			n = $-1
		end
	else
		local n = 1
		while n <= #group do
			drawChar(v,player,cam,group[n][1],group[n][2],group[n][3],position,n,#group)
			n = $+1
		end
	end
	--Draw name
	local align = 'center'
	local flags = 0
	local x,y = 0, position*8
	if position == PLAYER
-- 		x = 80
		y = 170
-- 		x = 150
-- 		align = 'right'
		x = 160
	elseif position == ALLY
		x = 40
		y = 32
		align = 'thin-center'
		flags = $|V_SNAPTOLEFT|V_SNAPTOTOP
	elseif position == FOE
		x = 240
		y = 170
-- 		x = 170
-- 		align = 'left'
	elseif position == HORDE
		x = 290
		y = 170
		align = 'right'
		flags = $|V_SNAPTORIGHT
	elseif position == CENTER
		x = 160
		y = 170
	end
	if name != nil
		local lerpamt = doInterp(0)
		y = B.FixedLerp(300, $, lerpamt)
		v.drawString(x, y, name,flags,align)
	end
end

-- Native HUD control
local huditems = {'textspectator','score','time','rings','lives'}
local disabled = false

local doEnable = do
	if disabled
		for _,item in pairs(huditems) do
			hud.enable(item)
		end
		disabled = false
		return true
	end
	return false
end

local doDisable = do
	if not(disabled)
		for _,item in pairs(huditems) do
			hud.disable(item)
		end
		disabled = true
		return true
	end
	return false
end

B.GameHudEnabled = do
	return not(disabled)
end

-- Get scrolling bar images (random on mapload)
local patches = {
	'CHECKER1',
	'CHECKER2',
	'CHECKER3',
	'CHECKER4',
	'CHECKER5',
	'CHECKER6',
	'CHECKER7',
	'CHECKER8',
	'CHECKER9',
	'CHECKERA'
}
local patch1, patch2 = 'CHECKER1', 'CHECKER2'
addHook('MapLoad', do
	patch1 = patches[P_RandomRange(1, #patches)]
	patch2 = patches[P_RandomRange(1, #patches)]	
end)

local getPortraitColormap = function(skin, color, flags)
	return (flags and flags & BSP_SHADOW) and TC_BLINK
		or color and skins[skin] and skins[skin].prefcolor != color and TC_RAINBOW
		or TC_DEFAULT
end
local getHudIconColormap = function(flags)
	return (flags and flags & BSP_SHADOW) and TC_RAINBOW
		or TC_DEFAULT
end
local getPlayerSkin = function(player)
	if player.mo
		return player.mo.skin
	else
		return player.realmo.skin
	end
end
local getSkinColor = function(skin, color)
	if not(color) and skins[skin]
		return skins[skin].prefcolor
	else 
		return color
	end
end
local buildSkinFromPlayer = function(player)
	local skin = getPlayerSkin(player)
	local color = getSkinColor(skin, player.skincolor)
	local colormap = getPortraitColormap(skin, color, player.battlespflags)
	local t = {
		skin,
		color,
		colormap,
		skins[skin].realname or skins[skin].name or "???"
	}
	if #plays < 4
		table.insert(plays, t)
	else --Try to reduce crowding on the front row
		table.insert(allies, t)
	end
end

local buildSkinFromQueue = function(data, header)
	local t = {
		data.skin,
		getSkinColor(data.skin, data.color),
		getPortraitColormap(data.skin, data.color, data.flags),
		data.name
	}
	if data.team == 2
		table.insert(allies, t)
	elseif header and header.teamsize and header.teamsize < #header.fighters
		table.insert(horde, t)
	else
		table.insert(foes, t)
	end
end

local maxstages = 8
--Draw stage progress
local drawProgress = function(v, player, cam)
	if not(currentstage)
		return
	end
	local x, y, flags = 0, 0, 0
	--Find width of our progress HUD so we can adjust the left-most offset accordingly
	local offset = 24
	local width = min(offset * #stages, 320)
	x = 160 - width/2 - offset
	
	if leveltime >= scrolldelay --Don't slide in, but do slide out
		y = B.FixedLerp(-64, 0, doInterp(0)) --Interpolation method for y sliding
	end
	
	-- Determine which stage should be highlighted. We start off by highlighting the previous stage, then we highlight the current stage once all elements have slid in
	local highlightstage = (leveltime > APPEARDELAY+APPEARTIME
			or leveltime > APPEARDELAY and leveltime&1) --Transition period, in which highlight stage will rapidly switch between current stage and previous stage
			and currentstage
			or currentstage-1


	local patch, color, skin
	for n,stage in pairs(stages) do
		if currentstage-maxstages > n
		or currentstage+maxstages < n
			continue  --Only iterate through nearby stages
		end
		local noicon = false
		x = $+offset --Set the x offset for this icon
		-- Do background box
		if n > highlightstage
			color = 8 --Grayish white for future stages
		elseif n == highlightstage
			color = 82 --Bright yellow for highlighted stage
		else
			color = 253 --Dark blue for past stages
		end
		v.drawFill(x, y, 16, 16, color)
		-- Do patch
		skin = stage.skin
		color = nil
		if skin == nil --Resolve empty icons
			noicon = true
		elseif skins[skin] --Get data from skin
			patch = v.getSprite2Patch(skin, 'LIFE', false, 0)
			color = v.getColormap(stage.colormap or TC_DEFAULT, stage.color or skins[skin].prefcolor)
		elseif string.sub(skin,1,1) == "~" --Custom graphic was specified
			skin = string.sub(skin,2,#skin)
			patch = v.cachePatch(skin)
			color = v.getColormap(stage.colormap or TC_DEFAULT, stage.color or 0)
		end
		if noicon == false
			if patch == nil -- Missing graphic handler
				B.Warning('Could not find skin or graphic '..tostring(stage.skin)..' for stage '..n)
				stage.skin = "~ERROR16" --Prevent this message from showing up again
				patch = v.cachePatch("ERROR16")
				color = v.getColormap(stage.colormap or TC_DEFAULT, stage.color or 0)
			end
			
			if n != highlightstage
				flags = $|V_TRANSLUCENT
			else
				flags = $&~V_TRANSLUCENT
			end
			v.draw(x+8,y+12,patch,flags,color)
		end
		-- Do pipeline to the next stage
		if n < #stages
			v.drawFill(x+offset-8, y+7, 8, 4, 148)
		end
	end
	v.drawString(160, y+20, "Stage "..currentstage, 0, "center")
end

-- Get HUD elements from game and map header
B.SetVSHUD = function(header)
	dprint("Getting HUD elements for campaign")
	plays = {}
	allies = {}
	foes = {}
	horde = {}
	local blueteam = {} --This is used for group naming purposes on the player's side
	local playname = ""
	local foename = ""
	centergraphic = nil
	stagetext = nil
	if not(header.hudbonus)
		--Get player data from players.iterate and queued fighters
		if consoleplayer --Always prioritize consoleplayer as the first skin
			buildSkinFromPlayer(consoleplayer)
			table.insert(blueteam, plays[1])
		end
		for player in players.iterate do
			if consoleplayer continue end -- we already did you, get outta here
			buildSkinFromPlayer(player)
			if #blueteam < 4
				table.insert(blueteam, plays[#plays])
			end
		end
		--Get allies and foes
		for n,fighter in pairs(B.QueueFighters) do
			buildSkinFromQueue(fighter, header)
			if fighter.team == 2 and #blueteam < 4
				table.insert(blueteam, allies[#allies])
			end
		end
		
		dprint("Constructed blueteam size "..#blueteam.." from "..#plays.." players and "..#allies.." CPU allies")
		dprint("Got "..#foes.." rival opponents and "..#horde.." horde enemies")

		--Decide player group name
		if #blueteam == 1
			playname = blueteam[1][4] -- Grab skin fullname from field 4 in player 1's info
		elseif #blueteam == 2
			playname = blueteam[1][4].." & "..blueteam[2][4]
		else
			playname = blueteam[1][4].." & Co." -- Too many to count!
		end
		
		--Decide opponent group name
		if header.hudname
			foename = header.hudname
		elseif #foes == 1
			foename = foes[1][4]
		elseif #foes == 2
			foename = foes[1][4].." & "..foes[2][4]
		elseif #foes
			foename = foes[1][4].." & Co." -- Too many to count!
		elseif #horde
			foename = horde[1][4].." Team"
		end
		if #horde
			foename = $.."\x86\ [vs."..#horde.."]"
		end

		stagetext = playname.." \x82\VS\x80\ "..foename
	else
		centergraphic = header.hudbonus
		stagetext = header.hudname
	end
	
	-- Get stage data from mapheader and Campaign table
	stages = {}
	currentstage = tonumber(mapheaderinfo[gamemap].battlecampaign) or gamemap
	local defaultheader = B.GetCampaignHeader(-1)
	local maxstages = 0
	for n,t in pairs(B.Campaign) do
		if tonumber(n)
			maxstages = $+1
		end
	end
	dprint("Found "..maxstages.." numbered stages in campaign")
	if currentstage < 1 or currentstage > maxstages
		currentstage = 0
		return --Don't draw progress, since we're not on the campaign path
	end
	local n = 0
	repeat
		n = $+1
		local header = B.Campaign[n]
		if header == nil
			B.Warning('Stage '..n.." not found, skipping")
			continue
		end
		--Get hud icons for stage progress
		local skin, color, colormap = 
			header.hudicon, header.hudiconcolor, header.hudiconcolormap
		if skin == nil --No icon found?
			if header.fighters
				local docontinue = false
				local fighter
				--Get first valid enemy fighter
				for m,t in pairs(header.fighters) do
					--Error handling
					if not(type(t) == "table")
						B.Warning('Stage '..n..' fighters table is improperly formatted! Make sure individual fighters are separately bracketed, e.g. "fighters = {{skin = fang}}", NOT "fighters = {skin = fang}"')
						docontinue = true
						break
					end
					if not(t.ally)
						fighter = t
						break --Found our preferred fighter
					end
				end
				if docontinue == true
					table.insert(stages,{skin = "~ERROR16"})
					continue
				end
				-- Fill in missing definitions based on fighter data
				if fighter
					local flags = fighter.flags or 0
					skin = fighter.skin
					colormap = getHudIconColormap(flags)
					if flags & BSP_SHADOW
						local shield = fighter.shield or SH_PITY
						color = B.ShadowCharacterFX[shield].color
					else
						color = $ or getSkinColor(skin, $ or fighter.color)
					end
				end
			end
		end
		if skin != nil and string.sub(tostring(skin), 1) != "~"
			--Check skin for special arguments
			if skin == "?" or skin == "*"
				skin = "~QUESTION"
			elseif skin == "!"
				skin = "~EXCLAIM"
			elseif skin == "#"
				skin = "~BATTLE16"
			elseif skin == "="
				if not(netgame)
					skin = B.GetP1Skin()
				else
					skin = "~QUESTION"
				end
			end
			--Default skin color is skin prefcolor
			if skins[skin] and color == nil
				color = skins[skin].prefcolor
			end
		end
		--Colormap default
		if colormap == nil
			colormap = TC_DEFAULT
		end
		--Apply stage data
		table.insert(stages,{skin = skin, color = color, colormap = colormap})
		dprint('Added stage '..n..' with skin '..tostring(skin)..', color '..tostring(color)..', colormap '..tostring(colormap))
	until n >= maxstages
end

-- Perform all HUD elements
B.VersusHUD = function(v, player, cam)
	if not(B.PreRoundWait()) or B.PlayerCanRoulette(player) 
		doEnable()
		return 
	elseif leveltime > (scrolldelay+scrolltics)
		if leveltime < (scrolldelay+scrolltics) + TICRATE/4
			 if not(doEnable()) doDisable() end --flashing
		else
			doEnable()
		end
	else
		doDisable()
	end
	doFill(v, player, cam)
	drawscroll(v, player, cam, 0, -160, patch1, "right", scrollspeed, false)
	drawscroll(v ,player, cam,0, 232, patch2, "left", scrollspeed, true)
	drawGroup(v, player, cam, allies, ALLY, 0, "Ally")
	drawGroup(v, player, cam, horde, HORDE, 0, nil)
 	drawGroup(v, player, cam, foes, FOE, 0, nil)
	drawGroup(v, player, cam, plays, PLAYER, 1, stagetext)
	if centergraphic
		drawGroup(v, player, cam, {{centergraphic}}, CENTER, 0, stagetext) 
	end
	drawProgress(v, player, cam)
	if not(centergraphic)
		drawVS(v, player, cam)
	end
end