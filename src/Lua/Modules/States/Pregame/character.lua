local state = {}

local SKINS_ROW = 12
local SKINS_WIDTH = 16*FU
local SKINS_PADDING = 2*FU
local SKINS_UNSELECTED_SCALE = FU
local SKINS_SELECTED_SCALE = tofixed("1.25")

local RIBBON_START_RADIUS = 5*FU
local RIBBON_END_RADIUS = 40*FU
local RIBBON_TWEEN = 7

local CHAR_TWEEN = 10

-- start x defined by text width
local TEXT_END_X = 8*FU
local TEXT_DELAY = 4
local TEXT_TWEEN = 12

local function Twn(tics, dur)
	return FixedDiv(max(0, min(tics, dur)), dur)
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

local function GetSkinPortrait(v, skin)
	if IsSpriteValid(skin, SPR2_FHBN, A) then
		return v.getSprite2Patch(skin, SPR2_FHBN, false, A)
	end

	if IsSpriteValid(skin, SPR2_XTRA, B) then
		return v.getSprite2Patch(skin, SPR2_XTRA, false, B)
	end

	return v.getSprite2Patch("sonic", SPR2_FHBN, false, A)
end

local function GetSkinIcon(v, skin)
	if IsSpriteValid(skin, SPR2_LIFE, A) then
		return v.getSprite2Patch(skin, SPR2_LIFE, false, A)
	end

	return v.cachePatch("CONTINS"), true
end

local rect

local function DrawRect(v, x, y, width, height, flags, color)
	if not rect
	or not rect.valid then
		rect = v.cachePatch("FH_BLACK")
	end

	local xscale = FixedDiv(width, rect.width*FU)
	local yscale = FixedDiv(height, rect.height*FU)

	v.drawStretched(
		x, y, xscale, yscale, rect, flags, color
	)
end

local function DrawOutline(v, x, y, width, height, flags, color)
	DrawRect(v, x, y, width, FU, flags, color)
	DrawRect(v, x + width - FU, y, FU, height, flags, color)
	DrawRect(v, x, y + height - FU, width, FU, flags, color)
	DrawRect(v, x, y, FU, height, flags, color)
end

local function DrawCharacterRibbon(v, y, skin, flags, tics)
	local skin_data = FangsHeist.CharList[skin]
	local portrait = GetSkinPortrait(v, skin_data.name)
	local color = v.getColormap(skin, skin_data.prefcolor)

	local sw = v.width() * FU / v.dupx()
	local sh = v.height() * FU / v.dupy()

	local scale = FixedMul(skin_data.highresscale, tofixed("0.75"))

	-- Animation
	tics = $ or 0

	-- Ribbon
	local rr = ease.outquad(
		Twn(tics, RIBBON_TWEEN),
		RIBBON_START_RADIUS,
		RIBBON_END_RADIUS
	)

	local rx = 0
	local ry = y - rr/2

	DrawRect(v, rx, ry, sw, rr, V_SNAPTOLEFT|flags, v.getColormap(TC_BLINK, skin_data.prefcolor))

	-- Portrait
	local px = ease.outquad(
		Twn(tics, CHAR_TWEEN),
		320*FU,
		316*FU - portrait.width*scale
	)

	local py = y - portrait.height*scale/2
	local po = 5*FU

	v.drawScaled(px+po, py+po, scale, portrait, V_SNAPTORIGHT|flags, v.getColormap(TC_BLINK, skin_data.prefcolor))
	v.drawScaled(px, py, scale, portrait, V_SNAPTORIGHT|flags)

	-- Name
	local width = customhud.CustomFontStringWidth(v, skin_data.realname, "FHBFT", FU)
	local tx = ease.outquad(
		Twn(tics-TEXT_DELAY, TEXT_TWEEN),
		-width,
		8*FU)
	local ty = y - 22*FU/2

	customhud.CustomFontString(v,
		tx,
		ty,
		skin_data.realname,
		"FHBFT",
		V_SNAPTOLEFT|flags,
		"left",
		FU,
		skin_data.prefcolor)
end

local function GetIconGridWidth(v, selection)
	local total_width = 0
	local width = 0

	for i = 1, #FangsHeist.CharList do
		local skin = FangsHeist.CharList[i]
		local icon = GetSkinIcon(v, skin.name)
		local icon_scale = SKINS_UNSELECTED_SCALE

		if i == selection then
			icon_scale = SKINS_SELECTED_SCALE
		end

		if (i-1) % SKINS_ROW == 0 then
			width = 0
		end

		width = $ + FixedMul(SKINS_WIDTH, icon_scale)
		if (i-1) % SKINS_ROW ~= SKINS_ROW-1
		and i < #FangsHeist.CharList then
			width = $ + SKINS_PADDING
		end

		total_width = max($,  width)
	end

	return total_width
end

local function DrawIconGrid(v, x, y, selection, flags)
	local width = 0
	local height = 0

	for i = 1, #FangsHeist.CharList do
		local skin = FangsHeist.CharList[i]
		local icon, null = GetSkinIcon(v, skin.name)
		local icon_scale = SKINS_UNSELECTED_SCALE

		if i % SKINS_ROW == 0 then
			y = $ + height + SKINS_PADDING

			width = 0
			height = 0
		end

		local ds = FixedMul(skin.highresscale, icon_scale)
		local dx = x + icon.leftoffset*ds + width
		local dy = y + icon.topoffset*ds

		if null then
			ds = icon_scale
		end
	
		-- center the positions to the icons midpoint
		dx = $ + SKINS_WIDTH/2 - icon.width*ds/2
		dy = $ + SKINS_WIDTH/2 - icon.height*ds/2

		v.drawScaled(dx, dy, ds, icon, flags, v.getColormap(skin.name, skin.prefcolor))
	
		if i == selection then
			-- draw lines around selected character
			DrawOutline(v, x+width-FU, y-FU, SKINS_WIDTH+2*FU, SKINS_WIDTH+2*FU, flags, v.getColormap(TC_BLINK, SKINCOLOR_RED))
		end
	
		width = $ + FixedMul(SKINS_WIDTH, icon_scale)

		if i % SKINS_ROW ~= SKINS_ROW-1
		and i < #FangsHeist.CharList then
			width = $ + SKINS_PADDING
		end

		height = max($, SKINS_WIDTH)
	end
end

local function ChangeSelection(self, x, unrelative)
	local prev = self.heist.skin_index

	self.heist.skin_index = $+x
	if unrelative then
		self.heist.skin_index = x
	end

	if self.heist.skin_index > #FangsHeist.CharList then
		self.heist.skin_index = 1
	elseif self.heist.skin_index < 1 then
		self.heist.skin_index = #FangsHeist.CharList
	end

	if prev == self.heist.skin_index then
		return
	end

	self.heist.locked_skin = FangsHeist.CharList[self.heist.skin_index].name
	self.heist.cs_switchtime = 0
	self.heist.alt_skin = 0

	S_StartSound(nil, sfx_menu1, self)
end

function state:enter()
	self.heist.cs_switchtime = 0
end

function state:exit()
	self.heist.cs_switchtime = nil
end

function state:tick()
	local x, y = FangsHeist.getPressDirection(self)

	if self.heist.buttons & BT_JUMP
	and not (self.heist.lastbuttons & BT_JUMP) then
		S_StartSound(nil, sfx_strpst, self)
		return "team"
	end

	self.heist.cs_switchtime = $+1

	if abs(x) > 0 then
		ChangeSelection(self, x)
	end

	if abs(y) > 0
	and #skins > SKINS_ROW then
		local i = self.heist.locked_skin + SKINS_ROW*y

		if i >= 0
		and i <= #skins-1 then
			ChangeSelection(self, self.heist.locked_skin + SKINS_ROW*y, true)
		end
	end

	local skindef = skins[self.heist.locked_skin]
	local heistskindef = FangsHeist.Characters[skindef.name]

	if #heistskindef.skins > 0
	and self.heist.buttons & BT_CUSTOM1
	and not (self.heist.lastbuttons & BT_CUSTOM1) then
		self.heist.alt_skin = ($+1) % (#heistskindef.skins+1)
		S_StartSound(nil, sfx_menu1)
	end
end

function state:draw(v, c, transparency)
	local skin_data = FangsHeist.CharList[self.heist.skin_index]
	local width = GetIconGridWidth(v, self.heist.skin_index)
	local tics = self.heist.cs_switchtime

	local skindef = skins[self.heist.locked_skin]
	local heistskindef = FangsHeist.Characters[skindef.name]

	DrawCharacterRibbon(v, 100*FU, self.heist.skin_index, transparency, tics)
	if tics >= TEXT_DELAY + TEXT_TWEEN then
		DrawIconGrid(v, 160*FU - width/2, 100*FU + RIBBON_END_RADIUS, self.heist.skin_index, transparency)
	end

	if #heistskindef.skins > 0 then
		local skin = heistskindef.skins[self.heist.alt_skin]
		local name = "Default"

		if skin then
			name = skin.name or $
		end
		v.drawString(160*FU, 100*FU - 10*FU - RIBBON_END_RADIUS/2, "[CUSTOM 1] - Change Skin ("..name..")", V_ALLOWLOWERCASE, "thin-fixed-center")
	end
end

return state