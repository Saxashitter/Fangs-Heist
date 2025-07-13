local module = {}

local WINNER_SEP = 76*FU
local WINNER_WIDTH = 128

local LOSER_SEP = 50*FU
local LOSER_WIDTH = 86

local FLASH_BUILDUP = 24
local FLASH_TICS = 10

local function RotatePoint(x_original, y_original, angle_fixedpoint)
	local cos_angle = cos(angle_fixedpoint) -- Use fixed-point cos
	local sin_angle = sin(angle_fixedpoint) -- Use fixed-point sin
	
	local x_rotated = FixedMul(x_original, cos_angle) - FixedMul(y_original, sin_angle)
	local y_rotated = FixedMul(x_original, sin_angle) + FixedMul(y_original, cos_angle)
	
	return x_rotated, y_rotated
end

local function GetXYCoords(v, x, y)
	local sw = v.width() / v.dupx()
	local sh = v.height() / v.dupy()

	return x * sw, y * sh
end

local function GetSpriteScale(sprite, targRes, scaleBy)
	local scale = FU

	if scaleBy == true then
		-- Scale down by the sprite's height.
		scale = FixedDiv(targRes, sprite.height)
	else
		-- Scale down by the sprite's width.
		scale = FixedDiv(targRes, sprite.width)
	end

	return scale
end

local function IsSpriteValid(skin, sprite, frame)
	local skin = skins[skin]
	local sprites = skin.sprites[sprite]
	local numframes = sprites.numframes

	if numframes
	and numframes > frame then -- B = 2 so, check if it has the B frame
		return true
	end

	return false
end

local function GetTeamLeader(team)
	for _, p in ipairs(team) do
		if p
		and p.valid then
			return p
		end
	end
end

local function GetPlayerName(p)
	if #p.name > 12 then
		return p.name:sub(1, 12)
	end

	return p.name
end

local function GetTeamString(team)
	local p = GetTeamLeader(team)

	if not (p and p.valid) then
		return ""
	end

	local name = GetPlayerName(p)

	if #team > 1 then
		return "Team "..name
	end

	return name
end

local function DrawSprite(v, x, y, targRes, scaleBy, sprite, flags, flip, color, offX, offY)
	local scale = FU
	flags = $ or 0

	if targRes ~= nil and targRes > 0 then
		scale = GetSpriteScale(sprite, targRes, scaleBy)
	end

	if flip == true then
		-- Flip the sprite.
		if flags & V_FLIP then
			flags = $ & ~V_FLIP
		else
			flags = $|V_FLIP
		end
	end

	-- Wait! Don't offset the sprite.
	if not offX then
		x = $ + sprite.leftoffset * scale
	end
	if not offY then
		y = $ + sprite.topoffset * scale
	end

	v.drawScaled(x, y, scale, sprite, flags, color)
end

local function DrawWinnerParallax(v)
	local sw = (v.width() / v.dupx()) * FU
	local sh = (v.height() / v.dupy()) * FU

	local WINNERS = FangsHeist.Net.placements
	local skin = "Unknown"

	local team = WINNERS[1]

	if (team and team[1] and team[1].valid) then
		local p = team[1]
		skin = skins[p.skin].name
	end

	local char = FangsHeist.Characters[skin]

	if char.customPregameBackground then
		char.customPregameBackground(v,consoleplayer)
		return
	end

	local patch = v.cachePatch(char.pregameBackground)
	local y = -patch.height*FU + (leveltime*FU/2) % (patch.height*FU)
	local x = -patch.width*FU + (leveltime*FU/2) % (patch.width*FU)

	while y < sh do
		local x = x

		while x < sw do
			v.drawScaled(x, y, FU, patch, V_SNAPTOLEFT|V_SNAPTOTOP|f)
			x = $+patch.width*FU
		end
	
		y = $+patch.height*FU
	end
end

local function DrawWinners(v, percent, blinkWhite, easing)
	-- Plan: During blackout, the players will be drawn innpure white.
	-- After which, the screen flashes and then the players stay still.

	if easing == nil then
		easing = ease.linear
	end

	local WINNERS = FangsHeist.Net.placements
	local PATCHES = {}

	local WIDTH = 0
	local HEIGHT = 0

	for i = 1, 3 do
		local team = WINNERS[i]

		if not (team and team[1] and team[1].valid) then
			break
		end
		local p = GetTeamLeader(team)

		-- TODO: make unsupported mods use XTRAB0
		local SPR2 = SPR2_FHBN
		local FRAME = B
		local ROT = 0
		local TARG = LOSER_WIDTH

		if not IsSpriteValid(p.skin, SPR2, FRAME) then
			SPR2 = SPR2_XTRA
		end

		if i == 1 then
			TARG = WINNER_WIDTH
		end

		local PATCH, FLIP = v.getSprite2Patch(
			p.skin,
			SPR2,
			false,
			FRAME,
			ROT)
		table.insert(PATCHES, {PATCH, FLIP})
		local scale = GetSpriteScale(PATCH, TARG, true)

		HEIGHT = max($, PATCH.height*scale)

		if i == #WINNERS then
			local sep = i == 1 and WINNER_SEP or LOSER_SEP

			WIDTH = $ + max(sep, PATCH.width*scale)
			continue
		end

		if i == 1 then
			WIDTH = $ + WINNER_SEP
			continue
		end

		WIDTH = $ + LOSER_SEP
	end

	local x, y = GetXYCoords(v, FU/2, FU)
	x = $ - WIDTH/2

	local FIRST_X = x
	local SECOND_X = FIRST_X + WINNER_SEP
	local THIRD_X = SECOND_X + LOSER_SEP

	percent = easing($, 0, FU)

	for i = 3, 1, -1 do
		local data = WINNERS[i]
		if not (data and data[1] and data[1].valid) then
			continue
		end

		local p = GetTeamLeader(data)

		local TARG = LOSER_WIDTH
		local SEP = LOSER_SEP

		if i == 1 then
			TARG = WINNER_WIDTH
			SEP = WINNER_SEP
		end

		local x = FIRST_X
		if i == 2 then
			x = SECOND_X
		elseif i == 3 then
			x = THIRD_X
		end

		local PATCH, FLIP = unpack(PATCHES[i])

		local offsetY = 0
		local scale = GetSpriteScale(PATCH, TARG, true)

		offsetY = $ - 80*scale
		offsetY = $ + FixedMul(HEIGHT, percent)

		local y = y+offsetY
		local color = v.getColormap(skins[p.skin].name, p.skincolor)

		if blinkWhite then
			color = v.getColormap(TC_BLINK, SKINCOLOR_WHITE)
		end

		DrawSprite(v, x, y, TARG, true, PATCH, V_SNAPTOLEFT|V_SNAPTOTOP, FLIP, color)

		x = $ + PATCH.width*scale/2
	end
end

local function GetPlayerStringWidth(v, p, text)
	local life
	local scale = FU/2
	if skins[p.skin].sprites[SPR2_LIFE].numframes then 
		scale = skins[p.skin].highresscale/2
		life = v.getSprite2Patch(p.skin,
			SPR2_LIFE, false, A, 0)
	else
		life = v.cachePatch("CONTINS")
	end

	return v.stringWidth(text, V_ALLOWLOWERCASE, "thin")*FU + life.width*scale + 2*FU
end

freeslot("SKINCOLOR_SUPERBLACK")
local ramp = {}
for i = 1,16 do
	ramp[i] = 31
end

skincolors[SKINCOLOR_SUPERBLACK] = {
	name = "sybau",
	ramp = ramp,
	invcolor = SKINCOLOR_ORANGE,
	invshade = 9,
	chatcolor = V_BLUEMAP,
	accessible = false
}

local function DrawFlash(v, percent)
	local patch = v.cachePatch("FH_PINK_SCROLL")
	local sw = v.width() * FU / v.dupx()
	local sh = v.height() * FU / v.dupy()

	local alpha = V_10TRANS*ease.linear(percent, 10, 0)
	if alpha > V_90TRANS then return end

	v.drawStretched(
		0, 0,
		FixedDiv(sw, patch.width*FU),
		FixedDiv(sh, patch.height*FU),
		patch,
		alpha|V_SNAPTOTOP|V_SNAPTOLEFT,
		v.getColormap(TC_BLINK, SKINCOLOR_WHITE)
	)
end

local function DrawFade(v, percent)
	local patch = v.cachePatch("FH_PINK_SCROLL")

	local alpha = V_10TRANS*ease.linear(percent, 10, 0)
	if alpha > V_90TRANS then return end

	local sw = v.width() * FU / v.dupx()
	local sh = v.height() * FU / v.dupy()

	v.drawStretched(
		0, 0,
		FixedDiv(sw, patch.width*FU),
		FixedDiv(sh, patch.height*FU),
		patch,
		alpha|V_SNAPTOTOP|V_SNAPTOLEFT,
		v.getColormap(TC_BLINK, SKINCOLOR_SUPERBLACK)
	)
end

local function DrawPlayerString(v, x, y, p, text, flags, align)
	local name = GetPlayerName(p)

	local life
	local scale = FU/2
	if skins[p.skin].sprites[SPR2_LIFE].numframes then 
		scale = skins[p.skin].highresscale/2
		life = v.getSprite2Patch(p.skin,
			SPR2_LIFE, false, A, 0)
	else
		life = v.cachePatch("CONTINS")
	end

	local color = v.getColormap(skins[p.skin].name, p.skincolor)
	local chatcolor = skincolors[p.skincolor].chatcolor

	local width = GetPlayerStringWidth(v, p, text)

	x = $*FU
	y = $*FU

	if align == "center" then
		x = $ - width/2
	elseif align == "right" then
		x = $ - width
	end

	v.drawString(x, y, text, (flags or 0)|V_ALLOWLOWERCASE|chatcolor, "thin-fixed")
	x = $ + v.stringWidth(text, V_ALLOWLOWERCASE, "thin")*FU + 2*FU

	v.drawScaled(x+life.leftoffset*scale, y+life.topoffset*scale, scale, life, flags, color)
end

local function DrawWinnerText(v)
	local WINNERS = FangsHeist.Net.placements

	local x = 160
	local y = 8

	if not (WINNERS and WINNERS[1] and WINNERS[1][1] and WINNERS[1][1].valid) then
		local string = "NO WINNERS"
		local width = v.levelTitleWidth(string)

		v.drawLevelTitle(x - width/2, y, string, V_SNAPTOTOP)
		return
	end

	local winner = WINNERS[1]
	local p = GetTeamLeader(winner)
	local string = GetTeamString(winner)

	local color = p.skincolor
	if color == SKINCOLOR_NONE then
		color = SKINCOLOR_BLUE
	end

	local chatcolor = skincolors[color].chatcolor
	local width = v.levelTitleWidth(string)

	--v.drawLevelTitle(x - width/2, y, string, V_SNAPTOTOP|chatcolor)
	customhud.CustomFontString(v,
		x*FU,
		y*FU,
		string,
		"FHBFT",
		V_SNAPTOTOP,
		"center",
		FU,
		color)
	y = $ + 22 + 2

	-- v.drawString(x, y, FangsHeist.Net.game_over_winline:gsub("PlayerName", string), V_SNAPTOTOP|chatcolor|V_ALLOWLOWERCASE, "thin-center")
	customhud.CustomFontString(v,
		x*FU,
		y*FU,
		FangsHeist.Net.game_over_winline:gsub("PlayerName", string),
		"FHFNT",
		V_SNAPTOTOP,
		"center",
		FU,
		color)
	y = $+13+4

	-- RUNNER-UPS
	if #WINNERS <= 1 then
		return
	end

	v.drawString(x, y, "Runner-ups:", V_SNAPTOTOP|V_ALLOWLOWERCASE, "thin-center")

	for i = 2, 4 do
		if not (WINNERS[i]
		and WINNERS[i][1]
		and WINNERS[i][1].valid) then
			continue
		end

		local team = WINNERS[i]
		local p = team[1]

		y = $+10
		DrawPlayerString(v, x, y, p, GetTeamString(team), V_SNAPTOTOP, "center")
	end
end

local MAP_GRAP = "MAP%sP"
local MAP_SCALE = FU/3

local function DrawMapSelection(v, x, y, map, votes, selected, confirmed, flags)
	flags = $ or 0

	-- Map is drawn from center.
	local mapName = G_BuildMapName(map).."P"
	if not v.patchExists(mapName) then
		mapName = MAP_GRAP:format("01")
	end

	local patch = v.cachePatch(mapName)

	x = $ - patch.width*MAP_SCALE/2
	y = $ - patch.height*MAP_SCALE/2

	v.drawScaled(x, y, MAP_SCALE, patch, flags)

	local STRING_X = x + patch.width*MAP_SCALE/2
	local VOTES_Y = y + patch.height*MAP_SCALE + 2*FU

	flags = $ or 0

	if selected
	and confirmed then
		flags = $|V_GREENMAP
	end

	v.drawString(STRING_X, VOTES_Y, tostring(votes), flags, "thin-fixed-center")

	if not selected then return end

	local NAME_Y = y - 9*FU - 2*FU
	local RETAKE_Y = NAME_Y - 9*FU

	v.drawString(STRING_X, NAME_Y, G_BuildMapTitle(map), flags|V_ALLOWLOWERCASE, "thin-fixed-center")

	if map == gamemap then
		flags = ($ & ~V_GREENMAP)|V_REDMAP
		v.drawString(STRING_X, RETAKE_Y, "RETAKE", flags, "thin-fixed-center")
	end
end

local function DrawMapVote(v, percent)
	percent = ease.outquart($, 0, FU)
	local y = FU - ease.linear(percent, 0, FU/2)

	local maps = FangsHeist.Net.map_choices
	
	local selected = 2
	local confirmed = false
	local p = consoleplayer

	if p
	and p.valid
	and p.heist then
		selected = p.heist.selected
		confirmed = p.heist.voted
	end

	for i, map in ipairs(maps) do
		local selected = selected == i
		local pos = FixedMul(FU/2, FixedDiv(i, #maps-1))
		local x, y = GetXYCoords(v, pos, y)

		DrawMapSelection(v, x, y, map.map, map.votes, selected, confirmed, V_SNAPTOLEFT|V_SNAPTOTOP)
	end
end

local function DrawBlackout(v, tics)
	local RAISE_OFFSET = 0
	local FLASH_OFFSET = 15
	local FADE_DUR = 8

	v.drawFill()

	local raise_tics = max(0, tics - RAISE_OFFSET)
	local flash_tics = max(0, tics - FLASH_OFFSET)
	local fade_tics = min(tics, FADE_DUR)

	DrawWinners(v, FU-fixdiv(raise_tics, FangsHeist.BLACKOUT_TICS-RAISE_OFFSET), true, ease.outcubic)
	--v.drawString(160, 100-5, "This game's winner is...", V_ALLOWLOWERCASE, "center")
	customhud.CustomFontString(v,
		160*FU,
		100*FU - 13*FU/2,
		"This game's winner is...",
		"FHFNT",
		0,
		"center",
		FU,
		SKINCOLOR_WHITE)

	DrawFlash(v, FixedDiv(flash_tics, FangsHeist.BLACKOUT_TICS-FLASH_OFFSET))
	DrawFade(v, FU-FixedDiv(fade_tics, FADE_DUR))
end

freeslot("SPR_MCVD") -- SAXA: srb2 limitations
local function DrawResults(v)
	local tics = FangsHeist.Net.game_over_ticker - FangsHeist.GAME_TICS
	local remaining = FangsHeist.SWITCH_TICS - FangsHeist.Net.game_over_ticker

	if tics < FangsHeist.BLACKOUT_TICS then
		DrawBlackout(v, tics)
		return
	end

	DrawWinnerParallax(v)

	local num = remaining/TICRATE
	local str = tostring(num)
	local x = 4*FU

	for i = 1,#str do
		local num = tonumber(string.sub(str, i, i))
		local patch = v.cachePatch("STTNUM"..num)

		v.drawScaled(x, 4*FU, FU, patch, V_SNAPTOLEFT|V_SNAPTOTOP|f)
		x = $+patch.width*FU
	end

	local transition = 12
	local FLASH_OFFSET = 7

	if FangsHeist.isMapVote() then
		local tics = FangsHeist.Net.game_over_ticker - FangsHeist.RESULTS_TICS
		local trans_tics = min(tics, transition)
		DrawMapVote(v, FixedDiv(trans_tics, transition))

		local flash_tics = min(tics, FLASH_OFFSET)
		DrawFlash(v, FU-FixedDiv(flash_tics, FLASH_OFFSET))

		return
	end

	local until_vote = FangsHeist.RESULTS_TICS - FangsHeist.Net.game_over_ticker
	local percent_tics = max(0, transition - until_vote)

	DrawWinners(v, FixedDiv(percent_tics, transition), false, ease.inquart)
	DrawWinnerText(v)

	local TICS = min(tics-FangsHeist.BLACKOUT_TICS, FLASH_OFFSET)

	DrawFlash(v, FU-fixdiv(TICS, FLASH_OFFSET))
end

local function DrawHeistBackground(v)
	local patch = v.cachePatch("HEISTBACK")

	local sw = (v.width() / v.dupx()) * FU
	local sh = (v.height() / v.dupy()) * FU

	local y = -patch.height*FU + (leveltime*FU/3) % (patch.height*FU)
	local x = -patch.width*FU + (leveltime*FU/3) % (patch.width*FU)

	while y < sh do
		local x = x

		while x < sw do
			v.drawScaled(x, y, FU, patch, V_SNAPTOLEFT|V_SNAPTOTOP)
			x = $+patch.width*FU
		end
	
		y = $+patch.height*FU
	end
end

local function DrawGame(v)
	local tics = FangsHeist.Net.game_over_ticker
	local remain = FangsHeist.GAME_TICS - tics

	local flash_dur = 12
	local flash_tics = min(tics, flash_dur)
	local flash_frac = FU-FixedDiv(flash_tics, flash_dur)

	local fade_dur = 10
	local fade_tics = max(0, fade_dur - remain)
	local fade_frac = FixedDiv(fade_tics, fade_dur)

	local game = v.cachePatch("FH_GAMESET")
	local game_scale = FU

	DrawHeistBackground(v)
	v.drawScaled(160*FU - game.width*game_scale/2, 100*FU - game.height*game_scale/2, game_scale, game)
	DrawFlash(v, flash_frac)
	DrawFade(v, fade_frac)
end

function module.init()
end

function module.draw(v)
	if not FangsHeist.Net.game_over then
		return
	end

	if FangsHeist.isGameAnim() then
		DrawGame(v)
		return
	end

	DrawResults(v)
end

return module, "gameandscores"