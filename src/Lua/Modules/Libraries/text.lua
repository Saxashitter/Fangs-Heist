local text = {}

local patches = {}
local function get_patch(v, patch)
	if not patches[patch] then
		patches[patch] = v.cachePatch(patch)
		if patch ~= "MISSING" and patches[patch] == get_patch(v, "MISSING") then
			patches[patch] = nil
		end
	end

	return patches[patch]
end

text.draw = function(v, x, y, scale, str, font, align, flags, color)
	local graphics = {}

	if not str then return end

	local SPACE_SPACING = 4
	local width = 0

	for i = 1,#str do
		local cut = string.sub(str, i, i)

		if cut == " " then // space lol
			width = $+(SPACE_SPACING*scale)
			continue
		end

		graphics[i] = get_patch(v, string.format(font.."%03d", cut:byte()))
	end

	for k,v in pairs(graphics) do
		width = $+(v.width*scale)
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

		-- local y_offset = -((graphic.height*scale)-height)/2

		v.drawScaled(x, y, scale, graphic, flags, color)
		x = $+(graphic.width*scale)
	end
end

return text