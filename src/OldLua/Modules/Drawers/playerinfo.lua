local module = {}

local PROFITFORM = string.char(1) .. " %d"
local RINGSFORM = string.char(2) .. " %d"
local RANKFORM = "[c:red]P [c:white]%s"

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

local function returnPlace(i)
	local format = "%dth"

	if i == 1 then
		format = "%dst"
	elseif i == 2 then
		format = "%dnd"
	elseif i == 3 then
		format = "%drd"
	end

	return format:format(i)
end


local function DrawText(v, x, y, string, flags, align, color, rich)
	FangsHeist.DrawString(v,
		x*FU,
		y*FU,
		FU,
		string,
		"FHTXT",
		align,
		flags,
		color,
		rich)
end

function module.draw(v, p)
	if FangsHeist.Net.pregame then return end
	if FangsHeist.Net.game_over then return end
	if not p.heist:isAlive() then return end
	
	local team = p.heist:getTeam()
	local pi = FangsHeist.getGamemode().preferredhud

	local rings = RINGSFORM:format(p.rings)
	local profit = PROFITFORM:format(team.profit)
	local rank = RANKFORM:format(returnPlace(team.place or 0))

	if pi.rings.string then
		rings = pi.rings.string(p.rings)
	end
	if pi.profit.string then
		profit = pi.profit.string(team.profit)
	end
	if pi.rank.string then
		rank = pi.rank.string(returnPlace(team.place or 0))
	end

	local strings = {
		{str = rings, on = pi.rings.enabled},
		{str = profit, on = pi.profit.enabled},
		{str = rank, on = pi.rank.enabled},
	}

	local multiplier = p.heist:getMultiplier()

	if multiplier > 1 then
		strings[2].str = $ .. " [c:yellow]"..multiplier.."x"
	end

	local y = pi.pos.y

	for k,data in ipairs(strings) do
		if not data.on then
			continue
		end

		DrawText(v, pi.pos.x, y, data.str, pi.pos.flags, "left", nil, true)
		y = $ + 11
	end
end

return module