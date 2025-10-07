local DEFAULT = {
	space = 4,
	padding = 0
}

local fontCache = {}
local numCache = {}
local preCalculatedFont = {}
local preCalculatedNum = {}

FangsHeist.FontDefs = {
	CRFNT = {
		space = 8,
		padding = 0
	},
	FHARL = {
		space = 4,
		padding = 0
	},
}

local function GetStringWidth(v, str, scale, font)
	local width = 0
	local def = FangsHeist.FontDefs[font] or DEFAULT

	if not fontCache[font] then
		fontCache[font] = {}
	end

	if not preCalculatedFont[font] then
		preCalculatedFont[font] = {}
	end
	if preCalculatedFont[font][str] then
		return preCalculatedFont[font][str] * scale
	end

	for i = 1,#str do
		local letter = str:sub(i, i)
		local byte = letter:byte()
		local name = string.format("%s%03d", font, byte)

		if not fontCache[font][byte]
		and not v.patchExists(name) then
			width = $ + def.space
	
			if i < #str then
				width = $ + def.padding
			end

			continue
		end

		local patch = fontCache[font][byte]
	
		if not (patch and patch.valid) then
			fontCache[font][byte] = v.cachePatch(name)
			patch = fontCache[font][byte]
		end

		width = $ + patch.width

		if i < #str then
			width = $ + def.padding
		end
	
	end

	preCalculatedFont[font][str] = width
	return width * scale
end

local function GetNumberWidth(v, number, scale, font)
	local width = 0
	local def = FangsHeist.FontDefs[font] or DEFAULT
	local str = tostring(number)

	if not numCache[font] then
		numCache[font] = {}
	end

	for i = 1,#str do
		local letter = str:sub(i, i)
		local name = string.format("%s%s", font, letter)

		if not numCache[font][letter]
		and not v.patchExists(name) then
			width = $ + def.space*scale
	
			if i < #str then
				width = $ + def.padding*scale
			end

			continue
		end

		local patch = numCache[font][letter]
	
		if not (patch and patch.valid) then
			numCache[font][letter] = v.cachePatch(name)
			patch = numCache[font][letter]
		end

		width = $ + patch.width*scale

		if i < #str then
			width = $ + def.padding*scale
		end
	end

	return width
end

FangsHeist.GetStringWidth =	GetStringWidth
FangsHeist.GetNumberWidth = GetNumberWidth

local richCache = {}

function FangsHeist.DrawString(v, x, y, scale, str, font, align, flags, color, rich)
	local points = {}

	if rich
	and #str - 4 >= 4 then
		if not richCache[str] then
			local iter = 1
			local raw_str = str
	
			while iter < #str - 4 do
				local cut = str:sub(iter, iter+2)
	
				if cut == "[c:" then
					local _, length = str:sub(iter, #str):find("%b[]")
					local color = str:sub(iter+3, iter+length-2):upper()

					str = str:sub(1, iter - 1) .. str:sub(iter + length, #str)
					points[iter] = {
						color = color == "WHITE" and -1 or _G["V_"..color.."MAP"]
					}
				end
	
				iter = iter+1
			end

			richCache[raw_str] = {
				str = str,
				points = points
			}
		else
			points = richCache[str].points
			str = richCache[str].str
		end
	end
	local width = GetStringWidth(v, str, scale, font)

	if align == "center" then
		x = $ - width/2
	end

	if align == "right" then
		x = $ - width
	end

	local def = FangsHeist.FontDefs[font] or DEFAULT

	for i = 1,#str do
		local letter = str:sub(i, i)
		local byte = letter:byte()
		local name = string.format("%s%03d", font, byte)

		if not fontCache[font][byte] then
			x = $ + def.space*scale
	
			if i < #str then
				x = $ + def.padding*scale
			end

			continue
		end

		local patch = fontCache[font][byte]

		if points[i]
		and points[i].color ~= nil then
			if points[i].color == -1 then
				color = nil
			else
				color = v.getStringColormap(points[i].color)
			end
		end

		v.drawScaled(x, y, scale, patch, flags, color)

		x = $ + patch.width*scale

		if i < #str then
			x = $ + def.padding*scale
		end
	end
end

function FangsHeist.DrawNumber(v, x, y, scale, number, font, flags, color)
	local width = GetNumberWidth(v, number, scale, font)

	if align == "center" then
		x = $ - width/2
	end

	if align == "right" then
		x = $ - width
	end

	local str = tostring(number)
	local def = FangsHeist.FontDefs[font] or DEFAULT

	for i = 1,#str do
		local letter = str:sub(i, i)
		local name = string.format("%s%d", font, letter)

		if not numCache[font][letter] then
			x = $ + def.space*scale
	
			if i < #str then
				x = $ + def.padding*scale
			end

			continue
		end

		local patch = numCache[font][letter]

		v.drawScaled(x, y, scale, patch, flags, color)

		x = $ + patch.width*scale

		if i < #str then
			x = $ + def.padding*scale
		end
	end
end

function FangsHeist.DrawParallax(v, x, y, width, height, scale, patch, flags, ox, oy)
	local width = fixdiv(width, scale)
	local height = fixdiv(height, scale)

	local offsetX = fixdiv(ox or 0, scale)
	local offsetY = fixdiv(oy or 0, scale)

	local currentX = -offsetX
	local currentY = -offsetY

	while currentY < height do
		local sh = patch.height*FU

		if currentY+sh > height then
			sh = height - currentY
		end

		while currentX < width do
			local sw = patch.width*FU

			if currentX+sw > width then
				sw = width - currentX
			end

			v.drawCropped(
				x+FixedMul(max(0, currentX), scale),
				y+FixedMul(max(0, currentY), scale),
				scale,
				scale,
				patch,
				flags,
				nil,
				-min(currentX, 0),
				-min(currentY, 0),
				sw + min(currentX, 0),
				sh + min(currentY, 0)
			)

			currentX = $+sw
		end

		currentY = $+sh
		currentX = -offsetX
	end
end