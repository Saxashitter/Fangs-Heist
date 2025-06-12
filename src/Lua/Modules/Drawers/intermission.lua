local module = {}

local test = CV_RegisterVar{
	name = "blackout",
	defaultvalue = 60
}
local WINNER_SEP = 90*FU
local WINNER_WIDTH = 128

local LOSER_SEP = 50*FU
local LOSER_WIDTH = 86

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

local function GetTeamLeader(team)
	for _, p in ipairs(team) do
		if p
		and p.valid then
			return p
		end
	end
end

local function GetTeamString(team)
	local p = GetTeamLeader(team)

	if not (p and p.valid) then
		return ""
	end

	if #team > 1 then
		return "Team "..p.name
	end

	return p.name
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

	local char = FangsHeist.Characters["sonic"]

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

local WINNERS = {
	{
		skin = "sonic",
		color = SKINCOLOR_BLUE
	},
	{
		skin = "tails",
		color = SKINCOLOR_ORANGE
	},
	{
		skin = "knuckles",
		color = SKINCOLOR_RED
	}
}

local function DrawWinners(v, progress)
	-- Plan: During blackout, the players will be drawn innpure white.
	-- After which, the screen flashes and then the players stay still.

	local WINNERS = FangsHeist.Net.placements
	local PATCHES = {}

	local WIDTH = 0

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

	for i = #WINNERS, 1, -1 do
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

		local y = y+offsetY
		local color = v.getColormap(skins[p.skin].name, p.skincolor)

		DrawSprite(v, x, y, TARG, true, PATCH, V_SNAPTOLEFT|V_SNAPTOTOP, FLIP, color)

		x = $ + PATCH.width*scale/2
	end
end

local function DrawWinnerText(v)
	local WINNERS = FangsHeist.Net.placements

	local x = 160
	local y = 8

	if not (WINNERS and WINNERS[1] and WINNERS[1][1] and WINNERS[1][1].valid) then
		local string = "NO WINNERS"
		local width = v.levelTitleWidth(string)

		v.drawLevelTitle(x - width/2, y, string, V_SNAPTOTOP)
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

	v.drawLevelTitle(x - width/2, y, string, V_SNAPTOTOP|chatcolor)

	y = $ + v.levelTitleHeight(string) + 2

	v.drawString(x, y, FangsHeist.Net.game_over_winline, V_SNAPTOTOP|chatcolor, "thin-center")
end

local function DrawBlackout(v, progress)
	v.drawFill()
	v.drawString(160, 100, "This game's winner is...", V_ALLOWLOWERCASE, "center")
end

local function DrawResults(v)
	local tics = FangsHeist.Net.game_over_ticker - FangsHeist.GAME_TICS

	if tics < test.value then
		DrawBlackout(v, fixdiv(tics, test.value))

		return
	end

	DrawWinnerParallax(v)

	if FangsHeist.isMapVote() then
	end

	DrawWinners(v, 0)
	DrawWinnerText(v)
end

local function DrawGame(v)
	local tics = FangsHeist.Net.game_over_ticker

	v.drawFill()
	v.drawString(160, 100, "GAME", 0, "center")
end

function module.init()
end

function module.draw(v)
	if not FangsHeist.Net.game_over then
		return
	end

	local BLACKOUT_TICS = test.value

	if FangsHeist.isGameAnim() then
		DrawGame(v)
		return
	end

	DrawResults(v)
end

return module, "gameandscores"