local text = {}

local patches = {}
local get_patch = function(v, patch)
	if not patches[patch] then
		patches[patch] = v.cachePatch(patch) or v.cachePatch("MISSING")
	end

	return patches[patch]
end

text.draw = function(v, x, y, scale, str, font, align, flags, color)
	local graphics = {}

	if not str then return end

	local SPACE_SPACING = 4
	local width = 0
	local height = 0

	for i = 1,#str do
		local cut = string.sub(str, i, i)

		if cut == " " then // space lol
			width = $+(SPACE_SPACING*scale)
		end

		graphics[i] = get_patch(v, string.format(font.."%03d", cut:byte()))
	end

	for k,v in pairs(graphics) do
		width = $+(v.width*scale)
		height = max($, v.height*scale)
	end

	if align == "center" then
		x = $-width/2
	end
	if align == "right" then
		x = $-width
	end

	for i = 1,#str do
		local graphic = graphics[i]

		if not graphics[i] then
			x = $+(SPACE_SPACING*scale)
			continue
		end

		local y_offset = -((graphic.height*scale)-height)/2

		v.drawScaled(x, y+y_offset, scale, graphic, flags, color)
		x = $+(graphic.width*scale)
	end
end

return text