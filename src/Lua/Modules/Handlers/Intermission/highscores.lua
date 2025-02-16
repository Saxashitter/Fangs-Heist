local module = {}

local text = FangsHeist.require"Modules/Libraries/text"

module.name = "High Scores"

function module.think(p) // runs when selected
end

local TRIM_LENGTH = 12
local function trim(str)
	if #str > TRIM_LENGTH then
		local trim = string.sub(str, 1, TRIM_LENGTH-3)

		trim = $.."..."

		return trim
	end

	return str
end

local function draw_data(v, data, i)
	local skin = data[1]
	local color = trim(data[2])
	local name = data[3]
	local score = data[4]

	if not skins[skin] then
		skin = "sonic"
	end

	color = FangsHeist.getColorByName(color)
	
	local life
	local scale = FU
	if skins[skin].sprites[SPR2_LIFE].numframes then 
		life = v.getSprite2Patch(skin,
			SPR2_LIFE, false, A, 0)
		scale = skins[skin].highresscale
	else
		life = v.cachePatch("CONTINS")
	end

	local x = 16*FU
	local y = 40*FU

	y = $+(10*((i-1)*FU))

	v.drawScaled(x + (life.topoffset*scale/2),
		y + (life.topoffset*scale/2),
		scale/2,
		life,
		0,
		v.getColormap(skin, color))

	v.drawString(x + 16*FU,
		y,
		name,
		V_ALLOWLOWERCASE,
		"fixed")

	v.drawString(x + 16*FU + v.stringWidth(name, V_ALLOWLOWERCASE)*FU + 4*FU,
		y,
		tostring(score),
		0,
		"fixed")
end

function module.draw(v)
	local plyrs = {}

	local width = v.width()*FU/v.dupx()
	local height = v.height()*FU/v.dupy()

	local scores = FangsHeist.Save.ServerScores[gamemap]

	if not (scores and #scores) then
		text.draw(v,
			160*FU,
			100*FU - 21*FU/2,
			FU,
			"NO SCORES!",
			"FHFNT",
			"center",
			0,
			v.getColormap(nil, SKINCOLOR_RED)
		)
		return
	end

	for k,i in pairs(scores) do
		draw_data(v, i, k)
	end
end

return module