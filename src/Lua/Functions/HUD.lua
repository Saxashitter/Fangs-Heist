local DEFAULT = {
	space = 4,
	padding = 0
}

FangsHeist.FontDefs = {
	CRFNT = {
		space = 8,
		padding = 0
	}
}

local function GetStringWidth(v, str, scale, font)
	local width = 0
	local def = FangsHeist.FontDefs[font] or DEFAULT

	for i = 1,#str do
		local letter = str:sub(i, i)
		local byte = letter:byte()
		local name = string.format("%s%03d", font, byte)

		if not v.patchExists(name) then
			width = $ + def.space*scale
	
			if i < #str then
				width = $ + def.padding*scale
			end

			continue
		end

		local patch = v.cachePatch(name)

		width = $ + patch.width*scale

		if i < #str then
			width = $ + def.padding*scale
		end
	end

	return width
end

local function GetNumberWidth(v, number, scale, font)
	local width = 0
	local def = FangsHeist.FontDefs[font] or DEFAULT
	local str = tostring(number)

	for i = 1,#str do
		local letter = str:sub(i, i)
		local name = string.format("%s%s", font, letter)

		if not v.patchExists(name) then
			width = $ + def.space*scale
	
			if i < #str then
				width = $ + def.padding*scale
			end

			continue
		end

		local patch = v.cachePatch(name)

		width = $ + patch.width*scale

		if i < #str then
			width = $ + def.padding*scale
		end
	end

	return width
end

FangsHeist.GetStringWidth =	GetStringWidth
FangsHeist.GetNumberWidth = GetNumberWidth

function FangsHeist.DrawString(v, x, y, scale, str, font, align, flags, color)
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

		if not v.patchExists(name) then
			x = $ + def.space*scale
	
			if i < #str then
				x = $ + def.padding*scale
			end

			continue
		end

		local patch = v.cachePatch(name)

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

		if not v.patchExists(name) then
			x = $ + def.space*scale
	
			if i < #str then
				x = $ + def.padding*scale
			end

			continue
		end

		local patch = v.cachePatch(name)

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