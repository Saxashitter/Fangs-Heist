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
	local patches = {}

	for i = 1,#str do
		local letter = str:sub(i, i)
		local byte = letter:byte()
		local name = string.format("%s%03d", font, byte)

		if not patches[byte]
		and not v.patchExists(name) then
			width = $ + def.space*scale
	
			if i < #str then
				width = $ + def.padding*scale
			end

			continue
		end

		local patch = patches[byte] or v.cachePatch(name)

		width = $ + patch.width*scale

		if i < #str then
			width = $ + def.padding*scale
		end
		patches[byte] = $ or patch
	end

	return width, patches
end

local function GetNumberWidth(v, number, scale, font)
	local width = 0
	local def = FangsHeist.FontDefs[font] or DEFAULT
	local str = tostring(number)
	local patches = {}

	for i = 1,#str do
		local letter = str:sub(i, i)
		local name = string.format("%s%s", font, letter)

		if not patches[i]
		and not v.patchExists(name) then
			width = $ + def.space*scale
	
			if i < #str then
				width = $ + def.padding*scale
			end

			continue
		end

		local patch = patches[i] or v.cachePatch(name)

		width = $ + patch.width*scale

		if i < #str then
			width = $ + def.padding*scale
		end
		patches[i] = $ or patch
	end

	return width, patches
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
	local width, patches = GetStringWidth(v, str, scale, font)

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

		if not patches[byte] then
			x = $ + def.space*scale
	
			if i < #str then
				x = $ + def.padding*scale
			end

			continue
		end

		local patch = patches[byte]

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
	local width, patches = GetNumberWidth(v, number, scale, font)

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

		if not patches[i] then
			x = $ + def.space*scale
	
			if i < #str then
				x = $ + def.padding*scale
			end

			continue
		end

		local patch = patches[i]

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